(*
 * Copyright 2015-2016 IBM Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)

Section TPatterntoNRAEnv.

  Require Import String List.

  Require Import Utils BasicSystem.
  Require Import NRASystem NRAEnvSystem.
  Require Import Pattern PatterntoNRAEnv.

  Require Import TPattern TPatterntoNRA.

  Local Open Scope string_scope.
  Local Open Scope list_scope.
  Local Open Scope rule_scope.

  Hint Constructors algenv_type unaryOp_type binOp_type.

  Context {m:basic_model}.

  Lemma algenv_of_pat_type_preserve τc Γ pf p τin τout :
    [τc&Γ] |= p ; τin ~> τout ->
    algenv_of_pat p ▷ τin >=> Coll τout ⊣ τc;(Rec Closed Γ pf).
  Proof.
    Hint Resolve data_type_drec_nil.
    revert Γ pf τin τout.
    induction p; simpl; inversion 1; subst.
    (* PTconst *)
    - unfold envpat_match.
      eauto.
    (* PTunop *)
    - eauto. 
    (* PTbinop *)
    - econstructor.
      + eapply (@ANTBinop m _ (Rec Closed Γ pf) (Rec Closed (("a1", τ₂₁)::("a2", τ₂₂)::nil) (eq_refl _))). eauto.
        apply (@ANTUnop m _ (Rec Closed Γ pf) (Rec Closed (("a1", τ₂₁) :: ("a2", τ₂₂) :: nil) eq_refl) (Rec Closed (("a1", τ₂₁) :: ("a2", τ₂₂) :: nil) eq_refl)).
        econstructor; reflexivity.
        eauto.
        apply (@ANTUnop m _ (Rec Closed Γ pf) (Rec Closed (("a1", τ₂₁) :: ("a2", τ₂₂) :: nil) eq_refl) (Rec Closed (("a1", τ₂₁) :: ("a2", τ₂₂) :: nil) eq_refl)).
        econstructor; reflexivity.
        econstructor; eauto.
      + econstructor; eauto.
    (* PTmap *)
    - econstructor; eauto.
    (* PTassert *)
    - repeat econstructor; eauto.
    (* PTorElse *)
    - eauto.
    (* PTit *)
    - econstructor; eauto.
    (* PTletIt *)
    - econstructor; eauto.
    (* PTgetconstant *)
    - repeat (econstructor; eauto).
    (* PTenv *)
    - rewrite (is_list_sorted_ext _ _ pf pf0).
      repeat (econstructor; eauto).
    (* PTletEnv *)
    - econstructor; eauto.
      econstructor; eauto.
      assert (Γeq:Γ'' = rec_concat_sort Γ Γ')
        by (unfold merge_bindings in *; 
             destruct (compatible Γ Γ'); congruence).
      generalize (merge_bindings_sorted H4). subst. 
      intros.
      econstructor; eauto.
    (* PTEither *)
    - repeat (econstructor; eauto).
    (* PTEither *)
    - repeat (econstructor; eauto).
    Grab Existential Variables.
    eauto. eauto. eauto.
  Qed.

  (** Some corollaries of the main Lemma *)

  Lemma algenv_of_pat_algenv_of_pat_top p τc τin τout :
    algenv_of_pat p ▷ τin >=> Coll τout ⊣ τc;(Rec Closed nil eq_refl) ->
    algenv_of_pat_top p ▷ τin >=> Coll τout ⊣ τc;(Rec Closed nil eq_refl).
  Proof.
    intros.
    repeat (econstructor; eauto).
  Qed.
    
  Theorem alg_of_pat_top_type_preserve p τc τin τout :
    [τc&nil] |= p ; τin ~> τout ->
    algenv_of_pat_top p ▷ τin >=> Coll τout ⊣ τc;(Rec Closed nil eq_refl).
  Proof.
    intros.
    apply algenv_of_pat_algenv_of_pat_top.
    apply algenv_of_pat_type_preserve; eauto.
  Qed.

  Require Import TRule RuletoNRAEnv.

  Theorem algenv_of_rule_type_preserve τworld τout r :
    @rule_type m τworld τout r ->
    algenv_of_rule r ▷ Unit >=> Coll τout ⊣  (mkTWorld τworld);(Rec Closed nil eq_refl).
    Proof.
      unfold rule_type; intros.
      apply algenv_of_pat_type_preserve; trivial.
    Qed.

End TPatterntoNRAEnv.

(* 
*** Local Variables: ***
*** coq-load-path: (("../../coq" "QCert")) ***
*** End: ***
*)
