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

Section TOps.
  Require Import String List ZArith.
  Require Import Compare_dec.
  
  Require Import Utils Types BasicRuntime.
  Require Import ForeignDataTyping ForeignOpsTyping TData.

  Require Import Program.

  (* Useful *)

  Definition tdot {A} (l:list (string * A)) (a:string) : option A := edot l a.

  (** Typing rules for unary operators *)

  Section u.
    Context {fdata:foreign_data}.
    Context {fuop:foreign_unary_op}.
    Context {ftype:foreign_type}.
    Context {fdtyping:foreign_data_typing}.
    Context {m:brand_model}.
    Context {fuoptyping:foreign_unary_op_typing}.

    Inductive unaryOp_type : unaryOp -> rtype -> rtype -> Prop :=
    | ATIdOp τ : unaryOp_type AIdOp τ τ
    | ATNeg: unaryOp_type ANeg Bool Bool
    | ATColl {τ} : unaryOp_type AColl τ (Coll τ)
    | ATSingleton τ :
        unaryOp_type ASingleton (Coll τ) (Option τ)
    | ATFlatten τ: unaryOp_type AFlatten (Coll (Coll τ)) (Coll τ)
    | ATDistinct τ: unaryOp_type ADistinct (Coll τ) (Coll τ)
    | ATRec {τ} s pf : unaryOp_type (ARec s) τ (Rec Closed ((s,τ)::nil) pf)
    | ATDot {τ' τout} k s pf :
        tdot τ' s = Some τout ->
        unaryOp_type (ADot s) (Rec k τ' pf) τout
    | ATRecRemove {τ} k s pf1 pf2 :
        unaryOp_type (ARecRemove s) (Rec k τ pf1) (Rec k (rremove τ s) pf2)
    | ATRecProject {τ} k sl pf1 pf2 :
        sublist sl (domain τ) -> 
        unaryOp_type (ARecProject sl) (Rec k τ pf1) (Rec Closed (rproject τ sl) pf2)
    | ATCount τ: unaryOp_type ACount (Coll τ) Nat
    | ATSum : unaryOp_type ASum (Coll Nat) Nat
    | ATNumMin : unaryOp_type ANumMin (Coll Nat) Nat
    | ATNumMax : unaryOp_type ANumMax (Coll Nat) Nat
    | ATArithMean : unaryOp_type AArithMean (Coll Nat) Nat
    | ATToString τ: unaryOp_type AToString τ String
    | ATLeft τl τr: unaryOp_type ALeft τl (Either τl τr)
    | ATRight τl τr: unaryOp_type ARight τr (Either τl τr)
    | ATBrand b :
        unaryOp_type (ABrand b) (brands_type b) (Brand b)
    | ATUnbrand {bs} :
        unaryOp_type AUnbrand (Brand bs) (brands_type bs)
    | ATCast br {bs} :
        unaryOp_type (ACast br) (Brand bs) (Option (Brand br))
    | ATUArith (u:ArithUOp) : unaryOp_type (AUArith u) Nat Nat
    | ATForeignUnaryOp {fu τin τout} :
        foreign_unary_op_typing_has_type fu τin τout ->
        unaryOp_type (AForeignUnaryOp fu) τin τout.
  End u.

  Tactic Notation "unaryOp_type_cases" tactic(first) ident(c) :=
  first;
    [ Case_aux c "ATIdOp"%string
    | Case_aux c "ATNeg"%string
    | Case_aux c "ATColl"%string
    | Case_aux c "ATSingleton"%string
    | Case_aux c "ATFlatten"%string
    | Case_aux c "ATDistinct"%string
    | Case_aux c "ATRec"%string
    | Case_aux c "ATDot"%string
    | Case_aux c "ATRecRemove"%string
    | Case_aux c "ATRecProject"%string
    | Case_aux c "ATCount"%string
    | Case_aux c "ATSum"%string
    | Case_aux c "ATNumMin"%string
    | Case_aux c "ATNumMax"%string
    | Case_aux c "ATArithMean"%string
    | Case_aux c "ATToString"%string
    | Case_aux c "ATLeft"%string
    | Case_aux c "ATRight"%string
    | Case_aux c "ATBrand"%string
    | Case_aux c "ATUnbrand"%string
    | Case_aux c "ATCast"%string
    | Case_aux c "ATUArith"%string
    | Case_aux c "ATForeignUnaryOp"%string].

  (** Typing rules for binary operators *)

  Section b.

    Context {fdata:foreign_data}.
    Context {fbop:foreign_binary_op}.
    Context {ftype:foreign_type}.
    Context {fdtyping:foreign_data_typing}.
    Context {m:brand_model}.
    Context {fboptyping:foreign_binary_op_typing}.
    
    Inductive binOp_type: binOp -> rtype -> rtype -> rtype -> Prop :=
    | ATEq {τ} : binOp_type AEq τ τ Bool
    | ATConcat {τ₁ τ₂ τ₃} pf1 pf2 pf3 :
        rec_concat_sort τ₁ τ₂ = τ₃ ->
        binOp_type AConcat (Rec Closed τ₁ pf1) (Rec Closed τ₂ pf2) (Rec Closed τ₃ pf3)
    | ATMergeConcat {τ₁ τ₂ τ₃} pf1 pf2 pf3 : 
        merge_bindings τ₁ τ₂ = Some τ₃ ->
        binOp_type AMergeConcat (Rec Closed τ₁ pf1) (Rec Closed τ₂ pf2) (Coll (Rec Closed τ₃ pf3))
    | ATMergeConcatOpen {τ₁ τ₂ τ₃} pf1 pf2 pf3 : 
        merge_bindings τ₁ τ₂ = Some τ₃ ->
        binOp_type AMergeConcat (Rec Open τ₁ pf1) (Rec Open τ₂ pf2) (Coll (Rec Open τ₃ pf3))
    | ATAnd : binOp_type AAnd Bool Bool Bool
    | ATOr : binOp_type AOr Bool Bool Bool
    | ATBArith (b:ArithBOp) : binOp_type (ABArith b) Nat Nat Nat
    | ATLt : binOp_type ALt Nat Nat Bool
    | ATLe : binOp_type ALe Nat Nat Bool
    | ATUnion {τ} : binOp_type AUnion (Coll τ) (Coll τ) (Coll τ)
    | ATMinus {τ} : binOp_type AMinus (Coll τ) (Coll τ) (Coll τ)
    | ATMin {τ} : binOp_type AMin (Coll τ) (Coll τ) (Coll τ)
    | ATMax {τ} : binOp_type AMax (Coll τ) (Coll τ) (Coll τ)
    | ATContains {τ} : binOp_type AContains τ (Coll τ) Bool
    | ATSConcat :  binOp_type ASConcat String String String
    | ATForeignBinaryOp {fb τin₁ τin₂ τout} :
        foreign_binary_op_typing_has_type fb τin₁ τin₂ τout ->
        binOp_type (AForeignBinaryOp fb) τin₁ τin₂ τout
    .
  End b.

  Tactic Notation "binOp_type_cases" tactic(first) ident(c) :=
    first;
    [ Case_aux c "ATEq"%string
    | Case_aux c "ATConcat"%string
    | Case_aux c "ATMergeConcat"%string
    | Case_aux c "ATMergeConcatOpen"%string
    | Case_aux c "ATAnd"%string
    | Case_aux c "ATOr"%string
    | Case_aux c "ATBArith"%string
    | Case_aux c "ATLt"%string
    | Case_aux c "ATLe"%string
    | Case_aux c "ATUnion"%string
    | Case_aux c "ATMinus"%string
    | Case_aux c "ATMin"%string
    | Case_aux c "ATMax"%string
    | Case_aux c "ATContains"%string
    | Case_aux c "ATSConcat"%string
    | Case_aux c "ATForeignBinaryOp"%string].

  (** Type soundness lemmas for individual operations *)
    Context {fdata:foreign_data}.
    Context {fuop:foreign_unary_op}.
    Context {fbop:foreign_binary_op}.
    Context {ftype:foreign_type}.
    Context {fdtyping:foreign_data_typing}.
    Context {h:brand_model}.
    Context {fuoptyping:foreign_unary_op_typing}.
    Context {fboptyping:foreign_binary_op_typing}.

  Lemma forall_typed_bunion {τ} d1 d2:
    Forall (fun d : data => data_type d τ) d1 ->
    Forall (fun d : data => data_type d τ) d2 ->
    Forall (fun d : data => data_type d τ) (bunion d1 d2).
  Proof.
    intros; rewrite Forall_forall in *.
    induction d1.
    simpl in *; intros.
    apply H0; assumption.
    simpl in *; intros.
    elim H1; intros; clear H1.
    apply (H x).
    left; assumption.
    assert (forall x : data, In x d1 -> data_type x τ).
    intros.
    apply (H x0).
    right; assumption.
    apply IHd1; assumption.
  Qed.

  Lemma bminus_in_remove (x a:data) (d1 d2:list data) :
    In x (bminus d1 (remove_one a d2)) -> In x (bminus d1 d2).
  Proof.
    revert d2.
    induction d1; simpl; intros.
    - induction d2; simpl in *.
      assumption.
      revert H.
      elim (EquivDec.equiv_dec a a0); unfold EquivDec.equiv_dec; intros.
      rewrite <- a1.
      right; assumption.
      simpl in H.
      elim H; intros; clear H.
      left; assumption.
      right; apply (IHd2 H0).
    - specialize (IHd1 (remove_one a0 d2)).
      apply IHd1.
      rewrite remove_one_comm; assumption.
  Qed.      
    
  Lemma forall_typed_bminus {τ} d1 d2:
    Forall (fun d : data => data_type d τ) d1 ->
    Forall (fun d : data => data_type d τ) d2 ->
    Forall (fun d : data => data_type d τ) (bminus d1 d2).
  Proof.
    intros; rewrite Forall_forall in *.
    induction d1.
    simpl in *; intros.
    apply H0; assumption.
    simpl in *; intros.
    assert (forall x : data, In x d1 -> data_type x τ).
    intros.
    apply (H x0).
    right; assumption.
    assert (In x (bminus d1 d2))
      by (apply bminus_in_remove with (a:=a); assumption).
    apply IHd1; assumption.
  Qed.

  Lemma forall_typed_bmin {τ} d1 d2:
    Forall (fun d : data => data_type d τ) d1 ->
    Forall (fun d : data => data_type d τ) d2 ->
    Forall (fun d : data => data_type d τ) (bmin d1 d2).
  Proof.
    intros.
    unfold bmin.
    assert (Forall (fun d : data => data_type d τ) (bminus d2 d1)).
    apply forall_typed_bminus; assumption.
    apply forall_typed_bminus; assumption.
  Qed.

  Lemma forall_typed_bmax {τ} d1 d2:
    Forall (fun d : data => data_type d τ) d1 ->
    Forall (fun d : data => data_type d τ) d2 ->
    Forall (fun d : data => data_type d τ) (bmax d1 d2).
  Proof.
    intros.
    unfold bmax.
    assert (Forall (fun d : data => data_type d τ) (bminus d1 d2)).
    apply forall_typed_bminus; assumption.
    apply forall_typed_bunion; assumption.
  Qed.

  Lemma forall_in_weaken {A} (P Q:A -> Prop) l:
    (forall x : A, P x \/ In x l -> Q x)
    -> (forall x : A, In x l -> Q x).
  Proof.
    intros.
    induction l.
    simpl in H; contradiction.
    simpl in *.
    specialize (H x). elim H0; intros; clear H0; apply H.
    right; left; assumption.
    right; right; assumption.
  Qed.
  
  Lemma forall_typed_bdistinct {τ} d1:
    Forall (fun d : data => data_type d τ) d1 ->
    Forall (fun d : data => data_type d τ) (bdistinct d1).
  Proof.
    intros; rewrite Forall_forall in *.
    intros.
    induction d1.
    simpl in *.
    contradiction.
    simpl in *.
    assert (forall x : data, In x d1 -> data_type x τ)
      by (apply (forall_in_weaken (fun x => a = x)); assumption).
    destruct (mult (bdistinct d1) a).
    elim H0; intros; clear H0.
    rewrite <- H2 in *.
    apply (H a).
    left; reflexivity.
    specialize (IHd1 H1 H2); assumption.
    specialize (IHd1 H1 H0); assumption.
  Qed.

  Lemma Forall2_lookupr_none  (l : list (string * data)) (l' : list (string * rtype)) (s:string):
    (Forall2
       (fun (d : string * data) (r : string * rtype) =>
          fst d = fst r /\ data_type (snd d) (snd r)) l l') ->
    assoc_lookupr ODT_eqdec l' s = None -> 
    assoc_lookupr ODT_eqdec l s = None.
  Proof.
    intros.
    induction H; simpl in *.
    reflexivity.
    destruct x; destruct y; simpl in *.
    elim H; intros; clear H.
    rewrite H2 in *; clear H2 H3.
    revert H0 IHForall2.
    elim (assoc_lookupr string_eqdec l' s); try congruence.
    elim (string_eqdec s s1); intros; try congruence.
    specialize (IHForall2 H0); rewrite IHForall2.
    reflexivity.
  Qed.    

  Lemma Forall2_lookupr_some  (l : list (string * data)) (l' : list (string * rtype)) (s:string) (d':rtype):
    (Forall2
       (fun (d : string * data) (r : string * rtype) =>
          fst d = fst r /\ data_type (snd d) (snd r)) l l') ->
    assoc_lookupr ODT_eqdec l' s = Some d' -> 
    (exists d'', assoc_lookupr ODT_eqdec l s = Some d'' /\ data_type d'' d').
  Proof.
    intros.
    induction H; simpl in *.
    - elim H0; intros; congruence.
    - destruct x; destruct y; simpl in *.
      assert ((exists d, assoc_lookupr string_eqdec l' s = Some d) \/
              assoc_lookupr string_eqdec l' s = None)
        by (destruct (assoc_lookupr string_eqdec l' s);
            [left; exists r0; reflexivity|right; reflexivity]).
      elim H2; intros; clear H2.
      elim H3; intros; clear H3.
      revert H0 IHForall2.
      rewrite H2; intros.
      elim (IHForall2 H0); intros; clear IHForall2.
      elim H3; intros; clear H3.
      rewrite H4. exists x0. split;[reflexivity|assumption].
      clear IHForall2; assert (assoc_lookupr string_eqdec l s = None)
          by apply (Forall2_lookupr_none l l' s H1 H3).
      rewrite H3 in *; rewrite H2 in *; clear H2 H3.
      elim H; intros; clear H.
      rewrite H2 in *; clear H2.
      revert H0; elim (string_eqdec s s1); intros.
      exists d; split; try reflexivity.
      inversion H0; rewrite H2 in *; assumption.
      congruence.
  Qed.      

  Lemma rec_concat_with_drec_concat_well_typed  dl dl0 τ₁ τ₂:
    is_list_sorted ODT_lt_dec (domain τ₁) = true ->
    is_list_sorted ODT_lt_dec (domain τ₂) = true ->
      is_list_sorted ODT_lt_dec (domain (rec_concat_sort τ₁ τ₂)) = true ->
      Forall2
        (fun (d : string * data) (r : string * rtype) =>
           fst d = fst r /\ data_type (snd d) (snd r)) dl τ₁ ->
      Forall2
        (fun (d : string * data) (r : string * rtype) =>
           fst d = fst r /\ data_type (snd d) (snd r)) dl0 τ₂ ->
      Forall2
        (fun (d : string * data) (r : string * rtype) =>
           fst d = fst r /\ data_type (snd d) (snd r)) (rec_sort (dl ++ dl0))
        (rec_concat_sort τ₁ τ₂).
  Proof.
    intros pf1 pf2 pf3 H H0.
    assert (domain dl = domain τ₁)
      by (apply (sorted_forall_same_domain); assumption).
    assert (domain dl0 = domain τ₂)
      by (apply (sorted_forall_same_domain); assumption).
    assert (rec_sort dl = dl)
      by (apply sort_sorted_is_id; rewrite H1; assumption).
    assert (rec_sort dl0 = dl0)
      by (apply sort_sorted_is_id; rewrite H2; assumption).
    assert (rec_sort τ₂ = τ₂)
      by (apply sort_sorted_is_id; assumption).
    assert (rec_sort τ₁ = τ₁)
      by (apply sort_sorted_is_id; assumption).
    unfold rec_concat_sort.
    induction H; simpl in *.
    rewrite H4; rewrite H5.
    assumption.
    assert (is_list_sorted ODT_lt_dec (domain l') = true).
    revert pf1.
    destruct l'.
    reflexivity.
    simpl.
    destruct (StringOrder.lt_dec (fst y) (fst p)); congruence.
    assert (is_list_sorted ODT_lt_dec
                (domain (rec_sort (l' ++ τ₂))) = true)
      by (apply (@rec_sort_sorted string ODT_string) with (l1 := l' ++ τ₂); reflexivity).
    specialize (IHForall2 H8 H9).
    inversion H1.
    specialize (IHForall2 H12).
    assert (is_list_sorted ODT_lt_dec (domain l') = true).
    revert pf1.
    destruct l'; try reflexivity; simpl.
    destruct (StringOrder.lt_dec (fst y) (fst p)); congruence.
    assert (is_list_sorted ODT_lt_dec (domain l') = true)
      by (apply (@rec_sorted_skip_first string ODT_string _ l' y); assumption).
    assert (rec_sort l' = l')
      by (apply rec_sorted_id; assumption).
    assert (is_list_sorted ODT_lt_dec (domain l) = true)
      by (apply (sorted_forall_sorted l l'); assumption).
    assert (rec_sort l = l)
      by (apply rec_sorted_id; assumption).
    specialize (IHForall2 H16 H14).
    clear H4 H5 H12 H10 H13 H14 H15 H16.
    elim H; intros; clear H H4.
    clear pf1 pf2.
    assert (is_list_sorted
              ODT_lt_dec
              (domain
                 (insertion_sort_insert rec_field_lt_dec x (rec_sort (l ++ dl0)))) =
            true).
    apply (insert_and_foralls_mean_same_sort l dl0 l' τ₂ x y); assumption.
    apply Forall2_cons_sorted; assumption.
  Qed.

  Lemma concat_well_typed {τ₁ τ₂ τ₃} d1 d2 pf1 pf2 pf3:
    rec_concat_sort τ₁ τ₂ = τ₃ ->
    data_type d1 (Rec Closed τ₁ pf1) ->
    data_type d2 (Rec Closed τ₂ pf2) ->
    exists dl dl0 d3,
      d1 = drec dl /\
      d2 = drec dl0 /\
      ((rec_sort (dl ++ dl0)) = d3) /\
      data_type (drec d3) (Rec Closed τ₃ pf3).
  Proof.
    intros.
    destruct (data_type_Rec_inv H0); subst.
    destruct (data_type_Rec_inv H1); subst.
    apply dtrec_closed_inv in H0.
    apply dtrec_closed_inv in H1.
    do 3 eexists; do 3 (split; try reflexivity).
    apply dtrec_full.
    apply rec_concat_with_drec_concat_well_typed; assumption.
  Qed. 

  Lemma rremove_well_typed τ s dl:
    Forall2
      (fun (d : string * data) (r : string * rtype) =>
         fst d = fst r /\ data_type (snd d) (snd r)) dl τ ->
    is_list_sorted ODT_lt_dec (domain τ) = true ->
    Forall2
      (fun (d : string * data) (r : string * rtype) =>
         fst d = fst r /\ data_type (snd d) (snd r)) (rremove dl s)
      (rremove τ s).
  Proof.
    intros.
    induction H.
    apply Forall2_nil.
    simpl.
    assert (is_list_sorted ODT_lt_dec (domain l') = true)
      by (apply (@rec_sorted_skip_first string ODT_string _ l' y); assumption).
    specialize (IHForall2 H2); clear H2.
    elim H; clear H; intros.
    rewrite H in *.
    elim (string_dec s (fst y)); intros.
    assumption.
    apply Forall2_cons.
    split; assumption.
    assumption.
  Qed.
    
  Lemma rproject_well_typed τ rl s dl:
    Forall2
      (fun (d : string * data) (r : string * rtype) =>
         fst d = fst r /\ data_type (snd d) (snd r)) dl rl ->
    sublist s (domain τ) ->
    sublist τ rl ->
    is_list_sorted ODT_lt_dec (domain τ) = true ->
    is_list_sorted ODT_lt_dec (domain rl) = true ->
    Forall2
      (fun (d : string * data) (r : string * rtype) =>
         fst d = fst r /\ data_type (snd d) (snd r)) (rproject dl s)
      (rproject τ s).
  Proof.
    intros.
    assert (sublist s (domain rl)) by
        (apply (sublist_trans s (domain τ) (domain rl)); try assumption;
         apply sublist_domain; assumption).
    assert (NoDup (domain rl))
      by (apply is_list_sorted_NoDup_strlt; assumption).
    rewrite (rproject_sublist τ rl s H2 H3); try assumption.
    clear H0 H1 H4 H2.
    induction H.
    - apply Forall2_nil.
    - inversion H5; subst.
      assert (is_list_sorted ODT_lt_dec (domain l') = true)
        by (apply (@rec_sorted_skip_first string ODT_string _ l' y); assumption).
      specialize (IHForall2 H1 H6).
      elim H; intros.
      simpl; rewrite H2.
      destruct (in_dec string_dec (fst y) s).
      apply Forall2_cons; try assumption; split; assumption.
      assumption.
  Qed.
  
  (** Main type-soundness lemma for binary operators *)

  Require Import RelationClasses EquivDec.
  Existing Instance rec_field_lt_strict.

  (* key idea: any overlap must have the same data.
      so we can give it the same type.  and we need only do that 
      for things not in the subset, since they are already compatible.
   *)
(* s is what we care about from l.
    l2 is what we take from if we don't care 
*)
  Definition mapTopNotSub s l2 (l:list (string*rtype)) :=
    map (fun xy => (fst xy, if in_dec string_dec (fst xy) s
                            then snd xy
                            else match lookup string_dec l2 (fst xy) with
                                   | Some y' => y'
                                   | None => Top
                                 end
                   )) l.

  Lemma mapTopNotSub_domain s l2 l :
    domain (mapTopNotSub s l2 l) = domain l.
  Proof.
    induction l; simpl; congruence.
  Qed.
  
  Lemma mapTopNotSub_in {s l x} l2:
    In (fst x) s -> In x l -> In x (mapTopNotSub s l2 l).
  Proof.
    induction l; simpl; intuition.
    subst. destruct x; simpl in *.
    match_destr; intuition.
  Qed.

  Lemma mapTopNotSub_in2 {s l x y} l2:
      ~ In x s -> In x (domain l) -> lookup string_dec l2 x = Some y -> In (x,y) (mapTopNotSub s l2 l).
  Proof.
    induction l; simpl; intuition.
    subst.
    match_destr; intuition.
    rewrite H1. intuition.
  Qed.

    Lemma in_mapTopNotSub {s l x} l2:
    In (fst x) s -> In x (mapTopNotSub s l2 l) -> In x l.
  Proof.
    induction l; simpl; intuition.
      destruct a; subst. simpl in *. 
      match_destr; intuition.
  Qed.
    
  Lemma mapTopNotSub_in_sublist {s l x} l2 :
    sublist s l ->
      In x s -> In x (mapTopNotSub (domain s) l2 l).
  Proof.
    intros.
    eapply mapTopNotSub_in; eauto.
    - destruct x. apply in_dom in H0; simpl; trivial.
    - eapply sublist_In; eauto.
  Qed.
    
  Lemma mapTopNotSub_sublist {s l s'} l2:
    sublist s l ->
    sublist s s' ->
    sublist s (mapTopNotSub (domain s') l2 l).
  Proof.
    revert s s'.
    induction l; inversion 1; subst.
    - constructor.
    - simpl; intros.
      destruct a; simpl in *.
      match_destr.
      + apply sublist_cons. apply IHl; trivial.
           eapply sublist_skip_l; eauto.
      + elim n. 
        eapply in_dom.
        eapply (sublist_In H0).
        simpl. left; reflexivity.
    - simpl; intros.
      destruct a; simpl in *.
      apply sublist_skip; auto.
  Qed.

  Lemma mapTopNotSub_sublist_same {s l} l2:
    sublist s l ->
    sublist s (mapTopNotSub (domain s) l2 l).
  Proof.
    intros. apply mapTopNotSub_sublist; trivial.
    reflexivity.
  Qed.
  

  Lemma mapTopNotSub_in_inv {s l2 l x} :
    In x (mapTopNotSub s l2 l) ->
    (In (fst x) s /\ In x l) \/
    (~ In (fst x) s /\
     (In x l2 \/
      (~ In (fst x) (domain l2) /\ snd x = Top))).
  Proof.
    induction l; simpl; intuition.
    destruct x. destruct a; simpl in *.
    inversion H0; simpl in *; subst.
    match_destr; intuition. 
    right; split; trivial.
    
    match_case; intros.
    - left. eapply lookup_in; eauto.
    -  apply lookup_none_nin in H.  intuition. 
  Qed.

  Lemma mapTopNotSub_compatible {t1 t2} rl1 rl2 :
    NoDup (domain rl1) -> NoDup (domain rl2) ->
    sublist t1 rl1 ->
    sublist t2 rl2 ->
  compatible t1 t2 = true ->
    compatible (mapTopNotSub (domain t1) t2 rl1)
               (mapTopNotSub (domain t2) t1 rl2) = true.
  Proof.
    unfold compatible, RCompat.compatible.
    repeat rewrite forallb_forall.
    unfold compatible_with.
    intros.
    match_case; intros.
    match_destr. elim c; clear c; red.
    destruct x; simpl in *.
    apply assoc_lookupr_in in H5.
    generalize (mapTopNotSub_in_inv H4); simpl.
    intuition.
    - destruct (in_domain_in H6) as [r' inn].
       specialize (H3 _ inn).
       simpl in *.
       apply in_mapTopNotSub in H4; simpl; trivial.
       apply (sublist_In H1) in inn.
       generalize (nodup_in_eq H inn H4); intros; subst.
       match_case_in H3; intros.
       + rewrite H7 in H3.
         match_destr_in H3. unfold equiv in *; subst.
         apply assoc_lookupr_in in H7.
         apply in_mapTopNotSub in H5; simpl; trivial.
         * apply (sublist_In H2) in H7.
           generalize (nodup_in_eq H0 H7 H5); trivial.
         * eapply in_dom; eauto.
       + clear H3.
          apply mapTopNotSub_in_inv in H5.
          simpl in *.
          apply assoc_lookupr_none_nin in H7.
          intuition.
          generalize (sublist_In H1 _ H3); intros ? .
          eapply (nodup_in_eq H H8 H9); eauto.
    - apply mapTopNotSub_in_inv in H5. simpl in *.
      intuition.
      + generalize (sublist_In H2 _ H7); intros.
         eapply (nodup_in_eq H0); eauto.
      + apply in_dom in H8; intuition.
      + apply in_dom in H7. intuition.
    - apply mapTopNotSub_in_inv in H5. simpl in *.
      intuition.
      + apply in_dom in H7. intuition.
      + congruence.
  Qed.    

  Require Import Bool.

  Lemma Forall2_compat_mapTopNotSub {x x0 rl rl0 t2} t1:
    is_list_sorted ODT_lt_dec (domain rl) = true ->
    is_list_sorted ODT_lt_dec (domain rl0) = true ->
    sublist t2 rl0 ->
    Forall2  (fun (d : string * data) (r : string * rtype) =>
                fst d = fst r /\ snd d ▹ snd r) x rl ->
        Forall2  (fun (d : string * data) (r : string * rtype) =>
                fst d = fst r /\ snd d ▹ snd r) x0 rl0 ->
        compatible x x0 = true ->
        Forall2
          (fun (d : string * data) (r : string * rtype) =>
             fst d = fst r /\ snd d ▹ snd r) x (mapTopNotSub t1 t2 rl).
  Proof.
    revert x x0 rl0 t1 t2.
    induction rl; intros; inversion H2; subst; auto 1.
    clear H2.
    destruct x1; destruct a; simpl in H8; destruct H8; subst.
    simpl.
    constructor.
    - simpl; split; trivial.
      match_destr.
      match_case; intros; eauto 2.
      apply lookup_in in H2.
      destruct (Forall2_In_r H3 (sublist_In H1 _ H2)) as [[??] [?[??]]].
      simpl in *; subst.
      rewrite andb_true_iff in H4. destruct H4 as [cw _ ].
      unfold compatible_with in cw.
      match_case_in cw; intros.
      + rewrite H4 in cw. match_destr_in cw.
         unfold equiv in *; subst.
         apply assoc_lookupr_in in H4.
         assert (nd:NoDup (domain x0)).
         (rewrite (sorted_forall_same_domain H3); eauto 2).
         generalize (nodup_in_eq nd H4 H6); intros; subst.
         trivial.
      + apply assoc_lookupr_none_nin in H4. apply in_dom in H6.
         intuition.
    - eapply IHrl; eauto 3.
      + eapply is_list_sorted_cons_inv; eauto.
      + unfold compatible, RCompat.compatible in *. rewrite forallb_forall in *.
         intros. apply H4; simpl; intuition.
  Qed.

  Lemma Forall2_compat_app_strengthen {x x0 rl rl0 t1 t2}:
    is_list_sorted ODT_lt_dec (domain rl) = true ->
    is_list_sorted ODT_lt_dec (domain rl0) = true ->
    sublist t1 rl ->
    sublist t2 rl0 ->
    compatible t1 t2 = true ->
    Forall2  (fun (d : string * data) (r : string * rtype) =>
                fst d = fst r /\ snd d ▹ snd r) x rl ->
        Forall2  (fun (d : string * data) (r : string * rtype) =>
                fst d = fst r /\ snd d ▹ snd r) x0 rl0 ->
        compatible x x0 = true -> 
        exists rl' rl0',
          compatible rl' rl0' = true /\
          sublist t1 rl' /\
          sublist t2 rl0' /\
          Forall2  (fun (d : string * data) (r : string * rtype) =>
                      fst d = fst r /\ snd d ▹ snd r) x rl' /\
          Forall2  (fun (d : string * data) (r : string * rtype) =>
                      fst d = fst r /\ snd d ▹ snd r) x0 rl0'.
  Proof.
    intros.
    exists (mapTopNotSub (domain t1) t2 rl).  
    exists (mapTopNotSub (domain t2) t1 rl0).
    intuition.
    - apply mapTopNotSub_compatible; eauto.
    - apply mapTopNotSub_sublist_same; trivial.
    - apply mapTopNotSub_sublist_same; trivial.
    - eapply Forall2_compat_mapTopNotSub; eauto.
    - eapply Forall2_compat_mapTopNotSub;
        try eapply H4; eauto.
      + unfold compatible in *. apply compatible_true_sym in H6; trivial.
         rewrite (sorted_forall_same_domain H5); eauto.
  Qed.                 

  Lemma sorted_sublists_sorted_concat (τ₁ τ₂ rl rl0:list (string*rtype)):
    is_list_sorted ODT_lt_dec (domain τ₁) = true ->
    is_list_sorted ODT_lt_dec (domain τ₂) = true ->
    is_list_sorted ODT_lt_dec (domain rl) = true ->
    is_list_sorted ODT_lt_dec (domain rl0) = true ->
    compatible rl rl0 = true ->
    sublist τ₁ rl ->
    sublist τ₂ rl0 ->
    sublist (rec_sort (τ₁ ++ τ₂)) (rec_sort (rl ++ rl0)).
  Proof.
    intros.
    eapply Sorted_incl_sublist; eauto; try apply insertion_sort_Sorted.
    intros.
    generalize (in_insertion_sort H6); intros inn.
    apply insertion_sort_in_strong.
    - apply compatible_asymmetric_over.
      apply compatible_app_compatible; trivial.
    - clear H6. revert x inn. apply sublist_In.
      apply sublist_app; trivial.
  Qed.

  Lemma typed_binop_yields_typed_data {τ₁ τ₂ τout} (d1 d2:data) (b:binOp) :
    (d1 ▹ τ₁) -> (d2 ▹ τ₂) -> (binOp_type  b τ₁ τ₂ τout) ->
    (exists x, fun_of_binop brand_relation_brands b d1 d2 = Some x /\ x ▹ τout).
  Proof.
    Hint Constructors data_type.
    intros.
    binOp_type_cases (dependent induction H1) Case; simpl.
    - Case "ATEq"%string.
      unfold unbdata.
      destruct (if data_eq_dec d1 d2 then true else false).
      exists (dbool true); split; [reflexivity|apply dtbool].
      exists (dbool false); split; [reflexivity|apply dtbool].
    - Case "ATConcat"%string.
      assert(exists dl dl0 d3,
               d1 = drec dl /\
               d2 = drec dl0 /\
               ((rec_sort (dl ++ dl0)) = d3) /\
               data_type (drec d3) (Rec Closed τ₃ pf3)).
      apply (concat_well_typed d1 d2 pf1 pf2 pf3); assumption.
      elim H2; clear H2; intros.
      elim H2; clear H2; intros.
      elim H2; clear H2; intros.
      elim H2; clear H2; intros.
      elim H3; clear H3; intros.
      elim H4; clear H4; intros.
      rewrite H2; rewrite H3; clear H0 H1.
      exists (drec x1).
      rewrite <- H4 in *.
      split; [reflexivity|assumption].
    - Case "ATMergeConcat"%string.
      destruct (data_type_Rec_inv H); subst.
      destruct (data_type_Rec_inv H0); subst.
      apply dtrec_closed_inv in H.
      apply dtrec_closed_inv in H0.
      unfold merge_bindings in *.
      destruct (RCompat.compatible τ₁ τ₂); try discriminate.
      inversion H1; clear H1; subst.
      destruct (RCompat.compatible x x0);
        (eexists; split; [reflexivity|]); eauto.
      econstructor. econstructor; eauto.
      apply dtrec_full.
      unfold rec_concat_sort.
      apply rec_concat_with_drec_concat_well_typed; auto.
    - Case "ATMergeConcatOpen"%string.
      destruct (data_type_Rec_inv H); subst.
      destruct (data_type_Rec_inv H0); subst.
      inversion H; clear H; subst; clear H6.
      inversion H0; clear H0; subst; clear H8.
      rtype_equalizer. subst.
      case_eq (merge_bindings x x0); intros.
      + unfold merge_bindings in *.
        case_eq (RCompat.compatible τ₁ τ₂); intros eqq; rewrite eqq in *; try discriminate.
        inversion H1; clear H1; subst.
        case_eq (RCompat.compatible x x0); intros eqq2; rewrite eqq2 in *;
          (eexists; split; [reflexivity | ]); eauto.
        * econstructor. econstructor; eauto.
          inversion H; clear H; subst.
          assert (is_list_sorted ODT_lt_dec (domain (rec_sort (rl ++ rl0))) = true)
            by (apply (@rec_sort_sorted string ODT_string _ (rl++rl0)); reflexivity).
          destruct (Forall2_compat_app_strengthen pf' pf'0 H5 H6 eqq H7 H9 eqq2) as [rl'[rl0' [?[?[?[??]]]]]].
          assert(pfrl':is_list_sorted ODT_lt_dec (domain rl') = true).
          rewrite <- (sorted_forall_same_domain H3).
          rewrite (sorted_forall_same_domain H7); trivial.
          assert(pfrl0':is_list_sorted ODT_lt_dec (domain rl0') = true).
          rewrite <- (sorted_forall_same_domain H4).
          rewrite (sorted_forall_same_domain H9); trivial.
          (* need a lemma about strengthening here *)
          apply (@dtrec_open _ _ _ _ (rec_sort (x ++ x0)) (rec_sort (rl' ++ rl0'))); try assumption.
          eauto.
          apply sorted_sublists_sorted_concat; trivial.
          apply rec_concat_with_drec_concat_well_typed; try assumption.
          unfold rec_concat_sort.
          eauto.
        * congruence.
      + exists (dcoll []); split; try reflexivity;
        apply dtcoll; apply Forall_nil.
    - Case "ATAnd"%string.
      dependent induction H; dependent induction H0; simpl.
      exists (dbool (b && b0)).
      split; [reflexivity|apply dtbool].
    - Case "ATOr"%string.
      dependent induction H; dependent induction H0; simpl.
      exists (dbool (b || b0)).
      split; [reflexivity|apply dtbool].
    - Case "ATBArith"%string.
      dependent induction H; dependent induction H0; simpl.
      eauto.
    - Case "ATLt"%string.
      dependent induction H; dependent induction H0; simpl.
      exists (dbool (if Z_lt_dec n n0 then true else false)).
      split; [reflexivity|apply dtbool].
    - Case "ATLe"%string.
      dependent induction H; dependent induction H0; simpl.
      exists (dbool (if Z_le_dec n n0 then true else false)).
      split; [reflexivity|apply dtbool].
    - Case "ATUnion"%string.
      dependent induction H; dependent induction H0; simpl.
      autorewrite with alg.
      exists (dcoll (bunion dl dl0)).
      split; [reflexivity|apply dtcoll].
      assert (r = τ) by (apply rtype_fequal; assumption).
      assert (r0 = τ) by (apply rtype_fequal; assumption).
      rewrite H1 in *; rewrite H2 in *.
      apply forall_typed_bunion; assumption.
    - Case "ATMinus"%string.
      dependent induction H; dependent induction H0; simpl.
      autorewrite with alg.
      exists (dcoll (bminus dl dl0)).
      split; [reflexivity|apply dtcoll].
      assert (r = τ) by (apply rtype_fequal; assumption).
      assert (r0 = τ) by (apply rtype_fequal; assumption).
      rewrite H1 in *; rewrite H2 in *.
      apply forall_typed_bminus; assumption.
    - Case "ATMin"%string.
      dependent induction H; dependent induction H0; simpl.
      autorewrite with alg.
      exists (dcoll (bmin dl dl0)).
      split; [reflexivity|apply dtcoll].
      assert (r = τ) by (apply rtype_fequal; assumption).
      assert (r0 = τ) by (apply rtype_fequal; assumption).
      rewrite H1 in *; rewrite H2 in *.
      apply forall_typed_bmin; assumption.
    - Case "ATMax"%string.
      dependent induction H; dependent induction H0; simpl.
      autorewrite with alg.
      exists (dcoll (bmax dl dl0)).
      split; [reflexivity|apply dtcoll].
      assert (r = τ) by (apply rtype_fequal; assumption).
      assert (r0 = τ) by (apply rtype_fequal; assumption).
      rewrite H1 in *; rewrite H2 in *.
      apply forall_typed_bmax; assumption.
    - Case "ATContains"%string.
      inversion H0.
      rtype_equalizer; subst.
      dependent induction H0.
      rtype_equalizer; subst. subst.
      simpl.
      destruct (in_dec data_eq_dec d1 dl).
      + exists (dbool true).
        split; try reflexivity.
        apply dtbool.
      + exists (dbool false).
        split; try reflexivity.
        apply dtbool.
    - Case "ATSConcat"%string.
      dependent induction H; dependent induction H0; simpl.
      eauto.
    - Case "ATForeignBinaryOp"%string.
      eapply foreign_binary_op_typing_sound; eauto.
  Qed.

  (* TODO: move this stuff *)
  Definition canon_brands_alt {br:brand_relation} (b:brands) :=
    fold_right meet [] (map (fun x => x::nil) b).

  Lemma canon_brands_alt_is_canon {br:brand_relation} (b:brands) :
    is_canon_brands brand_relation_brands (canon_brands_alt b).
  Proof.
    unfold canon_brands_alt.
    destruct b; simpl.
    - red; intuition.
    - apply brand_meet_is_canon.
  Qed.

  Lemma canon_brands_fold_right_hoist {br:brand_relation} (l:list brands) :
    fold_right
      (fun a b : brands => canon_brands brand_relation_brands (a ++ b))
      [] l =
    canon_brands brand_relation_brands
                 (fold_right (fun a b : brands => (a ++ b))
                             [] l).
  Proof.
    induction l; simpl.
    - reflexivity.
    - rewrite IHl.
      rewrite app_commutative_equivlist.
      rewrite canon_brands_canon_brands_app1.
      rewrite app_commutative_equivlist.
      trivial.
  Qed.
  
  Lemma canon_brands_alt_equiv {br:brand_relation} (b:brands) :
    canon_brands brand_relation_brands b
    =  canon_brands_alt b.
  Proof.
    unfold canon_brands_alt.
    unfold meet; simpl.
    unfold brand_meet.
    rewrite canon_brands_fold_right_hoist.
    f_equal.
    generalize (fold_right_app_map_singleton b); simpl.
    auto.
  Qed.

  Require Import Permutation.

  (** Main type-soundness lemma for unary operators *)
  Lemma typed_unop_yields_typed_data {τ₁ τout} (d1:data) (u:unaryOp) :
    (d1 ▹ τ₁) -> (unaryOp_type u τ₁ τout) ->
    (exists x, fun_of_unaryop brand_relation_brands u d1 = Some x /\ x ▹ τout).
  Proof.
    Hint Resolve dtsome dtnone.

    intros.
    unaryOp_type_cases (dependent induction H0) Case; simpl.
    - Case "ATIdOp"%string.
      eauto.
    - Case "ATNeg"%string.
       dependent induction H; simpl.
      exists (dbool (negb b)).
      split; [reflexivity|apply dtbool].
    - Case "ATColl"%string.
      exists (dcoll [d1]); split; try
      reflexivity.  apply dtcoll; apply Forall_forall; intros.  elim H0;
      intros.  rewrite <- H1; assumption.  contradiction.
    - Case "ATSingleton"%string.
      inversion H; rtype_equalizer.
      subst.
      repeat (destruct dl; eauto).
      inversion H2; subst.
      eauto.
    - Case "ATFlatten"%string.
      dependent induction H.
      rewrite Forall_forall in *.
      unfold rflatten.
      induction dl; simpl in *.
      exists (dcoll []).
      split; try reflexivity.
      apply dtcoll; apply Forall_nil.
      assert (forall x : data, In x dl -> data_type x r) by
          (intros; apply (H x0); right; assumption).
      elim (IHdl H0); clear IHdl H0; intros.
      elim H0; clear H0; intros.
      unfold lift in H0.
      assert (exists a', oflat_map
           (fun x : data =>
            match x with
            | dcoll y => Some y
            | _ => None
            end) dl = Some a' /\ x0 = (dcoll a')).
      revert H0.
      destruct (oflat_map
       (fun x1 : data =>
        match x1 with
          | dcoll y => Some y
          | _ => None
        end) dl); intros.
      inversion H0.
      exists l; split; reflexivity.
      congruence.
      elim H2; clear H2; intros.
      elim H2; clear H2; intros.
      rewrite H2; clear H2 H0.
      assert (data_type a r)
        by (apply (H a); left; reflexivity).
      assert (r = Coll τ) by (apply rtype_fequal; assumption).
      rewrite H2 in *; clear H2.
      dependent induction H0.
      assert (r0 = τ) by (apply rtype_fequal; assumption).
      simpl.
      exists (dcoll (dl0 ++ x1)); split; try reflexivity.
      apply dtcoll.
      dependent induction H1.
      assert (r1 = τ) by (apply rtype_fequal; assumption).
      apply Forall_app; rewrite Forall_forall in *.
      rewrite H2 in *; assumption.
      rewrite H3 in *; assumption.
    - Case "ATDistinct"%string.
      dependent induction H.
      autorewrite with alg.
      exists (dcoll (bdistinct dl)).
      split; [reflexivity|apply dtcoll].
      assert (r = τ) by (apply rtype_fequal; assumption).
      rewrite H0 in *.
      apply forall_typed_bdistinct; assumption.
    - Case "ATRec"%string.
      exists (drec [(s,d1)]).
      split; [reflexivity|apply dtrec_full].
      apply Forall2_cons.
      split; [reflexivity|assumption].
      apply Forall2_nil.
    - Case "ATDot"%string.
      dependent induction H. rtype_equalizer; subst.
      unfold tdot in *.
      unfold edot in *.
      apply (Forall2_lookupr_some _ _ _ _ H1).
      eapply assoc_lookupr_nodup_sublist; eauto.
    - Case "ATRecRemove"%string.
      dependent induction H; rtype_equalizer. subst.
      exists (drec (rremove dl s)); split; try reflexivity.
      eapply dtrec; try (apply rremove_well_typed; [eassumption |]).
      + apply is_sorted_rremove; trivial.
      + apply sublist_filter; trivial.
      + intuition; congruence.
      + trivial.
    - Case "ATRecProject"%string.
      dependent induction H.
      rtype_equalizer ; subst.
      exists (drec (rproject dl sl)); split; try reflexivity.
      apply dtrec_full.
      clear H0 pf1.
      apply (rproject_well_typed τ rl); try assumption.
    - Case "ATCount"%string.
      dependent induction H.
      autorewrite with alg.
      exists (dnat (Z_of_nat (bcount dl))).
      split; [reflexivity|apply dtnat].
    - Case "ATSum"%string.
      dependent induction H. revert r x H. induction dl; simpl; [eauto|intros].
      inversion H; subst. destruct (IHdl r x H3) as [x0 [x0eq x0d]].
      destruct H2; try solve[simpl in x; discriminate].
      simpl in *.
      destruct (some_lift x0eq); subst.
      rewrite e. simpl. eauto.
    - Case "ATNumMin"%string.
      dependent induction H.
      destruct r.
      destruct x0; simpl in x; try congruence.
      induction dl. rewrite Forall_forall in H.
      unfold lifted_min; simpl.
      exists (dnat 0). auto.
      inversion H. subst.
      specialize (IHdl H3).
      elim IHdl; clear IHdl; intros.
      elim H0; clear H0; intros.
      unfold lifted_min in *.
      unfold lift in *.
      unfold lifted_zbag in *.
      assert (Nat = (exist (fun τ₀ : rtype₀ => wf_rtype₀ τ₀ = true) Nat₀ e))
        by (apply rtype_fequal; reflexivity).
      rewrite <- H4 in H2.
      destruct (data_type_Nat_inv H2); subst.
      simpl.
      destruct (rmap (ondnat (fun x3 : Z => x3)) dl); try congruence.
      simpl.
      exists (dnat (fold_right (fun x3 y : Z => Z.min x3 y) x1 l)).
      split; [reflexivity|auto].
    - Case "ATNumMax"%string.
      dependent induction H.
      destruct r.
      destruct x0; simpl in x; try congruence.
      induction dl. rewrite Forall_forall in H.
      unfold lifted_max; simpl.
      exists (dnat 0). auto.
      inversion H. subst.
      specialize (IHdl H3).
      elim IHdl; clear IHdl; intros.
      elim H0; clear H0; intros.
      unfold lifted_max in *.
      unfold lift in *.
      unfold lifted_zbag in *.
      assert (Nat = (exist (fun τ₀ : rtype₀ => wf_rtype₀ τ₀ = true) Nat₀ e))
        by (apply rtype_fequal; reflexivity).
      rewrite <- H4 in H2.
      destruct (data_type_Nat_inv H2); subst.
      simpl.
      destruct (rmap (ondnat (fun x3 : Z => x3)) dl); try congruence.
      simpl.
      exists (dnat (fold_right (fun x3 y : Z => Z.max x3 y) x1 l)).
      split; [reflexivity|auto].
    - Case "ATArithMean"%string.
      assert(dsum_pf:exists x : data, lift dnat (lift_oncoll dsum d1) = Some x /\ x ▹ Nat).
      {dependent induction H. revert r x H. induction dl; simpl; [eauto|intros].
      inversion H; subst. destruct (IHdl r x H3) as [x0 [x0eq x0d]].
      destruct H2; try solve[simpl in x; discriminate].
      simpl in *.
      destruct (some_lift x0eq); subst.
      rewrite e. simpl. eauto.
      }
      destruct dsum_pf as [x [xeq xtyp]].
      dtype_inverter.
      apply some_lift in xeq.
      destruct xeq as [? eqq1 eqq2].
      simpl in eqq1.
      inversion eqq2; clear eqq2; subst.
      destruct (is_nil_dec d1); simpl.
      + subst; simpl; eauto.
      + exists (dnat (Z.quot x (Z_of_nat (length d1)))).
         split; [ | constructor ].
         unfold darithmean.
         rewrite eqq1; simpl.
         destruct d1; simpl; congruence.
    - Case "ATToString"%string.
      eauto.
    - Case "ATLeft"%string.
      eauto.
    - Case "ATRight"%string.
      eauto.
    - Case "ATBrand"%string.
      eexists; split; try reflexivity.
      apply dtbrand'.
      + eauto.
      + rewrite brands_type_of_canon; trivial.
      + rewrite canon_brands_equiv; reflexivity.
    - Case "ATUnbrand"%string.
      destruct d1; try solve[inversion H].
      apply dtbrand'_inv in H.
      destruct H as [isc [dt subb]].
      eexists; split; try reflexivity.
      rewrite subb in dt.
      trivial.
    - Case "ATCast"%string.
      inversion H; subst.
      match_destr; [| eauto].
      econstructor; split; try reflexivity.
      constructor. 
      econstructor; eauto.
    - Case "ATUArith"%string.
      dependent induction H; simpl.
      eauto.
    - Case "ATForeignUnaryOp"%string.
      eapply foreign_unary_op_typing_sound; eauto.
  Qed.

  (** Additional auxiliary lemmas *)

  Lemma tdot_rec_concat_sort_neq {A} (l:list (string*A)) a b xv :
       a <> b ->
       tdot (rec_concat_sort l [(a, xv)]) b = 
       tdot (rec_sort l) b.
   Proof.
     unfold tdot, edot; intros.
     unfold rec_concat_sort.
     apply (@assoc_lookupr_drec_sort_app_nin string ODT_string).
     simpl; intuition.
   Qed.

  Lemma tdot_rec_concat_sort_eq {A} (l : list (string * A)) a b :
               ~ In a (domain l) ->
               tdot (rec_concat_sort l [(a, b)]) a = Some b.
  Proof.
    unfold tdot.
    apply (@assoc_lookupr_insertion_sort_fresh string ODT_string).
  Qed.
  
End TOps.

  Tactic Notation "unaryOp_type_cases" tactic(first) ident(c) :=
  first;
    [ Case_aux c "ATIdOp"%string
    | Case_aux c "ATNeg"%string
    | Case_aux c "ATColl"%string
    | Case_aux c "ATSingleton"%string
    | Case_aux c "ATFlatten"%string
    | Case_aux c "ATDistinct"%string
    | Case_aux c "ATRec"%string
    | Case_aux c "ATDot"%string
    | Case_aux c "ATRecRemove"%string
    | Case_aux c "ATRecProject"%string
    | Case_aux c "ATCount"%string
    | Case_aux c "ATSum"%string
    | Case_aux c "ATNumMin"%string
    | Case_aux c "ATNumMax"%string
    | Case_aux c "ATArithMean"%string
    | Case_aux c "ATToString"%string
    | Case_aux c "ATLeft"%string
    | Case_aux c "ATRight"%string
    | Case_aux c "ATBrand"%string
    | Case_aux c "ATUnbrand"%string
    | Case_aux c "ATCast"%string
    | Case_aux c "ATUArith"%string
    | Case_aux c "ATForeignUnaryOp"%string].


  Tactic Notation "binOp_type_cases" tactic(first) ident(c) :=
    first;
    [ Case_aux c "ATEq"%string
    | Case_aux c "ATConcat"%string
    | Case_aux c "ATMergeConcat"%string
    | Case_aux c "ATMergeConcatOpen"%string
    | Case_aux c "ATAnd"%string
    | Case_aux c "ATOr"%string
    | Case_aux c "ATBArith"%string
    | Case_aux c "ATLt"%string
    | Case_aux c "ATLe"%string
    | Case_aux c "ATUnion"%string
    | Case_aux c "ATMinus"%string
    | Case_aux c "ATMin"%string
    | Case_aux c "ATMax"%string
    | Case_aux c "ATContains"%string
    | Case_aux c "ATSConcat"%string
    | Case_aux c "ATForeignBinaryOp"%string].

(* 
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "QCert")) ***
*** End: ***
*)

