import Mard.Basic
import Mathlib.Data.List.Sort
import Mathlib.Data.List.Induction

/-!
# Proposition 1: group medians attain the finite-sample minimum

`middle` removes one value from each end. For an odd sorted list it returns
the central value; for an even sorted list it returns the arithmetic mean of
the two central values. It returns zero on the empty list. `sampleMedian`
first sorts the observations, preserving all duplicates.
-/

set_option autoImplicit false
open scoped BigOperators Classical

namespace Mard

noncomputable section

def absLoss (l : List ℝ) (c : ℝ) : ℝ :=
  (l.map fun y => |y - c|).sum

def middle : List ℝ → ℝ := by
  classical
  exact List.bidirectionalRec 0 (fun a => a)
    (fun a l b inner => if l = [] then (a + b) / 2 else inner)

@[simp] theorem middle_nil : middle [] = 0 := by simp [middle]

@[simp] theorem middle_singleton (a : ℝ) : middle [a] = a := by simp [middle]

theorem middle_cons_append (a b : ℝ) (l : List ℝ) :
    middle (a :: (l ++ [b])) = if l = [] then (a + b) / 2 else middle l := by
  classical
  simp [middle]

@[simp] theorem absLoss_nil (c : ℝ) : absLoss [] c = 0 := by simp [absLoss]

@[simp] theorem absLoss_singleton (a c : ℝ) : absLoss [a] c = |a - c| := by
  simp [absLoss]

theorem absLoss_cons_append (a b c : ℝ) (l : List ℝ) :
    absLoss (a :: (l ++ [b])) c = |a - c| + absLoss l c + |b - c| := by
  simp [absLoss, add_assoc]

theorem absLoss_perm {l k : List ℝ} (h : l.Perm k) (c : ℝ) :
    absLoss l c = absLoss k c := (h.map (fun y => |y - c|)).sum_eq

theorem middle_bounds (l : List ℝ) (lo hi : ℝ) (hne : l ≠ [])
    (hb : ∀ z ∈ l, lo ≤ z ∧ z ≤ hi) : lo ≤ middle l ∧ middle l ≤ hi := by
  induction l using List.bidirectionalRec with
  | nil => exact (hne rfl).elim
  | singleton a => simpa using hb a (by simp)
  | cons_append a l b ih =>
    rw [middle_cons_append]
    split_ifs with hl
    · have ha := hb a (by simp)
      have hb' := hb b (by simp)
      constructor <;> linarith
    · apply ih hl
      intro z hz
      exact hb z (by simp [hz])

theorem pair_loss_minimized (a m b c : ℝ) (ham : a ≤ m) (hmb : m ≤ b) :
    |a - m| + |b - m| ≤ |a - c| + |b - c| := by
  rw [abs_of_nonpos (sub_nonpos.mpr ham), abs_of_nonneg (sub_nonneg.mpr hmb)]
  have h₁ := neg_le_abs (a - c)
  have h₂ := le_abs_self (b - c)
  linarith

theorem middle_minimizes_sorted (l : List ℝ) :
    l.Pairwise (· ≤ ·) → ∀ c : ℝ, absLoss l (middle l) ≤ absLoss l c := by
  induction l using List.bidirectionalRec with
  | nil => intro _ c; simp
  | singleton a => intro _ c; simp
  | cons_append a l b ih =>
    intro hs c
    have ha := (List.pairwise_cons.mp hs).1
    have ht := List.pairwise_append.mp (List.pairwise_cons.mp hs).2
    have hl : l.Pairwise (· ≤ ·) := ht.1
    have hab : a ≤ b := ha b (by simp)
    have hm : a ≤ middle (a :: (l ++ [b])) ∧
        middle (a :: (l ++ [b])) ≤ b := by
      rw [middle_cons_append]
      split_ifs with he
      · constructor <;> linarith
      · apply middle_bounds l a b he
        intro z hz
        exact ⟨ha z (by simp [hz]), ht.2.2 z hz b (by simp)⟩
    have hi : absLoss l (middle (a :: (l ++ [b]))) ≤ absLoss l c := by
      by_cases he : l = []
      · simp [he]
      · simpa [middle_cons_append, he] using ih hl c
    have hp := pair_loss_minimized a (middle (a :: (l ++ [b]))) b c hm.1 hm.2
    rw [absLoss_cons_append, absLoss_cons_append]
    linarith

