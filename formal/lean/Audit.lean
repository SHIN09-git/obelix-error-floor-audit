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

-- Print the three principal statements and the general population extension.
#check @Mard.grouped_median_optimal
#check @Mard.feature_refinement
#check @Mard.population_feature_refinement
#check Mard.Counterexample.population_counterexample
