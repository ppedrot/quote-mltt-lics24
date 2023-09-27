From LogRel.AutoSubst Require Import core unscoped Ast Extra.
From LogRel Require Import Utils BasicAst Notations Context Closed NormalForms NormalEq Weakening UntypedReduction
  DeclarativeTyping GenericTyping LogicalRelation Validity.
From LogRel.LogicalRelation Require Import Escape Reflexivity Neutral Weakening Irrelevance Application Reduction Transitivity NormalRed.
From LogRel.Substitution Require Import Irrelevance Properties SingleSubst.
From LogRel.Substitution.Introductions Require Import Universe Nat SimpleArr.

Set Universe Polymorphism.
Set Printing Primitive Projection Parameters.

Section QuoteValid.

Context `{GenericTypingProperties}.
Context {SN : SNTypingProperties ta _ _ _ _ _}.

Lemma nf_eval : forall {l Γ A t} {vA : [Γ ||-<l> A]}, [vA | Γ ||- t : A] ->
  ∑ r, [t ⇶* r] × dnf r × [Γ |- t ≅ r : A].
Proof.
intros l Γ A t vT vt.
destruct SN as [sn].
apply reflLRTmEq, escapeEqTerm, sn in vt.
destruct vt as (t₀&u₀&[]&[]&?&?&?).
exists t₀; try now prod_splitter.
Qed.

  Lemma QuoteRedEq : forall Γ l t t' (rΓ : [|- Γ]) (rNat := natRed rΓ),
    [Γ |- t : arr tNat tNat] ->
    [Γ |- t' : arr tNat tNat] ->
    [Γ ||-<l> t ≅ t' : arr tNat tNat | SimpleArr.ArrRedTy rNat rNat ] ->
    [Γ ||-<l> tQuote t ≅ tQuote t' : tNat | rNat ].
  Proof.
  intros * rt rt' re.
  assert [Γ |- t ≅ t' : arr tNat tNat] by now eapply escapeEqTerm.
  apply escapeEqTerm, snty_nf in re.
  destruct re as (l₀&r₀&[]&[]&?&?&?).
  remember (is_closedn 0 l₀) as b eqn:Hc; symmetry in Hc.
  assert (Hc' : is_closedn 0 r₀ = b).
  { erewrite eqnf_is_closedn; [tea|now apply Symmetric_eqnf]. }
  destruct b.
  - exists tZero tZero.
    + constructor; [gen_typing|].
      transitivity (tQuote l₀).
      * apply redtm_quote; tea.
      * apply redtm_eval; tea.
        now eapply urefl.
    + constructor; [gen_typing|].
      transitivity (tQuote r₀).
      * apply redtm_quote; tea.
      * apply redtm_eval; tea.
        now eapply urefl.
    + gen_typing.
    + constructor.
  - assert [Γ |-[ ta ] tQuote l₀ ~ tQuote r₀ : tNat].
    { apply convneu_quote; tea.
      + etransitivity; [now symmetry|].
        etransitivity; tea.
      + unfold closed0; destruct is_closedn; cbn; congruence.
      + unfold closed0; destruct is_closedn; cbn; congruence. }
    exists (tQuote l₀) (tQuote r₀).
    + constructor; [now eapply ty_quote, urefl|].
      apply redtm_quote; tea.
    + constructor; [now eapply ty_quote, urefl|].
      apply redtm_quote; tea.
    + apply convtm_convneu; tea.
    + constructor; constructor; tea.
  Qed.

  Context {Γ l t} (vΓ : [||-v Γ])
    (vNat := natValid (l := l) vΓ)
    (vArr := simpleArrValid vΓ vNat vNat)
    (vt : [ Γ ||-v< l > t : arr tNat tNat | vΓ | vArr ])
  .

  Lemma QuoteValid : [ Γ ||-v< l > tQuote t : tNat | vΓ | vNat ].
  Proof.
    econstructor.
    - intros Δ σ tΔ vσ; cbn in *.
      destruct vt as [vt0 vte].
      specialize (vt0 _ _ _ vσ).
      assert (Hv : [Δ |- t[σ] : arr tNat tNat]).
      { now eapply escapeTerm. }
      destruct (nf_eval vt0) as [r [Hdnf [Hr Hconv]]].
      assert ([Δ |- tQuote t[σ] ⤳* tQuote r : tNat]).
      { apply redtm_quote; tea. }
      assert [Δ |- r ≅ r : arr tNat tNat].
      { etransitivity; [symmetry|]; tea. }
      assert [Δ |- tQuote r : tNat ].
      { now apply ty_quote. }
      pose (c := is_closedn 0 r); assert (is_closedn 0 r = c) as Hc by reflexivity; destruct c.
      + exists tZero; [|gen_typing|constructor].
        constructor.
        { now apply ty_zero. }
        { transitivity (tQuote r); [tea|].
          now apply redtm_eval. }
      + assert (~ closed0 r).
        { unfold closed0; intros; destruct is_closedn; congruence. }
        exists (tQuote r).
        * split; [|tea].
          now apply ty_quote.
        * apply convtm_convneu, convneu_quote; tea.
        * apply NatRedTm.neR; constructor; tea.
          now apply convneu_quote.
  - intros Δ σ σ' tΔ vσ vσ' vσσ'; cbn.
    destruct vt as [vt0 vte].
    assert [Δ |- t[σ] : arr tNat tNat].
    { unshelve eapply escapeTerm, vt0; tea. }
    assert [Δ |- t[σ'] : arr tNat tNat].
    { unshelve eapply escapeTerm, vt0; tea. }
    unshelve eapply QuoteRedEq, LRTmEqIrrelevant', vte; cbn; tea.
    reflexivity.
  Qed.

Lemma evalValid : dnf t -> closed0 t ->
  [Γ ||-v<l> tQuote t ≅ tZero : tNat | vΓ | vNat].
Proof.
destruct SN as [sn].
econstructor.
intros Δ σ tΔ vσ.
destruct vt as [vt0 vte]; cbn.
assert (vtt0 := vt0 Δ σ tΔ vσ).
unshelve eassert (vte0 := vte Δ σ σ tΔ vσ vσ _).
{ apply reflSubst. }
apply escapeEqTerm, sn in vte0 as (t₀&u₀&[]&[]&?&?&?); cbn in *.
assert [Δ |-[ ta ] t[σ] : tProd tNat tNat].
{ eapply escapeTerm, vtt0. }
exists tZero tZero; cbn in *.
- constructor; [gen_typing|].
  transitivity (tQuote t₀).
  + apply redtm_quote; tea.
  + apply redtm_eval; tea.
    * now eapply urefl.
    * eapply dredalg_closed0; [tea|].
      now eapply closed0_subst.
- constructor; [gen_typing|].
  apply redtm_refl; gen_typing.
- gen_typing.
- constructor.
Qed.

End QuoteValid.

Section QuoteCongValid.

Context `{GenericTypingProperties}.
Context {SN : SNTypingProperties ta _ _ _ _ _}.

Context {Γ l t t'}
  (vΓ : [||-v Γ])
  (vNat := natValid (l := l) vΓ)
  (vArr := simpleArrValid vΓ vNat vNat)
  (vt : [Γ ||-v<l> t : arr tNat tNat | vΓ | vArr])
  (vt' : [Γ ||-v<l> t' : arr tNat tNat | vΓ | vArr])
.

Lemma QuoteCongValid :
  [Γ ||-v<l> t ≅ t' : arr tNat tNat | vΓ | vArr] ->
  [Γ ||-v<l> tQuote t ≅ tQuote t' : tNat | vΓ | vNat].
Proof.
intros [vte]; constructor.
intros Δ σ tΔ vσ; cbn.
assert [Δ |- t[σ] : arr tNat tNat].
{ unshelve eapply escapeTerm, vt; tea. }
assert [Δ |- t'[σ] : arr tNat tNat].
{ unshelve eapply escapeTerm, vt'; tea. }
unshelve eapply QuoteRedEq, LRTmEqIrrelevant', vte; cbn; tea.
reflexivity.
Qed.

End QuoteCongValid.
