import Mard.Median
import Mathlib.Probability.HasLaw
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.Topology.MetricSpace.Pseudo.Pi

/-! Expected within-sample absolute deviation about the fitted group median. -/

set_option autoImplicit false
open MeasureTheory ProbabilityTheory
open scoped BigOperators
noncomputable section

namespace Mard.Sampling

variable {n : ℕ}

/-- Equal-weight absolute loss for a fixed center on the indexed observations. -/
def sampleRisk (y : Fin n → ℝ) (c : ℝ) : ℝ := (∑ i, |y i - c|) / n

/-- Fit the same sample median as in the grouped finite-record theorem. -/
def fittedRisk (y : Fin n → ℝ) : ℝ := sampleRisk y (sampleMedian (List.ofFn y))

theorem fittedRisk_le (y : Fin n → ℝ) (c : ℝ) : fittedRisk y ≤ sampleRisk y c := by
  apply div_le_div_of_nonneg_right _ (Nat.cast_nonneg n)
  simpa only [absLoss, List.map_ofFn, List.sum_ofFn, Function.comp_apply] using
    sampleMedian_minimizes (List.ofFn y) c

theorem fittedRisk_nonneg (y : Fin n → ℝ) : 0 ≤ fittedRisk y :=
  div_nonneg (Finset.sum_nonneg fun _ _ => abs_nonneg _) (Nat.cast_nonneg n)

theorem fittedRisk_eq_inf (y : Fin n → ℝ) :
    fittedRisk y = sInf (Set.range (sampleRisk y)) := by
  symm
  apply IsLeast.csInf_eq
  exact ⟨⟨sampleMedian (List.ofFn y), rfl⟩, by rintro _ ⟨c,rfl⟩; exact fittedRisk_le y c⟩

theorem fittedRisk_eq_grouped (y : Fin n → ℝ) :
    fittedRisk y = optimalRisk Finset.univ y (fun _ => ()) := by
  rw [optimalRisk_eq_of_minimizer _ _ _ (fun _ => sampleMedian (List.ofFn y))]
  · simp [fittedRisk, sampleRisk, empiricalRisk]
  · intro f
    simpa [fittedRisk, sampleRisk, empiricalRisk] using fittedRisk_le y (f ())

