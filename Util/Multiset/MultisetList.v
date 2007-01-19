(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Adam Koprowski, 2004-09-06

This file provides an implementation of finite multisets using list
representation.
*)

(* $Id: MultisetList.v,v 1.2 2007-01-19 17:22:40 blanqui Exp $ *)

Set Implicit Arguments.

Require Import RelExtras.
Require Import MultisetCore.
Require Import Permutation.
Require Import Multiset.
Require Import List.
Require Import ListExtras.

Module FiniteMultisetList (ES : Eqset) : 

  FiniteMultisetCore with Module Sid := ES.

  Module Sid := ES.
  Import Sid.

  Parameter eqA_dec : forall x y, {eqA x y}+{~eqA x y}.

Section Operations.

  Definition Multiset := list A.

  Definition empty : Multiset := nil.
  Definition singleton a : Multiset := a :: nil.
  Definition union := app (A:=A).
  Definition meq := permutation eqA eqA_dec.

  Definition mult := countIn eqA eqA_dec.
  Definition rem := removeElem eqA eqA_dec.
  Definition diff := removeAll eqA eqA_dec.

  Definition intersection := inter_as_diff diff.

  Definition fold_left := fun T: Set => List.fold_left (A:=T)(B:=A).

End Operations.

Section ImplLemmas.

  Lemma empty_empty : forall M, (forall x, mult x M = 0) -> M = empty.

  Proof.
    intros M mulM; destruct M.
    trivial.
    absurd (mult a (a::M) = 0).
    simpl; case (eqA_dec a a); auto with sets.
    auto.
  Qed.

End ImplLemmas.

