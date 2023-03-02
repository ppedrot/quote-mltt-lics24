From LogRel.AutoSubst Require Import core unscoped Ast Extra.
From LogRel Require Import Utils BasicAst Notations Context Untyped Weakening GenericTyping LogicalRelation Reduction Validity.
From LogRel.LogicalRelation Require Import Induction Irrelevance Escape Reflexivity Weakening Neutral Transitivity Reduction Application.
From LogRel.Substitution Require Import Irrelevance Properties Conversion SingleSubst Reflexivity.

Set Universe Polymorphism.

Section Application.
Context `{GenericTypingProperties}.

Set Printing Primitive Projection Parameters.

Lemma appValid {Γ nF F G t u l}
  {VΓ : [||-v Γ]}
  {VF : [Γ ||-v<l> F | VΓ]}
  {VΠFG : [Γ ||-v<l> tProd nF F G | VΓ]}
  (Vt : [Γ ||-v<l> t : tProd nF F G | VΓ | VΠFG])
  (Vu : [Γ ||-v<l> u : F | VΓ | VF])
  (VGu := substSΠ VΠFG Vu) :
  [Γ ||-v<l> tApp t u : G[u..] | VΓ | VGu].
Proof.
  opector; intros.
  - instValid wfΔ Vσ.
    epose (appTerm RVΠFG RVt RVu (substSΠaux VΠFG Vu _ _ wfΔ Vσ)).
    irrelevance.
  - instAllValid wfΔ Vσ Vσ' Vσσ'. 
    unshelve epose (appcongTerm _ REVt RVu _ REVu (substSΠaux VΠFG Vu _ _ wfΔ Vσ)).
    2: irrelevance.
    eapply LRTmRedConv; tea.
    unshelve eapply LRTyEqSym. 2,3: tea.
Qed.

Lemma appcongValid {Γ nF F G t u a b l}
  {VΓ : [||-v Γ]}
  {VF : [Γ ||-v<l> F | VΓ]}
  {VΠFG : [Γ ||-v<l> tProd nF F G | VΓ]}
  (Vtu : [Γ ||-v<l> t ≅ u : tProd nF F G | VΓ | VΠFG])
  (Va : [Γ ||-v<l> a : F | VΓ | VF])
  (Vb : [Γ ||-v<l> b : F | VΓ | VF])
  (Vab : [Γ ||-v<l> a ≅ b : F | VΓ | VF])
  (VGa := substSΠ VΠFG Va) :
  [Γ ||-v<l> tApp t a ≅ tApp u b : G[a..] | VΓ | VGa].
Proof.
  constructor; intros; instValid wfΔ Vσ.
  pose proof (appcongTerm _ RVtu RVa RVb RVab (substSΠaux VΠFG Va _ _ wfΔ Vσ)).
  irrelevance.
Qed.

End Application.