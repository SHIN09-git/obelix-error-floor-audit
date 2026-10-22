# Repeated-composition dispersion does not identify a universal prediction-error floor

## A reproducible audit of OBELiX, with a LATP source case

**JIN HANZHE**

Independent Researcher, Chongqing, China | jinhanzhe09@gmail.com

Version 1.0.0 | MARD-01 | Prepared 22 Oct 2026 | Analysis 11 Oct 2026.

Not submitted to a journal or peer reviewed. The result concerns an inference from a published benchmark statistic; it does not establish a new material, process improvement or experimentally validated mechanism.

## Abstract

Experimental conductivity databases contain variation within nominal material classes. Interpreting that variation as an irreducible prediction-error floor requires assumptions about the prediction inputs, evaluation population and measurement target. We audit the 0.41 log-conductivity error-floor interpretation in the published OBELiX article. An independent implementation reproduces the underlying mean absolute deviation: 0.4077528700 across 122 entries in 48 repeated composition-and-space-group groups. The statistic is correctly computed, but its denominator and invariance constraint differ from those of the benchmark. For arbitrary predictors constrained to be constant within these groups, the exact finite-sample minimum MAE is 0.083048 over all 599 encoded entries and 0.030450 over the official 121-entry test set. These are descriptive minima using evaluation labels, not replacement noise estimates or achievable predictive scores. All 599 recorded composition, space-group and lattice-input combinations are distinct. A population counterexample shows why small lattice differences alone cannot establish a positive universal error floor. A LATP case additionally distinguishes a reported conductivity range from a specimen-level measurement. We conclude that the published dispersion is useful for describing heterogeneous records, but does not by itself justify diagnosing overfitting from MAE below 0.41.

## 1. Question and contribution

OBELiX provides a traceable experimental solid-electrolyte benchmark [1,2]. Section 4 of its published article interprets the mean absolute deviation within repeated composition-and-space-group groups as a lower bound on predictive MAE, and treats an error below 0.41 as an indication of likely overtraining. The same paper explicitly acknowledges inconsistent conductivity labels and missing measurement, processing and microstructural information. Our question is narrower than the general importance of experimental uncertainty: does the reported calculation establish that particular model-evaluation threshold?

We provide a version-specific numerical reproduction, an exact finite-sample characterization of what the statistic bounds, and a source-level LATP example. Median optimality under absolute loss is established statistical theory [3]; it is not claimed as a new method. The contribution is its application to this published interpretation and the quantification of the resulting population and input mismatches. We do not revise OBELiX entries, train a competing model, or claim that the published benchmark rankings change.

## 2. Materials and audit methods

The article examined is the RSC typeset version of DOI 10.1039/D5DD00441A, obtained from the NRC Publications Archive. The title page, benchmark claim, Figure 3 and limitations were checked visually. Data and code are pinned to the public OBELiX commit `4eaac889809dd489e3bae468c45d5c0e02b9147a`. The processed file has 599 unique IDs. The official downloadable splits contain 478 training and 121 test IDs; the test IDs agree exactly with the index used by the analysis script.

The upstream analysis script was read, not executed. Its grouping and log-space calculations were implemented independently using the Python standard library. A second computation used 45-digit decimal logarithms and paired the smallest and largest observations within each group, avoiding the median routine in the first implementation. Source hashes, pinned Git blob identities and split membership are recorded in the accompanying verification output.

Let y be log10 of the numerical conductivity expressed in S/cm. We follow the authors' exact stored-composition and space-group grouping, denoted G. MAD throughout this manuscript means **mean** absolute deviation from the group median, not median absolute deviation. The original raw file flags 37 entries as upper limits; processed values for these records are encoding placeholders. None belongs to the 122-entry repeated subset. Results excluding these 37 entries are reported separately; they are not recast as precise experimental measurements.

## 3. Numerical reproduction and scoring populations

The repeated subset contains 48 groups: 33 pairs, seven triples, five groups of four and three groups of five. Its sum of absolute deviations from group medians is 49.74585014457541 dex. Dividing by 122 gives 0.4077528700375033 dex; the corresponding root mean squared deviation from group means is 0.6295124506 dex. Both reproduce the article's rounded values. Thus the issue is the interpretation of the statistic, not an arithmetic failure.

