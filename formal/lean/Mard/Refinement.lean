import Mard.Basic
import Mathlib.MeasureTheory.Integral.Lebesgue.Basic

/-!
# Proposition 2: richer features cannot increase optimal absolute risk

The coarse feature must be a function of the rich feature. The finite-sample
theorem keeps *exactly the same records, labels, and denominator*.
The population theorem quantifies over measurable predictors and uses the
nonnegative extended integral, so infinite risk causes no undefined integral.
-/

set_option autoImplicit false
open scoped BigOperators ENNReal

namespace Mard

noncomputable section

variable {I X G : Type*}

theorem empiricalRisk_pullback (s : Finset I) (y : I → ℝ)
    (rich : I → X) (coarse : I → G) (forget : X → G)
    (h : ∀ i ∈ s, coarse i = forget (rich i)) (f : G → ℝ) :
    empiricalRisk s y rich (f ∘ forget) = empiricalRisk s y coarse f := by
  unfold empiricalRisk
  congr 1
  apply Finset.sum_congr rfl
  intro i hi
  simp [h i hi]

/-- Core proposition 2, finite-sample version. -/
theorem feature_refinement (s : Finset I) (y : I → ℝ)
    (rich : I → X) (coarse : I → G) (forget : X → G)
    (h : ∀ i ∈ s, coarse i = forget (rich i)) :
    optimalRisk s y rich ≤ optimalRisk s y coarse := by
  unfold optimalRisk
  apply le_csInf (Set.range_nonempty _)
  rintro _ ⟨f, rfl⟩
  rw [← empiricalRisk_pullback s y rich coarse forget h f]
  exact optimalRisk_le s y rich (f ∘ forget)

/-- Extra information can be a second component of the feature tuple. -/
theorem add_feature_nonincreasing (s : Finset I) (y : I → ℝ)
    (coarse : I → G) (extra : I → X) :
    optimalRisk s y (fun i => (coarse i, extra i)) ≤ optimalRisk s y coarse := by
  exact feature_refinement s y _ coarse Prod.fst (fun _ _ => rfl)

open MeasureTheory

variable {Ω : Type*} [MeasurableSpace Ω] [MeasurableSpace X] [MeasurableSpace G]

def populationRisk (μ : Measure Ω) (y : Ω → ℝ) (x : Ω → X) : ℝ≥0∞ :=
  ⨅ f : {f : X → ℝ // Measurable f},
    ∫⁻ ω, ENNReal.ofReal |y ω - f.val (x ω)| ∂μ

/-- Population version, for the same measure and target. In particular this
applies to probability laws with finite first absolute moment. Measurable
coarse predictors lift to measurable rich predictors. -/
theorem population_feature_refinement (μ : Measure Ω) (y : Ω → ℝ)
    (rich : Ω → X) (forget : X → G) (hf : Measurable forget) :
    populationRisk μ y rich ≤ populationRisk μ y (forget ∘ rich) := by
  unfold populationRisk
  refine le_iInf fun f => ?_
  exact iInf_le_of_le ⟨f.val ∘ forget, f.property.comp hf⟩ le_rfl

end
end Mard
