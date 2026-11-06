import Mard.Refinement
import Mathlib.Data.Fintype.BigOperators

/-!
# Proposition 3: the explicit 0.41 versus zero counterexample

The sample space is Bool with two equally weighted outcomes. These two
weights also define a complete population law; they are not estimated from
training or test data. All decimals below are exact rational real numbers.
-/

set_option autoImplicit false
open scoped BigOperators

namespace Mard.Counterexample

noncomputable section

def sign (u : Bool) : ℝ := if u then 1 else -1
def feature (u : Bool) : ℝ := 503 / 500 + (3 / 500) * sign u
def outcome (u : Bool) : ℝ := -4 + (41 / 100) * sign u
def coarse (_ : Bool) : Unit := ()
def predictor (a : ℝ) : ℝ := -4 + ((41 / 100) / (3 / 500)) * (a - 503 / 500)

def coarseRisk (c : ℝ) : ℝ := (|outcome false - c| + |outcome true - c|) / 2

theorem feature_false : feature false = 1 := by norm_num [feature, sign]
theorem feature_true : feature true = 253 / 250 := by norm_num [feature, sign]

/-- The feature values differ by exactly 1.2% relative to the smaller value. -/
theorem relative_feature_difference :
    (feature true - feature false) / feature false = 3 / 250 := by
  rw [feature_false, feature_true]
  norm_num

theorem predictor_exact (u : Bool) : predictor (feature u) = outcome u := by
  unfold predictor feature outcome
  ring

theorem coarseRisk_lower_bound (c : ℝ) : 41 / 100 ≤ coarseRisk c := by
  have h₁ := neg_le_abs (outcome false - c)
  have h₂ := le_abs_self (outcome true - c)
  norm_num [outcome, sign] at h₁ h₂
  unfold coarseRisk
  norm_num [outcome, sign]
  linarith

theorem coarseRisk_attained : coarseRisk (-4) = 41 / 100 := by
  norm_num [coarseRisk, outcome, sign]

theorem coarse_empiricalRisk (f : Unit → ℝ) :
    Mard.empiricalRisk Finset.univ outcome coarse f = coarseRisk (f ()) := by
  simp [Mard.empiricalRisk, coarseRisk, coarse, add_comm]

/-- Optimal coarse risk is exactly 0.41, not merely at most 0.41. -/
theorem coarse_optimalRisk :
    Mard.optimalRisk Finset.univ outcome coarse = 41 / 100 := by
  rw [Mard.optimalRisk_eq_of_minimizer _ _ _ (fun _ => -4)]
  · rw [coarse_empiricalRisk, coarseRisk_attained]
  · intro f
    rw [coarse_empiricalRisk, coarse_empiricalRisk, coarseRisk_attained]
    exact coarseRisk_lower_bound (f ())

theorem richRisk_zero :
    Mard.empiricalRisk Finset.univ outcome feature predictor = 0 := by
  simp [Mard.empiricalRisk, predictor_exact]

theorem rich_optimalRisk :
    Mard.optimalRisk Finset.univ outcome feature = 0 := by
  apply le_antisymm
  · calc
      _ ≤ Mard.empiricalRisk Finset.univ outcome feature predictor :=
        Mard.optimalRisk_le _ _ _ _
      _ = 0 := richRisk_zero
  · exact Mard.optimalRisk_nonneg _ _ _

/-- Core proposition 3: one explicitly specified two-point population has
a positive coarse minimum, zero rich minimum, and only 1.2% feature variation. -/
theorem exact_counterexample :
    Mard.optimalRisk Finset.univ outcome coarse = 41 / 100 ∧
    Mard.optimalRisk Finset.univ outcome feature = 0 ∧
    (∀ u, predictor (feature u) = outcome u) ∧
    (feature true - feature false) / feature false = 3 / 250 :=
  ⟨coarse_optimalRisk, rich_optimalRisk, predictor_exact, relative_feature_difference⟩

/-- A coarse optimum is not a universal lower bound for richer input. -/
theorem coarse_bound_not_universal :
    ¬ Mard.optimalRisk Finset.univ outcome coarse ≤
      Mard.optimalRisk Finset.univ outcome feature := by
  rw [coarse_optimalRisk, rich_optimalRisk]
  norm_num

end
end Mard.Counterexample