Table 1 separates within-group dispersion from the minimum MAE over a specified finite scoring set. The latter permits a separate constant for every recorded G and uses that set's labels to choose those constants. Single-entry groups contribute zero to this mathematical minimum, because their constants can equal their labels. Their physical uncertainty remains unknown.

| Scoring set | All rows N | Repeated groups | Rows in repeats | Repeated-subset MAD | Group-constant minimum over N |
|---|---:|---:|---:|---:|---:|
| All encoded records | 599 | 48 | 122 | 0.407753 | 0.083048 |
| Official training set | 478 | 45 | 116 | 0.397081 | 0.096363 |
| Official test set | 121 | 3 | 6 | 0.614076 | 0.030450 |
| Records with CIFs | 321 | 17 | 45 | 0.528736 | 0.074122 |
| Official test with CIFs | 67 | 1 | 2 | 1.323909 | 0.039520 |
| Uncensored records only | 562 | 48 | 122 | 0.407753 | 0.088516 |

**Table 1.** All error quantities are in dex. These are label-dependent descriptive calculations, not test predictions, generalization estimates or alternative experimental noise floors. The CIF rows still use G for grouping; they do not establish equivalent crystal graphs or identical GNN representations.

All 48 repeated groups lie wholly within one official split. In particular, the test-set calculation uses only three pairs: 2uv/mn3, vwy/2ha and mdp/ptg. Their absolute-deviation sums are 2.6478174819, 0.6072925183 and 0.4293484729 dex. Their total divided by 121 gives 0.0304500700 dex. The authors' grouping precautions are therefore preserved; this audit does not allege leakage of those groups across the official training/test boundary. Nor does the different test-subset dispersion establish that one split has intrinsically more experimental noise: six repeated records are a small, selected subset.

## 4. What can be bounded mathematically

For a fixed scoring set E of N observations, restrict predictions to a constant c_g within each G group. The exact minimum is

\[
B_E(G)=\inf_{\{c_g\}}\frac{1}{N}\sum_g\sum_{i\in g}|y_i-c_g|=\frac{1}{N}\sum_g\sum_{i\in g}|y_i-\mathrm{med}(y_g)|.
\]

To prove the equality, order each group's observations. For any c, the errors on its smallest and largest observations sum to at least their difference. Pair successive extremes in the same way. A group median attains the sum of these lower bounds; an odd-sized group has one unpaired median with zero error. Minimization separates across groups, giving the stated expression. This also provides an independent algorithm for checking the reported arithmetic.

The value 0.407753 is B_E(G) when E consists solely of the 122 repeated records. It is not the same finite-set bound when E is the full dataset or official test set. Conversely, multiplying it by 122/599 does not estimate the population's experimental noise. That operation merely changes the denominator of a restricted empirical optimization problem. The singleton contribution to unknown future error cannot be estimated as zero from this construction.

The invariance restriction also matters. If X contains G and additional inputs, every G-only predictor is an X-based predictor, whereas the reverse need not hold. Hence, on the same E,

\[
B_E(X)\le B_E(G).
\]

At the population level, define the optimal absolute risk R*(X) as the infimum of E|Y-f(X)| over measurable f, assuming E|Y| is finite. The same function-class inclusion gives R*(X) no larger than R*(G). A coarse-group optimal risk therefore cannot automatically be used as a lower bound for a richer input representation. Sample dispersion is additionally distinct from either population risk.

The benchmark's RF and MLP use elemental amounts, space group and six lattice parameters. The parser retains elemental amounts rather than reducing them to fractions. After canonicalizing element order and recorded numeric equality, all 599 combinations of these inputs are distinct. Exact-input inconsistency alone consequently forces no positive empirical minimum for unrestricted functions of those inputs. This is consistent with the upstream preprocessing step that removes exact duplicate inputs. It says nothing about whether the remaining small differences are physically informative, whether a learned predictor can use them, or whether experimental noise vanishes. We make no corresponding identity claim for CIF graphs after model-specific transformations.

