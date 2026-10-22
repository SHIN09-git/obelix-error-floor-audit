"""Independent high-precision verification using sorted extreme pairs.

Does not import the main audit or calculate sample medians. This verifies
arithmetic and file provenance, not independent physical experiments.
"""
from __future__ import annotations

import csv
import argparse
import hashlib
import json
from collections import defaultdict
from decimal import Decimal, localcontext
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "reports/round11"
EVIDENCE = ROOT / "evidence/round11"
checks = []


def check(name, ok):
    checks.append({"check": name, "passed": bool(ok)})
    if not ok:
        raise AssertionError(name)


def read(path):
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--core-only", action="store_true", help="Verify public numerical inputs without local-only seed PDFs or project-history files")
    args = parser.parse_args()
    result = json.loads((OUT / "error_bound_audit.json").read_text(encoding="utf-8"))
    rows = read(ROOT / "evidence/round3/upstream_processed.csv")
    raw = read(ROOT / "evidence/round3/upstream_all.csv")
    train_ids = {r["ID"] for r in read(EVIDENCE / "upstream_train.csv")}
    test_ids = {r["ID"] for r in read(EVIDENCE / "upstream_test.csv")}
    index_ids = {r["ID"] for r in read(EVIDENCE / "upstream_test_idx.csv")}
    check("Official downloadable test and analysis-script index IDs agree", test_ids == index_ids)
    check("Official split sizes 478 / 121 and disjoint", len(train_ids) == 478 and len(test_ids) == 121 and not train_ids & test_ids)

    independent = {}
    with localcontext() as ctx:
        ctx.prec = 45
        for name, selected in (
            ("full_processed", rows),
            ("official_train", [r for r in rows if r["ID"] in train_ids]),
            ("official_test", [r for r in rows if r["ID"] in test_ids]),
            ("CIF_available", [r for r in rows if r["CIF"] != "No Match"]),
            ("CIF_official_test", [r for r in rows if r["CIF"] != "No Match" and r["ID"] in test_ids]),
        ):
            groups = defaultdict(list)
            for r in selected:
                groups[(r["Composition"], r["Space group number"])].append(Decimal(r["Ionic conductivity (S cm-1)"]).log10())
            bound_sum = Decimal(0)
            duplicate_count = 0
            for values in groups.values():
                values.sort()
                if len(values) >= 2:
                    duplicate_count += len(values)
                for k in range(len(values) // 2):
                    bound_sum += values[-1-k] - values[k]
            own = {"absolute_sum": str(bound_sum), "N": len(selected),
                   "repeated_N": duplicate_count,
                   "repeated_MAD": str(bound_sum / Decimal(duplicate_count)),
                   "full_E_group_constant_bound": str(bound_sum / Decimal(len(selected)))}
            independent[name] = own
            main_value = result["scenarios"][name + "__composition_spacegroup"]
            check(name + ": extreme-pair sum agrees with median algorithm at 1e-12 dex", abs(float(bound_sum) - main_value["sum_absolute_deviations_dex"]) < 1e-12)
            check(name + ": denominator and repeat count agree", len(selected) == main_value["rows"] and duplicate_count == main_value["repeated_rows"])

        # Population counterexample is specified analytically; these are its two support points.
        synthetic = []
        for u in (Decimal(-1), Decimal(1)):
            a = Decimal("1.006") + Decimal("0.006") * u
            y = Decimal(-4) + Decimal("0.41") * u
            prediction = Decimal(-4) + Decimal("0.41") * (a - Decimal("1.006")) / Decimal("0.006")
            synthetic.append({"U": str(u), "A": str(a), "Y": str(y), "prediction": str(prediction)})
            check("Population example exact zero error at U=" + str(u), prediction == y)
        check("Population example maximal relative A difference is 1.2 percent", (Decimal(synthetic[1]["A"]) - Decimal(synthetic[0]["A"])) / Decimal(synthetic[0]["A"]) == Decimal("0.012"))
        check("Population example group-only population minimum is 0.41", (Decimal(synthetic[1]["Y"]) - Decimal(synthetic[0]["Y"])) / 2 == Decimal("0.41"))

    repeated = json.loads((OUT / "repeated_group_audit.json").read_text(encoding="utf-8"))
    check("Published 48 groups / 122 records reproduced", len(repeated) == 48 and sum(g["n"] for g in repeated) == 122)
    check("Published rounded MAD 0.41 and RMS 0.63 reproduced", round(result["scenarios"]["full_processed__composition_spacegroup"]["repeated_subset_MAD_dex"], 2) == .41 and round(result["scenarios"]["full_processed__composition_spacegroup"]["repeated_subset_RMS_deviation_dex"], 2) == .63)
    check("No coarse repeated group crosses official split", all(len(g["splits"]) == 1 for g in repeated))
    check("599 canonical element-count plus space-group plus lattice keys are distinct", result["scenarios"]["full_processed__canonical_element_counts_plus_lattice"]["groups"] == 599)
    check("37 censored rows and none among 122 repeated entries", sum(r["Ionic conductivity (S cm-1)"].startswith("<") for r in raw) == 37 and result["censored_rows_in_repeated_subset"] == 0)
    check("All official test repeated groups are pairs", all(g["n"] == 2 for g in repeated if g["splits"] == ["test"]))
    check("33 of 48 coarse repeated groups have two records", sum(g["n"] == 2 for g in repeated) == 33)
    latp = [g for g in repeated if "9s4" in g["IDs"]][0]
    check("Seed LATP group contains five named records and is wholly train", set(latp["IDs"]) == {"9s4", "lap", "mg4", "ym6", "kab"} and latp["splits"] == ["train"])
    check("All five seed LATP CIFs are labelled Close Match", all(r["CIF"] == "Close Match" for r in latp["records"]))

    for source in result["sources"]:
        data = (ROOT / source["path"]).read_bytes()
        check("Source SHA256 " + source["path"], hashlib.sha256(data).hexdigest() == source["sha256"])
        if source.get("expected_git_blob"):
            check("Pinned Git blob " + source["path"], hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest() == source["expected_git_blob"])
    observed_hash = None
    if not args.core_only:
        old_validation = json.loads((ROOT / "reports/round10/VALIDATION.json").read_text(encoding="utf-8"))
        observed_hash = hashlib.sha256((ROOT / "data/observations.jsonl").read_bytes()).hexdigest()
        check("Frozen observations unchanged", observed_hash == old_validation["input_sha256"]["data/observations.jsonl"])
        check("Human-reviewed gold file remains empty", (ROOT / "data/gold_reviewed.jsonl").stat().st_size == 0)
        facts = json.loads((ROOT / "evidence/round5/original_facts.json").read_text(encoding="utf-8"))
        for source in facts["sources"]:
            check("Original seed PDF SHA256 " + source["source_id"], hashlib.sha256((ROOT / source["file"]).read_bytes()).hexdigest() == source["sha256"])
        selected_facts = {r["id"]: r for r in facts["records"]}
        check("Aono table IV 298 K total retained", selected_facts["aono_t4_total"]["value"] == .0007 and selected_facts["aono_t4_total"]["temperature_K"] == 298)
        interval = selected_facts["cretin_t6_SG_total_range"]
        check("Cretin table 6 interval midpoint equals database kab, history not inferred", (Decimal(str(interval["low"])) + Decimal(str(interval["high"]))) / 2 == Decimal("0.0000375"))

    output = {"checks_passed": len(checks), "checks": checks,
              "independent_sorted_extremes_Decimal45": independent,
              "non_experimental_population_counterexample": synthetic,
              "data_observations_sha256": observed_hash, "core_only": args.core_only,
              "scope": "File integrity, arithmetic, split membership and two-point analytic counterexample. Not independent experiments, scientific peer review, all-source semantic verification or proof of publication value."}
    (OUT / "VALIDATION.json").write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({"checks_passed": len(checks), "high_precision_repeated_MAD": independent["full_processed"]["repeated_MAD"], "official_test_bound": independent["official_test"]["full_E_group_constant_bound"]}, indent=2))


if __name__ == "__main__":
    main()
