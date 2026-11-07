import Mard.Sampling
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Integral.Gamma

/-! Exact population and two-observation fitted risks under a common real Gaussian law. -/

set_option autoImplicit false
open MeasureTheory ProbabilityTheory Set
open scoped BigOperators NNReal Real
noncomputable section

namespace Mard.Sampling

private theorem gaussian_half_moment :
    (∫ x : ℝ in Ioi 0, x * Real.exp (-(1/2 : ℝ) * x^2)) = 1 := by
  have h := integral_rpow_mul_exp_neg_mul_rpow (p := 2) (q := 1) (b := 1/2)
    (by norm_num) (by norm_num) (by norm_num)
  norm_num [Real.rpow_neg_one, Real.Gamma_one] at h
  simpa only [neg_mul] using h

theorem standardGaussian_abs :
    (∫ x : ℝ, |x| ∂gaussianReal 0 1) = Real.sqrt (2 / Real.pi) := by
  rw [integral_gaussianReal_eq_integral_smul (by norm_num : (1 : ℝ≥0) ≠ 0)]
  have density (x : ℝ) : gaussianPDFReal 0 1 x • |x| =
      (Real.sqrt (2 * Real.pi))⁻¹ * (|x| * Real.exp (-(1/2 : ℝ) * |x|^2)) := by
    simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero, smul_eq_mul, sq_abs]
    rw [show -x^2 / 2 = -(1/2 : ℝ) * x^2 by ring]
    ring
  simp only [density, integral_const_mul]
  rw [integral_comp_abs (f := fun x : ℝ => x * Real.exp (-(1/2 : ℝ) * x^2)), gaussian_half_moment]
  rw [Real.sqrt_div (by norm_num), Real.sqrt_mul (by norm_num)]
  have hs : Real.sqrt 2 ≠ 0 := by positivity
  have hp : Real.sqrt Real.pi ≠ 0 := by positivity
  field_simp
  nlinarith [Real.sq_sqrt (by norm_num : (0:ℝ) ≤ 2)]

/-- Absolute first moment, including the zero-variance point mass. -/
theorem gaussian_abs (v : ℝ≥0) :
    (∫ x : ℝ, |x| ∂gaussianReal 0 v) = Real.sqrt (v : ℝ) * Real.sqrt (2 / Real.pi) := by
  have scale : (⟨Real.sqrt (v : ℝ) ^ 2, sq_nonneg _⟩ : ℝ≥0) = v :=
    NNReal.eq (Real.sq_sqrt v.coe_nonneg)
  have law : HasLaw (fun x : ℝ => Real.sqrt v * x) (gaussianReal 0 v) (gaussianReal 0 1) :=
    ⟨by fun_prop, by simpa [scale] using gaussianReal_map_const_mul (μ := 0) (v := 1) (Real.sqrt v)⟩
  rw [← law.integral_comp (f := fun x : ℝ => |x|) (by fun_prop)]
  simp only [Function.comp_apply, abs_mul, abs_of_nonneg (Real.sqrt_nonneg _),
    integral_const_mul, standardGaussian_abs]

theorem gaussian_center_risk (m : ℝ) (v : ℝ≥0) :
    populationRisk (gaussianReal m v) m = Real.sqrt (v : ℝ) * Real.sqrt (2 / Real.pi) := by
  have law : HasLaw (fun x : ℝ => x - m) (gaussianReal 0 v) (gaussianReal m v) :=
    ⟨by fun_prop, by simpa using gaussianReal_map_sub_const (μ := m) (v := v) m⟩
  exact (law.integral_comp (f := fun z : ℝ => |z|) (by fun_prop)).trans (gaussian_abs v)