/-- The value of the fitted loss is continuous even when observations tie. -/
theorem fittedRisk_lipschitz (hn : 0 < n) : LipschitzWith 1 (fittedRisk (n := n)) := by
  apply LipschitzWith.of_le_add_mul
  intro x y
  simp only [NNReal.coe_one, one_mul]
  let c := sampleMedian (List.ofFn y)
  have bound (i : Fin n) : |x i - c| ≤ |y i - c| + dist x y := by
    have h := abs_sub_le (x i) (y i) c
    have hd : |x i - y i| ≤ dist x y := dist_le_pi_dist x y i
    linarith
  have hn' : (n : ℝ) ≠ 0 := Nat.cast_ne_zero.mpr hn.ne'
  calc
    fittedRisk x ≤ sampleRisk x c := fittedRisk_le x c
    _ ≤ (∑ i : Fin n, (|y i - c| + dist x y)) / n :=
      div_le_div_of_nonneg_right (Finset.sum_le_sum fun i _ => bound i) (Nat.cast_nonneg n)
    _ = fittedRisk y + dist x y := by
      simp [Finset.sum_add_distrib, add_div, fittedRisk, sampleRisk, c, hn']

theorem fittedRisk_singleton (y : Fin 1 → ℝ) : fittedRisk y = 0 := by
  apply le_antisymm _ (fittedRisk_nonneg y)
  simpa [sampleRisk] using fittedRisk_le y (y 0)

theorem fittedRisk_two (y : Fin 2 → ℝ) : fittedRisk y = |y 0 - y 1| / 2 := by
  apply le_antisymm
  · simpa [sampleRisk, Fin.sum_univ_two] using fittedRisk_le y (y 1)
  · let c := sampleMedian (List.ofFn y)
    have h := abs_sub_le (y 0) c (y 1)
    rw [abs_sub_comm c (y 1)] at h
    simpa [fittedRisk, sampleRisk, Fin.sum_univ_two, c] using
      div_le_div_of_nonneg_right h (by norm_num : (0:ℝ) ≤ 2)

def populationRisk (ν : Measure ℝ) (c : ℝ) : ℝ := ∫ y, |y - c| ∂ν

def optimalPopulationRisk (ν : Measure ℝ) : ℝ := sInf (Set.range (populationRisk ν))

variable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
  {ν : Measure ℝ} {Y : Fin n → Ω → ℝ}

omit [IsProbabilityMeasure P] in
private theorem observation_integrable {X : Ω → ℝ} (law : HasLaw X ν P) (hν : Integrable id ν) :
    Integrable X P := by
  rw [← law.map_eq] at hν
  exact hν.comp_aemeasurable law.aemeasurable

private theorem fixed_integrable (law : ∀ i, HasLaw (Y i) ν P) (hν : Integrable id ν) (c : ℝ) :
    Integrable (fun ω => sampleRisk (fun i => Y i ω) c) P :=
  (integrable_finset_sum Finset.univ (fun i _ =>
    ((observation_integrable (law i) hν).sub (integrable_const c)).abs)).div_const _

theorem fittedRisk_integrable (hn : 0 < n) (law : ∀ i, HasLaw (Y i) ν P) (hν : Integrable id ν) :
    Integrable (fun ω => fittedRisk (fun i => Y i ω)) P := by
  have hm : AEMeasurable (fun ω i => Y i ω) P := aemeasurable_pi_lambda _ fun i => (law i).aemeasurable
  apply (fixed_integrable law hν 0).mono' ((fittedRisk_lipschitz hn).continuous.measurable.comp_aemeasurable hm).aestronglyMeasurable
  exact ae_of_all _ fun ω => by
    rw [Real.norm_eq_abs, Function.comp_apply, abs_of_nonneg (fittedRisk_nonneg _)]
    exact fittedRisk_le _ 0

theorem expected_fixedRisk (hn : 0 < n) (law : ∀ i, HasLaw (Y i) ν P) (hν : Integrable id ν)
    (c : ℝ) : (∫ ω, sampleRisk (fun i => Y i ω) c ∂P) = populationRisk ν c := by
  have hi (i : Fin n) : Integrable (fun ω => |Y i ω - c|) P :=
    ((observation_integrable (law i) hν).sub (integrable_const c)).abs
  have he (i : Fin n) : (∫ ω, |Y i ω - c| ∂P) = populationRisk ν c :=
    (law i).integral_comp (f := fun y => |y - c|) (by fun_prop)
  simp only [sampleRisk, integral_div, integral_finset_sum _ (fun i _ => hi i), he]
  simp [Nat.cast_ne_zero.mpr hn.ne']

/-- Section 4. A common marginal suffices for the expected-bias inequality. -/
theorem expected_fittedRisk_le (hn : 0 < n) (law : ∀ i, HasLaw (Y i) ν P)
    (hν : Integrable id ν) :
    (∫ ω, fittedRisk (fun i => Y i ω) ∂P) ≤ optimalPopulationRisk ν := by
  apply le_csInf (Set.range_nonempty _)
  rintro _ ⟨c,rfl⟩
  rw [← expected_fixedRisk hn law hν c]
  exact integral_mono (fittedRisk_integrable hn law hν) (fixed_integrable law hν c)
    (fun _ => fittedRisk_le _ c)

theorem expected_empirical_inf_le (hn : 0 < n) (law : ∀ i, HasLaw (Y i) ν P)
    (hν : Integrable id ν) :
    (∫ ω, sInf (Set.range (sampleRisk (fun i => Y i ω))) ∂P) ≤
      sInf (Set.range (fun c : ℝ => ∫ y, |y - c| ∂ν)) := by
  simpa only [← fittedRisk_eq_inf, optimalPopulationRisk, populationRisk] using
    expected_fittedRisk_le hn law hν

/-- The independent, identically distributed experiment, with its product probability law. -/
theorem iid_product_bias (hn : 0 < n) (ν : Measure ℝ) [IsProbabilityMeasure ν]
    (hν : Integrable id ν) :
    (∫ y : Fin n → ℝ, fittedRisk y ∂Measure.pi (fun _ : Fin n => ν)) ≤ optimalPopulationRisk ν :=
  expected_fittedRisk_le hn (fun i => (measurePreserving_eval (μ := fun _ : Fin n => ν) i).hasLaw) hν

end Mard.Sampling
