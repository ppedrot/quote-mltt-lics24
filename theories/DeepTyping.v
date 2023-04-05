(** * LogRel.DeclarativeInstance: proof that declarative typing is an instance of generic typing. *)
From Coq Require Import CRelationClasses.
From LogRel.AutoSubst Require Import core unscoped Ast Extra.
From LogRel Require Import Utils BasicAst Notations Context NormalForms UntypedReduction Weakening GenericTyping DeclarativeTyping DeclarativeInstance.

Import DeclarativeTypingData.

Record NfTypeDecl Γ (A A₀ : term) := {
  nftydecl_red : [A ⇶* A₀];
  nftydecl_nf : dnf A₀;
  nftydecl_conv : [Γ |- A ≅ A₀];
}.

Record NfTermDecl Γ (A t t₀ : term) := {
  nftmdecl_red : [t ⇶* t₀];
  nftmdecl_nf : dnf t₀;
  nftmdecl_conv : [Γ |- t ≅ t₀ : A];
}.

Record NeTermDecl Γ (A t t₀ : term) := {
  netmdecl_whne : whne t;
  netmdecl_nf : NfTermDecl Γ A t t₀;
}.

Record ConvTypeNfDecl Γ A B := {
  nfconvty_lhs : term;
  nfconvty_rhs : term;
  nfconvty_conv : [Γ |- A ≅ B];
  nfconvty_nfl : NfTypeDecl Γ A nfconvty_lhs;
  nfconvty_nfr : NfTypeDecl Γ B nfconvty_rhs;
}.

Record ConvTermNfDecl Γ A t u := {
  nfconvtm_lhs : term;
  nfconvtm_rhs : term;
  nfconvtm_conv : [Γ |- t ≅ u : A];
  nfconvtm_nfl : NfTermDecl Γ A t nfconvtm_lhs;
  nfconvtm_nfr : NfTermDecl Γ A u nfconvtm_rhs;
}.

Record ConvTermNeDecl Γ A t u := {
  neconvtm_lhs : term;
  neconvtm_rhs : term;
  neconvtm_conv : [Γ |- t ~ u : A];
  neconvtm_nfl : NeTermDecl Γ A t neconvtm_lhs;
  neconvtm_nfr : NeTermDecl Γ A u neconvtm_rhs;
}.

Section Nf.

Import DeclarativeTypingProperties.

#[local]
Lemma ConvTypeNf_PER : forall Γ, PER (ConvTypeNfDecl Γ).
Proof.
intros Γ; split.
- intros t u []; esplit; tea.
  now apply TypeSym.
- intros t u r [] []; esplit; tea.
  now eapply TypeTrans.
Qed.

Lemma NfTermConv : forall Γ A B t t₀, [Γ |-[de] A ≅ B] -> NfTermDecl Γ A t t₀ -> NfTermDecl Γ B t t₀.
Proof.
intros * H []; split; tea.
now eapply TermConv.
Qed.

Lemma NeTermConv : forall Γ A B t t₀, [Γ |-[de] A ≅ B] -> NeTermDecl Γ A t t₀ -> NeTermDecl Γ B t t₀.
Proof.
intros * ? [Hne Hnf]; split; [tea|].
now eapply NfTermConv.
Qed.

Lemma NfTypeDecl_tSort : forall Γ, [|-[de] Γ] -> NfTypeDecl Γ U U.
Proof.
intros; split.
+ reflexivity.
+ constructor.
+ now do 2 constructor.
Qed.

Lemma NfTypeDecl_tProd : forall Γ A A' A₀ B B₀,
  [Γ |-[de] A] ->
  [Γ |-[de] A ≅ A'] ->
  [Γ,, A |-[de] B ≅ B] ->
  NfTypeDecl Γ A' A₀ -> NfTypeDecl (Γ,, A) B B₀ -> NfTypeDecl Γ (tProd A' B) (tProd A₀ B₀).