/-- Reflection about the center proves that it attains the population absolute-loss minimum. -/
theorem gaussian_center_minimizes (m c : ℝ) (v : ℝ≥0) :
    populationRisk (gaussianReal m v) m ≤ populationRisk (gaussianReal m v) c := by
  let ν := gaussianReal m v
  have hi : Integrable id ν := memLp_one_iff_integrable.mp (memLp_id_gaussianReal 1)
  have loss (a : ℝ) : Integrable (fun x : ℝ => |x-a|) ν := (hi.sub (integrable_const a)).abs
  have reflect : HasLaw (fun x : ℝ => 2*m-x) ν ν :=
    ⟨by fun_prop, by simpa [ν,show 2*m-m=m by ring] using gaussianReal_map_const_sub (μ := m) (v := v) (2*m)⟩
  have reflected : Integrable (fun x : ℝ => |(2*m-x)-c|) ν := by
    have h := loss c
    nth_rw 1 [← reflect.map_eq] at h
    exact h.comp_aemeasurable reflect.aemeasurable
  have eq : (∫ x, |(2*m-x)-c| ∂ν) = populationRisk ν c :=
    reflect.integral_comp (f := fun x : ℝ => |x-c|) (by fun_prop)
  have h := integral_mono ((loss m).const_mul 2) ((loss c).add reflected) (fun x => by
    change 2 * |x-m| ≤ |x-c| + |(2*m-x)-c|
    have t := abs_sub_le x c (2*m-x)
    rw [show x-(2*m-x) = 2*(x-m) by ring, abs_mul, abs_of_pos (by norm_num : (0:ℝ)<2),
      abs_sub_comm c (2*m-x)] at t
    exact t)
  change (∫ x, 2*|x-m| ∂ν) ≤ ∫ x, (|x-c| + |(2*m-x)-c|) ∂ν at h
  rw [integral_const_mul, integral_add (loss c) reflected, eq] at h
  change 2*populationRisk ν m ≤ populationRisk ν c + populationRisk ν c at h
  change populationRisk ν m ≤ populationRisk ν c
  linarith

theorem gaussian_optimal_risk (m : ℝ) (v : ℝ≥0) :
    optimalPopulationRisk (gaussianReal m v) = Real.sqrt (v : ℝ) * Real.sqrt (2 / Real.pi) := by
  rw [← gaussian_center_risk]
  apply IsLeast.csInf_eq
  exact ⟨⟨m,rfl⟩,by rintro _ ⟨c,rfl⟩; exact gaussian_center_minimizes m c v⟩

variable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {Y : Fin 2 → Ω → ℝ}

theorem gaussian_difference_law {m : ℝ} {v : ℝ≥0} (law : ∀ i, HasLaw (Y i) (gaussianReal m v) P)
    (indep : IndepFun (Y 0) (Y 1) P) :
    HasLaw (fun ω => Y 0 ω - Y 1 ω) (gaussianReal 0 (v+v)) P := by
  have neg : HasLaw (fun x : ℝ => -x) (gaussianReal (-m) v) (gaussianReal m v) :=
    ⟨by fun_prop, gaussianReal_map_neg⟩
  have hneg : HasLaw (-(Y 1)) (gaussianReal (-m) v) P := neg.comp (law 1)
  refine ⟨(law 0).aemeasurable.sub (law 1).aemeasurable, ?_⟩
  simpa [sub_eq_add_neg, Pi.add_def, Pi.neg_def] using
    gaussianReal_add_gaussianReal_of_indepFun indep.neg_right (law 0).map_eq hneg.map_eq

/-- For two independent draws of standard deviation τ, the fitted loss has mean τ/√π. -/
theorem gaussian_two_expected {m : ℝ} (τ : ℝ≥0) (law : ∀ i, HasLaw (Y i) (gaussianReal m (τ^2)) P)
    (indep : IndepFun (Y 0) (Y 1) P) :
    (∫ ω, fittedRisk (fun i => Y i ω) ∂P) = (τ : ℝ) / Real.sqrt Real.pi := by
  simp only [fittedRisk_two, integral_div]
  have diff := gaussian_difference_law law indep
  rw [show (∫ ω, |Y 0 ω - Y 1 ω| ∂P) = ∫ x : ℝ, |x| ∂gaussianReal 0 (τ^2 + τ^2) from
    diff.integral_comp (f := fun x : ℝ => |x|) (by fun_prop), gaussian_abs]
  rw [NNReal.coe_add, NNReal.coe_pow, ← two_mul, Real.sqrt_mul (by norm_num),
    Real.sqrt_sq τ.coe_nonneg, Real.sqrt_div (by norm_num)]
  have hp : Real.sqrt Real.pi ≠ 0 := by positivity
  field_simp
  rw [Real.sq_sqrt (by norm_num : (0:ℝ) ≤ 2)]
  ring