Section SpecConformation.

  Notation "X =mul= Y" := (meq X Y) (at level 70).
  Notation "X =A= Y" := (eqA X Y) (at level 70).
  Notation "{{ x }}" := (singleton x) (at level 0).
  
  Lemma mult_eqA_compat : forall M x y, x =A= y -> mult x M = mult y M.

  Proof.
     induction M.
     auto.
     intros; simpl.
     case (eqA_dec x a); case (eqA_dec y a); intros;
       solve [ absurd (y =A= a); eauto with sets
             | assert (mult x M = mult y M); auto ].
  Qed.

  Lemma mult_comp : forall l a,
    mult a l = multiplicity (list_contents eqA eqA_dec l) a.

  Proof.
    induction l.
    auto.
    intro a0; simpl.
    case (eqA_dec a0 a); intro a0_a; case (eqA_dec a a0); intro a_a0;
      solve [ absurd (a0 =A= a); auto with sets 
            | rewrite (IHl a0); trivial].
  Qed.

  Lemma multeq_meq : forall M N, (forall x, mult x M = mult x N) -> M =mul= N.

  Proof.
    unfold meq.
    intros M N mult_MN x.
    repeat rewrite <- mult_comp.
    exact (mult_MN x).
  Qed.

  Lemma meq_multeq : forall M N, M =mul= N -> (forall x, mult x M = mult x N).

  Proof.
    unfold meq, permutation, Multiset.meq.
    intros M N eqMN x.
    repeat rewrite mult_comp.
    exact (eqMN x).
  Qed.

  Lemma empty_mult : forall x, mult x empty = 0.

  Proof.
    auto.
  Qed.

  Lemma union_mult : forall M N x, mult x (union M N) = mult x M + mult x N.

  Proof.
    induction M; auto.
    intros; simpl; case (eqA_dec x a); intro; auto.
    replace (mult x (union M N)) with (mult x M + mult x N); 
      solve [auto | apply IHM].
  Qed.

  Lemma diff_empty_l : forall M, diff empty M = empty.

  Proof.
    induction M; auto.
  Qed.

  Lemma diff_empty_r : forall M, diff M empty = M.

  Proof.
    induction M; auto.
  Qed.

  Lemma mult_remove_in : forall x a M, x =A= a -> mult x (rem a M) = mult x M - 1.

  Proof.
    induction M.
    auto.
    intro x_a.
    simpl; case (eqA_dec x a0); case (eqA_dec a a0); 
      simpl; intros; try solve [absurd (x =A= a); eauto with sets].
    auto with arith.
    destruct (eqA_dec x a0).
    contradiction.
    auto.
  Qed.

  Lemma mult_remove_not_in : forall M a x,
    ~ x =A= a -> mult x (rem a M) = mult x M.

  Proof.
    induction M; intros.
    auto.
    simpl; case (eqA_dec a0 a); intro a0_a.
    case (eqA_dec x a); intro x_a; 
      solve [absurd (x =A= a); eauto with sets | trivial].
    simpl; case (eqA_dec x a); intro x_a.
    rewrite (IHM a0 x); trivial.
    apply IHM; trivial.
  Qed.

  Lemma remove_perm_single : forall x a b M,
   mult x (rem a (rem b M)) = mult x (rem b (rem a M)).

  Proof.
    intros x a b M.
    case (eqA_dec x a); case (eqA_dec x b); intros x_b x_a.
     (* x=b,  x=a *)
    repeat rewrite mult_remove_in; trivial.
     (* x<>b, x=a *)
    rewrite mult_remove_in; trivial.
    do 2 (rewrite mult_remove_not_in; trivial).
    rewrite mult_remove_in; trivial.
     (* x=b,  x<>a *)
    rewrite mult_remove_not_in; trivial.
    do 2 (rewrite mult_remove_in; trivial).
    rewrite mult_remove_not_in; trivial.
     (* x<>b, x<>a *)
    repeat rewrite mult_remove_not_in; trivial.
  Qed.

  Lemma diff_mult_comp : forall x N M M',
    M =mul= M' -> mult x (diff M N) = mult x (diff M' N).

  Proof.
    induction N.
    intros; apply meq_multeq; trivial.
    intros M M' MM'.
    simpl.
    apply IHN.
    apply multeq_meq.
    intro x'.
    case (eqA_dec x' a).
    intro xa; repeat rewrite mult_remove_in; trivial.
    rewrite (meq_multeq MM'); trivial.
    intro xna; repeat rewrite mult_remove_not_in; trivial.
    apply meq_multeq; trivial.
  Qed.

  Lemma diff_perm_single : forall x a b M N, 
    mult x (diff M (a::b::N)) = mult x (diff M (b::a::N)).

  Proof.
    intros x a b M N.
    simpl; apply diff_mult_comp.
    apply multeq_meq.
    intro x'; apply remove_perm_single.
  Qed.

  Lemma diff_perm : forall M N a x,
    mult x (diff (rem a M) N) = mult x (rem a (diff M N)).

  Proof.
    intros M N; generalize M; clear M.
    induction N.
    auto.
    intros M b x.
    change (diff (rem b M) (a::N)) with (diff M (b::a::N)).
    rewrite diff_perm_single.
    simpl; apply IHN.
  Qed.

  Lemma diff_mult_step_eq : forall M N a x,
    x =A= a -> mult x (diff (rem a M) N) = mult x (diff M N) - 1.

  Proof.
    intros M N a x x_a.
    rewrite diff_perm.
    rewrite mult_remove_in; trivial.
  Qed.

  Lemma diff_mult_step_neq : forall M N a x,
    ~ x =A= a -> mult x (diff (rem a M) N) = mult x (diff M N).

  Proof.
    intros M N a x x_a.
    rewrite diff_perm.
    rewrite mult_remove_not_in; trivial.
  Qed.
 
  Lemma diff_mult : forall M N x, mult x (diff M N) = mult x M - mult x N.

  Proof.
    induction N.
     (* induction base *)
    simpl; intros; omega.
     (* induction step *)
    intro x; simpl.
    case (eqA_dec x a); intro x_a; simpl.
     (* x = a *)
    fold rem.
    rewrite (diff_mult_step_eq M N x_a).
    rewrite (IHN x).
    omega.
     (* x <> a *)
    fold rem.
    rewrite (diff_mult_step_neq M N x_a).
    exact (IHN x).
  Qed.

  Definition intersection_mult := inter_as_diff_ok mult diff diff_mult.

  Lemma singleton_mult_in : forall x y, x =A= y -> mult x {{y}} = 1.

  Proof.
    intros; compute.
    case (eqA_dec x y); [trivial | contradiction].
  Qed.
  
  Lemma singleton_mult_notin : forall x y, ~x =A= y -> mult x {{y}} = 0.

  Proof.
    intros; compute.
    case (eqA_dec x y); [contradiction | trivial].
  Qed.

  Lemma rev_list_ind_type : forall P : Multiset -> Type,
    P nil -> (forall a l, P (rev l) -> P (rev (a :: l))) -> forall l, P (rev l).

  Proof.
    induction l; auto.
  Qed.

  Lemma rev_ind_type : forall P : Multiset -> Type,
    P nil -> (forall x l, P l -> P (l ++ x :: nil)) -> forall l, P l.

  Proof.
    intros.
    generalize (rev_involutive l).
    intros E; rewrite <- E.
    apply (rev_list_ind_type P).
    auto.
    simpl in |- *.
    intros.
    apply (X0 a (rev l0)).
    auto.
  Qed.

  Lemma mset_ind_type : forall P : Multiset -> Type,
    P empty -> (forall M a, P M -> P (union M {{a}})) -> forall M, P M.

  Proof.
    induction M as [| x M] using rev_ind_type.
    exact X.
    exact (X0 M x IHM).
  Qed.
 
End SpecConformation.

End FiniteMultisetList.