def sampleMedian (l : List ℝ) : ℝ :=
  middle (l.mergeSort (· ≤ ·))

/-- The median exists by its explicit definition and minimizes absolute loss
for every finite list of real labels, including repeated labels. -/
theorem sampleMedian_minimizes (l : List ℝ) (c : ℝ) :
    absLoss l (sampleMedian l) ≤ absLoss l c := by
  have hp := List.mergeSort_perm l (· ≤ ·)
  rw [← absLoss_perm hp (sampleMedian l), ← absLoss_perm hp c]
  exact middle_minimizes_sorted _ (List.sorted_mergeSort' (· ≤ ·) l) c

variable {I G : Type*}

def groupLabels (s : Finset I) (y : I → ℝ) (group : I → G) (g : G) : List ℝ := by
  classical
  exact (s.filter fun i => group i = g).toList.map y

def medianPredictor (s : Finset I) (y : I → ℝ) (group : I → G) : G → ℝ :=
  fun g => sampleMedian (groupLabels s y group g)

theorem groupLabels_loss (s : Finset I) (y : I → ℝ) (group : I → G) (g : G)
    (c : ℝ) : absLoss (groupLabels s y group g) c =
      ∑ i ∈ s with group i = g, |y i - c| := by
  classical
  simp [absLoss, groupLabels, List.map_map, Finset.sum_map_toList, Function.comp_def]

theorem sum_group_losses (s : Finset I) (y : I → ℝ) (group : I → G) (f : G → ℝ) :
    (∑ g ∈ s.image group, absLoss (groupLabels s y group g) (f g)) =
      ∑ i ∈ s, |y i - f (group i)| := by
  classical
  simp_rw [groupLabels_loss]
  calc
    _ = ∑ g ∈ s.image group, ∑ i ∈ s with group i = g, |y i - f (group i)| := by
      apply Finset.sum_congr rfl
      intro g _
      apply Finset.sum_congr rfl
      intro i hi
      rw [(Finset.mem_filter.mp hi).2]
    _ = _ := Finset.sum_fiberwise_of_maps_to
      (fun i hi => Finset.mem_image_of_mem group hi) _

/-- All records have equal weight, the denominator is the full record count,
and each group must receive a single prediction. -/
theorem grouped_median_minimizes (s : Finset I) (y : I → ℝ) (group : I → G)
    (f : G → ℝ) :
    empiricalRisk s y group (medianPredictor s y group) ≤ empiricalRisk s y group f := by
  classical
  unfold empiricalRisk
  apply div_le_div_of_nonneg_right _ (Nat.cast_nonneg s.card)
  rw [← sum_group_losses s y group (medianPredictor s y group),
    ← sum_group_losses s y group f]
  apply Finset.sum_le_sum
  intro g _
  exact sampleMedian_minimizes (groupLabels s y group g) (f g)

/-- Core proposition 1: the infimum is attained by the group medians. The
nonempty domain states explicitly the intended meaning of an average. -/
theorem grouped_median_optimal (s : Finset I) (hne : s.Nonempty)
    (y : I → ℝ) (group : I → G) :
    optimalRisk s y group =
      (∑ g ∈ s.image group,
        absLoss (groupLabels s y group g) (sampleMedian (groupLabels s y group g))) /
      (s.card : ℝ) := by
  classical
  have _hN : (0 : ℝ) < s.card := Nat.cast_pos.mpr hne.card_pos
  rw [optimalRisk_eq_of_minimizer s y group (medianPredictor s y group)
    (grouped_median_minimizes s y group)]
  unfold empiricalRisk
  rw [← sum_group_losses]
  rfl

end
end Mard
