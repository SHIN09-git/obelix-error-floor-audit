import Mathlib.Data.Real.Archimedean
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-!
# Finite-sample absolute risk

The observations are a finite set of *record identifiers*. Distinct records may
have identical features and/or labels. Every risk uses the same denominator,
the number of records in that set. Predictions are arbitrary real-valued
functions of the specified features; no learnability claim is made.
-/

set_option autoImplicit false
open scoped BigOperators

namespace Mard

noncomputable section

variable {I X : Type*}

def empiricalRisk (s : Finset I) (y : I → ℝ) (x : I → X) (f : X → ℝ) : ℝ :=
  (∑ i ∈ s, |y i - f (x i)|) / (s.card : ℝ)

def optimalRisk (s : Finset I) (y : I → ℝ) (x : I → X) : ℝ :=
  sInf (Set.range (empiricalRisk s y x))

theorem empiricalRisk_nonneg (s : Finset I) (y : I → ℝ)
    (x : I → X) (f : X → ℝ) : 0 ≤ empiricalRisk s y x f := by
  exact div_nonneg (Finset.sum_nonneg fun i _ => abs_nonneg (y i - f (x i)))
    (Nat.cast_nonneg s.card)

theorem riskRange_bddBelow (s : Finset I) (y : I → ℝ) (x : I → X) :
    BddBelow (Set.range (empiricalRisk s y x)) := by
  refine ⟨0, ?_⟩
  rintro _ ⟨f, rfl⟩
  exact empiricalRisk_nonneg s y x f

theorem optimalRisk_nonneg (s : Finset I) (y : I → ℝ) (x : I → X) :
    0 ≤ optimalRisk s y x := by
  unfold optimalRisk
  apply le_csInf (Set.range_nonempty _)
  rintro _ ⟨f, rfl⟩
  exact empiricalRisk_nonneg s y x f

theorem optimalRisk_le (s : Finset I) (y : I → ℝ) (x : I → X) (f : X → ℝ) :
    optimalRisk s y x ≤ empiricalRisk s y x f :=
  csInf_le (riskRange_bddBelow s y x) ⟨f, rfl⟩

theorem optimalRisk_eq_of_minimizer (s : Finset I) (y : I → ℝ) (x : I → X)
    (f : X → ℝ) (h : ∀ g, empiricalRisk s y x f ≤ empiricalRisk s y x g) :
    optimalRisk s y x = empiricalRisk s y x f := by
  apply IsLeast.csInf_eq
  exact ⟨⟨f, rfl⟩, by rintro _ ⟨g, rfl⟩; exact h g⟩

end
end Mard
