"""Audit a descriptive MAD and its scope; never train a predictive model.

Independent implementation of the *read-only* upstream analysis recipe.
All minima use the evaluation labels, and hence are descriptive oracle minima,
not train-only baselines, measured generalization errors or Bayes risk estimates.
"""
from __future__ import annotations

import csv
import hashlib
import json
import math
import re
from collections import defaultdict
from decimal import Decimal
from pathlib import Path
from statistics import mean, median

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "evidence/round11"
OUT = ROOT / "reports/round11"
Y = "Ionic conductivity (S cm-1)"
LATTICE = ("a", "b", "c", "alpha", "beta", "gamma")
COARSE = ("Composition", "Space group number")


def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def digest(path):
    data = path.read_bytes()
    return {"path": path.relative_to(ROOT).as_posix(), "bytes": len(data),
            "sha256": hashlib.sha256(data).hexdigest(),
            "git_blob_sha1": hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()}


def signature(row, columns):
    # Decimal compares recorded numbers, so 90 and 90.0 are identical.
    return tuple(Decimal(row[c]) if c in LATTICE or c == "Space group number"
                 else canonical_counts(row["Composition"]) if c == "element_amounts"
                 else row[c] for c in columns)


def canonical_counts(formula):
    tokens = re.findall(r"([A-Z][a-z]?)([0-9]+(?:\.[0-9]+)?)", formula)
    assert "".join(e + n for e, n in tokens) == formula, formula
    counts = defaultdict(Decimal)
    for element, count in tokens:
        counts[element] += Decimal(count)
    return tuple(sorted((e, n) for e, n in counts.items() if n))


def group_rows(rows, columns):
    groups = defaultdict(list)
    for row in rows:
        groups[signature(row, columns)].append(row)
    return list(groups.values())


