(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Frederic Blanqui, 2009-07-07

root labelling (Zantema & Waldmann, RTA'07) (Sternagel & Middeldorp, RTA'08)
*)

Set Implicit Arguments.

Require Import ATrs.
Require Import AInterpretation.
Require Import LogicUtil.
Require Import ListUtil.
Require Import VecUtil.
Require Import BoolUtil.
Require Import EqUtil.
Require Import ASemLab.
Require Import SN.

(***********************************************************************)
(** data necessary for a root labelling *)

Module Type RootLab.

  Parameter Sig : Signature.
  Parameter some_symbol : Sig.

  Parameter Fs : list Sig.
  Parameter Fs_ok : forall x : Sig, In x Fs.

End RootLab.

(***********************************************************************)
(** root labelling *)

Module RootSemLab (Export R : RootLab) <: FinSemLab.

  Notation beq_symb_ok := (@beq_symb_ok Sig).
  Notation eq_symb_dec := (@eq_symb_dec Sig).

  Notation term := (term Sig). Notation terms := (vector term).
  Notation rule := (rule Sig). Notation rules := (rules Sig).

  Module SL <: SemLab.

    Definition Sig := Sig.

    Definition I := mkInterpretation some_symbol (fun f _ => f).

    Record Lab : Type := mk {
      L_symb : Sig;
      L_args : vector I (arity L_symb)
    }.

    Ltac Leqtac := repeat
      match goal with
        | H : mk ?x ?v = mk ?x ?w |- _ =>
          let h := fresh in
            (injection H; intro h1; ded (inj_pairT2 eq_symb_dec h1);
              clear h1; clear H)
        | H : mk ?x ?v = mk ?y ?w |- _ =>
          let h1 := fresh in let h2 := fresh in
            (injection H; intros h1 h2; subst; ded (inj_pairT2 eq_symb_dec h1);
              clear h1; clear H)
      end.

    Definition L := Lab.

    Definition beq (l1 l2 : L) :=
      let (f1,v1) := l1 in let (f2,v2) := l2 in
        beq_symb f1 f2 && beq_vec (@beq_symb Sig) v1 v2.

    Lemma beq_ok : forall l1 l2, beq l1 l2 = true <-> l1 = l2.

    Proof.
      intros [f1 v1] [f2 v2]. simpl. rewrite andb_eq. rewrite beq_symb_ok.
      intuition. subst. apply beq_vec_beq_impl_eq in H1. subst. refl.
      apply beq_symb_ok. Leqtac. refl. Leqtac. apply beq_vec_ok2.
      apply beq_symb_ok. hyp.
    Qed.

    Definition pi := mk.

  End SL.

  Definition Fs := Fs.
  Definition Fs_ok := Fs_ok.

  Definition Is := Fs.
  Definition Is_ok := Fs_ok.

End RootSemLab.

Module RootLabProps (Export R : RootLab).
  Module SL := RootSemLab R.
  Include (FinSemLabProps SL).
End RootLabProps.