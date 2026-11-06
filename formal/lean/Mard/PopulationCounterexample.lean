import Mard.Counterexample
import Mathlib.MeasureTheory.Integral.Lebesgue.Countable
import Mathlib.MeasureTheory.Constructions.BorelSpace.Basic

/-!
# The counterexample as an explicit probability measure

This bridges the two-point formula to `populationRisk`: each of false and
true has probability one half. The affine predictor is measurable.
-/

set_option autoImplicit false
open scoped ENNReal
open MeasureTheory

namespace Mard.Counterexample

noncomputable section

def coinMeasure : Measure Bool :=
  (1 / 2 : ℝ≥0∞) • (Measure.dirac false + Measure.dirac true)

theorem feature_measurable : Measurable feature := measurable_of_countable _
theorem outcome_measurable : Measurable outcome := measurable_of_countable _
theorem coarse_measurable : Measurable coarse := measurable_of_countable _

instance coinMeasure_isProbability : IsProbabilityMeasure coinMeasure := by
  constructor
  norm_num [coinMeasure, Measure.smul_apply, Measure.add_apply]
  exact ENNReal.inv_two_add_inv_two

theorem coin_expectedLoss (p : Bool → ℝ) :
    (∫⁻ u, ENNReal.ofReal |outcome u - p u| ∂coinMeasure) =
      ENNReal.ofReal ((|outcome false - p false| + |outcome true - p true|) / 2) := by
  rw [coinMeasure, lintegral_smul_measure, lintegral_add_measure]
  rw [lintegral_dirac, lintegral_dirac]
  rw [ENNReal.ofReal_div_of_pos (by norm_num : (0 : ℝ) < 2),
    ENNReal.ofReal_add (abs_nonneg _) (abs_nonneg _)]
  norm_num [smul_eq_mul, div_eq_mul_inv, mul_comm]

theorem predictor_measurable : Measurable predictor := by
  unfold predictor
  exact measurable_const.add (measurable_const.mul (measurable_id.sub measurable_const))

theorem coarse_populationRisk :
    Mard.populationRisk coinMeasure outcome coarse = ENNReal.ofReal (41 / 100) := by
  unfold Mard.populationRisk
  apply le_antisymm
  · refine iInf_le_of_le ⟨(fun _ => (-4 : ℝ)), measurable_const⟩ ?_
    rw [coin_expectedLoss]
    change ENNReal.ofReal (coarseRisk (-4)) ≤ _
    rw [coarseRisk_attained]
  · refine le_iInf fun f => ?_
    rw [coin_expectedLoss]
    change ENNReal.ofReal (41 / 100) ≤ ENNReal.ofReal (coarseRisk (f.val ()))
    exact ENNReal.ofReal_le_ofReal (coarseRisk_lower_bound _)

theorem rich_populationRisk : Mard.populationRisk coinMeasure outcome feature = 0 := by
  apply le_antisymm _ (zero_le _)
  unfold Mard.populationRisk
  refine iInf_le_of_le ⟨predictor, predictor_measurable⟩ ?_
  simp [predictor_exact]

/-- The original population counterexample, with its probability law and
measurability verified explicitly. -/
theorem population_counterexample :
    Mard.populationRisk coinMeasure outcome coarse = ENNReal.ofReal (41 / 100) ∧
    Mard.populationRisk coinMeasure outcome feature = 0 ∧
    Measurable predictor ∧ (∀ u, predictor (feature u) = outcome u) ∧
    (feature true - feature false) / feature false = 3 / 250 :=
  ⟨coarse_populationRisk, rich_populationRisk, predictor_measurable,
    predictor_exact, relative_feature_difference⟩

end
end Mard.Counterexample
