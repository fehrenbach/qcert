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

(*************************************************
 * Type-dependent NRAᵉ equivalences and rewrites *
 *************************************************)

(* those equivalences are for all well-typed expressions *)

Section TOptimEnv.

  Require Import Equivalence.
  Require Import Morphisms.
  Require Import Setoid.
  Require Import EquivDec.
  Require Import Program.
  Require Import Bool String List ListSet.
  
  Require Import BasicSystem.

  Require Import RAlgEnv RAlgEnvIgnore RAlgEnvEq.
  Require Import TAlgEnv TAlgEnvIgnore TAlgEnvEq.

  Require Import ROptimEnv.

  Local Open Scope algenv_scope.

  (***********************
   * Boolean expressions *
   ***********************)
  
  (* q₁ ∧ q₂ ⇒ q₂ ∧ q₁ *)

  Context {m:basic_model}.

  Lemma tand_comm_arrow (q₁ q₂:algenv) :
    q₁ ∧ q₂ ⇒ q₂ ∧ q₁.
  Proof.
    unfold talgenv_rewrites_to; intros; simpl.
    intuition; inferer. generalize envand_comm; intros.
    unfold algenv_eq in H.
    simpl in H. apply H; eauto.
  Qed.

  Lemma tand_comm {τc τenv τin} (q₁ q₂ ql qr: m ⊧ τin ⇝ Bool ⊣ τc;τenv) :
    (`ql = `q₂ ∧ `q₁) ->
    (`qr = `q₁ ∧ `q₂) ->
    ql ≡τ qr.
  Proof.
    intros.
    apply talg_rewrites_eq_is_typed_eq.
    rewrite H; rewrite H0.
    apply tand_comm_arrow.
  Qed.


  (**********************
   * Record expressions *
   **********************)

  Lemma tconcat_empty_record_r_arrow q:
    q ⊕ ‵[||] ⇒ q.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    invcs H0.
    rtype_equalizer.
    subst.
    cut_to H4; [| tauto].
    subst.
    invcs H5.
    revert pf3; rewrite rec_concat_sort_nil_r.
    rewrite sort_sorted_is_id by trivial.
    intros pf3.
    rewrite <- (is_list_sorted_ext StringOrder.lt_dec _ pf1 pf3).
    clear pf3.
    split; trivial.
    intros.
    input_well_typed.
    dtype_inverter.
    rewrite app_nil_r.
    apply data_type_normalized in τout.
    invcs τout.
    rewrite sort_sorted_is_id; trivial.
  Qed.

  Lemma tconcat_empty_record_l_arrow q:
    ‵[||] ⊕ q ⇒ q.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    invcs H0.
    rtype_equalizer.
    subst.
    cut_to H4; [| tauto].
    subst.
    invcs H5.
    revert pf3; rewrite rec_concat_sort_nil_l.
    rewrite sort_sorted_is_id by trivial.
    intros pf3.
    rewrite <- (is_list_sorted_ext StringOrder.lt_dec _ pf2 pf3).
    clear pf3.
    split; trivial.
    intros.
    input_well_typed.
    dtype_inverter.
    apply data_type_normalized in τout.
    invcs τout.
    rewrite sort_sorted_is_id; trivial.
  Qed.
    

  (* q ⊗ [] ⇒ { q } *)
  Lemma tmerge_empty_record_r_arrow q:
    q ⊗ ‵[||] ⇒ ‵{| q |}.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    simpl in *.
    inversion H0; clear H0; subst.
    rtype_equalizer. subst.
    specialize (H5 eq_refl); subst; clear H4.
    assert (‵{|q|} ▷ τin >=> Coll (Rec Closed τ₃ pf3) ⊣ τc;τenv /\
            q ▷ τin >=> Rec Closed τ₃ pf3 ⊣ τc;τenv ).
    - inversion H6; clear H6; subst.
      clear pf2 pf'.
      rewrite merge_bindings_nil_r in H.
      rewrite sort_sorted_is_id in H; try assumption.
      inversion H; clear H; subst.
      assert (Rec Closed τ₃ pf1 = Rec Closed τ₃ pf3).
      apply rtype_fequal; reflexivity.
      rewrite H in H7. clear H pf1.
      inferer.
    - econstructor. elim H0; clear H0; intros. assumption.
      elim H0; clear H0; intros.
      assert ((q ⊗ ‵[||]) ▷ τin >=> Coll (Rec Closed τ₃ pf3) ⊣ τc;τenv).
      econstructor; eauto; try econstructor; eauto.
      apply dtrec_full; simpl; assumption.
      input_well_typed.
      dependent induction τout.
      assert (domain dl = domain rl0) by (apply sorted_forall_same_domain; assumption).
      rewrite merge_bindings_nil_r.
      rewrite sort_sorted_is_id. reflexivity.
      rewrite H8.
      assumption.
    - assert (‵{|q|} ▷ τin >=> Coll (Rec Open τ₃ pf3) ⊣ τc;τenv /\
              q ▷ τin >=> Rec Open τ₃ pf3 ⊣ τc;τenv ).
      inversion H0. rtype_equalizer; subst.
      inversion H6; clear H6; intros. subst.
      econstructor; eauto.
      econstructor; eauto.
      inversion H4. subst.
      rewrite merge_bindings_nil_r in H.
      rewrite sort_sorted_is_id in H; try assumption.
      inversion H; clear H; subst.
      assert (Rec Open τ₃ pf1 = Rec Open τ₃ pf3).
      apply rtype_fequal; reflexivity.
      rewrite H in H7. clear H pf1. assumption.
      inversion H4. subst.
      rewrite merge_bindings_nil_r in H.
      rewrite sort_sorted_is_id in H; try assumption.
      inversion H; clear H; subst.
      assert (Rec Open τ₃ pf1 = Rec Open τ₃ pf3).
      apply rtype_fequal; reflexivity.
      rewrite H in H7; assumption.
      econstructor. elim H1; clear H1; intros; assumption; intros.
      intros.
      input_well_typed.
      dependent induction τout.
      rtype_equalizer. subst.
      inversion H0; clear H0; intros.
      rtype_equalizer; subst.
      rewrite merge_bindings_nil_r.
      rewrite sort_sorted_is_id. reflexivity.
      assert (domain dl = domain rl) by (apply sorted_forall_same_domain; assumption).
      rewrite H0; assumption.
      Grab Existential Variables.
      eauto.
  Qed.

    (* [] ⊗ q   ⇒ { q } *)

  Lemma tmerge_empty_record_l_arrow q:
    ‵[||] ⊗ q  ⇒ ‵{| q |}.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer;
      (inversion H0; clear H0; subst;
      rtype_equalizer; subst;
      inversion H6; clear H6; subst;
      unfold merge_bindings in H;
      inversion H4; subst;
      match_destr_in H;
      unfold rec_concat_sort in H; simpl in H;
      rewrite rec_sorted_id in H by trivial;
      inversion H; clear H; subst;
      simpl in *;
      destruct (is_list_sorted_ext StringOrder.lt_dec _ pf3 pf2);
      split; [econstructor; eauto | 
    intros;
        input_well_typed;
        dtype_inverter;
        unfold rec_concat_sort; simpl;
        rewrite rec_sorted_id; trivial;
        apply data_type_normalized in τout;
        inversion τout; subst; trivial]).
  Qed.

  (* [ a : q ].s ⇒ q *)

  Lemma tdot_over_rec_arrow a q :
    (‵[| (a, q)|]) · a ⇒ q.
  Proof.
    apply (rewrites_typed_with_untyped _ _ (dot_over_rec a q)).
    intros.
    inferer.
    unfold tdot, edot in H4; simpl in H4.
    destruct (string_eqdec s s); congruence.
  Qed.

  (* Note that concat favors the right side *)
  Lemma tdot_over_concat_eq_r_arrow a (q₁ q₂:algenv) :
    (q₁ ⊕ ‵[| (a, q₂) |])·a ⇒ q₂.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    unfold tdot, edot, rec_concat_sort in H0.
    rewrite assoc_lookupr_drec_sort
    , (@assoc_lookupr_app string) in H0.
    simpl in H0.
    destruct (string_eqdec s s); [| congruence].
    invcs H0.
    split; trivial.
    intros.
    input_well_typed.
    dtype_inverter.
    unfold edot.
    rewrite assoc_lookupr_drec_sort
    , (@assoc_lookupr_app string).
    simpl.
    destruct (string_eqdec s s); [| congruence].
    trivial.
  Qed.

  Lemma tdot_over_concat_neq_r_arrow a₁ a₂ (q₁ q₂:algenv) :
    a₁ <> a₂ ->
    (q₁ ⊕ ‵[| (a₁, q₂) |])·a₂ ⇒ q₁·a₂.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    unfold tdot, edot, rec_concat_sort in H1.
    rewrite assoc_lookupr_drec_sort
    , (@assoc_lookupr_app string) in H1.
    simpl in H1.
    destruct (string_eqdec a₂ s); [congruence | ].
    split.
    - inferer.
    - intros.
      input_well_typed.
      dtype_inverter.
    unfold edot, rec_concat_sort.
    rewrite assoc_lookupr_drec_sort
    , (@assoc_lookupr_app string).
    simpl.
    destruct (string_eqdec a₂ s); [congruence | ].
    trivial.
  Qed.

  Lemma tdot_over_concat_neq_l_arrow a₁ a₂ (q₁ q₂:algenv) :
    a₁ <> a₂ ->
    (‵[| (a₁, q₁) |] ⊕ q₂ )·a₂ ⇒ q₂·a₂.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    unfold tdot, edot, rec_concat_sort in H1.
    rewrite assoc_lookupr_drec_sort
    , (@assoc_lookupr_app string) in H1.
    simpl in H1.
    destruct (string_eqdec a₂ s); [congruence | ].
    match_case_in H1; intros; rewrite H0 in H1; invcs H1.
    split.
    - inferer.
    - intros.
      input_well_typed.
      dtype_inverter.
      unfold edot, rec_concat_sort.
      rewrite assoc_lookupr_insertion_sort_insert_neq; trivial.
      rewrite assoc_lookupr_drec_sort.
      trivial.
  Qed.

  (* [ a₁ : q₁; a₂ : q₂ ].a₂ ⇒ q₂ *)

  Lemma tenvdot_from_duplicate_r_arrow a₁ a₂ (q₁ q₂:algenv) :
    (‵[| (a₁, q₁) |] ⊕ ‵[| (a₂, q₂) |])·a₂ ⇒ q₂.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer. econstructor; eauto.
    - unfold tdot, edot in H0.
      unfold rec_concat_sort in H0.
      simpl in H0.
      destruct (StringOrder.lt_dec s s1); simpl in H0.
      destruct (string_eqdec s1 s1); try congruence.
      destruct (StringOrder.lt_dec s1 s); simpl in H0.
      destruct (string_eqdec s1 s); try congruence.
      destruct (string_eqdec s1 s1); try congruence.
      destruct (string_eqdec s1 s1); try congruence.
    - intros.
      input_well_typed.
      destruct (StringOrder.lt_dec s s1); simpl in H0.
      unfold edot; simpl.
      destruct (string_eqdec s1 s1); try congruence.
      destruct (StringOrder.lt_dec s1 s); simpl in H0.
      unfold edot; simpl.
      destruct (string_eqdec s1 s); try congruence.
      destruct (string_eqdec s1 s1); try congruence.
      unfold edot; simpl.
      destruct (string_eqdec s1 s1); try congruence.
  Qed.

  (* a₁ <> a₂ -> [ a₁ : q₁; a₂ : q₂ ].a₁ ⇒ q₁ *)

  Lemma tenvdot_from_duplicate_l_arrow a₁ a₂ (q₁ q₂:algenv) :
    a₁ <> a₂ -> (‵[| (a₁, q₁) |] ⊕ ‵[| (a₂, q₂) |])·a₁ ⇒ q₁.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer. econstructor; eauto.
    - unfold tdot, edot in H1.
      unfold rec_concat_sort in H1.
      simpl in H1.
      destruct (StringOrder.lt_dec s s1); simpl in H1.
      destruct (string_eqdec s s1); try congruence.
      destruct (string_eqdec s s); try congruence.
      destruct (StringOrder.lt_dec s1 s); simpl in H1.
      destruct (string_eqdec s s); try congruence.
      assert (s = s1) by (apply lt_contr1; assumption).
      congruence.
    - intros.
      input_well_typed.
      destruct (StringOrder.lt_dec s s1); simpl in H1.
      unfold edot; simpl.
      destruct (string_eqdec s s1); try congruence.
      destruct (string_eqdec s s); try congruence.
      destruct (StringOrder.lt_dec s1 s); simpl in H1.
      unfold edot; simpl.
      destruct (string_eqdec s s); try congruence.
      assert (s = s1) by (apply lt_contr1; assumption).
      congruence.
  Qed.

  (* { [ a₁ : q₁ ] } × { [ a₂ : q₂ ] } ⇒ { [ a₁ : q₁; a₂ : q₂ ] } *)

  Lemma tproduct_singletons_arrow a₁ a₂ q₁ q₂:
    ‵{|‵[| (a₁, q₁) |] |} × ‵{| ‵[| (a₂, q₂) |] |} ⇒
     ‵{|‵[| (a₁, q₁) |] ⊕ ‵[| (a₂, q₂) |] |}.
  Proof.
    apply (rewrites_typed_with_untyped _ _ (product_singletons a₁ a₂ q₁ q₂)).
    intros.
    inferer.
    repeat (econstructor; eauto).
    Grab Existential Variables.
    eauto. eauto.
  Qed.

  Lemma tconcat_over_rec_eq s p₁ p₂ :
     ‵[| (s, p₁) |] ⊕ ‵[| (s, p₂) |] ⇒ ‵[| (s, p₂) |].
   Proof.
     red; intros.
     inverter.
     split; simpl.
     - revert pf3.
       unfold rec_concat_sort; simpl.
       destruct (StringOrder.lt_dec s s);
         [ elim (ODT_lt_irr (odt:=ODT_string) s); trivial | ].
       intros; econstructor; eauto.
       econstructor; eauto.
     - intros.
       input_well_typed.
       destruct (StringOrder.lt_dec s s);
         [ elim (ODT_lt_irr (odt:=ODT_string) s); trivial | ].
       trivial.
   Qed.
   
  (* a₁ <> a₂ -> [ a₁ : q₁ ] ⊗ [ a₂ : q₂ ] ⇒ { [ a₁ : q₁ ; a₂ : q₂ ] } *)
  
  Lemma tmerge_concat_to_concat_arrow a₁ a₂ q₁ q₂:
    a₁ <> a₂ ->
    ‵[| (a₁, q₁)|] ⊗ ‵[| (a₂, q₂) |] ⇒ ‵{|‵[| (a₁, q₁)|] ⊕ ‵[| (a₂, q₂)|]|}.
  Proof.
    intros.
    apply (rewrites_typed_with_untyped _ _ (merge_concat_to_concat a₁ a₂ q₁ q₂ H)).
    intros.
    inferer.
    unfold merge_bindings in H2.
    simpl in H2.
    unfold compatible_with in H2.
    simpl in H2.
    destruct (equiv_dec s s1); try congruence.
    simpl in H2.
    inversion H2.
    repeat (econstructor; eauto).
    Grab Existential Variables.
    eauto. eauto.
  Qed.
    
  (* a₁ <> a₂ -> [ a₁ : q₁ ] ⊗ ([ a₁ : q₁ ] ⊕ [ a₂ : q₂ ]) ⇒ { [ a₁ : q₁ ; a₂ : q₂ ] } *)
  
  Lemma tmerge_with_concat_to_concat_arrow a₁ a₂ q₁ q₂:
    a₁ <> a₂ ->
    ‵[| (a₁, q₁)|] ⊗ (‵[| (a₁, q₁) |] ⊕ ‵[| (a₂, q₂) |]) ⇒ ‵{|‵[| (a₁, q₁)|] ⊕ ‵[| (a₂, q₂)|]|}.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto.
    - unfold merge_bindings in H2; simpl in H2.
      unfold compatible_with in H2; simpl in H2.
      unfold rec_concat_sort in H2; simpl in H2.
      destruct (StringOrder.lt_dec s s1); simpl in *.
      + destruct (equiv_dec s s1); try congruence.
        destruct (equiv_dec s s); try congruence.
        destruct (@equiv_dec rtype (@eq rtype) (@eq_equivalence rtype)
                             rtype_eq_dec s3 s0); simpl in H2; try congruence.
        rewrite e0 in *; clear e0.
        destruct (StringOrder.lt_dec s s1); try congruence.
        simpl in H2.
        destruct (StringOrder.lt_dec s s); try congruence.
        assert False by (apply (lt_contr3 s); assumption); contradiction.
        inversion H2.  subst; clear H2.
        repeat econstructor; eauto.
        unfold rec_concat_sort in *.
        rewrite sort_sorted_is_id. reflexivity.
        assumption.
      + simpl in *.
        destruct (StringOrder.lt_dec s1 s); simpl in *; try congruence.
        * destruct (equiv_dec s s); try congruence; simpl.
          destruct (@equiv_dec rtype (@eq rtype) (@eq_equivalence rtype)
                             rtype_eq_dec s3 s0); simpl in H2; try congruence.
          rewrite e0 in *; clear e0 e.
          destruct (StringOrder.lt_dec s1 s); try congruence; simpl in *.
          destruct (StringOrder.lt_dec s s1); try congruence; simpl in *.
          destruct (StringOrder.lt_dec s1 s); try congruence; simpl in *.
          destruct (StringOrder.lt_dec s s); try congruence; simpl in *.
          assert False by (apply (lt_contr3 s); assumption); contradiction.
          inversion H2; clear H2; subst.
          repeat econstructor; eauto.
          rewrite drec_concat_sort_app_comm.
          unfold rec_concat_sort.
          rewrite sort_sorted_is_id. reflexivity.
          assumption.
          simpl.
          constructor. simpl.
          unfold not; intros.
          elim H0; auto; intros.
          constructor; auto.
          constructor.
        * destruct (equiv_dec s s1); try congruence; simpl in *.
          destruct (StringOrder.lt_dec s s1); try congruence; simpl in *.
          destruct (StringOrder.lt_dec s1 s); try congruence; simpl in *.
          assert (s = s1).
          apply lt_contr1; assumption.
          congruence.
    - intros. input_well_typed.
      destruct (StringOrder.lt_dec s s1); try congruence; simpl.
      + unfold merge_bindings; simpl.
        unfold compatible_with; simpl.
        destruct (equiv_dec s s1); try congruence.
        destruct (equiv_dec s s); try congruence.
        destruct (equiv_dec dout dout); try congruence.
        simpl.
        unfold rec_concat_sort; simpl.
        destruct (StringOrder.lt_dec s s1); try congruence; simpl.
        destruct (StringOrder.lt_dec s s); try congruence; simpl.
        assert False. apply (lt_contr3 s); assumption. contradiction.
      + destruct (StringOrder.lt_dec s1 s); try congruence; simpl.
        * unfold merge_bindings; simpl.
          unfold compatible_with; simpl.
          destruct (equiv_dec s s); try congruence.
          destruct (equiv_dec s s1); try congruence.
          destruct (equiv_dec dout dout); try congruence.
          simpl.
          unfold rec_concat_sort; simpl.
          destruct (StringOrder.lt_dec s1 s); try congruence; simpl.
          destruct (StringOrder.lt_dec s s1); try congruence; simpl.
          destruct (StringOrder.lt_dec s1 s); try congruence; simpl.
          destruct (StringOrder.lt_dec s s); try congruence; simpl.
          assert False. apply (lt_contr3 s); assumption. contradiction.
        * unfold merge_bindings; simpl.
          unfold compatible_with; simpl.
          destruct (equiv_dec s s1); try congruence; simpl.
          assert (s = s1).
          apply lt_contr1; assumption.
          congruence.
          Grab Existential Variables.
          eauto. eauto. eauto. eauto.
  Qed.

  (*************
   * Selection *
   *************)

  Lemma tselect_over_nil q : σ⟨ q ⟩(‵{||}) ⇒ ‵{||}.
  Proof.
    apply rewrites_typed_with_untyped.
    - apply select_over_nil.
    - intros; inverter.
  Qed.

  (* σ⟨ q₁ ∧ q₂ ⟩( q ) ⇒ σ⟨ q₂ ∧ q₁ ⟩( q ) *)

  Lemma tselect_and_comm_arrow (q q₁ q₂:algenv) :
    σ⟨ q₁ ∧ q₂ ⟩(q) ⇒ σ⟨ q₂ ∧ q₁ ⟩(q).
  Proof.
    rewrite tand_comm_arrow.
    reflexivity.
  Qed.
      
  Lemma tselect_and_comm {τc τenv τin τ} (q ql qr: m ⊧ τin ⇝ Coll τ ⊣ τc;τenv)
        (q₁ q₂: m ⊧ τ ⇝ Bool ⊣ τc;τenv) :
    (`ql = σ⟨ `q₂ ∧ `q₁ ⟩(`q)) ->
    (`qr = σ⟨ `q₁ ∧ `q₂ ⟩(`q)) ->
    ql ≡τ qr.
  Proof.
    intros.
    apply talg_rewrites_eq_is_typed_eq.
    rewrite H; rewrite H0.
    apply tselect_and_comm_arrow.
  Qed.

  (* σ⟨ q₁ ⟩(σ⟨ q₂ ⟩( q )) ⇒ σ⟨ q₂ ∧ q₁ ⟩( q ) *)

  Lemma tselect_and_arrow (q q₁ q₂:algenv) :
    σ⟨ q₁ ⟩(σ⟨ q₂ ⟩(q)) ⇒ σ⟨ q₂ ∧ q₁ ⟩(q).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    split;[inferer|idtac]; intros.
    input_well_typed.
    dtype_inverter.
    autorewrite with alg.
    apply lift_dcoll_inversion.
    clear eout.
    inversion τout; clear τout; subst.
    rtype_equalizer. subst.
    induction dout; try reflexivity; simpl in *.
    inversion H1; clear H1; subst.
    specialize (IHdout H4); clear H4.
    rewrite <- IHdout; clear IHdout.
    simpl.
    input_well_typed. subst; simpl.
    dtype_inverter. simpl.
    destruct (lift_filter
                (fun x' : data =>
                   match brand_relation_brands ⊢ₑ q₂ @ₑ x' ⊣ c;env with
                   | Some (dbool b0) => Some b0
                   | _ => None
                   end) dout).
    + destruct x1; simpl.
      * input_well_typed.
        dtype_inverter.
        inversion eout0; subst.
        reflexivity.
      * input_well_typed.
        destruct (lift_filter
                    (fun x' : data =>
                       match brand_relation_brands ⊢ₑ q₁ @ₑ x' ⊣ c;env with
                         | Some (dbool b0) => Some b0
                         | _ => None
                       end) l); reflexivity.
    + destruct (brand_relation_brands ⊢ₑ q₁ @ₑ a ⊣ c;env); try reflexivity.
  Qed.
  
  (* σ⟨ q₂ ∧ q₁ ⟩( q ) ⇒ σ⟨ q₁ ⟩(σ⟨ q₂ ⟩( q )) *)

  Lemma selection_split_and (q q₁ q₂:algenv) :
    σ⟨ q₂ ∧ q₁ ⟩(q) ⇒ σ⟨ q₁ ⟩(σ⟨ q₂ ⟩(q)).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    split;[inferer|idtac]; intros.
    input_well_typed.
    dtype_inverter.
    autorewrite with alg.
    apply lift_dcoll_inversion.
    clear eout.
    inversion τout; clear τout; subst.
    rtype_equalizer. subst.
    induction dout; try reflexivity; simpl in *.
    inversion H1; clear H1; subst.
    specialize (IHdout H3); clear H3.
    rewrite IHdout; clear IHdout.
    simpl.
    input_well_typed. subst; simpl.
    dtype_inverter. simpl.
    destruct (lift_filter
                (fun x' : data =>
                   match brand_relation_brands ⊢ₑ q₂ @ₑ x' ⊣ c;env with
                   | Some (dbool b0) => Some b0
                   | _ => None
                   end) dout).
    + destruct x1; simpl.
      * input_well_typed.
        dtype_inverter.
        inversion eout0; subst.
        reflexivity.
      * input_well_typed.
        destruct (lift_filter
                    (fun x' : data =>
                       match brand_relation_brands ⊢ₑ q₁ @ₑ x' ⊣ c;env with
                         | Some (dbool b0) => Some b0
                         | _ => None
                       end) l); reflexivity.
    + destruct (brand_relation_brands ⊢ₑ q₁ @ₑ a ⊣ c;env); try reflexivity.
  Qed.

  (* From Ullman's database book:
      (* Relational rewrite: σ⟨ q₂ ∧ q₁ ⟩( q ) = σ⟨ q₁ ⟩(σ⟨ q₂ ⟩( q ))
         Notes:
          - This rewrite is only true in the absence of
            failure (i.e., for well-typed queries) *)

      Lemma selection_split_and (q q₁ q₂:algenv) :
        σ⟨ q₂ ∧ q₁ ⟩(q) ⇒ σ⟨ q₁ ⟩(σ⟨ q₂ ⟩(q)).
      Proof.
        ...
      Qed.

      (* Relational rewrite: σ⟨ q₂ ∨ q₁ ⟩( q ) = σ⟨ q₁ ⟩( q ) ⋃ σ⟨ q₂ ⟩( q )
         Notes:
          - Over bags rather than sets, this is true for
            'maximal union', but not for 'additive union' *)
      
      Lemma selection_split_or (q q₁ q₂:algenv) :
        σ⟨ q₂ ∨ q₁ ⟩( q ) ⇒ σ⟨ q₁ ⟩( q ) ⋃max σ⟨ q₂ ⟩( q ).
      Proof.
        ...
      Qed.

 *)
  
  Lemma tselect_and {τc τenv τin τ} (q ql qr: m ⊧ τin ⇝ (Coll τ) ⊣ τc;τenv) (q₁ q₂:m ⊧ τ ⇝ Bool ⊣ τc;τenv) :
    (`ql = σ⟨ `q₁ ⟩(σ⟨ `q₂ ⟩(`q))) ->
    (`qr = σ⟨ `q₂ ∧ `q₁ ⟩(`q)) ->
    (ql ≡τ qr).
  Proof.
    intros.
    apply talg_rewrites_eq_is_typed_eq.
    rewrite H; rewrite H0.
    apply tselect_and_arrow.
  Qed.

  (* σ⟨ q₁ ⟩(σ⟨ q₂ ⟩( q )) ⇒ σ⟨ q₂ ⟩(σ⟨ q₁ ⟩( q )) *)

  Lemma tselect_comm_arrow (q q₁ q₂:algenv) :
    σ⟨ q₁ ⟩(σ⟨ q₂ ⟩( q )) ⇒ σ⟨ q₂ ⟩(σ⟨ q₁ ⟩( q )).
  Proof.
    unfold talgenv_rewrites_to; intros.
    assert (exists τ, σ⟨ q₁ ⟩(σ⟨ q₂ ⟩( q )) ▷ τin >=> Coll τ ⊣ τc;τenv) by inferer.
    split; try assumption; intros.
    inferer.
    elim H0; clear H0; intros τ; intros.
    clear H τout.
    assert (σ⟨ q₂ ⟩(σ⟨ q₁ ⟩( q )) ▷ τin >=> Coll τ ⊣ τc;τenv) by inferer.
    assert (q ▷ τin >=> Coll τ ⊣ τc;τenv) by inferer.
    assert (q₁ ▷ τ >=> Bool ⊣ τc;τenv) by inferer.
    assert (q₂ ▷ τ >=> Bool ⊣ τc;τenv) by inferer.
    assert (σ⟨ q₁ ∧ q₂ ⟩( q ) ▷ τin >=> Coll τ ⊣ τc;τenv) by eauto.
    assert (σ⟨ q₂ ∧ q₁ ⟩( q ) ▷ τin >=> Coll τ ⊣ τc;τenv) by eauto.
    rewrite (tselect_and (exist _ q H1)
                         (exist _ (σ⟨ q₁ ⟩( σ⟨ q₂ ⟩( q ))) H0)
                         (exist _ (σ⟨ q₂ ∧ q₁ ⟩( q )) H5)
                         (exist _ q₁ H2) (exist _ q₂ H3)); try assumption; try reflexivity.
    rewrite (tselect_and (exist _ q H1)
                         (exist _ (σ⟨ q₂ ⟩( σ⟨ q₁ ⟩( q ))) H)
                         (exist _ (σ⟨ q₁ ∧ q₂ ⟩( q )) H4)
                         (exist _ q₂ H3) (exist _ q₁ H2)); try assumption; try reflexivity.
    assert (q₁ ∧ q₂ ▷ τ >=> Bool ⊣ τc;τenv) by eauto.
    assert (q₂ ∧ q₁ ▷ τ >=> Bool ⊣ τc;τenv) by eauto.
    rewrite (tselect_and_comm
               (exist _ q H1)
               (exist _ (σ⟨q₂ ∧ q₁ ⟩( q )) H5)
               (exist _ (σ⟨q₁ ∧ q₂ ⟩( q )) H4)
               (exist _ q₁ H2) (exist _ q₂ H3) eq_refl eq_refl); intros; try assumption; reflexivity.
  Qed.
    
  Lemma tselect_comm {τc τenv τin τ} (q₁ q₂:m ⊧ τ ⇝ Bool ⊣ τc;τenv) (q ql qr: m ⊧ τin ⇝ (Coll τ) ⊣ τc;τenv) :
    (`ql = σ⟨ `q₁ ⟩(σ⟨ `q₂ ⟩(`q))) ->
    (`qr = σ⟨ `q₂ ⟩(σ⟨ `q₁ ⟩(`q))) ->
    ql ≡τ qr.
  Proof.
    intros.
    apply talg_rewrites_eq_is_typed_eq.
    rewrite H; rewrite H0.
    apply tselect_comm_arrow.
  Qed.


  (***********
   * Flatten *
   ***********)
  
  (* ♯flatten({ q }) ⇒ q *)
  
  Lemma tenvflatten_coll {τc τenv τin τout} (q:m ⊧ τin ⇝ Coll τout ⊣ τc;τenv) (ql qr:m ⊧ τin ⇝ Coll τout ⊣ τc;τenv):
    (`ql = ♯flatten(‵{| `q |})) -> (`qr = `q) -> ql ≡τ qr.
  Proof.
    unfold talgenv_eq; intros.
    rewrite H; rewrite H0; clear H H0.
    dependent induction q; simpl.
    assert (exists d, brand_relation_brands ⊢ₑ x @ₑ x0 ⊣ c;env = Some (dcoll d)).
    - generalize (@typed_algenv_yields_typed_data m τc τenv τin (Coll τout) c env x0 x dt_c dt_env dt_x p); intros.
      elim H; clear H; intros.
      elim H; clear H; intros.
      inversion H0.
      exists dl. rewrite H2; assumption.
    - elim H; clear H; intros.
      rewrite H; simpl.
      rewrite app_nil_r; reflexivity.
  Qed.

  Lemma tenvflatten_coll_arrow (q:algenv):
    ♯flatten(‵{| q |}) ⇒ q.
  Proof.
    unfold talgenv_rewrites_to; intros; simpl.
    inferer.
    split; try assumption; intros.
    input_well_typed.
    dtype_inverter.
    rewrite app_nil_r; reflexivity.
  Qed.

  Lemma tenvflatten_nil_arrow :
    ♯flatten(‵{||}) ⇒ ‵{||}.
  Proof.
    apply (rewrites_typed_with_untyped _ _ (envflatten_nil)).
    intros. inferer.
    repeat (econstructor; simpl).
  Qed.
    
  (* ♯flatten(χ⟨ { q₁ } ⟩( q₂ )) ⇒ χ⟨ q₁ ⟩( q₂ ) *)
  
  Lemma tenvflatten_map_coll_arrow q₁ q₂ :
    ♯flatten(χ⟨ ‵{| q₁ |} ⟩( q₂ )) ⇒ χ⟨ q₁ ⟩( q₂ ).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (envflatten_map_coll q₁ q₂)).
    intros. inferer.
  Qed.

  Lemma tflatten_flatten_map_either_nil p₁ p₂ p₃ :
    ♯flatten( ♯flatten(χ⟨ANEither p₁ ‵{||} ◯ p₂⟩(p₃))) ⇒
     ♯flatten( χ⟨ANEither( ♯flatten(p₁)) ‵{||} ◯ p₂⟩(p₃)).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (flatten_flatten_map_either_nil p₁ p₂ p₃)).
    intros. inferer.
    repeat (econstructor; simpl; eauto).
  Qed.
    
  (* ♯flatten(χᵉ⟨{ q₁ }⟩) ⇒ χᵉ⟨ q₁ ⟩ *)
  
  Lemma tflatten_mapenv_coll_arrow q₁:
    ♯flatten(ANMapEnv (‵{| q₁ |})) ⇒ ANMapEnv q₁.
  Proof.
    apply (rewrites_typed_with_untyped _ _ (flatten_mapenv_coll q₁)).
    intros. inferer.
  Qed.

  (* ♯flatten(χ⟨ χ⟨ { q₃ } ⟩( q₁ ) ⟩( q₂ )) ⇒ χ⟨ { q₃ } ⟩(♯flatten(χ⟨ q₁ ⟩( q₂ ))) *)
  (* Not sure if this holds unless well-typed. There is a degenerate form with
     q₁ = ♯flatten(q₀) && q₃ = ID in ROptimEnv *)

  Lemma tdouble_flatten_map_coll_arrow q₁ q₂ q₃ :
    ♯flatten(χ⟨ χ⟨ ‵{| q₃ |} ⟩( q₁ ) ⟩( q₂ )) ⇒ χ⟨ ‵{| q₃ |} ⟩(♯flatten(χ⟨ q₁ ⟩( q₂ ))).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto.
    intros.
    input_well_typed.
    dtype_inverter.
    autorewrite with alg.
    clear eout H7.
    induction dout; try reflexivity.
    inversion τout.
    rtype_equalizer. subst.
    simpl.
    inversion H1; clear H1; subst.
    input_well_typed.
    dtype_inverter.
    simpl.
    assert (dcoll dout ▹ Coll τ₁) by (constructor; assumption).
    specialize (IHdout H); clear H.
    destruct (rmap
                   (fun x0 : data =>
                    olift
                      (fun d : data =>
                       lift_oncoll
                         (fun c1 : list data =>
                          lift dcoll
                            (rmap
                               (fun x1 : data =>
                                olift (fun d1 : data => Some (dcoll [d1]))
                                  (brand_relation_brands ⊢ₑ q₃ @ₑ x1 ⊣ c;env))
                               c1)) d)
                      (brand_relation_brands ⊢ₑ q₁ @ₑ x0 ⊣ c;env)) dout);
      destruct ((rmap (fun_of_algenv brand_relation_brands c q₁ env) dout)); simpl in *; try congruence.
    - unfold olift in *.
      case_eq (rflatten l0); intros; rewrite H in *.
      + rewrite (rflatten_cons dout0 l0 l1 H).
        rewrite rmap_over_app.
        destruct ((rmap
           (fun x0 : data =>
            match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
            | Some x' => Some (dcoll [x'])
            | None => None
            end) l1)); simpl in *; try congruence.
        destruct ((rmap
              (fun x0 : data =>
               match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
               | Some x' => Some (dcoll [x'])
               | None => None
               end) dout0)); simpl; try reflexivity.
        unfold lift in *.
        case_eq (rflatten l); intros.
        rewrite H0 in IHdout.
        inversion IHdout.
        rewrite (rflatten_cons l3 l l4).
        subst; reflexivity. assumption.
        rewrite H0 in IHdout; congruence.
        destruct (rmap
              (fun x0 : data =>
               match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
               | Some x' => Some (dcoll [x'])
               | None => None
               end) dout0); try reflexivity.
        simpl.
        rewrite (rflatten_cons_none); auto.
        unfold lift in IHdout.
        destruct (rflatten l); try congruence.
      + simpl in *.
        rewrite (rflatten_cons_none); simpl in *; auto.
        destruct ((rmap
              (fun x0 : data =>
               match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
               | Some x' => Some (dcoll [x'])
               | None => None
               end) dout0)); simpl.
        rewrite (rflatten_cons_none); simpl in *; auto.
        unfold lift in IHdout.
        destruct (rflatten l); try congruence.
        reflexivity.
    - destruct ((rmap
               (fun x0 : data =>
                olift (fun d1 : data => Some (dcoll [d1]))
                      (brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env)) dout0)); simpl.
        rewrite (rflatten_cons_none); simpl in *; auto.
        unfold lift in IHdout.
        destruct (rflatten l); try congruence.
        reflexivity.
    - case_eq (rflatten l); intros.
      rewrite H in IHdout.
      rewrite (rflatten_cons dout0 l l0); try assumption; simpl.
      rewrite rmap_over_app.
      simpl in IHdout.
      destruct ((rmap
                (fun x0 : data =>
                 olift (fun d1 : data => Some (dcoll [d1]))
                       (brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env)) l0)); simpl in *; try congruence.
      destruct (rmap
                  (fun x0 : data =>
                     olift (fun d1 : data => Some (dcoll [d1]))
                           (brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env)) dout0); try reflexivity.
      rewrite rflatten_cons_none; simpl in *; auto.
      destruct (rmap
                  (fun x0 : data =>
                     olift (fun d1 : data => Some (dcoll [d1]))
                           (brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env)) dout0); reflexivity.
    - destruct (rmap
                  (fun x0 : data =>
                     olift (fun d1 : data => Some (dcoll [d1]))
                           (brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env)) dout0); reflexivity.
  Qed.
  
  (* ♯flatten(χ⟨ σ⟨ q₁ ⟩({ q₂ }) ⟩(q₃)) ⇒ σ⟨ q₁ ⟩(χ⟨ q₂ ⟩(q₃)) *)
  
  Lemma tnested_map_over_singletons_arrow q₁ q₂ q₃:
    ♯flatten(χ⟨ σ⟨ q₁ ⟩(‵{|q₂|}) ⟩(q₃)) ⇒ σ⟨ q₁ ⟩(χ⟨ q₂ ⟩(q₃)).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto; intros.
    input_well_typed.
    dtype_inverter.
    autorewrite with alg.
    clear eout.
    induction dout; try reflexivity; simpl in *.
    inversion τout. subst.
    rtype_equalizer. subst.
    inversion H1. subst.
    assert (dcoll dout ▹ Coll τ₁) by (constructor; assumption).
    specialize (IHdout H); clear H τout.
    input_well_typed; simpl.
    dtype_inverter.
    destruct x0; simpl.
    - autorewrite with alg.
      destruct (rmap (fun_of_algenv brand_relation_brands c q₂ env) dout);
        destruct (rmap
              (fun x0 : data =>
               olift
                 (fun d : data =>
                  lift_oncoll
                    (fun c1 : list data =>
                     lift dcoll
                       (lift_filter
                          (fun x' : data =>
                           match
                             brand_relation_brands ⊢ₑ q₁ @ₑ x' ⊣ c;env
                           with
                           | Some (dbool b) => Some b
                           | Some _ => None
                           | None => None
                           end) c1)) d)
                 (olift (fun d1 : data => Some (dcoll [d1]))
                        (brand_relation_brands ⊢ₑ q₂ @ₑ x0 ⊣ c;env))) dout); simpl in *; try congruence.
      rewrite eout0; simpl.
      unfold lift in IHdout.
      case_eq (rflatten l0); intros.
      rewrite H in *.
      rewrite (rflatten_cons [dout0] l0 l1 H).
      destruct (lift_filter
         (fun x' : data =>
          match brand_relation_brands ⊢ₑ q₁ @ₑ x' ⊣ c;env with
          | Some (dbool b) => Some b
          | Some _ => None
          | None => None
          end) l); simpl in *.
      inversion IHdout; reflexivity.
      congruence.
      rewrite H in *.
      destruct (lift_filter
         (fun x' : data =>
          match brand_relation_brands ⊢ₑ q₁ @ₑ x' ⊣ c;env with
          | Some (dbool b) => Some b
          | Some _ => None
          | None => None
          end) l); simpl in *; try congruence.
      rewrite rflatten_cons_none; try reflexivity. assumption.
      rewrite eout0.
      destruct (lift_filter
                (fun x' : data =>
                 match brand_relation_brands ⊢ₑ q₁ @ₑ x' ⊣ c;env with
                 | Some (dbool b) => Some b
                 | Some _ => None
                 | None => None
                 end) l); simpl in *.
      congruence. reflexivity.
      rewrite rflatten_cons_none; try reflexivity.
      unfold lift in IHdout.
      destruct (rflatten l); try congruence.
    - destruct (rmap
                   (fun x0 : data =>
                    olift
                      (fun d : data =>
                       lift_oncoll
                         (fun c1 : list data =>
                          lift dcoll
                            (lift_filter
                               (fun x' : data =>
                                match
                                  brand_relation_brands ⊢ₑ q₁ @ₑ x' ⊣ c;env
                                with
                                | Some (dbool b) => Some b
                                | Some _ => None
                                | None => None
                                end) c1)) d)
                      (olift (fun d1 : data => Some (dcoll [d1]))
                             (brand_relation_brands ⊢ₑ q₂ @ₑ x0 ⊣ c;env))) dout);
      destruct (rmap (fun_of_algenv brand_relation_brands c q₂ env) dout); simpl in *; try congruence; try rewrite eout0.
      + destruct (lift_filter
                (fun x' : data =>
                 match brand_relation_brands ⊢ₑ q₁ @ₑ x' ⊣ c;env with
                 | Some (dbool b) => Some b
                 | Some _ => None
                 | None => None
                 end) l0); simpl in *; try congruence.
        case_eq (rflatten l); intros.
        rewrite H in *. inversion IHdout.  subst.
        rewrite (rflatten_cons [] l l1 H). reflexivity.
        rewrite H in *; simpl in *; congruence.
        rewrite rflatten_cons_none; try reflexivity.
        unfold lift in IHdout.
        destruct (rflatten l); try congruence.
      + rewrite rflatten_cons_none; try reflexivity.
        unfold lift in IHdout.
        destruct (rflatten l); try congruence.
      + destruct (lift_filter
                (fun x' : data =>
                 match brand_relation_brands ⊢ₑ q₁ @ₑ x' ⊣ c;env with
                 | Some (dbool b) => Some b
                 | Some _ => None
                 | None => None
                 end) l); simpl in *; congruence.
  Qed.

  (* ♯flatten(χ⟨ χ⟨ q₁ ⟩( σ⟨ q₂ ⟩( (ANEither { ID } {}) ◯ q₃ ) ) ⟩( q₄ ))
            ⇒ χ⟨ q₁ ⟩( σ⟨ q₂ ⟩( ♯flatten( χ⟨ (ANEither { ID } {}) ◯ q₃ ⟩( q₄ ) ) ) ) *)

  Lemma tflatten_over_double_map_with_either_arrow q₁ q₂ q₃ q₄ :
    ♯flatten(χ⟨ χ⟨ q₁ ⟩( σ⟨ q₂ ⟩( (ANEither (‵{|ID|}) ‵{||}) ◯ q₃ ) ) ⟩( q₄ ))
            ⇒ χ⟨ q₁ ⟩( σ⟨ q₂ ⟩( ♯flatten( χ⟨ (ANEither (‵{|ID|}) ‵{||}) ◯ q₃ ⟩( q₄ ) ) ) ).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto.
    - repeat (econstructor; eauto).
    - intros.
      input_well_typed.
      dtype_inverter.
      autorewrite with alg; simpl.
      clear eout.
      induction dout; try reflexivity; simpl.
      inversion τout.
      rtype_equalizer. subst.
      inversion H4.
      assert (dcoll dout ▹ Coll τ₁) by (constructor; assumption).
      specialize (IHdout H9); clear H9 τout; subst.
      input_well_typed.
      autorewrite with alg.
      destruct dout0; try reflexivity; simpl.
      (* left *)
      + simpl.
        unfold olift, lift in *; simpl in *.
        case_eq (rmap
                     (fun x0 : data =>
                      match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
                      | Some (dleft dl) => Some (dcoll [dl])
                      | Some (dright _) => Some (dcoll [])
                      | Some _ => None
                      | None => None
                      end) dout); intros; rewrite H in *; simpl in *.
        * case_eq (rflatten l); intros; rewrite H2 in *; simpl in *.
          Focus 2.
          rewrite rflatten_cons_none; try assumption.
          destruct (match brand_relation_brands ⊢ₑ q₂ @ₑ dout0 ⊣ c;env with
               | Some (dbool b) => Some b
               | Some _ => None
               | None => None
                    end); try reflexivity.
                    destruct ((if b then Some [dout0] else Some [])); try reflexivity.
          destruct (lift_oncoll
           (fun c1 : list data =>
            match
              rmap (fun_of_algenv brand_relation_brands c q₁ env) c1
            with
            | Some a' => Some (dcoll a')
            | None => None
            end) (dcoll l)); try reflexivity; simpl in *.
          destruct (rmap
           (fun x0 : data =>
            match
              match
                match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
                | Some (dleft dl) => Some (dcoll [dl])
                | Some (dright _) => Some (dcoll [])
                | Some _ => None
                | None => None
                end
              with
              | Some x' =>
                  lift_oncoll
                    (fun c1 : list data =>
                     match
                       lift_filter
                         (fun x'0 : data =>
                          match
                            brand_relation_brands ⊢ₑ q₂ @ₑ x'0 ⊣ c;env
                          with
                          | Some (dbool b0) => Some b0
                          | Some _ => None
                          | None => None
                          end) c1
                     with
                     | Some a' => Some (dcoll a')
                     | None => None
                     end) x'
              | None => None
              end
            with
            | Some x' =>
                lift_oncoll
                  (fun c1 : list data =>
                   match
                     rmap (fun_of_algenv brand_relation_brands c q₁ env) c1
                   with
                   | Some a' => Some (dcoll a')
                   | None => None
                   end) x'
            | None => None
            end) dout); try congruence.
          destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l0); try reflexivity.
          clear H1 H2; case_eq (rflatten l1); intros; rewrite H1 in *; try congruence.
          rewrite rflatten_cons_none; assumption.
          destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l0); try reflexivity.
          destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l0); try reflexivity.
          destruct (rmap
                 (fun x0 : data =>
                  match
                    match
                      match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
                      | Some (dleft dl) => Some (dcoll [dl])
                      | Some (dright _) => Some (dcoll [])
                      | Some _ => None
                      | None => None
                      end
                    with
                    | Some x' =>
                        lift_oncoll
                          (fun c1 : list data =>
                           match
                             lift_filter
                               (fun x'0 : data =>
                                match
                                  brand_relation_brands ⊢ₑ q₂ @ₑ x'0 ⊣ c;env
                                with
                                | Some (dbool b) => Some b
                                | Some _ => None
                                | None => None
                                end) c1
                           with
                           | Some a' => Some (dcoll a')
                           | None => None
                           end) x'
                    | None => None
                    end
                  with
                  | Some x' =>
                      lift_oncoll
                        (fun c1 : list data =>
                         match
                           rmap
                             (fun_of_algenv brand_relation_brands c q₁ env)
                             c1
                         with
                         | Some a' => Some (dcoll a')
                         | None => None
                         end) x'
                  | None => None
                  end) dout); try reflexivity.
          clear H1 H2; case_eq (rflatten l2); intros; rewrite H1 in *; try congruence.
          rewrite rflatten_cons_none; assumption.
          rewrite (rflatten_cons [dout0] l l0 H2); simpl in *.
          destruct (brand_relation_brands ⊢ₑ q₂ @ₑ dout0 ⊣ c;env); try reflexivity.
          destruct d; try reflexivity; simpl in *.
          destruct b; simpl in *.
          case_eq (lift_filter
           (fun x' : data =>
            match brand_relation_brands ⊢ₑ q₂ @ₑ x' ⊣ c;env with
            | Some (dbool b) => Some b
            | Some _ => None
            | None => None
            end) l0); intros; rewrite H9 in *; simpl in *.
          destruct (brand_relation_brands ⊢ₑ q₁ @ₑ dout0 ⊣ c;env); try reflexivity.
          destruct (rmap
                 (fun x0 : data =>
                  match
                    match
                      match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
                      | Some (dleft dl) => Some (dcoll [dl])
                      | Some (dright _) => Some (dcoll [])
                      | Some _ => None
                      | None => None
                      end
                    with
                    | Some x' =>
                        lift_oncoll
                          (fun c1 : list data =>
                           match
                             lift_filter
                               (fun x'0 : data =>
                                match
                                  brand_relation_brands ⊢ₑ q₂ @ₑ x'0 ⊣ c;env
                                with
                                | Some (dbool b) => Some b
                                | Some _ => None
                                | None => None
                                end) c1
                           with
                           | Some a' => Some (dcoll a')
                           | None => None
                           end) x'
                    | None => None
                    end
                  with
                  | Some x' =>
                      lift_oncoll
                        (fun c1 : list data =>
                         match
                           rmap
                             (fun_of_algenv brand_relation_brands c q₁ env)
                             c1
                         with
                         | Some a' => Some (dcoll a')
                         | None => None
                         end) x'
                  | None => None
                  end) dout); try congruence.
          case_eq (rflatten l2); intros;
          rewrite H10 in *; simpl in *.
          rewrite (rflatten_cons [d] l2 l3 H10); simpl in *.
          destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l1); try congruence; simpl.
          inversion IHdout; reflexivity.
          rewrite rflatten_cons_none; simpl.
          destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l1); try congruence; simpl.
          reflexivity. assumption.
          destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l1); try congruence; simpl.
          reflexivity.
          destruct (brand_relation_brands ⊢ₑ q₁ @ₑ dout0 ⊣ c;env); try reflexivity; simpl.
          destruct (rmap
           (fun x0 : data =>
            match
              match
                match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
                | Some (dleft dl) => Some (dcoll [dl])
                | Some (dright _) => Some (dcoll [])
                | Some _ => None
                | None => None
                end
              with
              | Some x' =>
                  lift_oncoll
                    (fun c1 : list data =>
                     match
                       lift_filter
                         (fun x'0 : data =>
                          match
                            brand_relation_brands ⊢ₑ q₂ @ₑ x'0 ⊣ c;env
                          with
                          | Some (dbool b) => Some b
                          | Some _ => None
                          | None => None
                          end) c1
                     with
                     | Some a' => Some (dcoll a')
                     | None => None
                     end) x'
              | None => None
              end
            with
            | Some x' =>
                lift_oncoll
                  (fun c1 : list data =>
                   match
                     rmap (fun_of_algenv brand_relation_brands c q₁ env) c1
                   with
                   | Some a' => Some (dcoll a')
                   | None => None
                   end) x'
            | None => None
            end) dout); try reflexivity; simpl.
          case_eq (rflatten l1); intros; rewrite H10 in *; simpl in *. congruence.
          rewrite rflatten_cons_none. reflexivity. assumption.
          destruct (rmap
           (fun x0 : data =>
            match
              match
                match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
                | Some (dleft dl) => Some (dcoll [dl])
                | Some (dright _) => Some (dcoll [])
                | Some _ => None
                | None => None
                end
              with
              | Some x' =>
                  lift_oncoll
                    (fun c1 : list data =>
                     match
                       lift_filter
                         (fun x'0 : data =>
                          match
                            brand_relation_brands ⊢ₑ q₂ @ₑ x'0 ⊣ c;env
                          with
                          | Some (dbool b) => Some b
                          | Some _ => None
                          | None => None
                          end) c1
                     with
                     | Some a' => Some (dcoll a')
                     | None => None
                     end) x'
              | None => None
              end
            with
            | Some x' =>
                lift_oncoll
                  (fun c1 : list data =>
                   match
                     rmap (fun_of_algenv brand_relation_brands c q₁ env) c1
                   with
                   | Some a' => Some (dcoll a')
                   | None => None
                   end) x'
            | None => None
            end) dout); destruct (lift_filter
           (fun x' : data =>
            match brand_relation_brands ⊢ₑ q₂ @ₑ x' ⊣ c;env with
            | Some (dbool b) => Some b
            | Some _ => None
            | None => None
            end) l0); try congruence; simpl in *.
          case_eq (rflatten l1); intros; rewrite H9 in *; simpl in *.
          rewrite (rflatten_cons [] l1 l3 H9); simpl. assumption.
          rewrite rflatten_cons_none; simpl.
          destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l2); congruence.
          assumption.
          case_eq (rflatten l1); intros; rewrite H9 in *; simpl in *. congruence.
          rewrite rflatten_cons_none; simpl. reflexivity.
          assumption.
        * destruct (match brand_relation_brands ⊢ₑ q₂ @ₑ dout0 ⊣ c;env with
               | Some (dbool b) => Some b
               | Some _ => None
               | None => None
                    end); try reflexivity.
          destruct ((if b then Some [dout0] else Some [])); try reflexivity.
          destruct (lift_oncoll
           (fun c1 : list data =>
            match
              rmap (fun_of_algenv brand_relation_brands c q₁ env) c1
            with
            | Some a' => Some (dcoll a')
            | None => None
            end) (dcoll l)); try reflexivity; simpl in *.
          destruct (rmap
           (fun x0 : data =>
            match
              match
                match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
                | Some (dleft dl) => Some (dcoll [dl])
                | Some (dright _) => Some (dcoll [])
                | Some _ => None
                | None => None
                end
              with
              | Some x' =>
                  lift_oncoll
                    (fun c1 : list data =>
                     match
                       lift_filter
                         (fun x'0 : data =>
                          match
                            brand_relation_brands ⊢ₑ q₂ @ₑ x'0 ⊣ c;env
                          with
                          | Some (dbool b0) => Some b0
                         | Some _ => None
                          | None => None
                          end) c1
                     with
                     | Some a' => Some (dcoll a')
                     | None => None
                     end) x'
              | None => None
              end
            with
            | Some x' =>
                lift_oncoll
                  (fun c1 : list data =>
                   match
                     rmap (fun_of_algenv brand_relation_brands c q₁ env) c1
                   with
                   | Some a' => Some (dcoll a')
                   | None => None
                   end) x'
            | None => None
            end) dout); try congruence.
          clear H; case_eq (rflatten l0); intros; rewrite H in *.
          congruence.
          rewrite rflatten_cons_none; assumption.
      (* right *)
      + simpl.
        unfold olift, lift in *; simpl in *.
        case_eq (rmap
                     (fun x0 : data =>
                      match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
                      | Some (dleft dl) => Some (dcoll [dl])
                      | Some (dright _) => Some (dcoll [])
                      | Some _ => None
                      | None => None
                      end) dout); intros; rewrite H in *; simpl in *.
        * case_eq (rflatten l); intros; rewrite H2 in *; simpl in *.
          Focus 2.
          rewrite rflatten_cons_none; try assumption.
          destruct (rmap
           (fun x0 : data =>
            match
              match
                match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
                | Some (dleft dl) => Some (dcoll [dl])
                | Some (dright _) => Some (dcoll [])
                | Some _ => None
                | None => None
                end
              with
              | Some x' =>
                  lift_oncoll
                    (fun c1 : list data =>
                     match
                       lift_filter
                         (fun x'0 : data =>
                          match
                            brand_relation_brands ⊢ₑ q₂ @ₑ x'0 ⊣ c;env
                          with
                          | Some (dbool b0) => Some b0
                          | Some _ => None
                          | None => None
                          end) c1
                     with
                     | Some a' => Some (dcoll a')
                     | None => None
                     end) x'
              | None => None
              end
            with
            | Some x' =>
                lift_oncoll
                  (fun c1 : list data =>
                   match
                     rmap (fun_of_algenv brand_relation_brands c q₁ env) c1
                   with
                   | Some a' => Some (dcoll a')
                   | None => None
                   end) x'
            | None => None
            end) dout); try congruence.
          clear H; case_eq (rflatten l0); intros; rewrite H in *; try congruence.
          rewrite rflatten_cons_none; assumption.
          destruct (rmap
                 (fun x0 : data =>
                  match
                    match
                      match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
                      | Some (dleft dl) => Some (dcoll [dl])
                      | Some (dright _) => Some (dcoll [])
                      | Some _ => None
                      | None => None
                      end
                    with
                    | Some x' =>
                        lift_oncoll
                          (fun c1 : list data =>
                           match
                             lift_filter
                               (fun x'0 : data =>
                                match
                                  brand_relation_brands ⊢ₑ q₂ @ₑ x'0 ⊣ c;env
                                with
                                | Some (dbool b) => Some b
                                | Some _ => None
                                | None => None
                                end) c1
                           with
                           | Some a' => Some (dcoll a')
                           | None => None
                           end) x'
                    | None => None
                    end
                  with
                  | Some x' =>
                      lift_oncoll
                        (fun c1 : list data =>
                         match
                           rmap
                             (fun_of_algenv brand_relation_brands c q₁ env)
                             c1
                         with
                         | Some a' => Some (dcoll a')
                         | None => None
                         end) x'
                  | None => None
                  end) dout); try reflexivity.
          clear H; case_eq (rflatten l1); intros; rewrite H in *; try congruence.
          rewrite (rflatten_cons [] l1 l2 H); simpl in *.
          rewrite (rflatten_cons [] l l0 H2); simpl in *.
          assumption.
          rewrite rflatten_cons_none; try assumption.
          rewrite (rflatten_cons [] l l0 H2); simpl in *.
          destruct (lift_filter
           (fun x' : data =>
            match brand_relation_brands ⊢ₑ q₂ @ₑ x' ⊣ c;env with
            | Some (dbool b) => Some b
            | Some _ => None
            | None => None
            end) l0); try congruence; simpl in *.
          rewrite (rflatten_cons [] l l0 H2); simpl in *.
          destruct (lift_filter
           (fun x' : data =>
            match brand_relation_brands ⊢ₑ q₂ @ₑ x' ⊣ c;env with
            | Some (dbool b) => Some b
            | Some _ => None
            | None => None
            end) l0); try congruence; simpl in *.
        * destruct (rmap
                 (fun x0 : data =>
                  match
                    match
                      match brand_relation_brands ⊢ₑ q₃ @ₑ x0 ⊣ c;env with
                      | Some (dleft dl) => Some (dcoll [dl])
                      | Some (dright _) => Some (dcoll [])
                      | Some _ => None
                      | None => None
                      end
                    with
                    | Some x' =>
                        lift_oncoll
                          (fun c1 : list data =>
                           match
                             lift_filter
                               (fun x'0 : data =>
                                match
                                  brand_relation_brands ⊢ₑ q₂ @ₑ x'0 ⊣ c;env
                                with
                                | Some (dbool b) => Some b
                                | Some _ => None
                                | None => None
                                end) c1
                           with
                           | Some a' => Some (dcoll a')
                           | None => None
                           end) x'
                    | None => None
                    end
                  with
                  | Some x' =>
                      lift_oncoll
                        (fun c1 : list data =>
                         match
                           rmap
                             (fun_of_algenv brand_relation_brands c q₁ env)
                             c1
                         with
                         | Some a' => Some (dcoll a')
                         | None => None
                         end) x'
                  | None => None
                  end) dout); try congruence.
          clear H; case_eq (rflatten l); intros; rewrite H in *; simpl in *.
          congruence.
          rewrite rflatten_cons_none; try reflexivity. assumption.
  Qed.

  (* ♯flatten(χ⟨χ⟨ q₁ ⟩( σ⟨ q₂ ⟩( { ID } ) ) ⟩( q₃ )) ⇒ χ⟨ q₁ ⟩( σ⟨ q₂ ⟩( q₃ ) ) *)

  Lemma tflatten_over_double_map_arrow q₁ q₂ q₃ :
    ♯flatten(χ⟨χ⟨ q₁ ⟩( σ⟨ q₂ ⟩(‵{|ID|}) ) ⟩( q₃ )) ⇒ χ⟨ q₁ ⟩( σ⟨ q₂ ⟩( q₃ ) ).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto.
    intros.
    input_well_typed; simpl.
    dtype_inverter; simpl.
    clear eout τout. 
    induction dout; try reflexivity; simpl.
    destruct (brand_relation_brands ⊢ₑ q₂ @ₑ a ⊣ c;env); try reflexivity; simpl.
    destruct d; try reflexivity; simpl.
    destruct b; try reflexivity; simpl in *; autorewrite with alg; simpl in *.
    - destruct (rmap
                  (fun x0 : data =>
                     olift
                       (fun d : data =>
                          lift_oncoll
                            (fun c1 : list data =>
                               lift dcoll
                                    (rmap
                                       (fun_of_algenv brand_relation_brands c q₁ env)
                                       c1)) d)
                       (lift dcoll
                             match
                               match
                                 brand_relation_brands ⊢ₑ q₂ @ₑ x0 ⊣ c;env
                               with
                               | Some (dbool b) => Some b
                               | Some _ => None
                               | None => None
                               end
                             with
                             | Some true => Some [x0]
                             | Some false => Some []
                             | None => None
                             end)) dout);
      destruct (lift_filter
                  (fun x' : data =>
                     match brand_relation_brands ⊢ₑ q₂ @ₑ x' ⊣ c;env with
                     | Some (dbool b) => Some b
                     | Some _ => None
                     | None => None
                     end) dout); simpl in *; try congruence.
      + destruct (brand_relation_brands ⊢ₑ q₁ @ₑ a ⊣ c;env); try reflexivity; simpl.
        unfold lift in *.
        case_eq (rflatten l); intros; rewrite H in *.
        destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l0); try congruence.
        rewrite (rflatten_cons [d] l l1 H).
        inversion IHdout; subst.
        reflexivity.
        destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l0); try congruence.
        rewrite rflatten_cons_none; try assumption; reflexivity.
      + destruct (brand_relation_brands ⊢ₑ q₁ @ₑ a ⊣ c;env); try reflexivity; simpl.
        unfold lift in *.
        case_eq (rflatten l); intros; rewrite H in *. congruence.
        rewrite rflatten_cons_none; try assumption.
      + destruct (brand_relation_brands ⊢ₑ q₁ @ₑ a ⊣ c;env); try reflexivity; simpl.
        destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l); try congruence.
        simpl in *; congruence.
        reflexivity.
      + destruct (brand_relation_brands ⊢ₑ q₁ @ₑ a ⊣ c;env); reflexivity.
    - destruct (rmap
                  (fun x0 : data =>
                     olift
                       (fun d : data =>
                          lift_oncoll
                            (fun c1 : list data =>
                               lift dcoll
                                    (rmap
                                       (fun_of_algenv brand_relation_brands c q₁ env)
                                       c1)) d)
                       (lift dcoll
                             match
                               match
                                 brand_relation_brands ⊢ₑ q₂ @ₑ x0 ⊣ c;env
                               with
                               | Some (dbool b) => Some b
                               | Some _ => None
                               | None => None
                               end
                             with
                             | Some true => Some [x0]
                             | Some false => Some []
                             | None => None
                             end)) dout);
      destruct (lift_filter
                  (fun x' : data =>
                     match brand_relation_brands ⊢ₑ q₂ @ₑ x' ⊣ c;env with
                     | Some (dbool b) => Some b
                     | Some _ => None
                     | None => None
                     end) dout); simpl in *; try congruence.
      + destruct (brand_relation_brands ⊢ₑ q₁ @ₑ a ⊣ c;env); try reflexivity; simpl.
        unfold lift in *.
        case_eq (rflatten l); intros; rewrite H in *.
        destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l0); try congruence.
        rewrite (rflatten_cons [] l l1 H).
        inversion IHdout; subst.
        reflexivity.
        destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l0); try congruence.
        rewrite rflatten_cons_none; try assumption; reflexivity.
        destruct (rmap (fun_of_algenv brand_relation_brands c q₁ env) l0); try congruence.
        unfold lift in *.
        case_eq (rflatten l); intros; rewrite H in *.
        rewrite (rflatten_cons [] l l2 H).
        inversion IHdout; subst.
        reflexivity.
        congruence.
        unfold lift in *.
        case_eq (rflatten l); intros; rewrite H in *. congruence.
        rewrite rflatten_cons_none; try assumption.
      + unfold lift in *.
        case_eq (rflatten l); intros; rewrite H in *. congruence.
        rewrite rflatten_cons_none; try assumption.
  Qed.

  Lemma tselect_over_flatten p₁ p₂ :
    σ⟨p₁⟩(♯flatten(p₂)) ⇒ ♯flatten(χ⟨σ⟨p₁⟩(ID)⟩(p₂)).
  Proof.
    apply rewrites_typed_with_untyped.
    - apply select_over_flatten.
    - intros.
      inverter. subst.
      econstructor; eauto.
  Qed.
  
  Lemma tselect_over_flatten_b p₁ p₂ :
    ♯flatten(χ⟨σ⟨p₁⟩(ID)⟩(p₂)) ⇒ σ⟨p₁⟩(♯flatten(p₂)).
  Proof.
    apply rewrites_typed_with_untyped.
    - symmetry; apply select_over_flatten.
    - intros.
      inverter. subst.
      econstructor; eauto.
  Qed.

  Lemma tmap_over_flatten p₁ p₂ :
    χ⟨p₁⟩(♯flatten(p₂)) ⇒ ♯flatten(χ⟨χ⟨p₁⟩(ID)⟩(p₂)).
  Proof.
    apply rewrites_typed_with_untyped.
    - apply map_over_flatten.
    - intros.
      inverter. subst.
      econstructor; eauto.
  Qed.

  Lemma tmap_over_flatten_b p₁ p₂ :
    ♯flatten(χ⟨χ⟨p₁⟩(ID)⟩(p₂)) ⇒ χ⟨p₁⟩(♯flatten(p₂)).
  Proof.
    apply rewrites_typed_with_untyped.
    - symmetry; apply map_over_flatten.
    - intros.
      inverter. subst.
      econstructor; eauto.
  Qed.

  Lemma tselect_over_either p₁ p₂ p₃ :
    σ⟨p₁⟩( ANEither p₂ p₃) ⇒ ANEither (σ⟨p₁⟩(p₂)) (σ⟨p₁⟩(p₃)).
  Proof.
    apply rewrites_typed_with_untyped.
    - apply select_over_either.
    - intros.
      inferer.
  Qed.
  
  (*******
   * Map *
   *******)

  Lemma tmap_over_nil q : χ⟨ q ⟩(‵{||}) ⇒ ‵{||}.
  Proof.
    apply rewrites_typed_with_untyped.
    - apply map_over_nil.
    - intros; inferer.
      repeat (econstructor; simpl).
  Qed.

  (* χ⟨ ID ⟩( q ) ⇒ q *)
  
  Lemma tenvmap_into_id_arrow q :
    χ⟨ ID ⟩( q ) ⇒ q.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    split; try assumption; intros; simpl.
    input_well_typed.
    dtype_inverter.
    clear eout.
    inversion τout; clear τout; subst.
    rtype_equalizer. subst.
    induction dout; try reflexivity.
    inversion H1; clear H1; subst.
    specialize (IHdout H3); clear H3.
    simpl.
    unfold lift in *.
    destruct (rmap (fun x : data => Some x) dout); congruence.
  Qed.

  (* χ⟨ q₁ ⟩( χ⟨ q₂ ⟩( q ) ) ⇒ χ⟨ q₁ ◯ q₂ ⟩( q ) *)

  Lemma tenvmap_map_compose_arrow q₁ q₂ q:
    χ⟨ q₁ ⟩( χ⟨ q₂ ⟩( q ) ) ⇒ χ⟨ q₁ ◯ q₂ ⟩( q ).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (envmap_map_compose q₁ q₂ q)).
    intros. inferer.
  Qed.
  
  (* χ⟨ q₁ ⟩( { q₂ } ) ⇒ { q₁ ◯ q₂ } *)

  Lemma tenvmap_singleton_arrow q₁ q₂:
    χ⟨ q₁ ⟩( ‵{| q₂ |} ) ⇒ ‵{| q₁ ◯ q₂ |}.
  Proof.
    apply (rewrites_typed_with_untyped _ _ (envmap_singleton q₁ q₂)).
    intros. inferer.
  Qed.
  
  (* χ⟨ q₂ ⟩(σ⟨ q₁ ⟩({ q })) ⇒ χ⟨ q₂ ◯ q ⟩(σ⟨ q₁ ◯ q ⟩({ ID })) *)

  Lemma tmap_full_over_select_arrow q q₁ q₂:
    χ⟨ q₂ ⟩(σ⟨ q₁ ⟩(‵{| q |})) ⇒ χ⟨ q₂ ◯ q ⟩(σ⟨ q₁ ◯ q ⟩(‵{| ID |})).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (map_full_over_select_id q₂ q₁ q)).
    intros.
    inferer.
    econstructor; eauto.
  Qed.

  Lemma tmap_over_map_split p₁ p₂ p₃ :
    χ⟨χ⟨p₁ ⟩( p₂) ⟩( p₃)  ⇒ χ⟨χ⟨p₁ ⟩( ID) ⟩(χ⟨p₂⟩(p₃)).
    apply (rewrites_typed_with_untyped _ _ (map_over_map_split p₁ p₂ p₃)).
    intros.
    inferer.
  Qed.
    
  (* Needs to be worked on, generalized ... *)
  (* χ⟨ ENV ⊗ ID ⟩(σ⟨ q₁ ⟩(ENV ⊗ q₂)) ⇒ χ⟨ { ID } ⟩(σ⟨ q₁ ⟩(ENV ⊗ q₂)) *)
  
  Lemma tflip_env6_arrow q₁ q₂:
    χ⟨ ENV ⊗ ID ⟩(σ⟨ q₁ ⟩(ENV ⊗ q₂)) ⇒ χ⟨ ‵{|ID|} ⟩(σ⟨ q₁ ⟩(ENV ⊗ q₂)).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto.
    - assert (merge_bindings τ₁ τ₂0 = Some τ₂0).
      apply (merge_idem τ₁ τ₂2 τ₂0 pf1 pf2); assumption.
      rewrite H2 in H; inversion H.
      inferer.
      econstructor; eauto.
      econstructor; eauto.
      assert (Rec Closed τ₂0 pf3 = Rec Closed τ₂0 pf4).
      apply rtype_fequal; reflexivity.
      rewrite <- H1; assumption.
    - intros.
      input_well_typed; simpl.
      dependent induction τout.
      rtype_equalizer.
      subst; simpl.
      case_eq env; intros; try reflexivity; simpl.
      subst.
      case_eq (merge_bindings l dl); intros; try reflexivity; simpl.
      autorewrite with alg.
      destruct (brand_relation_brands ⊢ₑ q₁ @ₑ drec l0 ⊣ c;(drec l)); try reflexivity; simpl.
      destruct d; try reflexivity; simpl.
      destruct b; try reflexivity; simpl.
      rewrite (merge_idem l dl l0); try reflexivity; try assumption.
      + dependent induction dt_env.
        rtype_equalizer. subst.
        apply (sorted_forall_sorted l rl0); assumption.
      + apply (sorted_forall_sorted dl rl); assumption.
    - econstructor; eauto.
      + assert (merge_bindings τ₁ τ₂0 = Some τ₂0).
        apply (merge_idem τ₁ τ₂2 τ₂0 pf1 pf2); assumption.
        rewrite H2 in H; inversion H.
        inferer.
        econstructor; eauto.
        econstructor; eauto.
        assert (Rec Open τ₂0 pf3 = Rec Open τ₂0 pf4).
        apply rtype_fequal; reflexivity.
        rewrite <- H1; assumption.
      + intros.
        input_well_typed; simpl.
        invcs τout.
        rtype_equalizer.
        subst; simpl.
        case_eq env; intros; try reflexivity; simpl.
        subst.
        case_eq (merge_bindings l dl); intros; try reflexivity; simpl.
        autorewrite with alg.
        destruct (brand_relation_brands ⊢ₑ q₁ @ₑ drec l0 ⊣ c;(drec l)); try reflexivity; simpl.
        destruct d; try reflexivity; simpl.
        destruct b; try reflexivity; simpl.
        rewrite (merge_idem l dl l0); try reflexivity; try assumption.
        * invcs dt_env.
          rtype_equalizer. subst.
          apply (sorted_forall_sorted l rl0); assumption.
        * apply (sorted_forall_sorted dl rl); assumption.
  Qed.

  Lemma tmap_over_either p₁ p₂ p₃ :
    χ⟨p₁⟩( ANEither p₂ p₃) ⇒ ANEither (χ⟨p₁⟩(p₂)) (χ⟨p₁⟩(p₃)).
  Proof.
    apply rewrites_typed_with_untyped.
    - apply envmap_over_either.
    - intros.
      inferer.
  Qed.

  Lemma tmap_over_either_app p₁ p₂ p₃ p₄:
    χ⟨p₁⟩( ANEither p₂ p₃ ◯ p₄) ⇒ ANEither (χ⟨p₁⟩(p₂)) (χ⟨p₁⟩(p₃)) ◯ p₄.
  Proof.
    apply rewrites_typed_with_untyped.
    - apply envmap_over_either_app.
    - intros.
      inferer.
  Qed.
  
  (********************
   * Compose Pushdown *
   ********************)

  (* d ◯ q ⇒ d *)
  
  Lemma tapp_over_const_arrow d q:
    (ANConst d) ◯ q ⇒ (ANConst d).
  Proof.
    unfold talgenv_rewrites_to; intros; simpl.
    inferer.
    econstructor; eauto.
    intros.
    input_well_typed.
    reflexivity.
  Qed.

  (* ENV ◯ q ⇒ ENV *)
  
  Lemma tapp_over_env_arrow q :
    ENV ◯ q ⇒ ENV.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto; intros.
    input_well_typed; reflexivity.
  Qed.

  (* q ◯ ID ⇒ q *)
  
  Lemma tapp_over_id_r_arrow q:
    q ◯ ID ⇒ q.
  Proof.
    apply (rewrites_typed_with_untyped _ _ (app_over_id q)).
    intros. inferer.
  Qed.
    
  (* ID ◯ q ⇒ q *)
  
  Lemma tapp_over_id_l_arrow q:
    ID ◯ q ⇒ q.
  Proof.
    apply (rewrites_typed_with_untyped _ _ (app_over_id_l q)).
    intros. inferer.
  Qed.
 
  (* (⊕u(q₁)) ◯ q₂ ⇒ ⊕u(q₁ ◯ q₂) *)

  Lemma tapp_over_unop_arrow u q₁ q₂:
    (ANUnop u q₁) ◯ q₂ ⇒ (ANUnop u (q₁ ◯ q₂)).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (app_over_unop u q₁ q₂)).
    intros. inferer.
  Qed.

  (* (q₂ ⊗b q₁) ◯ q ⇒ (q₂ ◯ q) ⊗b (q₁ ◯ q) *)
  (* This is a generalization, but duplicates the input... *)
  
  Lemma tapp_over_binop_arrow b q q₁ q₂:
    (ANBinop b q₂ q₁) ◯ q ⇒ (ANBinop b (q₂ ◯ q) (q₁ ◯ q)).
  Proof.
    intros.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto; intros.
    input_well_typed; reflexivity.
  Qed.

  (* χ⟨ q₁ ⟩( q₂ ) ◯ q ⇒ χ⟨ q₁ ⟩( q₂ ◯ q ) *)
  
  Lemma tapp_over_map_arrow q q₁ q₂:
    (χ⟨q₁⟩(q₂)) ◯ q ⇒ χ⟨ q₁ ⟩(q₂ ◯ q).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (app_over_map q q₁ q₂)).
    intros. inferer.
  Qed.

  (* ⋈ᵈ⟨ q₁ ⟩( q₂ ) ◯ q ⇒ ⋈ᵈ⟨ q₁ ⟩( q₂ ◯ q ) *)
  
  Lemma tapp_over_mapconcat_arrow q q₁ q₂:
    ⋈ᵈ⟨ q₁ ⟩( q₂ ) ◯ q ⇒ ⋈ᵈ⟨ q₁ ⟩( q₂ ◯ q ).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (app_over_mapconcat q q₁ q₂)).
    intros. inferer.
  Qed.

  (* σ⟨ q₁ ⟩( q₂ ) ◯ q ⇒ σ⟨ q₁ ⟩( q₂ ◯ q ) *)
 
  Lemma tapp_over_select_arrow q q₁ q₂:
    (σ⟨ q₁ ⟩( q₂ )) ◯ q ⇒ (σ⟨ q₁ ⟩( q₂ ◯ q )).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (app_over_select q q₁ q₂)).
    intros. inferer.
  Qed.
  
  Lemma tapp_over_select_back_arrow q q₁ q₂:
    (σ⟨ q₁ ⟩( q₂ ◯ q )) ⇒ (σ⟨ q₁ ⟩( q₂ )) ◯ q.
  Proof.
    apply rewrites_typed_with_untyped.
    - symmetry. apply app_over_select.
    - intros; inferer.
  Qed.

  (* (q₁ ◯ q₂) ◯ q₃ ⇒ q₁ ◯ (q₂ ◯ q₃) *)
  
  Lemma tapp_over_app_arrow q₁ q₂ q₃:
    (q₁ ◯ q₂) ◯ q₃ ⇒ q₁ ◯ (q₂ ◯ q₃).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (app_over_app q₁ q₂ q₃)).
    intros. inferer.
  Qed.

  Lemma tselect_over_app_either p₁ p₂ p₃ p₄ :
    σ⟨p₁⟩( ANEither p₂ p₃ ◯ p₄ ) ⇒ ANEither (σ⟨p₁⟩(p₂)) (σ⟨p₁⟩(p₃)) ◯ p₄.
  Proof.
    rewrite tapp_over_select_back_arrow.
    rewrite tselect_over_either.
    reflexivity.
  Qed.


  (************************
   * Compose-Env Pushdown *
   ************************)

  (* d ◯ᵉ q ⇒ d *)
  
  Lemma tappenv_over_const_arrow d q:
    (ANConst d) ◯ₑ q ⇒ (ANConst d).
  Proof.
    unfold talgenv_rewrites_to; intros; simpl.
    inferer.
    econstructor; eauto.
    intros.
    input_well_typed.
    reflexivity.
  Qed.
    
  (* ID ◯ᵉ q ⇒ ID *)
  
  Lemma tappenv_over_id_l_arrow q:
    ID ◯ₑ q ⇒ ID.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto; intros.
    input_well_typed; reflexivity.
  Qed.

  (* (ignores_id q₁) -> q₁ ◯ q₂ ⇒ q₁ *)
  
  Lemma tapp_over_ignoreid_arrow q₁ q₂:
    ignores_id q₁ -> q₁ ◯ q₂ ⇒ q₁.
  Proof.
    unfold talgenv_rewrites_to; intros; simpl.
    inferer.
    assert (q₁ ▷ τin >=> τout ⊣ τc;τenv)
           by (eapply tignores_id_swap; eauto).
    econstructor; eauto.
    intros.
    input_well_typed.
    rewrite (ignores_id_swap q₁ H _ _ env x dout) in eout1.
    congruence.
  Qed.
  
  (* ENV ◯ᵉ q ⇒ q *)
  
  Lemma tappenv_over_env_l_arrow q:
    ENV ◯ₑ q ⇒ q.
  Proof.
    apply (rewrites_typed_with_untyped _ _ (appenv_over_env q)).
    intros. inferer.
  Qed.

  (* q ◯ᵉ ENV ⇒ q *)
  
  Lemma tappenv_over_env_r_arrow q:
    q ◯ₑ ENV ⇒ q.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
  Qed.

  (* (⊕u(q₁)) ◯ᵉ q₂ ⇒ ⊕u(q₁ ◯ᵉ q₂) *)

  Lemma tappenv_over_unop_arrow u q₁ q₂:
    (ANUnop u q₁) ◯ₑ q₂ ⇒ (ANUnop u (q₁ ◯ₑ q₂)).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (appenv_over_unop u q₁ q₂)).
    intros. inferer.
  Qed.

  Lemma tunop_over_either u p₁ p₂ :
    ANUnop u (ANEither p₁ p₂)  ⇒ ANEither (ANUnop u p₁)(ANUnop u p₂).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (unop_over_either u p₁ p₂)).
    intros. inferer.
  Qed.

  Lemma tunop_over_either_app u p₁ p₂ p₃:
    ANUnop u (ANEither p₁ p₂ ◯ p₃) ⇒ ANEither (ANUnop u p₁)(ANUnop u p₂) ◯ p₃.
  Proof.
    apply (rewrites_typed_with_untyped _ _ (unop_over_either_app u p₁ p₂ p₃)).
    intros. inferer.
  Qed.

  (* (q₁ ⊗b q₂) ◯ᵉ ID ⇒ (q₁ ◯ᵉ ID) ⊗b (q₂ ◯ᵉ ID) *)
  
  Lemma tappenv_over_binop b q₁ q₂ q :
    (ANBinop b q₁ q₂) ◯ₑ q ⇒ (ANBinop b (q₁ ◯ₑ q) (q₂ ◯ₑ q)).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto; intros.
    input_well_typed.
    reflexivity.
  Qed.
    
  (* ignores_id q -> χ⟨ q₁ ⟩( q₂ ) ◯ᵉ q ⇒ χ⟨ q₁ ◯ᵉ q ⟩( q₂ ◯ᵉ q ) *)
  
  Lemma tappenv_over_map_arrow q q₁ q₂:
    ignores_id q ->
    χ⟨ q₁ ⟩( q₂ ) ◯ₑ q ⇒ χ⟨ q₁ ◯ₑ q ⟩( q₂ ◯ₑ q ).
  Proof.
    intros.
    apply (rewrites_typed_with_untyped _ _ (appenv_over_map q q₁ q₂ H)).
    intros; inferer.
    econstructor; eauto.
    econstructor; eauto.
    apply (tignores_id_swap q H _ _ _ τenv' τenv H3).
  Qed.

  (* ignores_env q₁ -> χ⟨ q₁ ⟩( q₂ ) ◯ᵉ q ⇒ χ⟨ q₁ ⟩( q₂ ◯ᵉ q ) *)
  
  Lemma tappenv_over_map_ignores_env_arrow q₁ q₂:
    ignores_env q₁ ->
    χ⟨ q₁ ⟩( q₂ ) ◯ₑ ANID ⇒ χ⟨ q₁ ◯ₑ ANID ⟩( q₂ ◯ₑ ANID ).
  Proof.
    unfold talgenv_rewrites_to; simpl; intros.
    inferer.
    econstructor; eauto.
    - econstructor; eauto.
      econstructor; eauto.
      apply (tignores_env_swap q₁ H _ _ _ _ _ H2).
    - intros.
      destruct (brand_relation_brands ⊢ₑ q₂ @ₑ x ⊣ c;x); try reflexivity; simpl.
      destruct d; try reflexivity; simpl.
      induction l; try reflexivity; simpl.
      rewrite (ignores_env_swap q₁ H _ c x a a).
      destruct (brand_relation_brands ⊢ₑ q₁ @ₑ a ⊣ c;a); try reflexivity; simpl.
      unfold lift in *.
      destruct (rmap (fun_of_algenv brand_relation_brands c q₁ x) l);
        destruct (rmap (fun x0 : data => brand_relation_brands ⊢ₑ q₁ @ₑ x0 ⊣ c;x0) l);
        simpl in *; congruence.
  Qed.

  (* σ⟨ q₁ ⟩( q₂ ) ◯ᵉ q ⇒ σ⟨ q₁ ◯ᵉ q ⟩( q₂ ◯ᵉ q ) *)
  
  Lemma tappenv_over_select_arrow q q₁ q₂:
    ignores_id q ->
    σ⟨ q₁ ⟩( q₂ ) ◯ₑ q ⇒ σ⟨ q₁ ◯ₑ q ⟩( q₂ ◯ₑ q ).
  Proof.
    intros.
    apply (rewrites_typed_with_untyped _ _ (appenv_over_select q q₁ q₂ H)).
    intros; inferer.
    econstructor; eauto.
    econstructor; eauto.
    apply (tignores_id_swap q H _ _ _ _ _ H3).
  Qed.
    
  (* (q₁ ◯ₑ q₂) ◯ₑ q ⇒ q₁ ◯ₑ (q₂ ◯ₑ q) *)
  
  Lemma tappenv_over_appenv_arrow q q₁ q₂:
    (q₁ ◯ₑ q₂) ◯ₑ q ⇒ q₁ ◯ₑ (q₂ ◯ₑ q).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto.
    intros.
    input_well_typed; reflexivity.
  Qed.
    
  (* (q₁ ◯ q₂) ◯ₑ q ⇒ (q₁ ◯ₑ q) ◯ (q₂ ◯ₑ q) *)
  
  Lemma tappenv_over_app_arrow q q₁ q₂:
    ignores_id q -> (q₁ ◯ q₂) ◯ₑ q ⇒ (q₁ ◯ₑ q) ◯ (q₂ ◯ₑ q).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto.
    - repeat econstructor; eauto.
      apply (tignores_id_swap q H _ τin τ1 τenv' τenv H3).
    - intros.
      input_well_typed; simpl.
      rewrite (ignores_id_swap q H _ _ env dout0 x).
      rewrite eout; simpl.
      rewrite eout1; reflexivity.
  Qed.

  Lemma tappenv_over_app_ie_arrow p1 p2 p3:
    ignores_env p3 ->
    ((p3 ◯ p2) ◯ₑ p1) ⇒ p3 ◯ (p2 ◯ₑ p1).
  Proof.
    intros.
    apply (rewrites_typed_with_untyped _ _ (appenv_over_app_ie p1 p2 p3 H)).
    intros; inferer.
    econstructor; eauto.
    apply (tignores_env_swap p3 H _ _ _ _ _ H8).
  Qed.
    
  (* (q₁ ◯ₑ q₂) ◯ q ⇒ (q₁ ◯ q) ◯ₑ (q₂ ◯ q) *)
  
  Lemma tapp_over_appenv_arrow q q₁ q₂:
    ignores_id q₁ -> (q₁ ◯ₑ q₂) ◯ q ⇒ q₁ ◯ₑ (q₂ ◯ q).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto.
    - econstructor; eauto.
      apply (tignores_id_swap q₁ H _ τ1 τin τout τenv' H8).
    - intros.
      input_well_typed; simpl.
      rewrite (ignores_id_swap q₁ H _ _ dout0 x dout).
      rewrite eout1; simpl; reflexivity.
  Qed.
    
  (* (ignores_env q₁) -> q₁ ◯ᵉ q₂ ⇒ q₁ *)
  
  Lemma tappenv_over_ignoreenv_arrow q₁ q₂:
    ignores_env q₁ -> q₁ ◯ₑ q₂ ⇒ q₁.
  Proof.
    unfold talgenv_rewrites_to; intros; simpl.
    inferer.
    assert (q₁ ▷ τin >=> τout ⊣ τc;τenv)
      by apply (tignores_env_swap q₁ H _ τin τout τenv' τenv H7).
    econstructor; eauto.
    intros.
    input_well_typed.
    rewrite (ignores_env_swap q₁ H _ _ env dout x) in eout1.
    rewrite eout0 in eout1.
    inversion eout1.
    reflexivity.
  Qed.

  (* ignores_env q₁ -> (ENV ⊗ q₁) ◯ₑ q ⇒ q ⊗ q₁ *)
  
  Lemma tappenv_over_env_merge_l_arrow q₁ q:
    ignores_env q₁ ->
    ANAppEnv (ENV ⊗ q₁) q ⇒ q ⊗ q₁.
  Proof.
    intros.
    apply (rewrites_typed_with_untyped _ _ (appenv_over_env_merge_l q₁ q H)); intros.
    inferer.
    econstructor; eauto.
    assert (q₁ ▷ τin >=> Rec Closed τ₂0 pf2 ⊣ τc;τenv)
      by apply (tignores_env_swap q₁ H _ τin (Rec Closed τ₂0 pf2) (Rec Closed τ₁0 pf1) τenv H10).
    eauto.
    econstructor; eauto.
    assert (q₁ ▷ τin >=> Rec Open τ₂0 pf2 ⊣ τc;τenv)
      by apply (tignores_env_swap q₁ H _ τin (Rec Open τ₂0 pf2) (Rec Open τ₁0 pf1) τenv H10).
    eauto.
  Qed.

  (* Needs to be worked on, generalized ... *)
  (* (χ⟨ ENV ⟩(σ⟨ q ⟩({ ID }))) ◯ᵉ ID ⇒ (χ⟨ ID ⟩(σ⟨ q ⟩({ ID }))) ◯ᵉ ID *)
  
  Lemma tflip_env1_arrow q :
    (χ⟨ ENV ⟩(σ⟨ q ⟩(‵{|ID|}))) ◯ₑ ID ⇒ σ⟨ q ⟩(‵{|ID|}) ◯ₑ ID.
  Proof.
    apply (rewrites_typed_with_untyped _ _ (flip_env1 q)).
    intros; inferer.
  Qed.

  (* This overlaps with the previous (but neither is more general...) *)
  Lemma tflip_env4_arrow q₁ q₂:
    ignores_env q₁ -> (χ⟨ENV⟩( σ⟨ q₁ ⟩(‵{|ID|}))) ◯ₑ q₂ ⇒ χ⟨q₂⟩( σ⟨ q₁ ⟩(‵{|ID|})).
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto.
    - repeat econstructor; eauto.
      apply (tignores_env_swap q₁ H _ τ₁ Bool τ₂ τenv H6).
    - intros.
      input_well_typed.
      rewrite (ignores_env_swap q₁ H _ _ env dout x).
      rewrite eout0.
      destruct dout0; try reflexivity.
      autorewrite with alg.
      unfold olift.
      destruct b; try reflexivity; simpl.
      rewrite eout.
      reflexivity.
  Qed.
 
  (* Needs to be worked on, generalized ... *)
  (* σ⟨ q ⟩(ID) ◯ᵉ ID) ⇒ σ⟨ q ◯ᵉ ID ⟩(ID). *)

  Lemma tflip_env2_arrow q :
    σ⟨ q ⟩(‵{|ID|}) ◯ₑ ID ⇒ σ⟨ q ◯ₑ ID ⟩(‵{|ID|}).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (flip_env2 q)).
    intros; inferer.
  Qed.

  (* ♯flatten(q₁ ◯ᵉ q₂) ⇒ ♯flatten(q₁) ◯ᵉ q₂ *)
  (* This is an odd one, rever from push appenv through unop, should be removed in some way *)
  
  Lemma tflatten_through_appenv_arrow q₁ q₂ :
    ♯flatten(q₁ ◯ₑ q₂) ⇒ ♯flatten(q₁) ◯ₑ q₂.
  Proof.
    apply (rewrites_typed_with_untyped _ _ (flatten_through_appenv q₁ q₂)).
    intros. inferer.
  Qed.

  Lemma tappenv_through_either q₁ q₂ q₃:
    ignores_id q₃ ->
    ANEither q₁ q₂ ◯ₑ q₃ ⇒ ANEither (q₁ ◯ₑ q₃) (q₂ ◯ₑ q₃).
  Proof.
    intros ig.
    apply (rewrites_typed_with_untyped _ _ (appenv_through_either q₁ q₂ q₃ ig)).
    intros. inferer.
    generalize (tignores_id_swap _ ig τc).
    econstructor;
      (econstructor; [| eassumption]; eauto). 
  Qed.

  (**********
   * MapEnv *
   **********)

  (* χᵉ⟨ ENV ⟩( q ) ⇒ ENV *)

  Lemma tmapenv_to_env_arrow q :
    (ANMapEnv (ENV)) ◯ q ⇒ ENV.
  Proof.
    unfold talgenv_rewrites_to; intros; simpl.
    inferer.
    econstructor; eauto.
    intros.
    input_well_typed; simpl.
    dtype_inverter.
    rewrite rmap_id.
    reflexivity.
  Qed.

  Lemma tmapenv_over_singleton_arrow q₁ q₂ :
    (ANMapEnv q₁) ◯ₑ (‵{|q₂|}) ⇒ ‵{| q₁ ◯ₑ q₂ |}.
  Proof.
    unfold talgenv_rewrites_to; intros.
    inferer.
    econstructor; eauto.
    intros.
    destruct (brand_relation_brands ⊢ₑ q₂ @ₑ x ⊣ c;env); try reflexivity; simpl.
    destruct (brand_relation_brands ⊢ₑ q₁ @ₑ x ⊣ c;d); reflexivity.
  Qed.

  (* ignores_id q₁ -> χᵉ⟨ q₁ ⟩(ID) ◯ᵉ q₂ ⇒ χ⟨ q₁ ◯ᵉ ID ⟩(q₂) *)
  
  Lemma tmapenv_to_map_arrow q₁ q₂:
    ignores_id q₁ ->
    (ANMapEnv q₁) ◯ₑ q₂ ⇒ χ⟨ q₁ ◯ₑ ID ⟩(q₂).
  Proof.
    intros.
    unfold talgenv_rewrites_to; simpl; intros.
    inferer; econstructor; eauto.
    - repeat econstructor; eauto.
      apply (tignores_id_swap q₁ H _ τin τenv0 τ₂ τenv0); assumption.
    - intros.
      input_well_typed.
      destruct dout; try reflexivity; simpl; clear eout τout H3.
      induction l; try reflexivity; simpl.
      rewrite (ignores_id_swap q₁ H _ _ a x a).
      destruct (brand_relation_brands ⊢ₑ q₁ @ₑ a ⊣ c;a); try reflexivity; simpl.
      destruct (rmap (fun env' : data => brand_relation_brands ⊢ₑ q₁ @ₑ x ⊣ c;env') l);
        destruct (rmap (fun x0 : data => brand_relation_brands ⊢ₑ q₁ @ₑ x0 ⊣ c;x0) l);
         simpl in *; congruence.
  Qed.


  (***********
   * Complex *
   ***********)
  
  (* ♯flatten(χᵉ⟨χ⟨ENV⟩(σ⟨ q₁ ⟩(‵{| ID |}))⟩) ◯ᵉ χ⟨ENV⟩(σ⟨ q₂ ⟩(‵{| ID |}))
       ⇒ χ⟨ ENV ⟩(σ⟨ q₁ ⟩(σ⟨ q₂ ⟩(‵{| ID |})) *)
  
  Lemma tcompose_selects_in_mapenv_arrow q₁ q₂ :
    (♯flatten(ANMapEnv (χ⟨ENV⟩(σ⟨ q₁ ⟩( ‵{| ID |}))))) ◯ₑ (χ⟨ENV⟩(σ⟨ q₂ ⟩( ‵{| ID |})))
                                                          ⇒ (χ⟨ENV⟩(σ⟨ q₁ ⟩(σ⟨ q₂ ⟩( ‵{| ID |})))).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (compose_selects_in_mapenv q₁ q₂)).
    intros; inferer.
  Qed.

  (* (χᵉ⟨ q ⟩) ◯ᵉ (ENV ⊗ [ a : ID ]) ⇒ χ⟨ (q ◯ ENV·a) ◯ᵉ ID ⟩(ENV ⊗ [ a : ID ]) *)
  
  Lemma tappenv_mapenv_to_map_arrow q a:
    ANAppEnv (ANMapEnv q) (ENV ⊗ ‵[| (a, ID)|]) ⇒
             χ⟨(q ◯ (ANUnop (ADot a) ANEnv)) ◯ₑ ID⟩( (ENV ⊗ ‵[| (a, ID)|]) ).
  Proof.
    unfold talgenv_rewrites_to; intros; simpl.
    inferer.
    econstructor; eauto.
    - assert (RSort.is_list_sorted ODT_lt_dec (domain τ₃) = true)
        by (unfold merge_bindings in *;
             destruct (compatible τ₁0 [x]); try discriminate;
            inversion H3;
            apply (@rec_concat_sort_sorted string ODT_string _ τ₁0 [x] (rec_concat_sort τ₁0 [x])); reflexivity).
      rename H into pf3.
      econstructor; eauto.
      econstructor; eauto.
      econstructor; eauto.
      econstructor; eauto.
      destruct τenv0; subst.
      destruct x0; try discriminate.
      assert (Rec Closed τ₃ pf3 = (exist (fun τ₀ : rtype₀ => wf_rtype₀ τ₀ = true) (Rec₀ k srl) e)).
      simpl in H1; inversion H1. subst.
      apply rtype_fequal; simpl. reflexivity.
      rewrite <- H.
      destruct x; simpl in *.
      assert (tdot τ₃ s = Some s0) by (apply (edot_merge_bindings τ₁0 τ₃ s s0); assumption).
      apply ATDot; assumption.
      econstructor; eauto.
      assert (Rec Closed τ₃ pf3 = τenv0)
      by (apply rtype_fequal; simpl in *; assumption).
      rewrite <- H in *.
      generalize (@ATMergeConcat _ _ _ _ _ _ τ₁0 [(fst x, snd x)] τ₃ pf1 eq_refl pf3); intros.
      destruct x; simpl in *.
      apply (H2 H3).
    - intros.
      input_well_typed.
      invcs dt_env; rtype_equalizer.
      subst.
      specialize (H6 (eq_refl _)).
      subst.
      destruct x; simpl.
      case_eq (merge_bindings dl [(s, x0)]); intros; try reflexivity; subst; simpl.
      rewrite (edot_merge_bindings dl l s x0); simpl.
      reflexivity.
      trivial.
  Qed.

  (* ♯flatten(χᵉ⟨ q ⟩) ◯ᵉ (ENV ⊗ [ a : ID ])
   ⇒ ♯flatten(χ⟨ ( q ◯ ENV·a ) ◯ᵉ ID ⟩( ENV ⊗ [ a : ID ])) *)
  
  Lemma tappenv_flatten_mapenv_to_map_arrow q a:
    ANAppEnv (♯flatten(ANMapEnv q)) (ENV ⊗ ‵[| (a, ID)|]) ⇒
           ♯flatten(χ⟨(q ◯ (ANUnop (ADot a) ANEnv)) ◯ₑ ID⟩( (ENV ⊗ ‵[| (a, ID)|]) )).
  Proof.
    unfold talgenv_rewrites_to; intros; simpl.
    inferer.
    econstructor; eauto.
    - assert (RSort.is_list_sorted ODT_lt_dec (domain τ₃) = true)
        by (unfold merge_bindings in *;
             destruct (compatible τ₁0 [x]); try discriminate;
            inversion H3;
            apply (@rec_concat_sort_sorted string ODT_string _ τ₁0 [x] (rec_concat_sort τ₁0 [x])); reflexivity).
      rename H into pf3.
      econstructor; eauto.
      econstructor; eauto.
      econstructor; eauto.
      econstructor; eauto.
      econstructor; eauto.
      destruct τenv0; subst.
      destruct x0; try discriminate.
      assert (Rec Closed τ₃ pf3 = (exist (fun τ₀ : rtype₀ => wf_rtype₀ τ₀ = true) (Rec₀ k srl) e))
        by (apply rtype_fequal; simpl in *; assumption).
      rewrite <- H.
      destruct x; simpl in *.
      assert (tdot τ₃ s = Some s0) by (apply (edot_merge_bindings τ₁0 τ₃ s s0); assumption).
      apply ATDot; assumption.
      econstructor; eauto.
      assert (Rec Closed τ₃ pf3 = τenv0)
      by (apply rtype_fequal; simpl in *; assumption).
      rewrite <- H in *.
      generalize (@ATMergeConcat _ _ _ _ _ _ τ₁0 [(fst x, snd x)] τ₃ pf1 eq_refl pf3); intros.
      destruct x; simpl in *.
      apply (H2 H3).
    - intros.
      input_well_typed.
      invcs dt_env; rtype_equalizer.
      subst.
      destruct x; simpl.
      specialize (H6 eq_refl); subst.
      case_eq (merge_bindings dl [(s, x0)]); intros; try reflexivity; subst; simpl.
      rewrite (edot_merge_bindings dl l s x0); simpl.
      reflexivity.
      trivial.
  Qed.


  (********
   * Misc *
   ********)
  
  (* ♯toString(s) ⇒ s *)
  
  Lemma ttostring_dstring_arrow s:
    (ANUnop AToString (ANConst (dstring s))) ⇒ (ANConst (dstring s)).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (tostring_dstring s)).
    intros; inferer.
    inversion H2; subst.
    econstructor. apply normalize_preserves_type.
    econstructor.
  Qed.

  (* ♯toString(♯toString(q)) ⇒ ♯toString(q) *)
  
  Lemma ttostring_tostring_arrow q:
    (ANUnop AToString (ANUnop AToString q)) ⇒ (ANUnop AToString q).
  Proof.
    apply (rewrites_typed_with_untyped _ _ (tostring_tostring q)).
    intros.
    inversion H. clear H; subst.
    inversion H2; clear H2; subst.
    inversion H6; clear H6; subst.
    econstructor; eauto.
  Qed.

  (* ♯toString(♯sConcat q₁ q₂) ⇒ ♯toString(♯sConcat q₁ q₂) *)
  
  Lemma ttostring_sconcat_arrow q₁ q₂:
    (ANUnop AToString (ANBinop ASConcat q₁ q₂)) ⇒ (ANBinop ASConcat q₁ q₂).
  Proof.
    unfold talgenv_rewrites_to; intros; simpl.
    inferer.
    econstructor; eauto.
    - inversion H3; clear H3; subst.
      inversion H2; clear H2; subst.
      econstructor; eauto.
    - intros.
      input_well_typed; simpl.
      case_eq (unsdstring append dout dout0); intros; try reflexivity; simpl.
      generalize (unsdstring_is_string append dout dout0 d H); intros.
      elim H0; clear H0; intros.
      rewrite H0; reflexivity.
  Qed.

   (****************
   * ARecProject *
   ****************)

  Lemma trproject_nil p :
    π[nil](p) ⇒  ‵[||].
  Proof.
    red; simpl; intros.
    inverter. split.
    - econstructor. apply dtrec_full.
      simpl. rewrite rproject_nil_r; trivial.
    - intros. input_well_typed.
      inversion τout.
      rewrite rproject_nil_r.
      trivial.
  Qed.
  
  Lemma trproject_over_concat_rec_r_in sl s p₁ p₂ :
    In s sl ->
    π[sl](p₁ ⊕ ‵[| (s, p₂) |]) ⇒ π[remove string_dec s sl](p₁) ⊕ ‵[| (s, p₂) |] .
  Proof.
    red; simpl; intros.
    inverter.
    split.
    econstructor.
    3: econstructor; [| eauto]; eauto.
    2: econstructor; [|eauto]; econstructor.
    + econstructor.
      unfold rec_concat_sort.
      rewrite rproject_rec_sort_commute, rproject_app.
      rewrite <- (rec_sort_rproject_remove_in s) by (simpl; intuition).
      simpl.
      destruct (in_dec string_dec s sl); [ | intuition ].
      trivial.
    + apply (sublist_remove equiv_dec s) in H1.
      rewrite remove_domain_filter in H1.
      unfold rec_concat_sort in H1.
      rewrite rec_sort_filter_fst_commute in H1 by (simpl; intuition).
      rewrite filter_app in H1; simpl in H1.
      unfold nequiv_decb, equiv_decb in H1.
      destruct (equiv_dec s s); [| congruence].
      simpl in H1.
      rewrite app_nil_r in H1.
      rewrite sort_sorted_is_id in H1.
      * rewrite H1.
        apply sublist_domain.
        apply filter_sublist.
      * apply sorted_over_filter; trivial.
    + intros.
      destruct (brand_relation_brands ⊢ₑ p₁ @ₑ x ⊣ c;env); simpl; trivial.
      destruct d; simpl;
      destruct (brand_relation_brands ⊢ₑ p₂ @ₑ x ⊣ c;env); simpl; trivial.
      rewrite rproject_rec_sort_commute, rproject_app.
      rewrite <- (rec_sort_rproject_remove_in s) by (simpl; intuition).
      simpl.
      destruct (in_dec string_dec s sl); simpl; intuition.
      Grab Existential Variables.
      { eapply is_list_sorted_sublist.
         - eapply pf0.
         - apply sublist_domain.
           apply sublist_rproject.
      }
      { simpl; trivial. }
  Qed.

   Lemma trproject_over_const sl l :
    π[sl](ANConst (drec l)) ⇒ ANConst (drec (rproject l sl)).
  Proof.
    apply rewrites_typed_with_untyped.
    - apply rproject_over_const.
    - intros.
      inverter.
      inversion H0; subst.
      rtype_equalizer. subst.
      econstructor.
      simpl.
      apply dtrec_full.
      rewrite <- rproject_map_fst_same; simpl; trivial.
      rewrite <- rproject_rec_sort_commute.
      eapply rproject_well_typed; try eassumption.
  Qed.
  
  Lemma trproject_over_rec_in sl s p :
    In s sl ->
    π[sl](‵[| (s, p) |]) ⇒ ‵[| (s, p) |].
  Proof.
    intros.
    apply rewrites_typed_with_untyped.
    - apply rproject_over_rec_in; trivial.
    - intros.
      inverter.
      econstructor; eauto.
      destruct (@in_dec string string_dec
              s sl); [| intuition].
      econstructor.
  Qed.

  Lemma trproject_over_rec_nin sl s p :
    ~ In s sl ->
    π[sl](‵[| (s, p) |]) ⇒ ‵[||].
  Proof.
    intros.
    transitivity (‵[||] ◯ p); [ | apply tapp_over_const_arrow].
    apply rewrites_typed_with_untyped.
    - apply rproject_over_rec_nin; trivial.
    - intros.
      inverter.
      econstructor; eauto.
      econstructor; eauto.
      destruct (@in_dec string string_dec
                        s sl); [| intuition]; [intuition | ].
      simpl. econstructor; eauto.
  Qed.
      
  Lemma trproject_over_concat_rec_r_nin sl s p₁ p₂ :
    ~ In s sl ->
    π[sl](p₁ ⊕ ‵[| (s, p₂) |]) ⇒ π[sl](p₁).
  Proof.
    red; simpl; intros.
    inverter.
    split.
    - econstructor; [ | eauto].
      revert pf2.
      unfold rec_concat_sort.
      rewrite rproject_rec_sort_commute, rproject_app.
      simpl.
      destruct (in_dec string_dec s sl); [intuition | ].
      rewrite app_nil_r.
      rewrite sort_sorted_is_id.
      + intros. econstructor.
        apply (sublist_nin_remove equiv_dec _ _ _ n) in H1.
        rewrite remove_domain_filter in H1.
        unfold rec_concat_sort in H1.
        rewrite rec_sort_filter_fst_commute in H1 by (simpl; intuition).
        rewrite filter_app in H1; simpl in H1.
        unfold nequiv_decb, equiv_decb in H1.
        destruct (equiv_dec s s); [| congruence].
        simpl in H1.
        rewrite app_nil_r in H1.
        rewrite sort_sorted_is_id in H1.
        * rewrite H1.
          apply sublist_domain.
          apply filter_sublist.
        * apply sorted_over_filter; trivial.
      + apply sorted_over_filter; trivial.
    - intros.
      input_well_typed.
      destruct dout; simpl; trivial.
      rewrite rproject_rec_sort_commute, rproject_app.
      simpl.
      destruct (in_dec string_dec s sl); simpl; [intuition | ].
      rewrite app_nil_r.
      rewrite sort_sorted_is_id; trivial.
      apply sorted_over_filter; trivial.
      apply data_type_normalized in τout.
      inversion τout; trivial.
  Qed.

  Lemma trproject_over_concat_rec_l_nin sl s p₁ p₂ :
    ~ In s sl ->
    π[sl](‵[| (s, p₁) |] ⊕ p₂) ⇒ π[sl](p₂).
  Proof.
    red; intros.
    inverter.
    split.
    - econstructor; [ | eauto].
      revert pf2.
      unfold rec_concat_sort.
      rewrite rproject_rec_sort_commute, rproject_app.
      simpl.
      destruct (in_dec string_dec s sl); [intuition | ].
      simpl.
      rewrite sort_sorted_is_id.
      + intros. econstructor.
        apply (sublist_nin_remove equiv_dec _ _ _ n) in H1.
        rewrite remove_domain_filter in H1.
        unfold rec_concat_sort in H1.
        rewrite rec_sort_filter_fst_commute in H1 by (simpl; intuition).
        rewrite filter_app in H1; simpl in H1.
        unfold nequiv_decb, equiv_decb in H1.
        destruct (equiv_dec s s); [| congruence].
        simpl in H1.
        rewrite sort_sorted_is_id in H1.
        * rewrite H1.
          apply sublist_domain.
          apply filter_sublist.
        * apply sorted_over_filter; trivial.
      + apply sorted_over_filter; trivial.
    - intros.
      input_well_typed.
      destruct dout0; trivial.
      simpl.
      replace (insertion_sort_insert rec_field_lt_dec (s, dout) (rec_sort l)) with
      (rec_sort ((s,dout)::l)) by reflexivity.
      rewrite rproject_rec_sort_commute.
      simpl.
      destruct (in_dec string_dec s sl); simpl; [intuition | ].
      rewrite sort_sorted_is_id; trivial.
      apply sorted_over_filter; trivial.
      apply data_type_normalized in τout0.
      inversion τout0; trivial.
  Qed.

    Lemma trproject_over_concat_recs_in_in sl s₁ p₁ s₂ p₂ :
      In s₁ sl -> In s₂ sl ->
      π[sl](‵[| (s₁, p₁) |] ⊕ ‵[| (s₂, p₂) |]) ⇒ ‵[| (s₁, p₁) |] ⊕ ‵[| (s₂, p₂) |].
    Proof.
      intros.
      apply rewrites_typed_with_untyped.
      - rewrite rproject_over_concat.
        repeat rewrite rproject_over_rec_in by trivial.
        reflexivity.
      - intros.
        inverter.
        econstructor; eauto.
        econstructor; eauto.
        unfold rec_concat_sort.
        rewrite rproject_rec_sort_commute, rproject_app.
        simpl.
        destruct (in_dec string_dec s sl); [| intuition ].
        destruct (in_dec string_dec s1 sl); [| intuition ].
        reflexivity.
      Grab Existential Variables.
      solve[eauto].
      solve[eauto].
    Qed.
  
  Lemma trproject_over_rproject sl1 sl2 p :
    π[sl1](π[sl2](p)) ⇒ π[set_inter string_dec sl2 sl1](p).
  Proof.
    apply rewrites_typed_with_untyped.
    - apply rproject_over_rproject.
    - intros.
      inverter.
      generalize pf3.
      rewrite (rproject_rproject τ1 sl1 sl2).
      econstructor; eauto.
      econstructor.
      apply sublist_set_inter.
      trivial.
  Qed.

  Lemma trproject_over_either sl p1 p2 :
    π[sl](ANEither p1 p2) ⇒ ANEither (π[sl](p1)) (π[sl](p2)).
  Proof.
    apply rewrites_typed_with_untyped.
    - apply rproject_over_either.
    - intros.
      inverter.
      econstructor; eauto.
  Qed.

  (****************
   * Brand/Either *
   ****************)

  (**********
   * ACount *
   **********)
  
  (* #count does not care about the identity of the elements
     in a collection, only how many there are *)
  Lemma tcount_over_map p₁ p₂ :
        ♯count(χ⟨p₁⟩(p₂)) ⇒  ♯count(p₂).
  Proof.
    red; intros; split.
    - inferer.
      inversion H2; rtype_equalizer; subst.
      inferer.
    - intros.
      inferer.
      input_well_typed.
      destruct dout; simpl; trivial.
      clear eout.
      revert l τout0.
      induction l; simpl; trivial.
      intros.
      inversion τout0. rtype_equalizer; subst.
      inversion H3; subst.
      assert (typ:dcoll l ▹ Coll τ₁)
             by (econstructor; trivial).
      specialize (IHl typ).
      input_well_typed.
      unfold olift in IHl.
      match_case_in IHl; [ intros ? eqq | intros eqq];
      rewrite eqq in IHl; simpl in *; try discriminate.
      apply some_lift in eqq.
      destruct eqq as [? eqq ?]; subst.
      apply some_lift in IHl.
      destruct IHl as [? IHl ?]; subst.
      inversion e; clear e; subst.
      rewrite eqq; simpl.
      simpl in IHl.
      inversion IHl; clear IHl.
      apply of_nat_inv in H0.
      congruence.
  Qed.

  Lemma tcount_over_flat_map_map p₁ p₂ p₃ :
    ♯count(♯flatten(χ⟨χ⟨p₁⟩(p₂)⟩(p₃))) ⇒
          ♯count(♯flatten(χ⟨p₂⟩(p₃))).
  Proof.
    rewrite tmap_over_map_split.
    rewrite tmap_over_flatten_b.
    rewrite tcount_over_map.
    reflexivity.
  Qed.

  Lemma tmap_over_either_nil_b p₁ p₂ :
    ANEither (χ⟨p₁⟩(p₂)) ‵{||} ⇒ χ⟨p₁⟩(ANEither p₂ ‵{||}).
  Proof.
     apply rewrites_typed_with_untyped.
     - rewrite envmap_over_either.
       red; simpl; trivial.
    - intros.
      inferer.
      repeat (econstructor; simpl; eauto).
  Qed.

  Lemma tcount_over_flat_map_either_nil_map p₁ p₂ p₃ :
    ♯count(♯flatten(χ⟨ANEither (χ⟨p₁⟩(p₂)) ‵{||}⟩(p₃))) ⇒
          ♯count(♯flatten(χ⟨ANEither p₂ ‵{||}⟩(p₃))).
  Proof.
    rewrite tmap_over_either_nil_b.
    rewrite tcount_over_flat_map_map.
    reflexivity.
  Qed.

  Lemma tcount_over_flat_map_either_nil_app_map p₁ p₂ p₃ p₄:
    ♯count(♯flatten(χ⟨ANEither (χ⟨p₁⟩(p₂)) ‵{||} ◯ p₄⟩(p₃))) ⇒
          ♯count(♯flatten(χ⟨ANEither p₂ ‵{||} ◯ p₄⟩(p₃))).
  Proof.
    rewrite tmap_over_either_nil_b.
    rewrite tapp_over_map_arrow.
    rewrite tcount_over_flat_map_map.
    reflexivity.
  Qed.

  Lemma tcount_over_flat_map_either_nil_app_singleton p₁ p₂ p₃:
    ♯count(♯flatten(χ⟨ANEither (‵{| p₁ |}) ‵{||} ◯ p₃⟩(p₂))) ⇒
          ♯count(♯flatten(χ⟨ANEither (‵{| ANConst dunit |}) ‵{||} ◯ p₃⟩(p₂))).
  Proof.
    red; intros; split.
    - inferer.
      inversion H2; rtype_equalizer; subst.
      inferer.
      econstructor.
      2: (repeat econstructor; simpl; eauto).
      econstructor.
    - intros.
      inferer.
      input_well_typed.
      destruct dout; simpl; trivial.
      clear eout.
      revert l τout0.
      induction l; simpl; trivial.
      intros.
      inversion τout0. rtype_equalizer; subst.
      inversion H3; subst.
      assert (typ:dcoll l ▹ Coll τ₁)
             by (econstructor; trivial).
      specialize (IHl typ).
      input_well_typed.
      case_eq ((rmap
                   (fun x0 : data =>
                    olift
                      (fun x' : data =>
                       match x' with
                       | dleft dl =>
                           olift (fun d1 : data => Some (dcoll [d1]))
                             (brand_relation_brands ⊢ₑ p₁ @ₑ dl ⊣ c; env)
                       | dright _ => Some (dcoll [])
                       | _ => None
                       end) (brand_relation_brands ⊢ₑ p₃ @ₑ x0 ⊣ c; env)) l))
      ; [ intros ? eqq | intros eqq];
      rewrite eqq in IHl; simpl in *; try discriminate.
      + unfold olift in IHl |- *.
        case_eq ((rmap
                 (fun x0 : data =>
                  match @brand_relation_brands brand_model_relation ⊢ₑ p₃ @ₑ x0 ⊣ c; env with
                  | Some (dleft _) => Some (dcoll [dunit])
                  | Some (dright _) => Some (dcoll [])
                  | Some _ => None
                  | None => None
                  end) l))
        ; [ intros ? eqq1 | intros eqq1];
        rewrite eqq1 in IHl; simpl in *; try discriminate.
        * { match_case_in IHl; [ intros ? eqq2 | intros eqq2];
            rewrite eqq2 in IHl; simpl in *; try discriminate;
            (match_case_in IHl; [ intros ? eqq3 | intros eqq3];
             rewrite eqq3 in IHl; simpl in *; try discriminate).
            - apply some_lift in eqq2; destruct eqq2 as [? eqq2 ?]; subst.
              apply some_lift in eqq3; destruct eqq3 as [? eqq3 ?]; subst.
              simpl in IHl.
              inversion IHl; clear IHl.
              apply of_nat_inv in H1.
              unfold olift.
              destruct dout; simpl; trivial.
              + inversion τout1; clear τout1.
                rtype_equalizer. subst.
                input_well_typed.
                rewrite (rflatten_cons _ _ _ eqq2).
                simpl.
                rewrite H1.
                rewrite (rflatten_cons _ _ _ eqq3).
                simpl.
                trivial.
              + rewrite (rflatten_cons _ _ _ eqq2).
                rewrite (rflatten_cons _ _ _ eqq3).
                simpl.
                rewrite H1.
                trivial.
            - apply some_lift in eqq2; destruct eqq2 as [? eqq2 ?]; subst.
              apply none_lift in eqq3.
              simpl in IHl.
              discriminate.
            - apply none_lift in eqq2.
              apply some_lift in eqq3; destruct eqq3 as [? eqq3 ?]; subst.
              destruct eqq3 as [? eqq3 ?]; subst.
              simpl in IHl.
              discriminate.
            - apply none_lift in eqq2.
              apply none_lift in eqq3.
              unfold olift.
              destruct dout; simpl; trivial.
              + inversion τout1; clear τout1; rtype_equalizer.
                subst.
                input_well_typed.
                rewrite (rflatten_cons_none _ _ eqq2).
                simpl.
                rewrite (rflatten_cons_none _ _ eqq3).
                simpl.
                trivial.
              + rewrite (rflatten_cons_none _ _ eqq2).
                simpl.
                rewrite (rflatten_cons_none _ _ eqq3).
                simpl.
                trivial.
          }
        * { match_case_in IHl; [ intros ? eqq2 | intros eqq2];
            rewrite eqq2 in IHl; simpl in *; try discriminate.
            - apply some_lift in eqq2; destruct eqq2 as [? eqq2 ?]; subst.
              simpl in IHl.
              discriminate.
            - apply none_lift in eqq2.
              unfold olift.
              destruct dout; inversion τout1; clear τout1.
              + rtype_equalizer.
                subst.
                input_well_typed.
                rewrite (rflatten_cons_none _ _ eqq2).
                simpl.
                trivial.
              + simpl.
                rewrite (rflatten_cons_none _ _ eqq2).
                simpl.
                trivial.
          }
      + unfold olift in IHl.
        case_eq ((rmap
                 (fun x0 : data =>
                  match @brand_relation_brands brand_model_relation ⊢ₑ p₃ @ₑ x0 ⊣ c; env with
                  | Some (dleft _) => Some (dcoll [dunit])
                  | Some (dright _) => Some (dcoll [])
                  | Some _ => None
                  | None => None
                  end) l))
        ; [ intros ? eqq1 | intros eqq1];
        rewrite eqq1 in IHl; simpl in *; try discriminate.
        * { match_case_in IHl; [ intros ? eqq2 | intros eqq2];
            rewrite eqq2 in IHl; simpl in *; try discriminate.
            - apply some_lift in eqq2; destruct eqq2 as [? eqq2 ?]; subst.
              simpl in IHl.
              discriminate.
            - apply none_lift in eqq2.
              unfold olift.
              rewrite eqq1.
              destruct dout; inversion τout1; clear τout1.
              + rtype_equalizer.
                subst.
                input_well_typed.
                rewrite (rflatten_cons_none _ _ eqq2).
                simpl.
                trivial.
              + simpl.
                rewrite (rflatten_cons_none _ _ eqq2).
                simpl.
                trivial.
          }
        * unfold olift; rewrite eqq1; simpl.
          { destruct dout; inversion τout1; clear τout1.
            - rtype_equalizer.
                subst.
                input_well_typed.
                trivial.
            - simpl; trivial.
          }
  Qed.

  (*************
   * MapConcat *
   *************)

  (* ⋈ᵈ⟨ p₁ ⟩(‵{| ‵[||] |}) ⇒ p₁ ◯ (‵[||]) *)
  
  Lemma tmapconcat_over_singleton p₁ :
    ⋈ᵈ⟨ p₁ ⟩(‵{| ‵[||] |}) ⇒ p₁ ◯ (‵[||]).
  Proof.
    red; intros; split.
    - inferer.
      assert (Rec Closed τ₁ pf1 = τ)
        by (apply rtype_fequal; simpl in *; auto).
      subst; clear H.
      inversion H0; rtype_equalizer; specialize (H5 eq_refl).
      subst; subst; clear H4 H0.
      inversion H6; subst; simpl in *; clear H6.
      unfold rec_concat_sort in *; simpl in *.
      assert (rec_sort τ₂ = τ₂)
        by (apply (sort_sorted_is_id τ₂); eauto 2).
      assert (Coll (Rec Closed τ₂ pf2) = Coll (Rec Closed (rec_sort τ₂) pf3)).
      apply rtype_fequal; simpl.
      rewrite H; reflexivity.
      econstructor; eauto.
      econstructor; eauto.
      Focus 2.
      rewrite <- H0. eauto.
      simpl.
      apply dtrec_full. auto.
    - intros.
      simpl.
      unfold rmap_concat; simpl.
      unfold oomap_concat; simpl.
      inferer.
      assert (Rec Closed τ₁ pf1 = τ)
        by (apply rtype_fequal; simpl in *; auto).
      subst; clear H.
      input_well_typed.
      dtype_inverter.
      unfold omap_concat; simpl.
      clear H2 pf3 H0 pf1 eout.
      induction dout; try reflexivity; simpl in *.
      inversion τout. subst.
      assert (Rec Closed τ₂ pf2 = r)
        by (apply rtype_fequal; simpl in *; auto).
      subst; clear H0.
      inversion H1; clear H1; subst.
      assert (dcoll dout ▹ Coll (Rec Closed τ₂ pf2))
        by (econstructor; assumption).
      dtype_inverter.
      inversion H2. subst; clear H2.
      rtype_equalizer. subst.
      specialize (IHdout H); clear H τout.
      unfold rec_concat_sort in *; simpl in *.
      assert (is_list_sorted StringOrder.lt_dec (domain a) = true).
      apply (@same_domain_same_sorted string ODT_string rtype data rl a);
        try assumption.
      assert (domain a = domain rl).
      apply (@sorted_forall_same_domain _ _ _ _ a rl); assumption. auto.
      rewrite sort_sorted_is_id; [|assumption].
      destruct (rmap
                 (fun x0 : data =>
                  match x0 with
                  | drec r1 => Some (drec (rec_sort r1))
                  | _ => None
                  end) dout); simpl in *; congruence.
  Qed.

  (** composite lemmas: these are just composites of previous rewrites.
      They are here since the optimizer uses them. *)
  
  Lemma  tmap_over_flatten_map (p₁ p₂ p₃: algenv) :
    χ⟨p₁⟩(♯flatten(χ⟨p₂⟩(p₃))) ⇒ ♯flatten(χ⟨χ⟨p₁⟩(p₂)⟩(p₃)).
  Proof.
    rewrite tmap_over_flatten.
    rewrite tenvmap_map_compose_arrow.
    rewrite tapp_over_map_arrow.
    rewrite tapp_over_id_l_arrow.
    reflexivity.
  Qed.
  
  Lemma tdup_elim (q:algenv) :
    nodupA q -> ANUnop ADistinct q  ⇒  q.
  Proof.
    intros nd.
    apply rewrites_typed_with_untyped.
    - rewrite dup_elim by trivial.
      reflexivity.
    - intros.
      inferer.
      invcs H2.
      trivial.
  Qed.

End TOptimEnv.

(* begin hide *)
(* Hints for optimization tactic

   Note: all of those are valid, indepently of typing
   Note: those marked with ** can be generalized with proper type
   information
*)

(**** Those aren't in the untyped form
       tmerge_empty_record_arrow : p ⊗ [] ⇒ { p }
*)

Hint Rewrite @tmerge_empty_record_r_arrow : talgenv_optim.
Hint Rewrite @tmerge_empty_record_l_arrow : talgenv_optim.
Hint Rewrite @tmapenv_to_env_arrow : talgenv_optim.
Hint Rewrite @tselect_and_arrow : talgenv_optim.
Hint Rewrite @tflatten_through_appenv_arrow : talgenv_optim.
Hint Rewrite @tflatten_mapenv_coll_arrow : talgenv_optim.
Hint Rewrite @tflatten_over_double_map_arrow : talgenv_optim.
Hint Rewrite @tflatten_over_double_map_with_either_arrow : talgenv_optim.

(*
       -- Those simplify over singleton collections
       tenvflatten_map_coll : ♯flatten(χ⟨ { p1 } ⟩( p2 )) ⇒ χ⟨ p1 ⟩( p2 )
       tenvmap_into_id : χ⟨ ID ⟩( P ) ⇒ P
*)

Hint Rewrite @tenvflatten_map_coll_arrow : talgenv_optim.
Hint Rewrite @tenvmap_into_id_arrow : talgenv_optim.

(*
       -- Those introduce a ◯ , but remove a χ
       tenvmap_map_compose : χ⟨ P1 ⟩( χ⟨ P2 ⟩( P3 ) ) ⇒ χ⟨ P1 ◯ P2 ⟩( P3 )
       tenvmap_singleton : χ⟨ P1 ⟩( { P2 } ) ⇒ { P1 ◯ P2 }
*)

Hint Rewrite @tenvmap_map_compose_arrow : talgenv_optim.
Hint Rewrite @tenvmap_singleton_arrow : talgenv_optim.

(*
       -- Those remove over flatten
       envflatten_coll : ♯flatten( { p } ) ⇒ p
*)

Hint Rewrite @tenvflatten_coll_arrow : talgenv_optim.
Hint Rewrite @tenvflatten_nil_arrow : talgenv_optim.

(*
       -- Those push-down or remove ◯
       app_over_const : d ◯ q ⇒ d
       app_over_env : ENV ◯ q ⇒ ENV
       app_over_id : q ◯ ID ⇒ q
       app_over_id_l : ID ◯ q ⇒ q
       app_over_app : (q₁ ◯ q₂) ◯ q₃ ⇒ q₁ ◯ (q₂ ◯ q₃)
       app_over_unop : (⊕u(q₁)) ◯ q₂ ⇒ ⊕u(q₁ ◯ q₂)
       app_over_map : χ⟨ q₁ ⟩( q₂ ) ◯ q ⇒ χ⟨ q₁ ⟩( q₂ ◯ q )
       app_over_select : σ⟨ q₁ ⟩( q₂ ) ◯ᵉ q ⇒ σ⟨ q₁ ◯ᵉ q ⟩( q₂ ◯ᵉ q )
       app_over_binop : (q₂ ⊗b q₁) ◯ q ⇒ (q₂ ◯ q) ⊗b (q₁ ◯ q)
*)

Hint Rewrite @tapp_over_const_arrow : talgenv_optim.
Hint Rewrite @tapp_over_env_arrow : talgenv_optim.
Hint Rewrite @tapp_over_id_r_arrow : talgenv_optim.
Hint Rewrite @tapp_over_id_l_arrow : talgenv_optim.
Hint Rewrite @tapp_over_app_arrow : talgenv_optim.
Hint Rewrite @tapp_over_unop_arrow : talgenv_optim.
Hint Rewrite @tapp_over_map_arrow : talgenv_optim.
Hint Rewrite @tapp_over_select_arrow : talgenv_optim.

(*
       -- Other misc rewrites
       product_singletons : { [ s1 : p1 ] } × { [ s2 : p2 ] } ⇒ { [ s1 : p1; s2 : p2 ] }
       double_flatten_map_coll : ♯flatten(χ⟨ χ⟨ { ID } ⟩( ♯flatten( p1 ) ) ⟩( p2 ))
                                 ⇒ χ⟨ { ID } ⟩(♯flatten(χ⟨ ♯flatten( p1 ) ⟩( p2 )))
       #toString(s) ⇒ s
       #toString(#toString(q)) ⇒ #toString(q)
*)

Hint Rewrite @tproduct_singletons_arrow : talgenv_optim.
Hint Rewrite @tdouble_flatten_map_coll_arrow : talgenv_optim.
Hint Rewrite @ttostring_dstring_arrow : talgenv_optim.
Hint Rewrite @ttostring_tostring_arrow : talgenv_optim.
Hint Rewrite @ttostring_sconcat_arrow : talgenv_optim.

(*
       -- Those handle operators on the environment
       appenv_over_mapenv : χᵉ⟨ { ENV } ⟩(ID) ◯ₑ ♯flatten(p) ⇒ χ⟨ { ID } ⟩(♯flatten(p))
       appenv_over_mapenv_coll : (χᵉ⟨ { { ENV } } ⟩(ID) ◯ₑ ♯flatten(p)) ⇒ χ⟨ { { ID } } ⟩(♯flatten(p))
       appenv_over_mapenv_merge : (χᵉ⟨ { ENV.e } ⟩(ID) ◯ₑ ANBinop AMergeConcat ENV ID)
                                   ⇒ χ⟨ { ID.e } ⟩(ANBinop AMergeConcat ENV ID)
       tcompose_selects_in_mapenv_arrow :
            ♯flatten(ANMapEnv (χ⟨ENV⟩(σ⟨p1⟩( ‵{| ID |})))(ID) ◯ₑ (χ⟨ENV⟩(σ⟨p2⟩( ‵{| ID |}))))
                ⇒ (χ⟨ENV⟩(σ⟨p1⟩(σ⟨p2⟩( ‵{| ID |}))))
*)

Hint Rewrite @tappenv_over_env_l_arrow : talgenv_optim.
Hint Rewrite @tappenv_over_env_r_arrow : talgenv_optim.
Hint Rewrite @tappenv_over_appenv_arrow : talgenv_optim.
Hint Rewrite @tappenv_over_app_arrow : talgenv_optim.
Hint Rewrite @tappenv_over_app_ie_arrow : talgenv_optim.
Hint Rewrite @tcompose_selects_in_mapenv_arrow : talgenv_optim.
Hint Rewrite @tappenv_flatten_mapenv_to_map_arrow : talgenv_optim.
Hint Rewrite @tappenv_over_const_arrow : talgenv_optim.
Hint Rewrite @tflip_env1_arrow : talgenv_optim.
Hint Rewrite @tflip_env2_arrow : talgenv_optim.
Hint Rewrite @tmapenv_over_singleton_arrow : talgenv_optim.
Hint Rewrite @tflip_env4_arrow : talgenv_optim.
Hint Rewrite @tappenv_over_binop : talgenv_optim.
Hint Rewrite @tflip_env6_arrow : talgenv_optim.
Hint Rewrite @tmapenv_to_map_arrow : talgenv_optim.
Hint Rewrite @tmerge_concat_to_concat_arrow : talgenv_optim.
Hint Rewrite @tmerge_with_concat_to_concat_arrow : talgenv_optim.
Hint Rewrite @tappenv_mapenv_to_map_arrow : talgenv_optim.

Hint Rewrite @tmap_over_nil : talgenv_optim.
Hint Rewrite @tselect_over_nil : talgenv_optim.
Hint Rewrite @tmap_over_either  : talgenv_optim.
Hint Rewrite @tmap_over_either_app : talgenv_optim.
Hint Rewrite @tselect_over_either : talgenv_optim.
Hint Rewrite @tselect_over_app_either : talgenv_optim.
Hint Rewrite @tappenv_through_either : talgenv_optim.
Hint Rewrite @tcount_over_map : talgenv_optim.
Hint Rewrite @tcount_over_flat_map_map : talgenv_optim.
Hint Rewrite @tcount_over_flat_map_either_nil_map : talgenv_optim.
Hint Rewrite @tcount_over_flat_map_either_nil_app_map : talgenv_optim.
Hint Rewrite @tunop_over_either : talgenv_optim.
Hint Rewrite @tunop_over_either_app : talgenv_optim.
Hint Rewrite @tflatten_flatten_map_either_nil : talgenv_optim.
Hint Rewrite @tcount_over_flat_map_either_nil_app_singleton : talgenv_optim.
(* end hide *)

(* 
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "QCert")) ***
*** End: ***
*)
