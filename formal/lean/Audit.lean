import Mard

-- This reports transitive axiom dependencies, not merely source-text matches.
#print axioms Mard.sampleMedian_minimizes
#print axioms Mard.grouped_median_minimizes
#print axioms Mard.grouped_median_optimal
#print axioms Mard.feature_refinement
#print axioms Mard.add_feature_nonincreasing
#print axioms Mard.population_feature_refinement
#print axioms Mard.Counterexample.coarseRisk_lower_bound
#print axioms Mard.Counterexample.coarse_optimalRisk
#print axioms Mard.Counterexample.rich_optimalRisk
#print axioms Mard.Counterexample.exact_counterexample
#print axioms Mard.Counterexample.coarse_bound_not_universal
#print axioms Mard.Counterexample.coinMeasure_isProbability
#print axioms Mard.Counterexample.feature_measurable
#print axioms Mard.Counterexample.outcome_measurable
#print axioms Mard.Counterexample.coarse_measurable
#print axioms Mard.Counterexample.predictor_measurable
#print axioms Mard.Counterexample.coarse_populationRisk
#print axioms Mard.Counterexample.rich_populationRisk
#print axioms Mard.Counterexample.population_counterexample

#print axioms Mard.Sampling.fittedRisk_le
#print axioms Mard.Sampling.fittedRisk_nonneg
#print axioms Mard.Sampling.fittedRisk_eq_inf
#print axioms Mard.Sampling.fittedRisk_eq_grouped
#print axioms Mard.Sampling.fittedRisk_lipschitz
#print axioms Mard.Sampling.fittedRisk_singleton
#print axioms Mard.Sampling.fittedRisk_two
#print axioms Mard.Sampling.fittedRisk_integrable
#print axioms Mard.Sampling.expected_fixedRisk
#print axioms Mard.Sampling.expected_fittedRisk_le
#print axioms Mard.Sampling.expected_empirical_inf_le
#print axioms Mard.Sampling.iid_product_bias
#print axioms Mard.Sampling.standardGaussian_abs
#print axioms Mard.Sampling.gaussian_abs
#print axioms Mard.Sampling.gaussian_center_risk
#print axioms Mard.Sampling.gaussian_center_minimizes
#print axioms Mard.Sampling.gaussian_optimal_risk
#print axioms Mard.Sampling.gaussian_difference_law
#print axioms Mard.Sampling.gaussian_two_expected
#print axioms Mard.Sampling.gaussian_two_bias
#print axioms Mard.Sampling.gaussian_two_strict
#print axioms Mard.Sampling.gaussian_product_two
#print axioms Mard.Sampling.gaussian_two_above_threshold

-- Print the three principal statements and the general population extension.
#check @Mard.grouped_median_optimal
#check @Mard.feature_refinement
#check @Mard.population_feature_refinement
#check Mard.Counterexample.population_counterexample
#check @Mard.Sampling.expected_empirical_inf_le
#check @Mard.Sampling.iid_product_bias
#check @Mard.Sampling.gaussian_two_bias
#check @Mard.Sampling.gaussian_two_above_threshold

-- Regression checks for ties and a pair of distinct observations.
example : Mard.Sampling.fittedRisk ![(4 : ℝ), 4] = 0 := by
  rw [Mard.Sampling.fittedRisk_two]
  norm_num

example : Mard.Sampling.fittedRisk ![(-2 : ℝ), 4] = 3 := by
  rw [Mard.Sampling.fittedRisk_two]
  norm_num
