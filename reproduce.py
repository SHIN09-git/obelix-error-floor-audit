#!/usr/bin/env python3
"""Offline numerical reproduction. Original code: MIT; see LICENSING.md."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from uuid import uuid4

ROOT = Path(__file__).resolve().parent
TOLERANCE = 1e-12


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def verify_manifest(root):
    manifest = read_json(root / "RELEASE_MANIFEST.json")
    records = manifest["files"]
    if not records:
        raise ValueError("Release manifest is empty.")
    seen = set()
    for record in records:
        relative = PurePosixPath(record["path"])
        if relative.is_absolute() or ".." in relative.parts or "\\" in record["path"]:
            raise ValueError("Unsafe manifest path.")
        if record["path"] in seen:
            raise ValueError("Duplicate manifest path: " + record["path"])
        seen.add(record["path"])
        path = root.joinpath(*relative.parts)
        if not path.resolve().is_relative_to(root.resolve()) or path.is_symlink():
            raise ValueError("Manifest path leaves release: " + record["path"])
        if not path.is_file():
            raise ValueError("Missing release file: " + record["path"])
        data = path.read_bytes()
        if len(data) != record["bytes"] or hashlib.sha256(data).hexdigest() != record["sha256"]:
            raise ValueError("Release integrity check failed: " + record["path"])
    return len(records)


def compare(actual, expected, label):
    """Compare structure and categories exactly; allow only tiny float drift."""
    if isinstance(expected, float):
        if isinstance(actual, bool) or not isinstance(actual, (int, float)):
            raise ValueError(label + ": expected a number")
        if not math.isclose(actual, expected, rel_tol=0.0, abs_tol=TOLERANCE):
            raise ValueError(label + ": numerical mismatch")
        return 1
    if type(actual) is not type(expected):
        raise ValueError(label + ": type mismatch")
    if isinstance(expected, dict):
        if actual.keys() != expected.keys():
            raise ValueError(label + ": key mismatch")
        return sum(compare(actual[k], expected[k], label + "." + k) for k in expected)
    if isinstance(expected, list):
        if len(actual) != len(expected):
            raise ValueError(label + ": length mismatch")
        return sum(compare(a, e, label + "[" + str(i) + "]")
                   for i, (a, e) in enumerate(zip(actual, expected)))
    if actual != expected:
        raise ValueError(label + ": value mismatch")
    return 1


def compare_results(destination):
    actual = read_json(destination / "reports/round11/error_bound_audit.json")
    expected = read_json(ROOT / "reference_results/error_bound_audit.json")
    # The historical result also lists reading copies of papers that are not
    # redistributed. Compare every numerical/semantic field and the sources
    # actually present in this portable release.
    expected["sources"] = [
        item for item in expected["sources"] if (ROOT / item["path"]).is_file()
    ]
    count = compare(actual, expected, "error_bound_audit")
    count += compare(
        read_json(destination / "reports/round11/repeated_group_audit.json"),
        read_json(ROOT / "reports/round11/repeated_group_audit.json"),
        "repeated_group_audit",
    )
    numeric = {
        "MAD_dex", "sum_absolute_deviations_dex", "absolute_deviation_share",
        "MAD_dex_excluding_this_group",
    }

    def csv_records(path):
        with path.open(encoding="utf-8", newline="") as handle:
            return [{key: float(value) if key in numeric else value
                     for key, value in row.items()} for row in csv.DictReader(handle)]

    count += compare(
        csv_records(destination / "reports/round11/repeated_groups.csv"),
        csv_records(ROOT / "reports/round11/repeated_groups.csv"),
        "repeated_groups.csv",
    )
    validation = read_json(destination / "reports/round11/VALIDATION.json")
    if validation["checks_passed"] != 41 or validation["core_only"] is not True:
        raise ValueError("Expected the 41 portable core checks.")
    return actual, validation, count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify-only", action="store_true",
                        help="Check packaged file hashes; do not write output.")
    parser.add_argument("--output", type=Path,
                        help="New output directory, outside the repository or under reproductions/.")
    args = parser.parse_args()
    if sys.version_info < (3, 11):
        parser.error("Python 3.11 or newer is required.")
    if args.verify_only and args.output:
        parser.error("--verify-only cannot be combined with --output.")
    file_count = verify_manifest(ROOT)
    if args.verify_only:
        print(json.dumps({"status": "PASS", "manifest_files_verified": file_count}, indent=2))
        return
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    destination = (args.output or ROOT / "reproductions" / (stamp + "-" + uuid4().hex[:8])).expanduser().resolve()
    if destination.is_relative_to(ROOT) and not destination.is_relative_to(ROOT / "reproductions"):
        parser.error("Within the repository, output must be under reproductions/.")
    # Never overwrite a previous run or a user-supplied directory.
    destination.mkdir(parents=True, exist_ok=False)
    for directory in ("evidence", "sources"):
        shutil.copytree(ROOT / directory, destination / directory)
    (destination / "scripts").mkdir()
    for name in ("audit_obelix_error_bound.py", "verify_obelix_error_bound.py"):
        shutil.copy2(ROOT / "scripts" / name, destination / "scripts" / name)
    for name, extra in (("audit_obelix_error_bound.py", []),
                        ("verify_obelix_error_bound.py", ["--core-only"])):
        # -I also ignores PYTHONOPTIMIZE; the original assertions stay enabled.
        completed = subprocess.run(
            [sys.executable, "-I", str(destination / "scripts" / name), *extra],
            cwd=destination, capture_output=True, text=True, encoding="utf-8",
        )
        (destination / (name + ".stdout.log")).write_text(completed.stdout, encoding="utf-8", newline="\n")
        (destination / (name + ".stderr.log")).write_text(completed.stderr, encoding="utf-8", newline="\n")
        if completed.returncode:
            raise RuntimeError(name + " failed; see logs in " + str(destination))
    actual, validation, compared = compare_results(destination)
    verify_manifest(ROOT)
    summary = {
        "status": "PASS", "release_version": "1.0.0",
        "python": sys.version.split()[0], "core_checks_passed": validation["checks_passed"],
        "manifest_files_verified": file_count, "reference_values_compared": compared,
        "absolute_float_tolerance": TOLERANCE, "source_tree_unchanged": True,
        "repeated_subset_MAD_dex": actual["scenarios"]["full_processed__composition_spacegroup"]["repeated_subset_MAD_dex"],
        "official_test_group_constant_oracle_MAE_dex": actual["scenarios"]["official_test__composition_spacegroup"]["all_rows_group_constant_oracle_MAE_dex"],
        "uses_evaluation_labels": True,
        "scope": "File integrity, numerical reproduction and reference agreement. Not human source verification, peer review, experiments or predictive performance.",
    }
    (destination / "REPRODUCTION_RESULT.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print("Results: " + str(destination))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, KeyError) as error:
        print("ERROR: " + str(error), file=sys.stderr)
        sys.exit(1)