Proof.
intros Γ A A' A₀ B B₀ HA HAA' HBB [HRA HAnf] [HRB HBnf].
split.
+ now apply dredalg_prod.
+ now constructor.
+ assert [ Γ |-[de] tProd A B ≅ tProd A' B ].
  { constructor; tea. }
  eapply TypeTrans; [now eapply TypeSym|].
  constructor; [tea|now eapply TypeTrans|tea].
Qed.

Lemma NfTermDecl_tProd : forall Γ A A' A₀ B B₀,
  [Γ |-[de] A : U] ->
  [Γ |-[de] A ≅ A' : U] ->
  [Γ,, A |-[de] B ≅ B : U] ->
  NfTermDecl Γ U A' A₀ -> NfTermDecl (Γ,, A) U B B₀ -> NfTermDecl Γ U (tProd A' B) (tProd A₀ B₀).
Proof.
intros Γ A A' A₀ B B₀ HA HAA' HBB [HRA HAnf] [HRB HBnf].
split.
+ now apply dredalg_prod.
+ now constructor.
+ assert [ Γ |-[de] tProd A B ≅ tProd A' B : U ].
  { constructor; tea. }
  eapply TermTrans; [now eapply TermSym|].
  constructor; [tea|now eapply TermTrans|tea].
Qed.

Lemma NfTermDecl_tLambda : forall Γ A A' A₀ B t t₀,
  [Γ |-[ de ] A] ->
  [Γ |-[ de ] A'] ->
  [Γ,, A |-[ de ] B] ->
  [Γ |-[ de ] A ≅ A'] ->
  [Γ |-[ de ] tLambda A' t : tProd A B] ->
  [Γ,, A |-[ de ] t : B] ->
  [Γ,, A' |-[ de ] t : B] ->
  NfTypeDecl Γ A' A₀ ->
  NfTermDecl (Γ,, A) B (tApp (tLambda A' t)⟨↑⟩ (tRel 0)) t₀ ->
  NfTermDecl Γ (tProd A B) (tLambda A' t) (tLambda A₀ t₀).
Proof.
intros * ? ? ? ? ? ? Ht [] [].
assert (eq0 : forall t, t⟨upRen_term_term ↑⟩[(tRel 0)..] = t).
{ bsimpl; apply idSubst_term; intros [|]; reflexivity. }
split.
+ apply dredalg_lambda; tea.
  assert (Hr : [tApp (tLambda A' t)⟨↑⟩ (tRel 0) ⇶ t]).
  { cbn. set (t' := t) at 2; rewrite <- (eq0 t'); constructor. }
  eapply dred_red_det; tea.
  econstructor; [tea|reflexivity].
+ now constructor.
+ assert [|- Γ] by boundary.
  assert [|- Γ,, A] by now constructor.
  apply TermLambdaCong; tea.
  - eapply TypeTrans; tea.
  - eapply TermTrans; [|tea].
    rewrite <- (eq0 B).
    eapply TermSym; cbn; eapply TermTrans; [eapply TermBRed|].
    * rewrite <- (wk1_ren_on Γ A); eapply typing_wk; tea.
    * repeat rewrite <- (wk1_ren_on Γ A).
      do 2 rewrite <- (wk_up_wk1_ren_on Γ A' A).
      eapply typing_wk; tea.
      constructor; tea.
      now eapply typing_wk.
    * eapply wfTermConv; [now apply ty_var0|].
      repeat rewrite <- (wk1_ren_on Γ A).
      eapply typing_wk; tea.
    * do 2 rewrite eq0; apply TermRefl; tea.
Qed.

Lemma NfTypeDecl_tSig : forall Γ A A' A₀ B B₀,
  [Γ |-[de] A] ->
  [Γ |-[de] A ≅ A'] ->
  [Γ,, A |-[de] B ≅ B] ->
  NfTypeDecl Γ A' A₀ -> NfTypeDecl (Γ,, A) B B₀ -> NfTypeDecl Γ (tSig A' B) (tSig A₀ B₀).
Proof.
intros Γ A A' A₀ B B₀ HA HAA' HBB [HRA HAnf] [HRB HBnf].
split.
+ now apply dredalg_sig.
+ now constructor.
+ assert [ Γ |-[de] tSig A B ≅ tSig A' B ].
  { constructor; tea. }
  eapply TypeTrans; [now eapply TypeSym|].
  constructor; [tea|now eapply TypeTrans|tea].
Qed.

Lemma NfTermDecl_tSig : forall Γ A A' A₀ B B₀,
  [Γ |-[de] A : U] ->
  [Γ |-[de] A ≅ A' : U] ->
  [Γ,, A |-[de] B ≅ B : U] ->
  NfTermDecl Γ U A' A₀ -> NfTermDecl (Γ,, A) U B B₀ -> NfTermDecl Γ U (tSig A' B) (tSig A₀ B₀).
Proof.
intros Γ A A' A₀ B B₀ HA HAA' HBB [HRA HAnf] [HRB HBnf].
split.
+ now apply dredalg_sig.
+ now constructor.
+ assert [ Γ |-[de] tSig A B ≅ tSig A' B : U ].
  { constructor; tea. }
  eapply TermTrans; [now eapply TermSym|].
  constructor; [tea|now eapply TermTrans|tea].
Qed.

Lemma NfTypeDecl_tId : forall Γ A A₀ t t₀ u u₀,
  NfTypeDecl Γ A A₀ -> NfTermDecl Γ A t t₀ -> NfTermDecl Γ A u u₀ -> NfTypeDecl Γ (tId A t u) (tId A₀ t₀ u₀).
Proof.
intros Γ A A₀ t t₀ u u₀ [HRA HAnf] [] [].
split.
+ now apply dredalg_id.
+ now constructor.
+ constructor; tea.
Qed.

Lemma NfTermDecl_tId : forall Γ A A₀ t t₀ u u₀,
  NfTermDecl Γ U A A₀ -> NfTermDecl Γ A t t₀ -> NfTermDecl Γ A u u₀ -> NfTermDecl Γ U (tId A t u) (tId A₀ t₀ u₀).
Proof.
intros Γ A A₀ t t₀ u u₀ [HRA HAnf] [] [].
split.
+ now apply dredalg_id.
+ now constructor.
+ constructor; tea.
Qed.

Lemma NfTermDecl_Refl : forall Γ A A₀ x x₀,
  NfTypeDecl Γ A A₀ -> NfTermDecl Γ A x x₀ -> NfTermDecl Γ (tId A x x) (tRefl A x) (tRefl A₀ x₀).
Proof.
intros * [] [].
split.
+ now apply dredalg_refl.
+ now constructor.
+ constructor; tea.
Qed.

Lemma NfTypeDecl_wk : forall Γ Δ A A₀ (ρ : Δ ≤ Γ), [|- Δ] -> NfTypeDecl Γ A A₀ -> NfTypeDecl Δ A⟨ρ⟩ A₀⟨ρ⟩.
Proof.
intros * tΔ []; split.
+ now apply gcredalg_wk.
+ now apply dnf_ren.
+ now apply typing_wk.
Qed.

Lemma NfTermDecl_wk : forall Γ Δ A t t₀ (ρ : Δ ≤ Γ), [|- Δ] -> NfTermDecl Γ A t t₀ -> NfTermDecl Δ A⟨ρ⟩ t⟨ρ⟩ t₀⟨ρ⟩.
Proof.
intros * tΔ []; split.
+ now apply gcredalg_wk.
+ now apply dnf_ren.
+ now apply typing_wk.
Qed.

Lemma NeTermDecl_wk : forall Γ Δ A t t₀ (ρ : Δ ≤ Γ), [|- Δ] -> NeTermDecl Γ A t t₀ -> NeTermDecl Δ A⟨ρ⟩ t⟨ρ⟩ t₀⟨ρ⟩.
Proof.
intros * tΔ [Hne Hnf]; split.
+ now eapply whne_ren.
+ now eapply NfTermDecl_wk.
Qed.

Lemma NfTypeDecl_tNat : forall Γ, [|-[de] Γ] -> NfTypeDecl Γ tNat tNat.
Proof.
intros; split.
+ reflexivity.
+ constructor.
+ now repeat econstructor.
Qed.

Lemma NfTermDecl_tNat : forall Γ, [|-[de] Γ] -> NfTermDecl Γ U tNat tNat.
Proof.
intros; split.
+ reflexivity.
+ constructor.
+ now repeat econstructor.
Qed.

Lemma NfTermDecl_tZero : forall Γ, [|-[de] Γ] -> NfTermDecl Γ tNat tZero tZero.
Proof.
intros; split.
+ reflexivity.
+ constructor.
+ now do 2 constructor.
Qed.

Lemma NfTermDecl_tSucc : forall Γ n n₀, NfTermDecl Γ tNat n n₀ -> NfTermDecl Γ tNat (tSucc n) (tSucc n₀).
Proof.
intros * []; split.
+ now apply dredalg_succ.
+ now constructor.
+ now do 2 constructor.
Qed.

Lemma NfTypeDecl_tEmpty : forall Γ, [|-[de] Γ] -> NfTypeDecl Γ tEmpty tEmpty.
Proof.
intros; split.
+ reflexivity.
+ constructor.
+ now repeat econstructor.
Qed.

Lemma NfTermDecl_tEmpty : forall Γ, [|-[de] Γ] -> NfTermDecl Γ U tEmpty tEmpty.
Proof.
intros; split.
+ reflexivity.
+ constructor.
+ now repeat econstructor.
Qed.

Lemma NfTermDecl_tPair : forall Γ A A' A₀ B B' B₀ a a' a₀ b' b₀,
  [Γ |-[ de ] A] ->
  [Γ,, A |-[ de ] B] ->
  [Γ |-[ de ] tPair A' B' a' b' : tSig A B] ->
  [Γ |-[ de ] A ≅ A'] ->
  [Γ,, A |-[ de ] B ≅ B'] ->
  [Γ |-[ de ] B[a..] ≅ B[a'..]] ->
  [Γ |-[ de ] a ≅ a' : A] ->
  NfTypeDecl Γ A' A₀ ->
  NfTypeDecl (Γ,, A) B' B₀ ->
  NfTermDecl Γ A a' a₀ ->
  NfTermDecl Γ B[a..] b' b₀ ->
  NfTermDecl Γ (tSig A B) (tPair A' B' a' b') (tPair A₀ B₀ a₀ b₀).
Proof.
intros * ? ? ? ? ? ? ? [] [] [] [].
split.
+ apply dredalg_pair; tea.
+ now constructor.
+ apply TermPairCong; tea.
  - now eapply TypeTrans.
  - now eapply TypeTrans.
  - eapply convtm_conv; tea.
Qed.

Lemma NeTermDecl_NfTermDecl : forall Γ A n n₀,
  NeTermDecl Γ A n n₀ -> NfTermDecl Γ A n n₀.
Proof.
intros * []; tea.
Qed.

Lemma NeTermDecl_dne : forall Γ A n,
  [Γ |-[de] n : A] -> dne n -> NeTermDecl Γ A n n.
Proof.
intros; split.
+ now apply dnf_dne_whnf_whne.
+ split.
  - reflexivity.
  - now constructor.
  - now apply TermRefl.
Qed.

Lemma NfTermDecl_exp : forall Γ A t t' t₀,
  [Γ |-[de] t ⤳* t' : A] ->
  [Γ |-[de] A] ->
  [Γ |-[de] A ≅ A] ->
  [Γ |- t' : A] ->
  NfTermDecl Γ A t' t₀ -> NfTermDecl Γ A t t₀.
Proof.
intros * ? ? ? ? [].
split; tea.
+ etransitivity; [|tea].
  now eapply dred_red, redtm_sound.
+ transitivity t'; [|tea].
  eapply convtm_exp; tea.
  * now eapply redtm_refl.
  * now eapply TermRefl.
Qed.

Lemma NeTermDecl_tApp : forall Γ A B t t' t₀ u u' u₀,
  [Γ |-[de] t ≅ t' : tProd A B] ->
  [Γ |-[de] u ≅ u' : A] ->
  NeTermDecl Γ (tProd A B) t' t₀ ->
  NfTermDecl Γ A u' u₀ ->
  NeTermDecl Γ B[u..] (tApp t' u') (tApp t₀ u₀).
Proof.
intros * ? ? [? []] []; split; [now constructor|].
split.
+ apply dredalg_app; tea.
  apply dne_dnf_whne; [tea|].
  now eapply dredalg_whne.
+ do 2 constructor; [|tea].
  apply dne_dnf_whne; [tea|].
  now eapply dredalg_whne.
+ transitivity (tApp t u).
  - symmetry; econstructor; tea.
  - econstructor.
    * eapply TermTrans; tea.
    * transitivity u'; tea.
Qed.

Lemma NeTermDecl_tFst : forall Γ A B p p₀,
  NeTermDecl Γ (tSig A B) p p₀ ->
  NeTermDecl Γ A (tFst p) (tFst p₀).
Proof.
intros * [? []]; split; [now constructor|].
split.
+ now apply dredalg_fst.
+ do 2 constructor.
  apply dne_dnf_whne; [tea|].
  now eapply dredalg_whne.
+ now eapply TermFstCong.
Qed.

Lemma NeTermDecl_tSnd : forall Γ A B p p' p₀,
  [Γ |-[de] p ≅ p' : tSig A B] ->
  NeTermDecl Γ (tSig A B) p' p₀ ->
  NeTermDecl Γ B[(tFst p)..] (tSnd p') (tSnd p₀).
Proof.
intros * ? [? []]; split; [now constructor|].
split.
+ now apply dredalg_snd.
+ do 2 constructor.
  apply dne_dnf_whne; [tea|].
  now eapply dredalg_whne.
+ transitivity (tSnd p); [symmetry|]; eapply TermSndCong; tea.
  eapply TermTrans; tea.
Qed.

Lemma NeTermDecl_tNatElim : forall Γ P P' P₀ hz hz' hz₀ hs hs' hs₀ t t' t₀,
  [Γ,, tNat |-[de] P ≅ P'] ->
  [Γ |-[de] hz ≅ hz' : P[tZero..]] ->
  [Γ |-[de] hs ≅ hs' : elimSuccHypTy P] ->
  [Γ |-[de] t ≅ t' : tNat] ->
  NfTypeDecl (Γ,, tNat) P' P₀ ->
  NfTermDecl Γ P[tZero..] hz' hz₀ ->
  NfTermDecl Γ (elimSuccHypTy P) hs' hs₀ ->
  NeTermDecl Γ tNat t' t₀ ->
  NeTermDecl Γ P[t..] (tNatElim P' hz' hs' t') (tNatElim P₀ hz₀ hs₀ t₀).
Proof.
intros * ? ? ? ? [] [] [] [? []]; split; [now constructor|].
split.
+ eapply dredalg_natElim; tea.
  apply dne_dnf_whne; [tea|].
  now eapply dredalg_whne.
+ do 2 constructor; tea.
  apply dne_dnf_whne; [tea|].
  now eapply dredalg_whne.
+ transitivity (tNatElim P hz hs t); [symmetry|].
  - constructor; tea.
  - constructor; etransitivity; tea.
Qed.

Lemma NeTermDecl_tEmptyElim : forall Γ P P' P₀ t t' t₀,
  [Γ,, tEmpty |-[de] P ≅ P'] ->
  [Γ |-[de] t ≅ t' : tEmpty] ->
  NfTypeDecl (Γ,, tEmpty) P' P₀ ->
  NeTermDecl Γ tEmpty t' t₀ ->
  NeTermDecl Γ P[t..] (tEmptyElim P' t') (tEmptyElim P₀ t₀).
Proof.
intros * ? ? [] [? []]; split; [now constructor|].
split.
+ eapply dredalg_emptyElim; tea.
  apply dne_dnf_whne; [tea|].
  now eapply dredalg_whne.
+ do 2 constructor; tea.
  apply dne_dnf_whne; [tea|].
  now eapply dredalg_whne.
+ transitivity (tEmptyElim P t); [symmetry|].
  - constructor; tea.
  - constructor; etransitivity; tea.
Qed.

Lemma NeTermDecl_tIdElim : forall Γ A A' A₀ x x' x₀ P P' P₀ hr hr' hr₀ y y' y₀ t t' t₀,
  [Γ |-[de] A] ->
  [Γ |-[de] A ≅ A'] ->
  [Γ |-[de] x : A] ->
  [Γ |-[de] x ≅ x' : A] ->
  [Γ ,, A ,, tId A⟨@wk1 Γ A⟩ x⟨@wk1 Γ A⟩ (tRel 0) |-[de] P ≅ P'] ->
  [Γ |-[de] hr ≅ hr' : P[tRefl A x .: x..]] ->
  [Γ |-[de] y ≅ y' : A] ->
  [Γ |-[de] t ≅ t' : tId A x y] ->
  NfTypeDecl Γ A' A₀ ->
  NfTermDecl Γ A x' x₀ ->
  NfTypeDecl (Γ,, A ,, tId A⟨@wk1 Γ A⟩ x⟨@wk1 Γ A⟩ (tRel 0)) P' P₀ ->
  NfTermDecl Γ  P[tRefl A x .: x..] hr' hr₀ ->
  NfTermDecl Γ A y' y₀ ->
  NeTermDecl Γ (tId A x y) t' t₀ ->
  NeTermDecl Γ P[t .: y..] (tIdElim A' x' P' hr' y' t') (tIdElim A₀ x₀ P₀ hr₀ y₀ t₀).
Proof.
intros * ? ? ? ? ? ? ? ? [] [] [] [] [] [? []]; split; [now constructor|].
split.
+ eapply dredalg_idElim; tea.
  apply dne_dnf_whne; [tea|].
  now eapply dredalg_whne.
+ do 2 constructor; tea.
  apply dne_dnf_whne; [tea|].
  now eapply dredalg_whne.
+ transitivity (tIdElim A x P hr y t); [symmetry|].
  - constructor; tea.
  - constructor; tea; etransitivity; tea.
Qed.

End Nf.

Module DeepTypingData.

  Definition nf : tag.
  Proof.
  constructor.
  Qed.

  #[export] Instance WfContext_Decl : WfContext nf := WfContextDecl.
  #[export] Instance WfType_Decl : WfType nf := WfTypeDecl.
  #[export] Instance Typing_Decl : Typing nf := TypingDecl.
  #[export] Instance ConvType_Decl : ConvType nf := ConvTypeNfDecl.
  #[export] Instance ConvTerm_Decl : ConvTerm nf := ConvTermNfDecl.
  #[export] Instance ConvNeuConv_Decl : ConvNeuConv nf := ConvTermNeDecl.
  #[export] Instance RedType_Decl : RedType nf := TypeRedClosure.
  #[export] Instance RedTerm_Decl : RedTerm nf := TermRedClosure.

End DeepTypingData.

Module DeepTypingProperties.

  Import DeclarativeTypingProperties DeepTypingData.

  Local Ltac invnf := repeat match goal with
  | H : [_ |-[nf] _ ≅ _] |- _ => destruct H
  | H : [_ |-[nf] _ ≅ _ : _] |- _ => destruct H
  | H : [_ |-[nf] _ ~ _ : _] |- _ => destruct H
  end.

  #[export, refine] Instance WfCtxDeclProperties : WfContextProperties (ta := nf) := {}.
  Proof.
    1-2: now constructor.
    all: intro Γ; try change [|-[nf] Γ] with [|-[de] Γ].
    intros; now eapply wfc_wft.
    intros; now eapply wfc_ty.
    intros * []; now eapply wfc_convty.
    intros * []; now eapply wfc_convtm.
    intros; now eapply wfc_redty.
    intros; now eapply wfc_redtm.
  Qed.

  #[export, refine] Instance WfTypeDeclProperties : WfTypeProperties (ta := nf) := {}.
  Proof.
  all: try apply DeclarativeTypingProperties.WfTypeDeclProperties.
  Qed.

  #[export, refine] Instance ConvTypeDeclProperties : ConvTypeProperties (ta := nf) := {}.
  Proof.
  - intros * [A₀ B₀]; exists A₀ B₀.
    + now econstructor.
    + destruct nfconvtm_nfl0; split; tea; try now econstructor.
    + destruct nfconvtm_nfr0; split; tea; try now econstructor.
  - intros; apply ConvTypeNf_PER.
  - intros; invnf; eexists.
    + now apply typing_wk.
    + now apply NfTypeDecl_wk.
    + now apply NfTypeDecl_wk.
  - intros; invnf; eexists.
    + eapply TypeTrans ; [eapply TypeTrans | ..].
      2: eassumption.
      2: eapply TypeSym.
      all: now eapply RedConvTyC.
    + destruct nfconvty_nfl0; split; tea.
      * etransitivity; [|eassumption].
        apply dred_red, H.
      * eapply TypeTrans; [apply H|tea].
    + destruct nfconvty_nfr0; split; tea.
      * etransitivity; [|eassumption].
        apply dred_red, H0.
      * eapply TypeTrans; [apply H0|tea].
  - intros; invnf; eexists.
    + now do 2 constructor.
    + now apply NfTypeDecl_tSort.
    + now apply NfTypeDecl_tSort.
  - intros; invnf; eexists.
    + constructor; tea.
    + eapply NfTypeDecl_tProd; tea.
      * now eapply lrefl.
      * now eapply lrefl.
    + eapply NfTypeDecl_tProd; tea.
      now eapply urefl.
  - intros; invnf; eexists.
    + constructor; match goal with H : _ |- _ => now apply H end.
    + eapply NfTypeDecl_tSig; tea.
      * now eapply lrefl.
      * now eapply lrefl.
    + eapply NfTypeDecl_tSig; tea.
      now eapply urefl.
  - intros; invnf; eexists.
    + constructor; now assumption.
    + apply NfTypeDecl_tId; tea.
    + apply NfTypeDecl_tId; tea.
      * now eapply NfTermConv.
      * now eapply NfTermConv.
  Qed.

  Inductive isNfFun Γ A B : term -> Set :=
  | LamNfFun : forall A' A₀ t t₀,
    [Γ |-[ de ] A'] ->
    [Γ |-[ de ] A ≅ A'] ->
    [Γ,, A |-[ de ] t : B] ->
    [Γ,, A' |-[ de ] t : B] ->
    NfTypeDecl Γ A' A₀ -> NfTermDecl (Γ,, A) B (tApp (tLambda A' t)⟨↑⟩ (tRel 0)) t₀ ->
    isWfFun (ta := de) Γ A B (tLambda A' t) -> isNfFun Γ A B (tLambda A' t)
  | NeNfFun : forall n n₀, [Γ |-[de] n ~ n : tProd A B] ->
    NeTermDecl Γ (tProd A B) n n₀ -> isNfFun Γ A B n.
  Arguments LamNfFun {_ _ _}.
  Arguments NeNfFun {_ _ _}.

  Inductive isNfPair Γ A B : term -> Set :=
  | PairNfPair : forall A' A₀ B' B₀ a a₀ b b₀,
    [Γ |-[ de ] A'] ->
    [Γ |-[ de ] A ≅ A'] ->
    [Γ,, A |-[ de ] B ≅ B'] ->
    [Γ |-[ de ] B[a..] ≅ B'[a..]] ->
    [Γ |-[ de ] a ≅ a : A] ->
    NfTypeDecl Γ A' A₀ ->
    NfTypeDecl (Γ,, A) B' B₀ ->
    NfTermDecl Γ A a a₀ ->
    NfTermDecl Γ B[a..] b b₀ ->
    isWfPair (ta := de) Γ A B (tPair A' B' a b) -> isNfPair Γ A B (tPair A' B' a b)
  | NeNfPair : forall n n₀, [Γ |-[de] n ~ n : tSig A B] ->
    NeTermDecl Γ (tSig A B) n n₀ -> isNfPair Γ A B n.
  Arguments PairNfPair {_ _ _}.
  Arguments NeNfPair {_ _ _}.

  Lemma isWfFun_isNfFun : forall Γ A B t t₀,
    NfTermDecl (Γ,, A) B (tApp t⟨↑⟩ (tRel 0)) t₀ -> isWfFun Γ A B t -> isNfFun Γ A B t.
  Proof.
  intros * H Hwf; revert H; destruct Hwf; intros; invnf.
  + econstructor; tea.
    constructor; tea.
  + econstructor; tea.
  Qed.

  Lemma isWfPair_isNfPair : forall Γ A B t (* p₀ q₀ *),
    isWfPair Γ A B t -> isNfPair Γ A B t.
  Proof.
  intros * Hwf; destruct Hwf; intros; invnf.
  + econstructor; tea.
    constructor; tea.
  + econstructor; tea.
  Qed.

  Definition exp_fun {Γ A B f} (w : isNfFun Γ A B f) : term := match w with
  | LamNfFun _ A₀ _ t₀ _ _ _ _ _ _ _ => tLambda A₀ t₀
  | NeNfFun _ n₀ _ _ => n₀
  end.

  Definition exp_pair {Γ A B p} (w : isNfPair Γ A B p) : term := match w with
  | PairNfPair _ A₀ _ B₀ _ a₀ _ b₀ _ _ _ _ _ _ _ _ _ _ => tPair A₀ B₀ a₀ b₀
  | NeNfPair _ n₀ _ _ => n₀
  end.

  #[export, refine] Instance ConvTermDeclProperties : ConvTermProperties (ta := nf) := {}.
  Proof.
  + intros; split.
    - intros ? ? []; eexists; tea.
      now symmetry.
    - intros ? ? ? [] []; eexists; tea.
      now etransitivity.
  + intros; invnf; eexists.
    - now eapply TermConv.
    - now eapply NfTermConv.
    - now eapply NfTermConv.
  + intros; invnf; eexists.
    - now apply typing_wk.
    - now apply NfTermDecl_wk.
    - now apply NfTermDecl_wk.
  + intros; invnf; eexists.
    - now eapply convtm_exp.
    - eapply NfTermDecl_exp with (t' := t'); tea.
    - eapply NfTermDecl_exp with (t' := u'); tea.
  + intros; invnf; eexists.
    - now apply convtm_convneu.
    - now apply NeTermDecl_NfTermDecl.
    - now apply NeTermDecl_NfTermDecl.
  + intros; invnf; eexists.
    - now apply convtm_prod.
    - eapply NfTermDecl_tProd; tea.
      * now eapply lrefl.
      * now eapply lrefl.
    - eapply NfTermDecl_tProd; tea.
      now eapply urefl.
  + intros; invnf; eexists.
    - constructor; tea.
    - eapply NfTermDecl_tSig; tea.
      * now eapply lrefl.
      * now eapply lrefl.
    - eapply NfTermDecl_tSig; tea.
      * now eapply urefl.
  + intros * ? ? ? Hf ? Hg [].
    eapply isWfFun_isNfFun in Hf; [|tea].
    eapply isWfFun_isNfFun in Hg; [|tea].
    eexists (exp_fun Hf) (exp_fun Hg).
    - apply convtm_eta; tea.
      * destruct Hf; constructor; tea.
      * destruct Hg; constructor; tea.
    - destruct Hf; cbn.
      * apply NfTermDecl_tLambda; tea.
      * now apply netmdecl_nf.
    - destruct Hg; cbn.
      * apply NfTermDecl_tLambda; tea.
      * now apply netmdecl_nf.
  + intros; eexists; tea.
    - do 2 constructor; tea.
    - now apply NfTermDecl_tNat.
    - now apply NfTermDecl_tNat.
  + intros; eexists.
    - now do 2 constructor.
    - now apply NfTermDecl_tZero.
    - now apply NfTermDecl_tZero.
  + intros; invnf; eexists.
    - constructor; tea.
    - now apply NfTermDecl_tSucc.
    - now apply NfTermDecl_tSucc.
  + intros * ? ? ? Hp ? Hp' [] [].
    eapply isWfPair_isNfPair in Hp; tea.
    eapply isWfPair_isNfPair in Hp'; tea.
    eexists (exp_pair Hp) (exp_pair Hp').
    - etransitivity; [|now eapply TermPairEta].
      etransitivity; [now symmetry; eapply TermPairEta|].
      constructor; tea; now apply TypeRefl.
    - destruct Hp.
      * invnf.
        eapply NfTermDecl_tPair; [..|tea]; tea.
        now eapply lrefl.
      * now eapply netmdecl_nf.
    - destruct Hp'.
      * invnf.
        eapply NfTermDecl_tPair; tea.
        now eapply lrefl.
      * now eapply netmdecl_nf.
  + intros; invnf; eexists.
    - now do 2 constructor.
    - now apply NfTermDecl_tEmpty.
    - now apply NfTermDecl_tEmpty.
  + intros; invnf; eexists.
    - now constructor.
    - now apply NfTermDecl_tId.
    - apply NfTermDecl_tId; tea.
      all: eapply NfTermConv; tea; now constructor.
  + intros; invnf; eexists.
    - now constructor.
    - now apply NfTermDecl_Refl.
    - eapply NfTermConv; [symmetry; now constructor|apply NfTermDecl_Refl; tea].
      eapply NfTermConv; tea.
  Qed.

  #[export, refine] Instance TypingDeclProperties : TypingProperties (ta := nf) := {}.
  Proof.
  all: try apply DeclarativeTypingProperties.TypingDeclProperties.
  + intros * ? []; now econstructor.
  Qed.

  #[export, refine] Instance ConvNeuDeclProperties : ConvNeuProperties (ta := nf) := {}.
  Proof.
  + intros; split.
    - intros ? ? []; eexists; tea.
      now symmetry.
    - intros ? ? ? [] []; eexists; tea.
      now etransitivity.
  + intros; invnf; eexists.
    - now eapply convneu_conv.
    - now eapply NeTermConv.
    - now eapply NeTermConv.
  + intros; invnf; eexists.
    - now eapply convneu_wk.
    - now eapply NeTermDecl_wk.
    - now eapply NeTermDecl_wk.
  + intros; invnf; now eapply convneu_whne.
  + intros; invnf; eexists.
    - now apply convneu_var.
    - apply NeTermDecl_dne; tea; now constructor.
    - apply NeTermDecl_dne; tea; now constructor.
  + intros * [f₀ g₀ Hfg] []; eexists; tea.
    - now eapply convneu_app.
    - eapply NeTermDecl_tApp; tea.
      * eapply lrefl, Hfg.
      * eapply lrefl; tea.
    - eapply NeTermDecl_tApp; tea.
      apply Hfg.
  + intros; invnf; eexists.
    - now eapply convneu_natElim.
    - eapply NeTermDecl_tNatElim; tea; try now symmetry.
      * now eapply lrefl.
      * now eapply lrefl, convtm_convneu.
    - eapply NeTermDecl_tNatElim; tea.
      now eapply convtm_convneu.
  + intros; invnf; eexists.
    - now eapply convneu_emptyElim.
    - eapply NeTermDecl_tEmptyElim; tea.
      * now eapply lrefl.
      * now eapply lrefl, convtm_convneu.
    - eapply NeTermDecl_tEmptyElim; tea.
      now eapply convtm_convneu.
  + intros; invnf; eexists.
    - now eapply convneu_fst.
    - now eapply NeTermDecl_tFst.
    - now eapply NeTermDecl_tFst.
  + intros; invnf; eexists.
    - now eapply convneu_snd.
    - eapply NeTermDecl_tSnd; tea.
      eapply lrefl; tea; apply neconvtm_conv0.
    - eapply NeTermDecl_tSnd; tea.
      now apply neconvtm_conv0.
  + intros; invnf; eexists.
    - now eapply convneu_IdElim.
    - eapply NeTermDecl_tIdElim; tea.
      all: try now eapply lrefl.
      now eapply lrefl, convtm_convneu.
    - eapply NeTermDecl_tIdElim; tea.
      now eapply convtm_convneu.
  Qed.

  #[export, refine] Instance RedTypeDeclProperties : RedTypeProperties (ta := nf) := {}.
  Proof.
  all: try apply DeclarativeTypingProperties.RedTypeDeclProperties.
  Qed.

  #[export, refine] Instance RedTermDeclProperties : RedTermProperties (ta := nf) := {}.
  Proof.
  all: try apply DeclarativeTypingProperties.RedTermDeclProperties.
  + intros; invnf; now apply DeclarativeTypingProperties.RedTermDeclProperties.
  + intros; invnf; change (@red_tm nf) with (@red_tm de).
    now eapply redtm_conv.
  Qed.

  #[export] Instance DeclarativeTypingProperties : GenericTypingProperties nf _ _ _ _ _ _ _ _ _ _ := {}.

End DeepTypingProperties.