/-- The exact population optimum and fitted expectation, with no division by the scale. -/
theorem gaussian_two_bias {m : ℝ} (τ : ℝ≥0) (law : ∀ i, HasLaw (Y i) (gaussianReal m (τ^2)) P)
    (indep : IndepFun (Y 0) (Y 1) P) :
    let empirical := ∫ ω, fittedRisk (fun i => Y i ω) ∂P
    let population := optimalPopulationRisk (gaussianReal m (τ^2))
    empirical = (τ : ℝ) / Real.sqrt Real.pi ∧
    population = (τ : ℝ) * Real.sqrt (2 / Real.pi) ∧
    population = Real.sqrt 2 * empirical := by
  dsimp only
  rw [gaussian_two_expected τ law indep, gaussian_optimal_risk, NNReal.coe_pow, Real.sqrt_sq τ.coe_nonneg]
  simp [Real.sqrt_div (by norm_num : (0:ℝ) ≤ 2)]
  ring

theorem gaussian_two_strict {m : ℝ} {τ : ℝ≥0} (hτ : 0 < τ)
    (law : ∀ i, HasLaw (Y i) (gaussianReal m (τ^2)) P) (indep : IndepFun (Y 0) (Y 1) P) :
    (∫ ω, fittedRisk (fun i => Y i ω) ∂P) < optimalPopulationRisk (gaussianReal m (τ^2)) := by
  obtain ⟨h,_,he⟩ := gaussian_two_bias τ law indep
  rw [he,h]
  have hr : (1:ℝ) < Real.sqrt 2 := by
    nlinarith [Real.sq_sqrt (by norm_num : (0:ℝ) ≤ 2), Real.sqrt_nonneg 2]
  have hp : 0 < (τ:ℝ) / Real.sqrt Real.pi := div_pos (by exact_mod_cast hτ) (by positivity)
  simpa using mul_lt_mul_of_pos_right hr hp

/-- The two-coordinate product realizes the asserted law and independence for every scale. -/
theorem gaussian_product_two (m : ℝ) (τ : ℝ≥0) :
    let ν := gaussianReal m (τ^2)
    (∫ p : ℝ × ℝ, |p.1-p.2| / 2 ∂ν.prod ν) = (τ : ℝ) / Real.sqrt Real.pi := by
  let ν := gaussianReal m (τ^2)
  let X : Fin 2 → ℝ × ℝ → ℝ := ![Prod.fst, Prod.snd]
  have laws (i : Fin 2) : HasLaw (X i) ν (ν.prod ν) := by
    fin_cases i
    · exact measurePreserving_fst.hasLaw
    · exact measurePreserving_snd.hasLaw
  have hind : IndepFun (X 0) (X 1) (ν.prod ν) := indepFun_prod measurable_id measurable_id
  simpa only [fittedRisk_two, X, Matrix.cons_val_zero, Matrix.cons_val_one] using
    gaussian_two_expected τ laws hind

/-- For positive scale even the population optimum can be exceeded by a single fitted sample. -/
theorem gaussian_two_above_threshold {m : ℝ} {τ : ℝ≥0} (hτ : 0 < τ)
    (law : ∀ i, HasLaw (Y i) (gaussianReal m (τ^2)) P) (indep : IndepFun (Y 0) (Y 1) P) (r : ℝ) :
    0 < P {ω | r < fittedRisk (fun i => Y i ω)} := by
  have diff := gaussian_difference_law law indep
  have hv : τ^2 + τ^2 ≠ 0 := by positivity
  have tail : 0 < gaussianReal 0 (τ^2 + τ^2) (Ioi (2*r)) := by
    apply pos_iff_ne_zero.mpr
    intro h
    have hz := (gaussianReal_absolutelyContinuous' 0 hv) h
    simp only [Real.volume_Ioi, ENNReal.top_ne_zero] at hz
  rw [← diff.map_eq, Measure.map_apply_of_aemeasurable diff.aemeasurable measurableSet_Ioi] at tail
  apply tail.trans_le (measure_mono ?_)
  intro ω hω
  have h : 2*r < Y 0 ω - Y 1 ω := hω
  change r < fittedRisk (fun i => Y i ω)
  rw [fittedRisk_two]
  linarith [le_abs_self (Y 0 ω - Y 1 ω)]

end Mard.Sampling
