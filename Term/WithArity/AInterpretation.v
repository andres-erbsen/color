(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Sebastien Hinderer, 2004-02-09

interpretation of algebraic terms with arity
*)

(* $Id: AInterpretation.v,v 1.10 2008-05-14 14:30:54 blanqui Exp $ *)

Set Implicit Arguments.

Section S.

Require Export ASignature.

Variable Sig : Signature.

Require Export ATerm.

Notation term := (term Sig).
Notation terms := (vector term).

(***********************************************************************)
(** interpretation of symbols *)

Require Export NaryFunction.

Record interpretation : Type := mkInterpretation {
  domain :> Set;
  some_elt : domain;
  fint : forall f : Sig, naryFunction domain (arity f)
}.

Variable I : interpretation.

Notation D := (domain I).

(***********************************************************************)
(** valuations *)

Definition valuation := variable -> D.

Fixpoint vec_of_val (xint : valuation) (n : nat) : vector D n :=
  match n as n0 return vector _ n0 with
    | O => Vnil
    | S p => Vadd (vec_of_val xint p) (xint p)
  end.

Lemma vec_of_val_eq : forall xint n x (H : lt x n),
  Vnth (vec_of_val xint n) H = xint x.

Proof.
intros xint n. elim n.
 intros x Hx. elimtype False. apply (lt_n_O _ Hx).
 intros p Hrec x H0. simpl vec_of_val.
 case (le_lt_eq_dec _ _ (le_S_n _ _ H0)); intro H1.
  rewrite (Vnth_addl (vec_of_val xint p) (xint p) H0 H1). apply Hrec.
  rewrite Vnth_addr. 2: assumption. rewrite H1. refl.
Qed.

Definition val_of_vec n (v : vector D n) : valuation :=
  fun x => match le_lt_dec n x with
    | left _ => (* n <= x *) some_elt I
    | right h => (* x < n *) Vnth v h
  end.

Definition fval (xint : valuation) n := val_of_vec (vec_of_val xint n).

Definition restrict (xint : valuation) (n : nat) : valuation :=
  fun x => match le_lt_dec n x with
    | left _ => (* n <= x *) some_elt I
    | right h => (* x < n *) xint x
  end.

(***********************************************************************)
(** interpretation of terms *)

Section term_int.

Variable xint : valuation.

Fixpoint term_int (t : term) : D :=
  match t with
    | Var x => xint x
    | Fun f ts =>
      let fix terms_int n (ts : terms n) {struct ts} : vector D n :=
        match ts in vector _ n return vector D n with
          | Vnil => Vnil
          | Vcons t' n' ts' => Vcons (term_int t') (terms_int n' ts')
        end
      in fint I f (terms_int (arity f) ts)
  end.

Lemma term_int_fun : forall f ts,
  term_int (Fun f ts) = fint I f (Vmap term_int ts).

Proof.
intros. simpl. apply (f_equal (fint I f)). induction ts. auto.
rewrite IHts. auto.
Qed.

End term_int.

Lemma term_int_eq : forall xint1 xint2 t,
  (forall x, In x (vars t) -> xint1 x = xint2 x) ->
  term_int xint1 t = term_int xint2 t.

Proof.
intros xint1 xint2 t. pattern t; apply term_ind_forall; clear t; intros.
simpl. apply H. simpl. intuition.
repeat rewrite term_int_fun. apply (f_equal (fint I f)). apply Vmap_eq.
apply Vforall_intro. intros. apply (Vforall_in H H1). intros. apply H0.
rewrite vars_fun. apply (vars_vec_in H2 H1).
Qed.

Lemma term_int_eq_restrict_lt : forall xint t k,
  maxvar t < k -> term_int xint t = term_int (restrict xint k) t.

Proof.
intros xint t. pattern t; apply term_ind_forall; clear t; intros.
simpl. unfold restrict. case (le_lt_dec k v); intro.
simpl in H. absurd (v<k); omega. refl.
repeat rewrite term_int_fun. apply (f_equal (fint I f)).
apply Vmap_eq. apply Vforall_intro. intros. apply (Vforall_in H H1).
rewrite maxvar_fun in H0. ded (Vin_map_intro (maxvar (Sig:=Sig)) H1).
ded (Vmax_in H2). omega.
Qed.

Lemma term_int_eq_restrict : forall xint t,
  term_int xint t = term_int (restrict xint (maxvar t + 1)) t.

Proof.
intros. apply term_int_eq_restrict_lt. omega.
Qed.

Lemma term_int_eq_fval_lt : forall xint t k,
  maxvar t < k -> term_int xint t = term_int (fval xint k) t.

Proof.
intros xint t. pattern t; apply term_ind_forall; clear t; intros.
simpl in *. unfold fval, val_of_vec. case (le_lt_dec k v); intro.
absurd (v<k); omega. symmetry. apply vec_of_val_eq.
repeat rewrite term_int_fun. apply (f_equal (fint I f)).
apply Vmap_eq. apply Vforall_intro. intros. apply (Vforall_in H H1).
rewrite maxvar_fun in H0. ded (Vin_map_intro (maxvar (Sig:=Sig)) H1).
ded (Vmax_in H2). omega.
Qed.

Lemma term_int_eq_fval : forall xint t,
  term_int xint t = term_int (fval xint (maxvar t + 1)) t.

Proof.
intros. apply term_int_eq_fval_lt. omega.
Qed.

End S.

Implicit Arguments mkInterpretation [Sig domain].