## 5. Why proximity and sample dispersion are insufficient

A population counterexample isolates the missing assumption. This is a mathematical construction, not an electrolyte measurement. Fix the composition and space group, let U equal -1 or +1 with equal probability, and define one additional recorded input A and a target Y by

\[
A=1.006+0.006U,\qquad Y=-4+0.41U.
\]

A differs by at most 1.2% across its two values. The best group-constant predictor has population MAE 0.41. Nevertheless, the specified linear function

\[
f(A)=-4+\frac{0.41}{0.006}(A-1.006)
\]

has zero error on new draws from this population. Its parameters were defined with the population, not fitted to held-out labels. This counterexample does not assert such lattice sensitivity in a real conductor. It proves that proximity alone is insufficient: a noise-floor argument also needs justified restrictions on how informative the additional inputs can be, such as a specified sensitivity bound or a validated conditional-noise model.

Even with genuinely identical inputs, fitting the group center and computing residuals on the same observations does not by itself produce a calibrated population bound. Under an independent, identically distributed within-group model, the expected sample minimum absolute loss is no larger than the population minimum. This follows by taking the expectation of an infimum before, rather than after, minimizing. It is an expectation inequality, not a one-sided confidence guarantee for a particular sample.

For illustration, with two independent normal observations of variance tau squared, the sample minimum average absolute loss is half their absolute difference. Its expectation is tau divided by the square root of pi, while the population median predictor has risk tau times the square root of 2/pi. Their ratio is 1/sqrt(2). We do not assume this distribution for OBELiX or apply that factor as a correction. The example only clarifies why small groups, sample-center fitting, and the target population must be specified before interpreting residuals as an irreducible floor.

## 6. LATP: a repeated database class is not an identified repeated specimen

The nominal Li1.3Al0.3Ti1.7(PO4)3 group contains IDs 9s4, lap, mg4, ym6 and kab, all in the training set. Its MAD is 0.488522 dex and it accounts for 4.91% of the repeated subset's absolute-deviation sum. The database marks all five associated CIFs as close matches. These flags should be retained; nominal-class membership cannot establish that transport and structural measurements came from the same pellet.

Two original papers were examined for the seed records. Aono et al. [4], Table IV, report total conductivity 7 x 10^-4 S/cm at 298 K, together with separate bulk and grain-boundary columns. The database's 9s4 value, 7.22 x 10^-4, is close to that total value, but the exact historical extraction of 7.22 was not established. Cretin and Fabry [5], Table 6, report a sol-gel LATP total-conductivity range of 1.5 x 10^-5 to 6 x 10^-5 S/cm at room temperature. The arithmetic midpoint is 3.75 x 10^-5, exactly the kab scalar. Numerical equality does not prove that this midpoint operation was the historical extraction procedure.

The interval does not identify separate pellets at its endpoints, a sample mean, a confidence interval, or a distribution from which a new measurement can be sampled. The original papers also concern different preparation routes and incompletely matched measurement conditions. Therefore these two database scalars cannot be treated as an identified pair of independent repeated measurements at a controlled material and measurement state. Both have total-conductivity source contexts; the case is not resolved simply by declaring one bulk and the other total. We do not attribute all observed variation to an extraction error or calculate a corrected noise floor. The other three entries were not given a new complete original-source audit for this note, and the case is not used to extrapolate a semantic-error rate across all 48 groups.

## 7. Interpretation, limits and recommended reporting

The reproducible result is that the published calculation does not identify a universal 0.41 MAE floor. It measures the within-class dispersion of a selected collection of recorded targets. Turning it into a predictive limit additionally requires the model's input equivalence relation, comparable measurement targets, a specified future population, and a justified sampling or noise model. None of our alternative finite-set minima supplies those missing assumptions.

This conclusion leaves the benchmark useful and its reported model results intact. Missing process and measurement variables may still impose substantial prediction uncertainty. An MAE below 0.41 might arise from leakage or overfitting, but crossing that number alone does not diagnose either. Conversely, an MAE above it does not establish a valid evaluation. We have neither trained a model that surpasses the published results nor estimated how much uncertainty is reducible in practice.

