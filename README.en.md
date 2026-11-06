# OBELiX error-floor audit (MARD-01)

[中文说明](README.md) · [Manuscript PDF](output/pdf/obelix_error_floor_audit.pdf) · [Source](reports/round11/MANUSCRIPT.md)

**JIN HANZHE** — Independent Researcher, Chongqing, China  
Release **1.0.0**, 22 October 2026; scientific analysis dated 11 October 2026.

[GitHub repository](https://github.com/SHIN09-git/obelix-error-floor-audit) · [v1.0.0 release and downloads](https://github.com/SHIN09-git/obelix-error-floor-audit/releases/tag/v1.0.0) · [Reproduction workflow](https://github.com/SHIN09-git/obelix-error-floor-audit/actions/workflows/reproduce.yml)

This audit reproduces the dispersion statistic reported in OBELiX and examines the inference that it establishes a universal prediction-error floor. The arithmetic is reproducible: the mean absolute deviation from group medians is **0.4077528700 dex** for **122 entries in 48 repeated composition-and-space-group groups**.

Under the restriction of a constant prediction within each such group, the finite-set minimum MAE is **0.083048** over all 599 encoded entries and **0.0304500700** over the official 121-entry test set. These calculations use evaluation labels. They are descriptive oracle minima, not predictive scores or replacement estimates of experimental noise. All 599 recorded elemental-count, space-group and lattice-input combinations are distinct. This does not establish that a learned model can exploit those differences.

The manuscript gives the relevant elementary proof, a population counterexample and a two-paper LATP source case. It does not train a model, change the dataset, establish leakage of the repeated groups across the official split, or invalidate the benchmark rankings. It has not been peer reviewed. See [authorship and AI disclosure](AUTHORSHIP.md).

## Lean formalization supplement — 6 November 2026

[Proofs and reproduction instructions](formal/lean/README.md) · [Recorded verification](formal/lean/verification/RESULT.json) · [Lean CI](https://github.com/SHIN09-git/obelix-error-floor-audit/actions/workflows/lean.yml)

Lean 4.24.0 verifies the analytical note's first three claims: group-median MAE optimality, monotonicity of optimal risk under richer inputs on the same scoring population, and an explicit population counterexample with coarse optimum `0.41` and rich optimum `0`. The proof includes measurability, a normalized probability law, lower bounds and attainment.

There are no proof placeholders or added axioms. The 19-declaration transitive axiom audit and a fresh kernel replay including imported dependencies passed. Empirical values, source interpretation and section 4 are outside this formalization. This repository supplement leaves the manuscript's fixed v1.0.0 release intact.

## Reproduce offline

Python **3.11+**, standard library only:

```console
python reproduce.py
```

The command checks release hashes, copies inputs into a new directory under `reproductions/`, runs the unchanged audit and a separate 45-digit Decimal calculation, and checks the results against frozen references. Success reports `"status": "PASS"`, including **41 portable core checks**, and writes `REPRODUCTION_RESULT.json`. Input files and packaged results remain unchanged.

```console
python reproduce.py --verify-only
python reproduce.py --output "../mard01-results"
```

The output directory must be new. See [reproduction details](REPRODUCIBILITY.md) and [release validation](VALIDATION.md). Numerical reproduction needs no network, third-party packages, GPU or original-paper PDFs. Semantic rechecking of the LATP references requires obtaining the papers separately; they are not redistributed.

## Sources and reuse

Inputs are pinned to [NRC-Mila/OBELiX commit 4eaac889809dd489e3bae468c45d5c0e02b9147a](https://github.com/NRC-Mila/OBELiX/tree/4eaac889809dd489e3bae468c45d5c0e02b9147a). [Third-party notices](THIRD_PARTY_NOTICES.md) preserve source paths, attribution and exclusions.

Original code: [MIT](LICENSE). Original prose and audit records: [CC BY 4.0](LICENSE-CC-BY-4.0.txt). Upstream snapshots retain their own CC BY 4.0 terms. See [file-level scope](LICENSING.md). The audit does not imply endorsement by the OBELiX authors.

Author/contact: **JIN HANZHE**, [jinhanzhe09@gmail.com](mailto:jinhanzhe09@gmail.com). AI-assisted source checking, analysis and drafting are disclosed in [AUTHORSHIP.md](AUTHORSHIP.md); no completed human scientific verification is claimed. Cite the manuscript using [CITATION.cff](CITATION.cff) and the versioned release URL. No DOI has been assigned to this release.

