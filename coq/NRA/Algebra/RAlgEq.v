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

(*******************************
 * Algebra constructors proper *
 *******************************)

Section RAlgEq.

  Require Import Equivalence.
  Require Import Morphisms.
  Require Import Setoid.
  Require Import EquivDec.
  Require Import Program.

  Require Import List.
  Require Import String.

  Require Import Utils BasicRuntime.
  Require Import RAlg.

  Local Open Scope alg_scope.

  Context {fruntime:foreign_runtime}.

  (* Equivalence relation between algebraic plans.
     Two plans are equivalent iff they return the same value for every input.
   *)
  
  Definition alg_eq (op1 op2:alg) : Prop :=
    forall (h:list(string*string)),
    forall x:data,
      data_normalized h x ->
      h ⊢ op1 @ₐ x = h ⊢ op2 @ₐ x.

  Global Instance alg_equiv : Equivalence alg_eq.
  Proof.
    constructor.
    - unfold Reflexive, alg_eq.
      intros; reflexivity.
    - unfold Symmetric, alg_eq.
      intros. rewrite H; trivial.
    - unfold Transitive, alg_eq.
      intros.
      rewrite H, H0 by trivial.
      trivial.
  Qed.

  (* all the algebraic constructors are proper wrt. equivalence *)

  (* AID *)
  Global Instance aid_proper : Proper alg_eq AID.
  Proof.
    unfold Proper, respectful, alg_eq.
    intros; reflexivity.
  Qed.

  (* AConst *)
  Global Instance aconst_proper : Proper (eq ==> alg_eq) AConst.
  Proof.
    unfold Proper, respectful, alg_eq.
    intros; rewrite H; reflexivity.
  Qed.

  (* ABinop *)

  Global Instance abinop_proper : Proper (binop_eq ==> alg_eq ==> alg_eq ==> alg_eq) ABinop.
  Proof.
    unfold Proper, respectful, alg_eq.
    intros; simpl.
    rewrite H0, H1 by trivial.
    case_eq (h ⊢ y1 @ₐ x2); case_eq (h ⊢ y0 @ₐ x2); simpl; trivial.
    intros.
    rewrite (H h); eauto.
  Qed.

  (* AUnop *)
  Global Instance aunop_proper : Proper (unaryop_eq ==> alg_eq ==> alg_eq) AUnop.
  Proof.
    unfold Proper, respectful, alg_eq.
    intros; simpl.
    rewrite (H0 h x1) by trivial.
    case_eq (h ⊢ y0 @ₐ x1); simpl; trivial; intros.
    rewrite (H h); eauto.
  Qed.
    
  Hint Resolve data_normalized_dcoll_in.

  (* AMap *)
  Global Instance amap_proper : Proper (alg_eq ==> alg_eq ==> alg_eq) AMap.
  Proof.
    unfold Proper, respectful.
    intros; unfold alg_eq in *; intros; simpl.
    rewrite (H0 h x1) by trivial.
    case_eq (h ⊢ y0 @ₐ x1); simpl; trivial; intros.
    destruct d; try reflexivity.
    simpl; f_equal.
    apply rmap_ext.
    eauto.
  Qed.

  (* AMapConcat *)

  Lemma oomap_concat_eq {h:list(string*string)} op1 op2 l:
    (forall x : data, h ⊢ op1 @ₐ x = h ⊢ op2 @ₐ x) ->
    oomap_concat (fun_of_alg h op1) l = oomap_concat (fun_of_alg h op2) l.
  Proof.
    intros.
    unfold oomap_concat; rewrite H; reflexivity.
  Qed.

  Global Instance amapconcat_proper : Proper (alg_eq ==> alg_eq ==> alg_eq) AMapConcat.
  Proof.
    unfold Proper, respectful.
    intros; unfold alg_eq in *; intros; simpl.
    rewrite (H0 h x1); case_eq (h ⊢ y0 @ₐ x1); intros; trivial.
    destruct d; try reflexivity.
    apply olift_ext; inversion 1; subst; intros.
    simpl. f_equal.
    apply rmap_concat_ext; intros.
    eauto.
  Qed.

  (* AProduct *)
  Global Instance aproduct_proper : Proper (alg_eq ==> alg_eq ==> alg_eq) AProduct.
  Proof.
    unfold Proper, respectful.
    intros; unfold alg_eq in *; intros; simpl.
    rewrite (H0 h x1) by trivial; rewrite (H h x1) by trivial.
    reflexivity.
  Qed.

  (* ASelect *)
  Global Instance aselect_proper : Proper (alg_eq ==> alg_eq ==> alg_eq) ASelect.
  Proof.
    unfold Proper, respectful, alg_eq.
    intros; simpl.
    rewrite (H0 h x1) by trivial.
    case_eq (h ⊢ y0 @ₐ x1); intro; trivial.
    destruct d; try reflexivity.
    intros. apply olift_ext; inversion 1; subst; intros.
    simpl.
    f_equal.
    apply lift_filter_ext; intros.
    rewrite H; trivial.
    eauto.
  Qed.

  (* ADefault *)
  Global Instance adefault_proper : Proper (alg_eq ==> alg_eq ==> alg_eq) ADefault.
  Proof.
    unfold Proper, respectful, alg_eq; intros; simpl.
    rewrite (H0 h x1) by trivial; rewrite (H h x1) by trivial.
    case_eq (h ⊢ y0 @ₐ x1); intros; case_eq (h ⊢ y @ₐ x1); intros; simpl; trivial.
  Qed.

  (* AEither *)
  Global Instance aeither_proper : Proper (alg_eq ==> alg_eq ==> alg_eq) AEither.
  Proof.
    unfold Proper, respectful, alg_eq; intros; simpl.
    destruct x1; simpl; trivial; inversion H1; subst; auto.
  Qed.

    (* AEitherConcat *)
  Global Instance aeitherconcat_proper : Proper (alg_eq ==> alg_eq ==> alg_eq) AEitherConcat.
  Proof.
    unfold Proper, respectful, alg_eq; intros; simpl.
    rewrite (H0 h x1) by trivial; rewrite (H h x1) by trivial.
    case_eq (h ⊢ y0 @ₐ x1); case_eq (h ⊢ y @ₐ x1); intros; simpl; trivial.
  Qed.

  (* AApp *)
  Global Instance aapp_proper : Proper (alg_eq ==> alg_eq ==> alg_eq) AApp.
  Proof.
    unfold Proper, respectful, alg_eq; intros; simpl.
    rewrite (H0 h x1) by trivial. case_eq (h ⊢ y0 @ₐ x1); intros; simpl; trivial.
    rewrite (H h d); eauto.
  Qed.

End RAlgEq.

Notation "X ≡ₐ Y" := (alg_eq X Y) (at level 90) : alg_scope.                             (* ≡ = \equiv *)

(* 
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "QCert")) ***
*** End: ***
*)