def describe(rows, columns):
    groups = group_rows(rows, columns)
    repeated = [g for g in groups if len(g) > 1]
    abs_errors = []
    sq_errors = []
    for group in repeated:
        ys = [math.log10(float(r[Y])) for r in group]
        abs_errors.extend(abs(y - median(ys)) for y in ys)
        sq_errors.extend((y - mean(ys)) ** 2 for y in ys)
    return {
        "rows": len(rows), "groups": len(groups), "repeated_groups": len(repeated),
        "repeated_rows": len(abs_errors), "singleton_rows": sum(len(g) == 1 for g in groups),
        "sum_absolute_deviations_dex": sum(abs_errors),
        "repeated_subset_MAD_dex": mean(abs_errors) if abs_errors else None,
        "repeated_subset_RMS_deviation_dex": math.sqrt(mean(sq_errors)) if sq_errors else None,
        "all_rows_group_constant_oracle_MAE_dex": sum(abs_errors) / len(rows) if rows else None,
        "columns": list(columns),
        "interpretation": "Finite-sample minimum over arbitrary functions constant on these recorded-input groups; evaluation labels used. Not predictive performance or an estimated population noise floor."
    }


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    processed_path = ROOT / "evidence/round3/upstream_processed.csv"
    raw_path = ROOT / "evidence/round3/upstream_all.csv"
    rows, raw = read_csv(processed_path), read_csv(raw_path)
    train = read_csv(EVIDENCE / "upstream_train.csv")
    test = read_csv(EVIDENCE / "upstream_test.csv")
    raw_by_id = {r["ID"]: r for r in raw}
    train_ids, test_ids = {r["ID"] for r in train}, {r["ID"] for r in test}
    assert len(raw_by_id) == len(raw)
    assert len({r["ID"] for r in rows}) == len(rows)
    assert not train_ids & test_ids
    assert train_ids | test_ids == set(raw_by_id)
    assert {r["ID"] for r in rows} == set(raw_by_id)
    for row in rows:
        row["split"] = "test" if row["ID"] in test_ids else "train"
        row["raw_y"] = raw_by_id[row["ID"]][Y]
        row["censored"] = row["raw_y"].lstrip().startswith("<")
        assert float(row[Y]) > 0

    queue = []
    for queue_name in ("source_queue.json", "benchmark_queue.json", "method_queue.json"):
        queue.extend(json.loads((EVIDENCE / queue_name).read_text(encoding="utf-8")))
    sources = [digest(processed_path), digest(raw_path)]
    for item in queue:
        path = EVIDENCE / item["filename"]
        if path.exists():
            record = {**digest(path), "url": item["url"]}
            if "expected_git_blob" in item:
                record["expected_git_blob"] = item["expected_git_blob"]
                record["pinned_blob_matches"] = record["git_blob_sha1"] == item["expected_git_blob"]
                assert record["pinned_blob_matches"]
            sources.append(record)

    scenarios = {}
    for subset_name, subset in (
        ("full_processed", rows),
        ("official_train", [r for r in rows if r["split"] == "train"]),
        ("official_test", [r for r in rows if r["split"] == "test"]),
        ("uncensored_only", [r for r in rows if not r["censored"]]),
        ("uncensored_test", [r for r in rows if not r["censored"] and r["split"] == "test"]),
        ("CIF_available", [r for r in rows if r["CIF"] != "No Match"]),
        ("CIF_official_test", [r for r in rows if r["CIF"] != "No Match" and r["split"] == "test"]),
    ):
        for key_name, columns in (("composition_spacegroup", COARSE),
                                  ("plus_recorded_lattice", COARSE + LATTICE),
                                  ("canonical_element_counts_plus_lattice", ("element_amounts", "Space group number") + LATTICE)):
            scenarios[f"{subset_name}__{key_name}"] = describe(subset, columns)

    detail = []
    for group in group_rows(rows, COARSE):
        if len(group) <= 1:
            continue
        ys = [math.log10(float(r[Y])) for r in group]
        errors = [abs(y - median(ys)) for y in ys]
        detail.append({
            "composition": group[0]["Composition"],
            "space_group": group[0]["Space group number"],
            "n": len(group), "IDs": [r["ID"] for r in group],
            "splits": sorted({r["split"] for r in group}),
            "unique_DOI_strings": sorted({r["DOI"] for r in group}),
            "censored_IDs": [r["ID"] for r in group if r["censored"]],
            "distinct_recorded_full_inputs": len(group_rows(group, COARSE + LATTICE)),
            "median_log10_conductivity": median(ys),
            "sum_absolute_deviations_dex": sum(errors),
            "MAD_dex": mean(errors), "log10_range": max(ys) - min(ys),
            "records": [{k: r[k] for k in ("ID", "DOI", Y, "raw_y", "split", "censored", "CIF") + LATTICE} for r in group]
        })
    detail.sort(key=lambda g: (-g["sum_absolute_deviations_dex"], g["IDs"][0]))
    assert all(len(g["splits"]) == 1 for g in detail)
    overall = scenarios["full_processed__composition_spacegroup"]
    for group in detail:
        group["absolute_deviation_share"] = group["sum_absolute_deviations_dex"] / overall["sum_absolute_deviations_dex"]
        group["MAD_dex_excluding_this_group"] = (
            overall["sum_absolute_deviations_dex"] - group["sum_absolute_deviations_dex"]
        ) / (overall["repeated_rows"] - group["n"])

    result = {
        "as_of": "2026-10-11", "upstream_commit": "4eaac889809dd489e3bae468c45d5c0e02b9147a",
        "method": "Independent stdlib implementation; raw published data unchanged; upstream code inspected, not executed.",
        "model_trained": False, "uses_evaluation_labels": True,
        "censored_rows_in_full": sum(r["censored"] for r in rows),
        "censored_rows_in_repeated_subset": sum(len(g["censored_IDs"]) for g in detail),
        "official_group_split_preserved": True,
        "same_DOI_string_overlap_train_test": sorted({r["DOI"] for r in rows if r["split"] == "train"} & {r["DOI"] for r in rows if r["split"] == "test"}),
        "sources": sources, "scenarios": scenarios,
        "limitations": ["Coarse grouping follows exact stored composition strings and space groups, as in the authors' analysis.",
                        "Exact lattice equality refers to recorded values, not physical equivalence or informative signal.",
                        "Zero empirical full-input inconsistency does not imply zero irreducible uncertainty or achievable held-out error.",
                        "Censored values in processed.csv are analysis placeholders; retained only for exact recipe reproduction and separately excluded.",
                        "No GNN representation equivalence, full CIF identity, or measured sample identity is asserted."]
    }
    (OUT / "error_bound_audit.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    (OUT / "repeated_group_audit.json").write_text(json.dumps(detail, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    fields = ["composition", "space_group", "n", "IDs", "splits", "censored_IDs", "distinct_recorded_full_inputs", "MAD_dex", "sum_absolute_deviations_dex", "absolute_deviation_share", "MAD_dex_excluding_this_group"]
    with (OUT / "repeated_groups.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for group in detail:
            writer.writerow({k: ";".join(group[k]) if isinstance(group[k], list) else group[k] for k in fields})
    print(json.dumps({"scenarios": scenarios, "censored_rows": result["censored_rows_in_full"],
                      "censored_repeats": result["censored_rows_in_repeated_subset"],
                      "largest_groups": [{k: g[k] for k in fields} for g in detail[:5]]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