A precise replacement interpretation is to report 0.408 dex as the mean within-group absolute deviation of 122 entries in 48 composition-and-space-group groups, with group-size and split coverage stated. It can motivate source reconciliation and uncertainty studies. Any proposed generalization floor should separately state which variables are held fixed, whether repetitions are independently prepared and comparably measured, how censored values are handled, and how the repeat sample represents the evaluation population. Uncertainty intervals must respect shared studies and batches rather than treating every row as independent.

The present numerical audit covers the pinned files, not every past or future release. Source semantics were examined in depth for two LATP papers, not for all repeated entries. A focused search and screening of the returned repository issue/PR bodies and issue comments did not identify a correction of this particular error-floor interpretation; this is not an exhaustive novelty search. The elementary mathematics is established. The substantive correction is the documented mismatch between the published interpretation and the statistic's actual conditions. No new materials mechanism, global data-error prevalence or downstream citation impact is claimed.

## Data, code and preparation statement

The companion files include every repeated-group ID, frozen numerical inputs, split membership, source identities and both calculation implementations. The repository entry point, `python reproduce.py`, runs the numerical audit and 41 portable core checks using Python 3.11 or newer and its standard library. It writes results to a new directory and compares them with frozen references. These checks establish file integrity and numerical agreement, not human scientific verification.

JIN HANZHE is the named author and project contact. Source checking, analysis, drafting and release preparation were performed with OpenAI Codex. AI is not listed as an author. No completed human scientific verification, independent laboratory replication or peer review is claimed.

Original code is licensed under MIT. The manuscript and original audit contributions are licensed under CC BY 4.0, with attribution to JIN HANZHE (2026). OBELiX snapshots retain their upstream CC BY 4.0 license and attribution [1,2]. The original papers and methodological reference are not redistributed; their DOI citations and source locations are retained for independent checking. See AUTHORSHIP.md, LICENSING.md and THIRD_PARTY_NOTICES.md in the companion repository for scope and attribution.

## References

[1] F. Therrien et al. OBELiX: a curated dataset of crystal structures and experimentally measured ionic conductivities for lithium solid-state electrolytes. Digital Discovery 5 (2026), 910-918. [DOI: 10.1039/D5DD00441A](https://doi.org/10.1039/D5DD00441A). Published text examined at pp. 914-917.

[2] NRC-Mila. OBELiX repository, commit 4eaac889809dd489e3bae468c45d5c0e02b9147a. [Pinned repository](https://github.com/NRC-Mila/OBELiX/tree/4eaac889809dd489e3bae468c45d5c0e02b9147a). Files examined include data/processed.csv, data/scripts/analysis.py, data/scripts/preprocessing.py, benchmark/parse.py and official split files. Accessed 11 October 2026 for newly obtained files; existing snapshots retain their earlier acquisition records.

[3] T. Gneiting. Making and Evaluating Point Forecasts. Journal of the American Statistical Association 106 (2011), 746-762. [DOI: 10.1198/jasa.2011.r10138](https://doi.org/10.1198/jasa.2011.r10138). Local reading copy: [author preprint arXiv:0912.0902](https://arxiv.org/abs/0912.0902), p. 7.

[4] H. Aono, E. Sugimoto, Y. Sadaoka, N. Imanaka and G. Adachi. Ionic Conductivity of Solid Electrolytes Based on Lithium Titanium Phosphate. Journal of The Electrochemical Society 137 (1990), 1023-1027. [DOI: 10.1149/1.2086597](https://doi.org/10.1149/1.2086597). Table IV, p. 1026.

[5] M. Cretin and P. Fabry. Comparative Study of Lithium Ion Conductors in the System Li1+xAlxA(IV)2-x(PO4)3 with A(IV)=Ti or Ge and 0<=x<=0.7 for Use as Li+ Sensitive Membranes. Journal of the European Ceramic Society 19 (1999), 2931-2940. [DOI: 10.1016/S0955-2219(99)00055-2](https://doi.org/10.1016/S0955-2219(99)00055-2). Table 6, p. 2937. A(IV) denotes the oxidation state in the original title.
