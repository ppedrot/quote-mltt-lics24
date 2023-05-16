(** * LogRel.TypeConstructorsInj: injectivity and no-confusion of type constructors, and many consequences, including subject reduction. *)
From Coq Require Import CRelationClasses.
From LogRel.AutoSubst Require Import core unscoped Ast Extra.
From LogRel Require Import Utils BasicAst Notations Context NormalForms Weakening UntypedReduction
  GenericTyping DeclarativeTyping DeclarativeInstance AlgorithmicTyping.
From LogRel Require Import LogicalRelation Validity Fundamental DeclarativeSubst.
From LogRel.LogicalRelation Require Import Escape Irrelevance Neutral Induction NormalRed.
From LogRel.Substitution Require Import Escape Poly.

Set Printing Primitive Projection Parameters.

Import DeclarativeTypingProperties.


Section TypeConstructors.

  Definition type_hd_view (Γ : context) {T T' : term} (nfT : isType T) (nfT' : isType T') : Type :=
    match nfT, nfT' with
      | @UnivType s, @UnivType s' => s = s'
      | @ProdType A B, @ProdType A' B' => [Γ |- A' ≅ A] × [Γ,, A' |- B ≅ B']
      | NatType, NatType => True
      | EmptyType, EmptyType => True
      | NeType _, NeType _ => [Γ |- T ≅ T' : U]
      | @SigType A B, @SigType A' B' => [Γ |- A' ≅ A] × [Γ,, A' |- B ≅ B']
      | _, _ => False
    end.

  Lemma red_ty_complete : forall (Γ : context) (T T' : term),
    isType T ->
    [Γ |- T ≅ T'] ->
    ∑ T'', [Γ |- T' ⇒* T''] × isType T''.
  Proof.
    intros * tyT Hconv.
    eapply Fundamental in Hconv as [HΓ HT HT' Hconv].
    eapply reducibleTyEq in Hconv.
    set (HTred := reducibleTy _ HT) in *.
    clearbody HTred.
    clear HT.
    destruct HTred as [[] lr] ; cbn in *.
    destruct lr.
    - destruct Hconv as [[]].
      eexists ; split; tea.
      constructor.
    - destruct Hconv as [? red].
      eexists ; split.
      1: apply red.
      apply ty_ne_whne in ne.
      now constructor.
    - destruct Hconv as [?? red].
      eexists ; split.
      1: apply red.
      now constructor.
    - destruct Hconv as [red].
      eexists ; split.
      1: apply red.
      now constructor.
    - destruct Hconv as [red].
      eexists ; split.
      1: apply red.
      now constructor.
    - destruct Hconv as [?? red].
      eexists; split.
      1: apply red.
      now constructor.
  Qed.

  Lemma ty_conv_inj : forall (Γ : context) (T T' : term) (nfT : isType T) (nfT' : isType T'),
    [Γ |- T ≅ T'] ->
    type_hd_view Γ nfT nfT'.
  Proof.
    intros * Hconv.
    eapply Fundamental in Hconv as [HΓ HT HT' Hconv].
    eapply reducibleTyEq in Hconv.
    set (HTred := reducibleTy _ HT) in *.
    clearbody HTred.
    clear HT.
    eapply reducibleTy in HT'.
    destruct HTred as [[] lrT].
    cbn in *.
    inversion lrT ; subst ; clear lrT.
    - subst.
      destruct Hconv as [].
      assert (T' = U) as HeqT' by (eapply redtywf_whnf ; gen_typing); subst.
      destruct H.
      assert (T = U) as HeqU by (eapply redtywf_whnf ; gen_typing). 
      destruct nfT ; inversion HeqU ; subst.
      2: now exfalso ; gen_typing.
      clear HeqU.
      remember U as T eqn:HeqU in nfT' |- * at 2.
      destruct nfT' ; inversion HeqU ; subst.
      2: now exfalso ; gen_typing.
      now reflexivity.
    - destruct neA as [nT ? ne], Hconv as [nT' ? ne'] ; cbn in *.
      assert (T = nT) as <- by
        (apply red_whnf ; gen_typing).
      assert (T' = nT') as <- by
        (apply red_whnf ; gen_typing).
      destruct nfT.
      + apply ty_ne_whne in ne, ne'; exfalso ; gen_typing.
      + apply ty_ne_whne in ne, ne'; exfalso ; gen_typing.
      + apply ty_ne_whne in ne, ne'; inversion ne.
      + apply ty_ne_whne in ne, ne'; inversion ne.
      + apply ty_ne_whne in ne, ne'; inversion ne.
      + destruct nfT'.
        * apply ty_ne_whne in ne, ne'; exfalso ; gen_typing.
        * apply ty_ne_whne in ne, ne'; exfalso ; gen_typing.
        * apply ty_ne_whne in ne, ne'; inversion ne'.
        * apply ty_ne_whne in ne, ne'; inversion ne'.
        * apply ty_ne_whne in ne, ne'; inversion ne'; gen_typing.
        * apply ty_ne_whne in ne, ne'. cbn. gen_typing.
    - assert [|- Γ] by (apply escape in HT' ; boundary).
      rewrite <- (ParamRedTy.beta_pack ΠAad) in *.
      remember (ParamRedTy.from ΠAad) as ΠA' eqn:Heq in *.
      clear ΠA ΠAad Heq.
      destruct ΠA' as [dom cod red], Hconv as [dom' cod' red'] ; cbn in *.
      assert (T = tProd dom cod) as HeqT by (apply red_whnf ; gen_typing). 
      assert (T' = tProd dom' cod') as HeqT' by (apply red_whnf ; gen_typing).
      destruct nfT.
      1,3,4,5: congruence.
      2: subst ; exfalso ; gen_typing.
      destruct nfT'.
      1,3,4,5: congruence.
      2: subst ; exfalso ; gen_typing.
      inversion HeqT ; inversion HeqT' ; subst ; clear HeqT HeqT'.
      cbn.
      destruct (polyRedEqId (normRedΠ0 (invLRΠ HT')) (PolyRedEqSym _ polyRed0)).
      split; now escape.
    - destruct Hconv.
      assert (T' = tNat) as HeqT' by (eapply redtywf_whnf ; gen_typing).
      assert (T = tNat) as HeqT by (destruct NA; eapply redtywf_whnf ; gen_typing).
      destruct nfT; inversion HeqT.
      + destruct nfT'; inversion HeqT'.
        * constructor.
        * exfalso; subst; inversion w.
      + exfalso; subst; inversion w.
    - destruct Hconv.
      assert (T' = tEmpty) as HeqT' by (eapply redtywf_whnf ; gen_typing).
      assert (T = tEmpty) as HeqT by (destruct NA; eapply redtywf_whnf ; gen_typing).
      destruct nfT; inversion HeqT.
      + destruct nfT'; inversion HeqT'.
        * econstructor.
        * exfalso; subst; inversion w.
      + exfalso; subst; inversion w.
    - assert [|- Γ] by (apply escape in HT' ; boundary).
      rewrite <- (ParamRedTy.beta_pack ΣAad) in *.
      remember (ParamRedTy.from ΣAad) as ΣA' eqn:Heq in *.
      clear ΣA ΣAad Heq.
      destruct ΣA' as [dom cod red], Hconv as [dom' cod' red'] ; cbn in *.
      assert (T = tSig dom cod) as HeqT by (apply red_whnf ; gen_typing). 
      assert (T' = tSig dom' cod') as HeqT' by (apply red_whnf ; gen_typing).
      destruct nfT.
      1-4: congruence.
      2: subst; inv_whne.
      destruct nfT'.
      1-4: congruence.
      2: subst ; inv_whne.
      inversion HeqT ; inversion HeqT' ; subst ; clear HeqT HeqT'.
      cbn.
      destruct (polyRedEqId (normRedΣ0 (invLRΣ HT')) (PolyRedEqSym _ polyRed0)).
      split; now escape.
  Qed.

  Corollary red_ty_compl_univ_l Γ T :
    [Γ |- U ≅ T] ->
    [Γ |- T ⇒* U].
  Proof.
    intros HT.
    pose proof HT as HT'.
    unshelve eapply red_ty_complete in HT' as (T''&[? nfT]).
    2: econstructor.
    enough (T'' = U) as -> by easy.
    assert [Γ |- U ≅ T''] as Hconv by
      (etransitivity ; [eassumption|now eapply RedConvTyC]).
    unshelve eapply ty_conv_inj in Hconv.
    1: econstructor.
    1: eassumption.
    now destruct nfT, Hconv.
  Qed.

  Corollary red_ty_compl_univ_r Γ T :
    [Γ |- T ≅ U] ->
    [Γ |- T ⇒* U].
  Proof.
    intros.
    eapply red_ty_compl_univ_l.
    now symmetry.
  Qed.

  Corollary red_ty_compl_nat_l Γ T :
    [Γ |- tNat ≅ T] ->
    [Γ |- T ⇒* tNat].
  Proof.
    intros HT.
    pose proof HT as HT'.
    unshelve eapply red_ty_complete in HT' as (T''&[? nfT]).
    2: econstructor.
    enough (T'' = tNat) as -> by easy.
    assert [Γ |- tNat ≅ T''] as Hconv by
      (etransitivity ; [eassumption|now eapply RedConvTyC]).
    unshelve eapply ty_conv_inj in Hconv.
    1: econstructor.
    1: eassumption.
    now destruct nfT, Hconv.
  Qed.

  Corollary red_ty_compl_nat_r Γ T :
    [Γ |- T ≅ tNat] ->
    [Γ |- T ⇒* tNat].
  Proof.
    intros.
    eapply red_ty_compl_nat_l.
    now symmetry.
  Qed.

  Corollary red_ty_compl_empty_l Γ T :
    [Γ |- tEmpty ≅ T] ->
    [Γ |- T ⇒* tEmpty].
  Proof.
    intros HT.
    pose proof HT as HT'.
    unshelve eapply red_ty_complete in HT' as (T''&[? nfT]).
    2: econstructor.
    enough (T'' = tEmpty) as -> by easy.
    assert [Γ |- tEmpty ≅ T''] as Hconv by
      (etransitivity ; [eassumption|now eapply RedConvTyC]).
    unshelve eapply ty_conv_inj in Hconv.
    1: econstructor.
    1: eassumption.
    now destruct nfT, Hconv.
  Qed.

  Corollary red_ty_compl_empty_r Γ T :
    [Γ |- T ≅ tEmpty] ->
    [Γ |- T ⇒* tEmpty].
  Proof.
    intros.
    eapply red_ty_compl_empty_l.
    now symmetry.
  Qed.

  Corollary red_ty_compl_prod_l Γ A B T :
    [Γ |- tProd A B ≅ T] ->
    ∑ A' B', [× [Γ |- T ⇒* tProd A' B'], [Γ |- A' ≅ A] & [Γ,, A' |- B ≅ B']].
  Proof.
    intros HT.
    pose proof HT as HT'.
    unshelve eapply red_ty_complete in HT as (T''&[? nfT]).
    2: econstructor.
    assert [Γ |- tProd A B ≅ T''] as Hconv by 
      (etransitivity ; [eassumption|now eapply RedConvTyC]).
    unshelve eapply ty_conv_inj in Hconv.
    1: constructor.
    1: assumption.
    destruct nfT, Hconv.
    do 2 eexists ; split.
    all: eassumption.
  Qed.

  Corollary prod_ty_inj Γ A B  A' B' :
    [Γ |- tProd A B ≅ tProd A' B'] ->
    [Γ |- A' ≅ A] × [Γ,, A' |- B ≅ B'].
  Proof.
    intros Hty.
    unshelve eapply ty_conv_inj in Hty.
    1-2: constructor.
    now eassumption.
  Qed.

  Corollary red_ty_compl_sig_l Γ A B T :
    [Γ |- tSig A B ≅ T] ->
    ∑ A' B', [× [Γ |- T ⇒* tSig A' B'], [Γ |- A' ≅ A] & [Γ,, A' |- B ≅ B']].
  Proof.
    intros HT.
    pose proof HT as HT'.
    unshelve eapply red_ty_complete in HT as (T''&[? nfT]).
    2: econstructor.
    assert [Γ |- tSig A B ≅ T''] as Hconv by 
      (etransitivity ; [eassumption|now eapply RedConvTyC]).
    unshelve eapply ty_conv_inj in Hconv.
    1: constructor.
    1: assumption.
    destruct nfT, Hconv.
    do 2 eexists ; split.
    all: eassumption.
  Qed.
  
  Corollary red_ty_compl_sig_r Γ A B T :
    [Γ |- T ≅ tSig A B] ->
    ∑ A' B', [× [Γ |- T ⇒* tSig A' B'], [Γ |- A' ≅ A] & [Γ,, A' |- B ≅ B']].
  Proof.
    intros; eapply red_ty_compl_sig_l; now symmetry.
  Qed.

  Corollary sig_ty_inj Γ A B  A' B' :
    [Γ |- tSig A B ≅ tSig A' B'] ->
    [Γ |- A' ≅ A] × [Γ,, A' |- B ≅ B'].
  Proof.
    intros Hty.
    unshelve eapply ty_conv_inj in Hty.
    1-2: constructor.
    now eassumption.
  Qed.

End TypeConstructors.

Section Boundary.

  Lemma in_ctx_wf Γ n decl :
    [|- Γ] ->
    in_ctx Γ n decl ->
    [Γ |- decl].
  Proof.
    intros HΓ Hin.
    induction Hin.
    - inversion HΓ ; subst ; cbn in * ; refold.
      renToWk.
      now apply typing_wk.
    - inversion HΓ ; subst ; cbn in * ; refold.
      renToWk.
      now eapply typing_wk.
  Qed.

  Let PCon (Γ : context) := True.
  Let PTy (Γ : context) (A : term) := True.
  Let PTm (Γ : context) (A t : term) := [Γ |- A].
  Let PTyEq (Γ : context) (A B : term) := [Γ |- A] × [Γ |- B].
  Let PTmEq (Γ : context) (A t u : term) := [× [Γ |- A], [Γ |- t : A] & [Γ |- u : A]].

  Lemma boundary : WfDeclInductionConcl PCon PTy PTm PTyEq PTmEq.
  Proof.
    subst PCon PTy PTm PTyEq PTmEq.
    apply WfDeclInduction.
    all: try easy.
    - intros.
      now eapply in_ctx_wf.
    - intros.
      now econstructor.
    - intros.
      now eapply typing_subst1, prod_ty_inv.
    - intros; gen_typing.
    - intros; gen_typing.
    - intros.
      now eapply typing_subst1.
    - intros; gen_typing.
    - intros.
      now eapply typing_subst1.
    - intros; gen_typing.
    - intros. now eapply sig_ty_inv.
    - intros.
      eapply typing_subst1.
      + now econstructor.
      + now eapply sig_ty_inv.
    - intros * ? _ ? [] ? [].
      split.
      all: constructor ; tea.
      eapply stability1.
      3: now symmetry.
      all: eassumption.
    - intros * ? _ ? [] ? []; split.
      1: gen_typing.
      constructor; tea.
      eapply stability1. 
      3: now symmetry.
      all: tea.
    - intros * ? [].
      split.
      all: now econstructor.
    - intros.
      split.
      + now eapply typing_subst1.
      + econstructor ; tea.
        now econstructor.
      + now eapply typing_subst1.
    - intros * ? _ ? [] ? [].
      split.
      + easy.
      + now econstructor.
      + econstructor ; tea.
        eapply stability1.
        4: eassumption.
        all: econstructor ; tea.
        now symmetry.
    - intros * ? [] ? [].
      split.
      + eapply typing_subst1.
        1: eassumption.
        now eapply prod_ty_inv.
      + now econstructor.
      + econstructor.
        1: now econstructor.
        eapply typing_subst1.
        1: now symmetry.
        econstructor.
        now eapply prod_ty_inv.
    - intros * ? []; split; gen_typing.
    - intros * ? [] ? [] ? [] ? []; split.
      + now eapply typing_subst1.
      + gen_typing.
      + eapply ty_conv.
        assert [Γ |-[de] tNat ≅ tNat] by now constructor.
        1: eapply ty_natElim; tea; eapply ty_conv; tea. 
        * eapply typing_subst1; tea; do 2 constructor; boundary.
        * eapply elimSuccHypTy_conv ; tea.
          now boundary.
        * symmetry; now eapply typing_subst1.
    - intros **; split; tea.
      eapply ty_natElim; tea; constructor; boundary.   
    - intros **.
      assert [Γ |- tSucc n : tNat] by now constructor.
      assert [Γ |- P[(tSucc n)..]] by now eapply typing_subst1.
      split; tea.
      2: eapply ty_simple_app.
      1,5: now eapply ty_natElim.
      2: tea.
      1: now eapply typing_subst1.
      replace (arr _ _) with (arr P P[tSucc (tRel 0)]⇑)[n..] by now bsimpl.
      eapply ty_app; tea.
    - intros * ? [] ? []; split.
      + now eapply typing_subst1.
      + gen_typing.
      + eapply ty_conv.
        assert [Γ |-[de] tEmpty ≅ tEmpty] by now constructor.
        1: eapply ty_emptyElim; tea; eapply ty_conv; tea. 
        * symmetry; now eapply typing_subst1.
    - intros * ??? [] ? []; split; tea.
      1: gen_typing.
      constructor; tea.
      eapply stability1.
      3: symmetry; gen_typing.
      all: gen_typing.
    - intros * ? []; split; tea.
      1: now eapply sig_ty_inv.
      all: gen_typing.
    - intros * ? _ ? _ ????; split; tea.
      now do 2 econstructor.
    - intros * ? []; split; tea.
      1: eapply typing_subst1; [gen_typing| now eapply sig_ty_inv].
      1: gen_typing.
      econstructor. 1: now econstructor.
      symmetry; eapply typing_subst1.
      1: now eapply TermFstCong.
      econstructor; now eapply sig_ty_inv.
    - intros * ? _ ? _ ????.
      assert [Γ |- tFst (tPair A B a b) : A] by now do 2 econstructor.
      assert [Γ |- tFst (tPair A B a b) ≅ a : A] by now econstructor.
      split.
      + eapply typing_subst1; tea.
      + now do 2 econstructor.
      + econstructor; tea.
        symmetry; eapply typing_subst1; tea.
        now econstructor.
    - intros * ? [] ? [].
      split ; gen_typing.
    - intros * ? [].
      split; gen_typing.
    - intros * ?[]?[].
      split; gen_typing.
  Qed.

End Boundary.

Corollary boundary_tm Γ A t : [Γ |- t : A] -> [Γ |- A].
Proof.
  now intros ?%boundary.
Qed.

Corollary boundary_ty_conv_l Γ A B : [Γ |- A ≅ B] -> [Γ |- A].
Proof.
  now intros ?%boundary.
Qed.

Corollary boundary_ty_conv_r Γ A B : [Γ |- A ≅ B] -> [Γ |- B].
Proof.
  now intros ?%boundary.
Qed.

Corollary boundary_red_ty_r Γ A B : [Γ |- A ⇒* B] -> [Γ |- B].
Proof.
  now intros ?%RedConvTyC%boundary.
Qed.

Corollary boundary_tm_conv_l Γ A t u : [Γ |- t ≅ u : A] -> [Γ |- t : A].
Proof.
  now intros []%boundary.
Qed.

Corollary boundary_tm_conv_r Γ A t u : [Γ |- t ≅ u : A] -> [Γ |- u : A].
Proof.
  now intros []%boundary.
Qed.

Corollary boundary_tm_conv_ty Γ A t u : [Γ |- t ≅ u : A] -> [Γ |- A].
Proof.
  now intros []%boundary.
Qed.

Corollary boundary_red_tm_r Γ A t u : [Γ |- t ⇒* u : A] -> [Γ |- u : A].
Proof.
  now intros []%RedConvTeC%boundary.
Qed.

Corollary boundary_red_tm_ty Γ A t u : [Γ |- t ⇒* u : A] -> [Γ |- A].
Proof.
  now intros []%RedConvTeC%boundary.
Qed.

#[export] Hint Resolve
  boundary_tm boundary_ty_conv_l boundary_ty_conv_r
  boundary_tm_conv_l boundary_tm_conv_r boundary_tm_conv_ty
  boundary_red_tm_l boundary_red_tm_r boundary_red_tm_ty
  boundary_red_ty_r : boundary.

Lemma boundary_ctx_conv_l (Γ Δ : context) :
  [ |- Γ ≅ Δ] ->
  [|- Γ].
Proof.
  destruct 1.
  all: econstructor ; boundary.
Qed.

#[export] Hint Resolve boundary_ctx_conv_l : boundary.

Corollary conv_ctx_refl_l (Γ Δ : context) :
[ |- Γ ≅ Δ] ->
[|- Γ ≅ Γ].
Proof.
  intros.
  eapply ctx_refl ; boundary.
Qed.

Lemma typing_eta' (Γ : context) A B f :
  [Γ |- f : tProd A B] ->
  [Γ,, A |- eta_expand f : B].
Proof.
  intros Hf.
  eapply typing_eta ; tea.
  - eapply prod_ty_inv.
    boundary.
  - eapply prod_ty_inv.
    boundary.
Qed.

Corollary red_ty_compl_prod_r Γ A B T :
  [Γ |- T ≅ tProd A B] ->
  ∑ A' B', [× [Γ |- T ⇒* tProd A' B'], [Γ |- A ≅ A'] & [Γ,, A |- B' ≅ B]].
Proof.
  intros HT.
  symmetry in HT.
  eapply red_ty_compl_prod_l in HT as (?&?&[HA ? HB]).
  do 2 eexists ; split ; tea.
  1: now symmetry.
  symmetry.
  eapply stability1 ; tea.
  1-2: now boundary.
  now symmetry.
Qed.

Section Stability.

  Lemma conv_well_subst (Γ Δ : context) :
    [ |- Γ ≅ Δ] ->
    [Γ |-s tRel : Δ].
  Proof.
    induction 1 as [| * ? HA].
    - now econstructor.
    - assert [Γ |- A] by boundary.
      assert [|- Γ,, A] by
        (econstructor ; boundary).
      econstructor ; tea.
      + eapply well_subst_ext, well_subst_up ; tea.
        reflexivity.
      + eapply wfTermConv.
        1: econstructor; [gen_typing| now econstructor].
        rewrite <- rinstInst'_term; do 2 erewrite <- wk1_ren_on.
        now eapply typing_wk.
  Qed.

  Let PCon (Γ : context) := True.
  Let PTy (Γ : context) (A : term) := forall Δ,
    [|- Δ ≅ Γ] -> [Δ |- A].
  Let PTm (Γ : context) (A t : term) := forall Δ,
    [|- Δ ≅ Γ] -> [Δ |- t : A].
  Let PTyEq (Γ : context) (A B : term) := forall Δ,
    [|- Δ ≅ Γ] -> [Δ |- A ≅ B].
  Let PTmEq (Γ : context) (A t u : term) := forall Δ,
    [|- Δ ≅ Γ] -> [Δ |- t ≅ u : A].

  Theorem stability : WfDeclInductionConcl PCon PTy PTm PTyEq PTmEq.
  Proof.
    red.
    repeat match goal with |- _ × _ => split end.
    1: now unfold PCon.
    all: intros * Hty Δ HΔ.
    all: pose proof (boundary_ctx_conv_l _ _ HΔ).
    all: eapply conv_well_subst in HΔ.
    all: pose proof (subst_refl _ _ _ HΔ).
    all: eapply typing_subst in Hty ; tea.
    all: asimpl ; repeat (rewrite idSubst_term in Hty ; [..|reflexivity]).
    all: try eassumption.
  Qed.


  #[global] Instance ConvCtxSym : Symmetric ConvCtx.
  Proof.
    intros Γ Δ.
    induction 1.
    all: constructor ; tea.
    eapply stability ; tea.
    now symmetry.
  Qed.

  Corollary conv_ctx_refl_r (Γ Δ : context) :
    [ |- Γ ≅ Δ] ->
    [|- Δ ≅ Δ].
  Proof.
    intros H.
    symmetry in H.
    now eapply ctx_refl ; boundary.
  Qed.

  #[global] Instance ConvCtxTrans : Transitive ConvCtx.
  Proof.
    intros Γ1 Γ2 Γ3 H1 H2.
    induction H1 in Γ3, H2 |- *.
    all: inversion H2 ; subst ; clear H2.
    all: constructor.
    1: eauto.
    etransitivity ; tea.
    now eapply stability.
  Qed.

End Stability.

Lemma termGen' Γ t A :
[Γ |- t : A] ->
∑ A', (termGenData Γ t A') × [Γ |- A' ≅ A].
Proof.
intros * H.
destruct (termGen _ _ _ H) as [? [? [->|]]].
2: now eexists.
eexists ; split ; tea.
econstructor.
boundary.
Qed.

Theorem subject_reduction_one Γ A t t' :
    [Γ |- t : A] ->
    [t ⇒ t'] ->
    [Γ |- t ≅ t' : A].
Proof.
  intros Hty Hred.
  induction Hred in Hty, A |- *.
  - apply termGen' in Hty as (?&((?&?&[-> Hty])&Heq)).
    apply termGen' in Hty as (?&((?&[->])&Heq')).
    eapply prod_ty_inj in Heq' as [? HeqB].
    econstructor.
    1: econstructor ; gen_typing.
    etransitivity ; tea.
    eapply typing_subst1 ; tea.
    now econstructor.
  - apply termGen' in Hty as (?&((?&?&[->])&Heq)).
    econstructor ; tea.
    econstructor.
    + now eapply IHHred.
    + now econstructor.
  - apply termGen' in Hty as [?[[->]?]].
    econstructor; tea.
    econstructor.
    1-3: now econstructor.
    now eapply IHHred.
  - apply termGen' in Hty as [?[[->]?]].
    now do 2 econstructor.
  - apply termGen' in Hty as [?[[-> ???(?&[->]&?)%termGen']?]].
    now do 2 econstructor.
  - apply termGen' in Hty as [?[[->]?]].
    econstructor ; tea.
    econstructor.
    1: now econstructor.
    now eapply IHHred.
  - apply termGen' in Hty as [? [[?[?[->]]]]].
    eapply TermConv; tea ; refold.
    now econstructor.
  - apply termGen' in Hty as [?[[?[?[-> h]]]]].
    apply termGen' in h as [?[[->] u]].
    destruct (sig_ty_inj _ _ _ _ _ u).
    eapply TermConv; refold.
    2: etransitivity;[|tea]; now symmetry.
    econstructor; tea.
  - apply termGen' in Hty as [? [[?[?[->]]]]].
    eapply TermConv; tea ; refold.
    now econstructor.
  - apply termGen' in Hty as [?[[?[?[-> h]]]]].
    apply termGen' in h as [?[[->] u]].
    destruct (sig_ty_inj _ _ _ _ _ u).
    assert [Γ |- B[(tFst (tPair A0 B a b))..] ≅ A].
    1:{ etransitivity; tea. eapply typing_subst1; tea.
      eapply TermConv; refold. 2: now symmetry.
      eapply TermRefl; refold; gen_typing.
    }
    eapply TermConv; tea; refold.
    now econstructor.
  Qed.


  Theorem subject_reduction_one_type Γ A A' :
  [Γ |- A] ->
  [A ⇒ A'] ->
  [Γ |- A ≅ A'].
Proof.
  intros Hty Hred.
  destruct Hred.
  all: inversion Hty ; subst ; clear Hty ; refold.
  all: econstructor.
  all: eapply subject_reduction_one ; tea.
  all: now econstructor.
Qed.

Theorem subject_reduction Γ t t' A :
  [Γ |- t : A] ->
  [t ⇒* t'] ->
  [Γ |- t ⇒* t' : A].
Proof.
  intros Hty Hr; split ; refold.
  - assumption.
  - assumption.
  - induction Hr.
    + now constructor.
    + eapply subject_reduction_one in o ; tea.
      etransitivity ; tea.
      eapply IHHr.
      now boundary.
Qed.

Theorem subject_reduction_type Γ A A' :
[Γ |- A] ->
[A ⇒* A'] ->
[Γ |- A ⇒* A'].
Proof.
  intros Hty Hr; split; refold.
  - assumption.
  - assumption.
  - induction Hr.
    + now constructor.
    + eapply subject_reduction_one_type in o ; tea.
      etransitivity ; tea.
      eapply IHHr.
      now boundary.
Qed.

Corollary conv_red_l Γ A A' A'' : [Γ |-[de] A' ≅ A''] -> [A' ⇒* A] -> [Γ |-[de] A ≅ A''].
Proof.
  intros Hconv **.
  etransitivity ; tea.
  symmetry.
  eapply RedConvTyC, subject_reduction_type ; tea.
  boundary.
Qed.

Lemma Uterm_isType Γ A :
  [Γ |-[de] A : U] ->
  whnf A ->
  isType A.
Proof.
  intros Hty Hwh.
  destruct Hwh.
  all: try solve [now econstructor].
  all: exfalso.
  all: eapply termGen' in Hty ; cbn in *.
  all: prod_hyp_splitter ; try easy.
  all: subst.
  all:
    match goal with
      H : [_ |-[de] _ ≅ U] |- _ => unshelve eapply ty_conv_inj in H as Hconv
    end.
  all: try now econstructor.
  all: try now cbn in Hconv.
Qed.
  
Lemma type_isType Γ A :
  [Γ |-[de] A] ->
  whnf A ->
  isType A.
Proof.
  intros [] ; refold.
  1-5: econstructor.
  intros.
  now eapply Uterm_isType.
Qed.

Lemma fun_isFun Γ A B t:
  [Γ |-[de] t : tProd A B] ->
  whnf t ->
  isFun t.
Proof.
  intros Hty Hwh.
  destruct Hwh.
  all: try now econstructor.
  all: eapply termGen' in Hty ; cbn in *.
  all: exfalso.
  all: prod_hyp_splitter ; try easy.
  all: subst.
  all:
    match goal with
      H : [_ |-[de] _ ≅ tProd _ _] |- _ => unshelve eapply ty_conv_inj in H as Hconv
    end.
  all: try now econstructor.
  all: now cbn in Hconv.
Qed.

Lemma nat_isNat Γ t:
  [Γ |-[de] t : tNat] ->
  whnf t ->
  isNat t.
Proof.
  intros Hty Hwh.
  destruct Hwh.
  all: try now econstructor.
  all: eapply termGen' in Hty ; cbn in *.
  all: exfalso.
  all: prod_hyp_splitter ; try easy.
  all: subst.
  all:
    match goal with
      H : [_ |-[de] _ ≅ tNat] |- _ => unshelve eapply ty_conv_inj in H as Hconv
    end.
  all: try now econstructor.
  all: now cbn in Hconv.
Qed.

Lemma empty_isEmpty Γ t:
  [Γ |-[de] t : tEmpty] ->
  whnf t ->
  whne t.
Proof.
  intros Hty Hwh.
  destruct Hwh ; try easy.
  all: eapply termGen' in Hty ; cbn in *.
  all: exfalso.
  all: prod_hyp_splitter ; try easy.
  all: subst.
  all:
    match goal with
      H : [_ |-[de] _ ≅ tEmpty] |- _ => unshelve eapply ty_conv_inj in H as Hconv
    end.
  all: try now econstructor.
  all: now cbn in Hconv.
Qed.

Lemma neutral_isNeutral Γ A t :
  [Γ |-[de] t : A] ->
  whne A ->
  whnf t ->
  whne t.
Proof.
  intros (?&Hgen&Hconv)%termGen' HwA Hwh.
  set (iA := NeType HwA).
  destruct Hwh ; cbn in * ; try easy.
  all: exfalso.
  all: prod_hyp_splitter.
  all: subst.
  all: unshelve eapply ty_conv_inj in Hconv ; tea.
  all: try now econstructor.
  all: now cbn in Hconv.
Qed.