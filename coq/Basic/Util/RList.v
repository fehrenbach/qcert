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

Section RList.
  Require Import List ListSet.
  Require Import Bool.

  Require Import RUtil.

  Require Import Permutation.
  Require Import Equivalence.
  Require Import Morphisms.
  Require Import Setoid.
  Require Import EquivDec.
  Require Import RelationClasses.
  Require Import Omega.

  Section misc.
    Context {A:Type}.

    Definition singleton {A} (x:A) : list A := x::nil.
    
    Lemma is_nil_dec (l:list A) : {l = nil} + {l <> nil}.
    Proof.
      destruct l.
      - eauto.
      - right; inversion 1.
    Qed.

    Fixpoint lflatten (l:list (list A)) : list A :=
      match l with
      | nil => nil
      | l1 :: l' =>
        l1 ++ (lflatten l')
      end.

    Lemma flat_map_app {B} (f:A->list B) l1 l2 :
      flat_map f (l1 ++ l2) = flat_map f l1 ++ flat_map f l2.
    Proof.
      induction l1; simpl; trivial.
      rewrite app_ass. congruence.
    Qed.
    
    Lemma map_nil f l :
      map f l = (@nil A) <-> l = (@nil A).
    Proof.
      split; intros.
      - induction l; try reflexivity; simpl in *.
        congruence.
      - rewrite H; reflexivity.
    Qed.
    
    Lemma eq_means_same_length :
      forall (l1 l2:list A),
        l1 = l2 -> (length l1) = (length l2).
    Proof.
      intros; rewrite H; reflexivity.
    Qed.

    Lemma app_cons_middle (l1 l2:list A) (a:A) :
      l1 ++ (a::l2) = (l1 ++ (a::nil))++l2.
    Proof.
      induction l1.
      reflexivity.
      simpl.
      rewrite IHl1.
      reflexivity.
    Qed.

  End misc.

  Section folds.
    Context {A B C: Type}.
    
    Lemma fold_left_map
          (f:A -> C -> A) (g:B->C) (l:list B) (init:A) :
      fold_left f (map g l) init = fold_left (fun a b => f a (g b)) l init.
    Proof.
      revert init.
      induction l; simpl; trivial.
    Qed.

    Lemma fold_left_ext
          (f g:A -> B -> A) (l:list B) (init:A) :
      (forall x y, f x y = g x y) ->
      fold_left f l init = fold_left g l init.
    Proof.
      intros eqq.
      revert init.
      induction l; simpl; trivial; intros.
      rewrite eqq, IHl.
      trivial.
    Qed.

    Lemma fold_right_app_map_singleton l : 
    fold_right (fun a b : list A => a ++ b) nil
              (map (fun x : A => (x::nil)) l) = l.
  Proof.
    induction l; simpl; congruence.
  Qed.

  Lemma fold_right_perm (f : A -> A -> A)
        (assoc:forall x y z : A, f x (f y z) = f (f x y) z) 
        (comm:forall x y : A, f x y = f y x) (l1 l2:list A) (unit:A) 
        (perm:Permutation l1 l2) :
    fold_right f unit l1 = fold_right f unit l2.
  Proof.
    revert l1 l2 perm.
    apply Permutation_ind_bis; simpl; intros.
    - trivial.
    - rewrite H0; trivial.
    - rewrite assoc, (comm y x), <- assoc, H0; trivial.
    - rewrite H0, H2; trivial.
  Qed.

  End folds.

  Section filter.
    Context {A:Type}.

    Lemma filter_length :
      forall (p:A -> bool), forall (l:list A),
          length l >= length (filter p l).
    Proof.
      intros.
      induction l; simpl.
      - auto.
      - elim (two_cases p a); intro; rewrite H; simpl; auto with arith.
    Qed.

    Lemma filter_smaller :
      forall (p:A -> bool), forall (l:list A), forall (x:A),
            filter p l <> x::l.
    Proof.
      intros.
      assert ((length (x::l)) > (length (filter p l))).
      simpl.
      assert ((length (filter p l) <= length l)).
      apply filter_length.
      auto with arith.
      assert ((length (x :: l)) <> (length (filter p l))).
      omega.
      unfold not in *; intro.
      apply H0.
      apply eq_means_same_length.
      rewrite H1.
      reflexivity.
    Qed.

    Lemma filter_filter :
      forall (p:A -> bool), forall (s:list A),
          filter p (filter p s) = filter p s.
    Proof.
      induction s.
      - reflexivity.
      - simpl. elim (two_cases p a); intro. rewrite H. simpl.
        rewrite H. rewrite IHs. reflexivity.
        rewrite H; rewrite IHs; reflexivity.
    Qed.

    Lemma filter_not_filter:
      forall (p:A -> bool), forall (s:list A),
            filter p (filter (fun x => negb (p x)) s) = nil.
    Proof.
      induction s.
      - simpl; reflexivity.
      - simpl; elim (two_cases p a); intro; rewrite H; simpl.
        rewrite IHs; reflexivity.
        rewrite H; assumption.
    Qed.

    Lemma filter_id_implies_pred :
      forall (p:A -> bool), forall (l:list A),
          filter p l = l -> forall (y:A), (In y l -> (p y = true)).
    Proof.
      intros.
      induction l; simpl in *; try contradiction.
      elim (two_cases p a); intro.
      rewrite H1 in H.
      elim H0; intro.
      rewrite <- H2; assumption.
      apply IHl.
      inversion H.
      rewrite filter_filter; reflexivity.
      assumption.
      rewrite H1 in H.
      clear H0 IHl H1.
      assert False.
      apply (filter_smaller p l a); assumption.
      contradiction.
    Qed.

    Lemma filter_nil_implies_not_pred :
      forall (p:A -> bool), forall (l:list A),
          filter p l = nil -> forall (y:A), (In y l -> (p y = false)).
    Proof.
      intros.
      induction l; simpl in *; try contradiction.
      elim (two_cases p a); intro; rewrite H1 in H.
      elim H0; intro; try discriminate.
      elim H0; intro.   
      rewrite <- H2; assumption.
      apply IHl; assumption.
    Qed.

    Lemma filter_comm:
      forall (x:list A) (p1 p2: A -> bool),
        (filter p1 (filter p2 x)) = (filter p2 (filter p1 x)).
    Proof.
      intros.
      induction x.
      simpl; reflexivity.
      simpl.
      generalize (four_cases p1 p2 a);intros.
      elim H; intro H1; elim H1; intro H2; elim H2; intros C1 C2; clear H H1 H2;
      rewrite C1; rewrite C2; simpl.
      - rewrite C1; rewrite C2; rewrite IHx; reflexivity. (* both predicates true *)
      - rewrite C2; rewrite IHx; reflexivity.             (* p1 true, p2 false *)
      - rewrite C1; rewrite IHx; reflexivity.             (* p2 true, p1 false *)
      - rewrite IHx; reflexivity.                         (* both predicates false *)
    Qed.

    Lemma filter_and:
      forall (x:list A) (p1 p2: A -> bool),
        (filter p1 (filter p2 x)) = (filter (fun a => andb (p1 a) (p2 a)) x).
    Proof.
      intros.
      induction x.
      simpl; reflexivity.
      simpl.
      generalize (four_cases p1 p2 a);intros.
      elim H; intro H1; elim H1; intro H2; elim H2; intros C1 C2; clear H H1 H2;
      rewrite C1; rewrite C2; simpl; try rewrite C1; rewrite IHx; reflexivity.
    Qed.

    Lemma filter_eq:
      forall (p1 p2:A -> bool),
        (forall x:A, p1 x = p2 x) -> (forall l:list A, filter p1 l = filter p2 l).
    Proof.
      intros.
      induction l.
      simpl; reflexivity.
      simpl; rewrite <- H.
      generalize (two_cases p1 a); intros; elim H0; intros; clear H0; rewrite H1.
      rewrite IHl; reflexivity.
      rewrite IHl; reflexivity.
    Qed.

    Lemma false_filter_nil {f} {l:list A} :
      (forall x, In x l -> f x = false) ->  filter f l = nil.
    Proof.
      induction l; simpl; trivial.
      intros.
      generalize (H a); intuition.
      rewrite H0.
      apply IHl; intuition.
    Qed.

    Lemma filter_app (f:A->bool) l1 l2 :
      filter f (l1 ++ l2) = filter f l1 ++ filter f l2.
    Proof.
      induction l1; simpl; intuition.
      match_destr.
      rewrite IHl1; simpl; trivial.
    Qed.

    Lemma Forall_filter {P} {l:list A} f :
      Forall P l -> Forall P (filter f l).
    Proof.
      induction l; simpl; trivial.
      inversion 1; subst.
      destruct (f a); auto.
    Qed.    
  
    Lemma find_filter f (l:list A) :  find f l = hd_error (filter f l).
    Proof.
      induction l; simpl; trivial.
      destruct (f a); simpl; auto.
    Qed.

    Lemma filter_ext (f g : A -> bool) (l : list A) : 
      (forall x, In x l -> f x = g x) ->
      filter f l = filter g l.
    Proof.
      induction l; simpl; trivial; intros.
      rewrite IHl by intuition.
      rewrite (H a) by intuition.
      trivial.
    Qed.

    Lemma true_filter (f : A -> bool) (l : list A) :
      (forall x : A, In x l -> f x = true) -> filter f l = l.
    Proof.
      induction l; simpl; trivial; intros.
      rewrite H, IHl; intuition.
    Qed.

  End filter.

  
        Lemma forall_in_dec {A:Type} P (l:list A)
          (dec:forall x, In x l -> {P x} + {~ P x}):
      {forall x, In x l -> P x} + {~ forall x, In x l -> P x}.
    Proof.
      induction l; simpl.
      - left; intuition.
      - simpl in dec.
        destruct (dec a); [intuition | | ].
        + destruct IHl.
          * simpl in dec; intuition.
          * left; intuition. subst; intuition.
          * right. intuition.
        + right. intuition.
    Defined.

    Lemma exists_in_dec {A:Type} P (l:list A)
          (dec:forall x, In x l -> {P x} + {~ P x}):
      {exists x, In x l /\ P x} + {~ exists x, In x l /\ P x}.
    Proof.
       induction l; simpl.
      - right. intros [??]; intuition.
      - simpl in dec.
        destruct (dec a); [intuition | | ].
        + left; eauto.
        + destruct IHl.
          * simpl in dec; intuition.
          * left. destruct e as [?[??]]; eauto.
          * right. intros [?[[?|?]?]]; subst; intuition; eauto.
    Defined.

    Lemma exists_nforall_in_dec {A:Type} P (l:list A)
          (dec:forall x, In x l -> {P x} + {~ P x}):
      {exists x, In x l /\ P x} + {forall x, In x l -> ~P x}.
    Proof.
       induction l; simpl.
      - right. intuition.
      - simpl in dec.
        destruct (dec a); [intuition | | ].
        + left; eauto.
        + destruct IHl.
          * simpl in dec; intuition.
          * left. destruct e as [?[??]]; eauto.
          * right. intros ? [?|?]; subst; intuition; eauto.
    Defined.

      Lemma existsb_ex {A : Type} (f : A -> bool) (l : list A) :
       existsb f l = true -> {x : A | In x l /\ f x = true}.
  Proof.
    induction l; simpl; intros.
    - discriminate.
    - case_eq (existsb f l); intros exx.
      + destruct (IHl exx) as [?[??]].
         exists x; intuition.
      + case_eq (f a); intros faa.
        * exists a; intuition.
        * rewrite exx, faa in H. discriminate.
  Qed.


  Section perm_equiv.
    Context {A:Type}.
    Context {eqdec:EqDec A eq}.

    Definition ldeqA := (@Permutation A).

    Definition rbag := list A.

    Global Instance perm_equiv : Equivalence (@Permutation A).
    Proof.
      constructor.
      - unfold Reflexive; auto.
      - intros l1 l2.
        induction 1; eauto.
        apply perm_swap.
        apply perm_trans with (l' := l'); assumption.
      - unfold Transitive; apply perm_trans.
    Qed.
  End perm_equiv.
    
  Section list2.
    Context {A B:Type}.

    Section fb2.
      Context (f:A->B->bool).
      Fixpoint forallb2 (l1:list A) (l2:list B): bool :=
        match l1,l2 with
          | nil, nil => true
          | a1::l1, a2::l2 => f a1 a2 && forallb2 l1 l2
          | _, _ => false
        end.

      Lemma forallb2_forallb : forall (l1:list A) (l2:list B), 
                                 (length l1 = length l2) ->
                                 forallb (fun xy => f (fst xy) (snd xy)) (combine l1 l2) = forallb2 l1 l2.
      Proof.
        induction l1; destruct l2; simpl; intuition.
        f_equal; auto.
      Qed.

      Lemma forallb2_forallb_true : forall (l1:list A) (l2:list B), 
                                      (length l1 = length l2 /\ forallb (fun xy => f (fst xy) (snd xy)) (combine l1 l2) = true)
                                      <->
                                      forallb2 l1 l2 = true.
      Proof.
        Hint Unfold iff.
        induction l1; destruct l2; simpl; intuition;
        repeat rewrite andb_true_iff in *; firstorder.
      Qed.  

      Lemma forallb2_Forallb : forall l1 l2, forallb2 l1 l2 = true <-> Forall2 (fun x y => f x y = true) l1 l2.
      Proof.
        Hint Constructors Forall2.
        Ltac inv := try match goal with 
                          | [H:Forall2 _ _ (_::_) |- _ ] => inversion H; clear H
                          | [H:Forall2 _ (_::_) _ |- _ ] => inversion H; clear H
                        end; firstorder.
        induction l1; destruct l2; simpl; intuition; inv;
        repeat rewrite andb_true_iff in *; firstorder.
      Qed.

    End fb2.
  
    Lemma Forall2_incl : forall (f1 f2:A->B->Prop) l1 l2, 
                           (forall x y, In x l1 -> In y l2 -> f1 x y-> f2 x y) ->
                           Forall2 f1 l1 l2 -> Forall2 f2 l1 l2.
    Proof.
      Hint Constructors Forall2.
      intros.
      induction H0; firstorder.
    Qed.

    Lemma forallb2_eq : forall (f1 f2:A->B->bool) l1 l2, 
                          (forall x y, In x l1 -> In y l2 -> f1 x y = f2 x y) ->
                          forallb2 f1 l1 l2 = forallb2 f2 l1 l2.
    Proof.
      induction l1; destruct l2; simpl; intuition.
      f_equal; auto.
    Qed.

  End list2.

  Section forall2.
  
    Lemma forallb2_sym {A B} : forall (f:A->B->bool) {l1 l2}, 
      forallb2 f l1 l2 = forallb2 (fun x y => f y x) l2 l1.
    Proof.
      induction l1; destruct l2; simpl; intuition.
      f_equal; trivial.
    Qed.

    Lemma Forall2_map {A B C D} (f:C->D->Prop) (g:A->C) (h:B->D) a b:
      Forall2 (fun x y => f (g x) (h y)) a b <-> Forall2 f (map g a) (map h b).
    Proof.
      revert b.
      induction a; destruct b; simpl; split; inversion 1;
      eauto 2; subst; firstorder.
    Qed.

    Lemma Forall2_map_f {A B C D} (f:C->D->Prop) (g:A->C) (h:B->D) a b:
      Forall2 (fun x y => f (g x) (h y)) a b -> Forall2 f (map g a) (map h b).
    Proof.
      apply Forall2_map.
    Qed.

    Lemma Forall2_map_b {A B C D} (f:C->D->Prop) (g:A->C) (h:B->D) a b:
      Forall2 f (map g a) (map h b) -> Forall2 (fun x y => f (g x) (h y)) a b.
    Proof.
      apply Forall2_map.
    Qed.

    Lemma Forall2_length {A B} (f:A->B->Prop)  a b:
      Forall2 f a b -> length a = length b.
    Proof.
      revert b;
      induction a; inversion 1; subst; simpl; intuition.
    Qed.

    Global Instance Forall2_refl {A} R `{Reflexive A R} : Reflexive (Forall2 R).
    Proof.
      red.
      induction x; simpl; trivial.
      constructor; auto.
    Qed.

    Global Instance Forall2_sym {A} R `{Symmetric A R} : Symmetric (Forall2 R).
    Proof.
      red.
      induction x; simpl; inversion 1; subst; trivial.
      constructor; auto.
    Qed.

    Global Instance Forall2_trans {A} R `{Transitive A R} : Transitive (Forall2 R).
    Proof.
      red.
      induction x; simpl; inversion 1; subst; trivial.
      inversion 1; subst.
      constructor; eauto.
    Qed.

  Global Instance Forall2_pre {A} R `{PreOrder A R} : PreOrder (Forall2 R).
  Proof.
    destruct H.
      constructor; red.
    - apply Forall2_refl; trivial.
    - apply Forall2_trans; trivial.
  Qed.

  Global Instance Forall2_part_eq {A} R `{PartialOrder A eq R } :
    PartialOrder eq (Forall2 R).
  Proof.
    intros l1 l2.
    split; intros HH.
    - repeat red; subst; intuition.
    - repeat red in HH; intuition.
      revert l2 H0 H1.
      induction l1; destruct l2; trivial; intros F1 F2;
        invcs F1; invcs F2.
      + f_equal.
        * apply antisymmetry; trivial.
        * apply IHl1; trivial.
  Qed.
  
  Lemma Forall2_trans_relations_weak {A B C}
        (R1:A->B->Prop) (R2:B->C->Prop) (R3:A->C->Prop):
    (forall a b c, R1 a b -> R2 b c -> R3 a c) ->
    forall a b c, Forall2 R1 a b -> Forall2 R2 b c -> Forall2 R3 a c.
  Proof.
    intros pf.
    induction a; intros b c Fab Fbc
    ; invcs Fab; invcs Fbc; eauto.
  Qed.

    Lemma Forall2_eq {A} (l1 l2:list A): Forall2 eq l1 l2 <-> l1 = l2.
    Proof.
      split; intros; subst; [ | reflexivity ].
      revert l2 H; induction l1; inversion 1; subst; trivial.
      f_equal; eauto.
    Qed.

    Lemma Forall2_flip {A B} {P:A->B->Prop} {l1 l2} :
      Forall2 P l1 l2 -> Forall2 (fun x y => P y x) l2 l1.
    Proof.
      revert l2; induction l1; simpl; inversion 1; subst; auto.
    Qed.
  
    Lemma Forall2_In_l {A B} {P:A->B->Prop} {l1 l2 a} :
      Forall2 P l1 l2 ->
      In a l1 ->
      exists b,
        In b l2 /\
        P a b.
    Proof.
      revert l2 a. induction l1; simpl; [intuition |].
      inversion 1; subst; intros.
      intuition; subst; simpl; eauto.
      destruct (IHl1 _ _ H4 H1); intuition; eauto.
    Qed.

    Lemma Forall2_In_r {A B} {P:A->B->Prop} {l1 l2 b} :
      Forall2 P l1 l2 ->
      In b l2 ->
      exists a,
        In a l1 /\
        P a b.
    Proof.
      intros.
      apply Forall2_flip in H.
      apply (Forall2_In_l H H0).
    Qed.

  Lemma Forall2_app_tail_inv {A B} P l1 l2 a1 a2 :
     @Forall2 A B P (l1 ++ (a1::nil)) (l2 ++ (a2::nil)) ->
     Forall2 P l1 l2 /\ P a1 a2.
   Proof.
     intros.
     destruct (Forall2_app_inv_l _ _ H) as [?[?[f1 [f2 eqq]]]].
     inversion f2; subst.
     inversion H4; subst.
     apply app_inj_tail in eqq.
     destruct eqq; subst.
     auto.
   Qed.
   
  Lemma filter_Forall2_same {A B} P f g (l1:list A) (l2:list B) :
    Forall2 P l1 l2 ->
    map f l1 = map g l2 ->
    Forall2 P (filter f l1) (filter g l2).
  Proof.
    revert l2.
    induction l1; simpl; inversion 1; subst; simpl; trivial.
    inversion 1.
    rewrite H3.
    match_destr.
    + constructor; auto.
    + auto.
  Qed.
  
  End forall2.

  Section forallb_ordpairs.

    Fixpoint forallb_ordpairs {A} f (l:list A)
      := match l with
         | nil => true
         | x::ls => forallb (f x) ls && forallb_ordpairs f ls
         end.

    Lemma forallb_ordpairs_ForallOrdPairs {A} f (l:list A) :
      forallb_ordpairs f l = true <-> (ForallOrdPairs (fun x y => f x y = true) l).
    Proof.
      induction l; simpl; intuition.
      - constructor.
      - rewrite andb_true_iff in H1.
        intuition.
        econstructor; trivial.
        rewrite Forall_forall.
        rewrite forallb_forall in H2.
        trivial.
      - rewrite andb_true_iff.
        rewrite forallb_forall.
        invcs H1.
        rewrite Forall_forall in H4.
        intuition.
    Qed.
    
    Lemma forallb_ordpairs_ext {A} f1 f2 (l:list A) :
      (forall x y, In x l -> In y l -> f1 x y = f2 x y) ->
      forallb_ordpairs f1 l = forallb_ordpairs f2 l.
    Proof.
      induction l; simpl; trivial; intros.
      rewrite IHl.
      - f_equal.
        apply forallb_ext.
        intuition.
      - intuition.
    Qed.

    Fixpoint forallb_ordpairs_refl {A} (f:A->A->bool) (l:list A)
      := match l with
         | nil => true
         | x::ls => forallb (f x) (x::ls) && forallb_ordpairs_refl f ls
         end.

    Lemma forallb_ordpairs_refl_conj A f (l:list A) :
      forallb_ordpairs_refl f l = forallb_ordpairs f l && forallb (fun x => f x x) l.
    Proof.
      induction l; simpl; trivial.
      rewrite IHl.
      repeat rewrite andb_assoc.
      f_equal.
      repeat rewrite <- andb_assoc.
      rewrite andb_comm.
      repeat rewrite andb_assoc.
      trivial.
    Qed.

        Lemma forallb_ordpairs_app_cons {A} f (l:list A) x :
    forallb_ordpairs f l = true ->
    forallb (fun y => f y x) l = true ->
    forallb_ordpairs f (l ++ x::nil) = true.
  Proof.
    induction l; simpl; trivial.
    repeat rewrite andb_true_iff in * .
    repeat rewrite forallb_forall in * .
    simpl in * .
    intuition.
    rewrite in_app_iff in H0.
    simpl in H0.
    intuition.
    congruence.
  Qed.
  
  Lemma forallb_ordpairs_refl_app_cons {A} f (l:list A) x :
    forallb_ordpairs_refl f l = true ->
    f x x = true ->
    forallb (fun y => f y x) l = true ->
    forallb_ordpairs_refl f (l ++ x::nil) = true.
  Proof.
    repeat rewrite forallb_ordpairs_refl_conj.
    repeat rewrite andb_true_iff.
    intuition.
    - apply forallb_ordpairs_app_cons; trivial.
    - rewrite forallb_app; simpl; intuition.
  Qed.

  End forallb_ordpairs.

  Lemma app_cons_cons_expand {A} (l:list A) a b :
    l ++ a::b::nil = (l ++ a ::nil)++b::nil.
  Proof.
    rewrite app_ass.
    simpl.
    trivial.
  Qed.
  
  Section remove.
    Context {A:Type}.
    Context {eqdec:EqDec A eq}.
    
    Lemma remove_in_neq
          (l : list A) (x y : A) : x <> y ->
                                   (In x l <-> In x (remove eqdec y l)).
    Proof.
      intros neq. induction l; simpl; intuition; subst.
      - destruct (eqdec y x); subst; intuition.
      - destruct (eqdec y a); subst; intuition.
      - destruct (eqdec y a); subst; intuition.
        simpl in *; intuition.
    Qed.

    Lemma list_in_remove_impl_diff x y l:
      In x (remove eqdec y l) -> x <> y.
    Proof.
      case (equiv_dec x y); try congruence.
      intros Heq; rewrite Heq in *; clear Heq.
      intros H.
      apply remove_In in H.
      contradiction.
    Qed.
    
    Lemma list_remove_append_distrib:
      forall (v:A) (l1 l2:list A),
        remove eqdec v l1 ++ remove eqdec v l2 = remove eqdec v (l1 ++ l2).
    Proof.
      intros.
      induction l1; try reflexivity.
      simpl.
      destruct (eqdec v a).
      - assumption.
      - simpl; rewrite IHl1; reflexivity.
    Qed.

    Lemma list_remove_idempotent:
      forall v l,
        remove eqdec v (remove eqdec v l) = remove eqdec v l.
    Proof.
      intros.
      induction l; try reflexivity.
      simpl.
      destruct (eqdec v a).
      - assumption.
      - simpl.
        destruct (eqdec v a); congruence.
    Qed.

    Lemma list_remove_commute:
      forall v1 v2 l,
        remove eqdec v1 (remove eqdec v2 l) = remove eqdec v2 (remove eqdec v1 l).
    Proof.
      induction l; try reflexivity.
      simpl.
      destruct (eqdec v2 a); destruct (eqdec v1 a); simpl.
      - assumption.
      - rewrite e in *.
        destruct (eqdec a a); congruence.
      - rewrite e in *.
        destruct (eqdec a a); congruence.
      - destruct (eqdec v1 a); destruct (eqdec v2 a); simpl.
        + assumption.
        + congruence.
        + congruence.
        + rewrite IHl; reflexivity.
    Qed.

    Remark list_remove_in v1 v2 l1 l2:
      (In v1 l1 -> In v1 l2) ->
      In v1 (remove eqdec v2 l1) -> In v1 (remove eqdec v2 l2).
    Proof.
      intros Hl1l2 Hl1rm.
      case (eqdec v1 v2).
      - intros Heq; rewrite Heq in *; clear Heq.
        assert (~ In v2 (remove eqdec v2 l1)); try contradiction.
        apply remove_In.
      - intros Heq.
        apply remove_in_neq; try congruence.
        apply remove_in_neq in Hl1rm; try congruence.
        apply Hl1l2.
        assumption.
    Qed.

    Lemma remove_inv v n l:
      In v (remove eqdec n l) -> In v l /\ v <> n.
    Proof.
      induction l; intros; simpl in *.
      - contradiction.
      - destruct (eqdec n a).
        elim (IHl H); intros; auto; simpl in *.
        elim H; clear H; intros; subst; auto.
        elim (IHl H); intros; auto.
    Qed.

    Lemma not_in_remove_impl_not_in:
      forall x v l,
        x <> v ->
        ~ In x (remove eqdec v l) ->
        ~ In x l.
    Proof.
      intros x v l.
      intros Hneq Hx.
      induction l.
      - simpl.
        trivial.
      - simpl.
        unfold not.
        intros H.
        destruct H.
        + rewrite H in *; clear H.
          simpl in Hx.
          case (eqdec v x) in Hx; try congruence.
          simpl in Hx.
          apply Decidable.not_or in Hx.
          destruct Hx.
          congruence.
        + simpl in Hx.
          case (eqdec v a) in Hx; try congruence.
          * simpl in Hx.
            apply IHl in Hx.
            contradiction.
          * simpl in Hx.
            apply Decidable.not_or in Hx.
            destruct Hx.
            apply IHl in H1.
            contradiction.
    Qed.

    Fixpoint remove_all (x : A) (l : list A) : list A :=
      match l with
      | nil => nil
      | y::tl => if (x == y) then (remove_all x tl) else y::(remove_all x tl)
      end.

    Global Instance remove_all_proper : Proper (eq ==> ldeqA ==> ldeqA) remove_all.
    Proof.
      unfold Proper, respectful.
      intros; rewrite H.
      elim H0; intros; simpl.
      - reflexivity.
      - destruct (equiv_dec y x1); rewrite H2; reflexivity.
      - destruct (equiv_dec y x1); destruct (equiv_dec y y1); try reflexivity.
        apply perm_swap.
      - rewrite H2; rewrite H4; reflexivity.
    Qed.

    Lemma remove_all_filter x l:
      remove_all x l = filter (nequiv_decb x) l.
    Proof.
      induction l; simpl; trivial.
      unfold nequiv_decb, negb, equiv_decb. rewrite IHl.
      match_destr.
    Qed.
    
    Lemma remove_all_app (v:A) l1 l2
      : remove_all v (l1 ++ l2) = remove_all v l1 ++ remove_all v l2.
    Proof.
      repeat rewrite remove_all_filter.
      rewrite filter_app.
      trivial.
    Qed.

    Lemma fold_left_remove_all_In {l init a} :
      In a (fold_left (fun (a : list A) (b : A) =>
                       filter (nequiv_decb b) a) l init)
      -> In a init /\ ~ In a l.
    Proof.
      revert init a.
      induction l; simpl.
      - intuition.
      - intros.
        destruct (IHl _ _ H).
        apply filter_In in H0.
        unfold nequiv_decb, equiv_decb, negb in H0.
        intuition; subst.
        destruct (equiv_dec a0 a0); intuition.
    Qed.

  End remove.

  Lemma nin_remove {A} dec (l:list A) a :
    ~ In a l -> remove dec a l = l.
  Proof.
    induction l; simpl; trivial.
    match_destr; intuition; congruence.
  Qed.

  Section repall.
    Context {A:Type}.
    Context `{eqdec:EqDec A eq}.

    Definition replace_all l v n
      := map (fun x => if eqdec x v then n else x) l.
    
    Lemma replace_all_nin l v n :
      ~ In v l -> 
      map (fun x => if eqdec x v then n else x) l = l.
    Proof.
      induction l; simpl; intuition.
      destruct (eqdec a v); congruence.
    Qed.

    Lemma replace_all_remove_neq l v0 v n:
      v <> v0 -> n <> v0 ->
      remove eqdec v0 
             (map (fun x  => if eqdec x v then n else x) 
                  l) =
      (map (fun x => if eqdec x v then n else x) 
           (remove eqdec v0 l)).
    Proof.
      induction l; simpl; intuition.
      rewrite H2.
      destruct (eqdec a v); subst; simpl.
      - destruct (eqdec v0 n); subst; simpl; intuition.
        destruct (eqdec v0 a); subst; simpl; [congruence|].
        rewrite e in *; clear e.
        destruct (eqdec v v); intuition.
      - destruct (eqdec v0 a); trivial; simpl.
        destruct (eqdec a v); subst; intuition.
    Qed.

    Lemma remove_replace_all_nin l v v' :
      ~ In v' l ->
      remove eqdec v' (replace_all l v v') =
      remove eqdec v l.
    Proof.
      induction l; simpl; intuition.
      rewrite H. destruct (eqdec a v); simpl; try (rewrite e in *; clear e).
      - destruct (eqdec v v); intuition; 
        destruct (eqdec v' v'); intuition.
      - destruct (eqdec v a); intuition;
        destruct (eqdec v' a); intuition.
    Qed.

    Definition flat_replace_all l (v:A) n
      := flat_map (fun x => if eqdec x v then n else (x::nil)) l.

    Lemma flat_replace_all_nil l (v:A) :
      flat_replace_all l v nil = @remove_all A eqdec v l.
    Proof.
      induction l; simpl; trivial.
      match_destr; match_destr; simpl; try congruence.
    Qed.

    Lemma flat_replace_all_app l1 l2 (v:A) n
      : flat_replace_all (l1 ++ l2) v n
        = flat_replace_all l1 v n ++ flat_replace_all l2 v n.
    Proof.
      unfold flat_replace_all.
      apply flat_map_app.
    Qed.

    Lemma fold_left_remove_all_nil_in_inv {B} {x ps l}:
      In x (fold_left
              (fun (h : list nat) (xy : nat * B) =>
                 remove_all (fst xy) h)
              ps l) ->
      In x l.
    Proof.
      revert l.
      induction ps using rev_ind; simpl; intuition; subst.
      apply IHps.
      rewrite fold_left_app in H.
      simpl in H.
      rewrite remove_all_filter in H.
      apply filter_In in H. intuition.
    Qed.

    Lemma fold_left_remove_all_nil_in_inv' {x ps l}:
      In x (fold_left
              (fun (h : list nat) (xy : nat) =>
                 remove_all xy h)
              ps l) ->
      In x l.
    Proof.
      revert l.
      induction ps using rev_ind; simpl; intuition; subst.
      apply IHps.
      rewrite fold_left_app in H.
      simpl in H.
      rewrite remove_all_filter in H.
      apply filter_In in H. intuition.
    Qed.

    Lemma fold_left_remove_all_nil_in_not_inv'  {x ps l}:
      In x (fold_left
              (fun (h : list nat) (xy : nat ) =>
                 remove_all xy h)
              ps l) ->
      ~ In x ps.
    Proof.
      revert l.
      induction ps; simpl; intuition; subst.
      - simpl in *.
        apply fold_left_remove_all_nil_in_inv' in H.
        rewrite remove_all_filter in H.
        apply filter_In in H. unfold nequiv_decb, equiv_decb in *.
        intuition. match_destr_in H1.
        congruence.
      - eauto.
    Qed.
    
    Lemma replace_all_remove_eq (l : list A) (v n : A) :
      map (fun x : A => if eqdec x v then n else x) (remove eqdec v l) = (remove eqdec v l).
    Proof.
      apply replace_all_nin.
      apply remove_In.
    Qed.

  End repall.

  Section incl.

    Definition cut_down_to {A B} {dec:EqDec A eq} (l:list (A*B)) (l2:list A) :=
      filter (fun a => existsb (fun z => (fst a) ==b z) l2) l.

    Lemma cut_down_to_in
          {A B} {dec:EqDec A eq}
          (l:list (A*B)) l2 a :
      In a (cut_down_to l l2) <-> In a l /\ In (fst a) l2 .
    Proof.
      unfold cut_down_to.
      red; intros.
      rewrite filter_In.
      rewrite existsb_exists.
      firstorder.
      - unfold equiv_decb in *; match_destr_in H1.
        congruence.
      - exists (fst a); split; trivial.
        unfold equiv_decb; match_destr.
        congruence.
    Qed.

    Lemma cut_down_to_app  {A B} {dec:EqDec A eq}
          (l l':list (A*B)) l2 :
      cut_down_to (l++l') l2 = cut_down_to l l2 ++ cut_down_to l' l2.
    Proof.
      unfold cut_down_to.
      apply filter_app.
    Qed.
   
    Lemma incl_dec {A} {dec:EqDec A eq} (l1 l2:list A) :
      {incl l1 l2} + {~ incl l1 l2}.
    Proof.
      unfold incl.
      induction l1.
      - left; inversion 1.
      - destruct IHl1.
        + destruct (in_dec dec a l2).
          * left; simpl; intros; intuition; congruence.
          * right; simpl;  intros inn; apply n; intuition.
        + right; simpl; intros inn; apply n; intuition.
    Defined.

    Global Instance incl_pre A : PreOrder (@incl A).
    Proof.
      unfold incl.
      constructor; red; intuition.
    Qed.


    Lemma set_inter_contained {A} dec (l l':list A):
      (forall a, In a l -> In a l') ->
      set_inter dec l l' = l.
    Proof.
      induction l; simpl; intuition.
      case_eq (set_mem dec a l'); trivial.
      - rewrite IHl; auto.
      - intros ninn. apply set_mem_complete1 in ninn.
        elim ninn. apply H; intuition.
    Qed.

    Lemma set_inter_idempotent {A} dec (l:list A):
      set_inter dec l l = l.
    Proof.
      apply set_inter_contained; trivial.
    Qed.

    Lemma set_inter_comm_in {A} dec a b :
      (forall x, In x (@set_inter A dec a b)  -> In x (set_inter dec b a)) .
    Proof.
      intros ? inn.
      apply set_inter_elim in inn.
      apply set_inter_intro; intuition.
    Qed.
  
   Lemma nincl_exists {A} {dec:EqDec A eq} (l1 l2:list A) :
     ~ incl l1 l2 -> {x | In x l1 /\ ~ In x l2}.
   Proof.
     unfold incl.
     induction l1; simpl.
     - intuition.
     - intros.
       destruct (in_dec dec a l2).
       + destruct IHl1.
         * intros inn.
           apply H. intuition; subst; trivial.
         * exists x; intuition.
      + exists a; intuition.
   Qed.

  End incl.

  Section equivlist.
    Context {A:Type}.

    Definition equivlist (l l':list A) 
      := forall x, In x l <-> In x l'.

    Global Instance equivlist_equiv : Equivalence equivlist.
    Proof.
      constructor; red; unfold equivlist; firstorder.
    Qed.

    Global Instance Permutation_equivlist :
      subrelation (@Permutation A) equivlist.
    Proof.
      split; intros.
      - eapply Permutation_in; eauto.
      - eapply Permutation_in. symmetry; eauto. eauto.
    Qed.

    Lemma equivlist_in {l1 l2} : equivlist l1 l2 -> (forall x:A, In x l1 -> In x l2).
    Proof.
      intros e x inn. specialize (e x); intuition.
    Qed.
  
    Lemma equivlist_incls (l1 l2:list A) :
      equivlist l1 l2 <-> (incl l1 l2 /\ incl l2 l1).
    Proof.
      unfold equivlist, incl.
      firstorder.
    Qed.

    Global Instance equivlist_In_proper : Proper (eq ==> equivlist ==> iff) (@In A).
  Proof.
    unfold Proper, respectful, equivlist; intros; subst; firstorder.
  Qed.

    Lemma equivlist_dec {dec:EqDec A eq} (l1 l2:list A) :
      {equivlist l1 l2} + {~ equivlist l1 l2}.
    Proof.
      destruct (incl_dec l1 l2).
      - destruct (incl_dec l2 l1).
        + left; rewrite equivlist_incls; intuition.
        + right; rewrite equivlist_incls; intuition.
      - right; rewrite equivlist_incls; intuition.
    Defined.
   
    Lemma equivlist_nil {l:list A} : equivlist l nil -> l = nil.
    Proof.
      destruct l; trivial.
      intros inn.
      destruct (inn a); simpl in *.
      intuition.
    Qed.

    Lemma app_idempotent_equivlist (l:list A) :
      equivlist (l++l) l.
    Proof.
      apply equivlist_incls; split;
      intros ? ?; rewrite in_app_iff in *; intuition.
    Qed.
    
    Lemma app_commutative_equivlist (l1 l2:list A) :
      equivlist (l1++l2) (l2++l1).
    Proof.
      apply equivlist_incls; split;
      intros ? ?; rewrite in_app_iff in *; intuition.
    Qed.
    
    Lemma app_contained_equivlist  (a b:list A) :
      incl b a ->
      equivlist (a ++ b) a.
    Proof.
      intros.
      apply equivlist_incls; split; intros x xin.
      - rewrite in_app_iff in xin. destruct xin; eauto.
      - rewrite in_app_iff. eauto.
    Qed.

    Lemma set_inter_equivlist dec a b :
      equivlist (@set_inter A dec a b) (set_inter dec b a) .
    Proof.
      split; intros; apply set_inter_comm_in; trivial.
    Qed.

    Global Instance set_inter_equivlist_proper dec : Proper (equivlist ==> equivlist ==> equivlist) (@set_inter A dec).
  Proof.
    cut (Proper (equivlist ==> equivlist ==> (@incl A)) (@set_inter A dec)); unfold Proper, respectful; intros.
    { apply equivlist_incls; intuition. }
    intros z zin.
    apply set_inter_elim in zin.
    rewrite H,H0 in zin.
    apply set_inter_intro; intuition.
  Qed.

    Lemma incl_list_dec (dec:forall x y:A, {x = y} + {x <> y}) (l1 l2:list A) : {(forall x, In x l1 -> In x l2)} + {~(forall x, In x l1 -> In x l2)}.
    Proof.
      case_eq (forallb (fun x => if in_dec dec x l2 then true else false) (l1)); intros fb.
      - left.
        rewrite forallb_forall in fb.
        intros a inna. specialize (fb _ inna).
        match_destr_in fb.
      - right. rewrite forallb_not_existb in fb. rewrite negb_false_iff in fb.
        rewrite existsb_exists in fb. destruct fb as [? [inn ne]].
        intro im. specialize (im _ inn).
        match_destr_in ne. congruence.
    Defined.

  End equivlist.

      Lemma set_inter_assoc {A} dec a b c:
        @set_inter A dec (set_inter dec a b) c
        = set_inter dec a (set_inter dec b c).
    Proof.
      revert b c.
      induction a; simpl; trivial; intros.
      case_eq (set_mem dec a b); intros.
      - simpl.
        apply set_mem_correct1 in H.
        case_eq (set_mem dec a c); simpl; intros.
        + apply set_mem_correct1 in H0.
          rewrite IHa.
          case_eq (set_mem dec a (set_inter dec b c));
            simpl; intros; trivial.
          apply set_mem_complete1 in H1.
          elim H1. apply set_inter_intro; trivial.
        + case_eq (set_mem dec a (set_inter dec b c));
              simpl; intros; trivial.
          apply set_mem_complete1 in H0.
          apply set_mem_correct1 in H1.
          apply set_inter_elim in H1.
          intuition.
      -  apply set_mem_complete1 in H.
         case_eq (set_mem dec a (set_inter dec b c));
              simpl; intros; trivial.
         apply set_mem_correct1 in H0.
         apply set_inter_elim in H0.
         intuition.
  Qed.
     
  Section Assym_over.
  
    Definition asymmetric_over {A} R (l:list A) :=
      forall x y, In x l-> In y l -> ~R x y -> ~R y x -> x = y.
  
    Lemma asymmetric_asymmetric_over {A} {R} :
      (forall x y:A, ~R x y -> ~R y x -> x = y) ->
      forall l, asymmetric_over R l .
    Proof.
      red; intuition.
    Qed.

    Lemma asymmetric_over_incl {A} {R} {l2:list A}
      : asymmetric_over R l2 ->
        forall l1,
          (forall x, In x l1 -> In x l2) ->
          asymmetric_over R l1.
    Proof.
      unfold asymmetric_over; intuition.
    Qed.

    Lemma asymmetric_over_equivlist {A} {R} {l1 l2:list A} :
      equivlist l1 l2 ->
      (asymmetric_over R l1 <->
       asymmetric_over R l2).
    Proof.
      intros; split; intros aH; eapply asymmetric_over_incl; try eapply aH;
      apply equivlist_in; trivial.
      symmetry; trivial.
    Qed.
    
    Lemma asymmetric_over_cons_inv {A} {R} {a:A} {l1} :
      asymmetric_over R (a::l1) ->
      asymmetric_over R l1.
    Proof.
      unfold asymmetric_over; simpl; intuition.
    Qed.

    Hint Resolve asymmetric_over_cons_inv.

    Lemma asymmetric_over_swap {A} R {a b:A} {l1} :
      asymmetric_over R (a::b::l1) ->
      asymmetric_over R (b::a::l1).
    Proof.
      unfold asymmetric_over; simpl; intuition.
    Qed.

  End Assym_over.

  
  Global Instance perm_in {A} : Proper (eq ==> (@Permutation A) ==> iff) (@In A).
  Proof.
    Hint Resolve Permutation_in Permutation_sym.
    unfold Proper, respectful; intros; subst; intuition; eauto.
  Qed.
  
  Lemma NoDup_perm' {A:Type} {a b:list A} : NoDup a -> Permutation a b -> NoDup b.
  Proof.
    intros nd p.
    revert nd.
    revert a b p.
    apply (Permutation_ind_bis (fun l l' => NoDup l -> NoDup l')); intuition.
    - inversion H1; subst. constructor; eauto.
    - inversion H1; subst. inversion H5; subst.
      rewrite H in H4,H6.
      constructor; [|constructor]; simpl in *; intuition; subst; eauto.
  Qed.
  
  Global Instance NoDup_perm {A:Type} :
    Proper (@Permutation A ==> iff) (@NoDup A).
  Proof.
    Hint Resolve NoDup_perm' Permutation_sym.
    unfold Proper, respectful; intros; subst; intuition; eauto.
  Qed.

  Lemma NoDup_Permutation' {A : Type} (l l' : list A) :
    NoDup l ->
    NoDup l' -> equivlist l l' -> Permutation l l'.
  Proof.
    intros.
    apply NoDup_Permutation; intuition.
  Qed.

  Lemma NoDup_rev {A:Type} (l:list A) : NoDup (rev l) <-> NoDup l.
  Proof.
    rewrite <- Permutation_rev.
    intuition.
  Qed.

  Lemma NoDup_app_inv {A:Type} {a b:list A} : NoDup (a++b) -> NoDup a.
  Proof.
    induction b; intuition.
    - rewrite app_nil_r in H; trivial.
    - rewrite <- Permutation_middle in H.
      inversion H; subst; auto.
  Qed.
  
  Hint Resolve NoDup_app_inv.

  Lemma NoDup_app_inv2 {A:Type} {a b:list A} : NoDup (a++b) -> NoDup b.
  Proof.
    rewrite Permutation_app_comm.
    eauto.
  Qed.

  Section disj.
    Definition disjoint {A:Type} (l1 l2:list A)
      := forall x, In x l1 -> In x l2 -> False.

    Lemma NoDup_app_dis {A:Type} (a b:list A) :
      NoDup (a++b) -> disjoint a b.
    Proof.
      red; intros.
      destruct (in_split _ _ H0) as [a1[a2 aeq]].
      subst.
      rewrite <- app_assoc in H.
      apply NoDup_app_inv2 in H.
      simpl in H.
      inversion H; subst.
      simpl in *; intuition.
    Qed.

    Lemma disjoint_cons_inv1 {A:Type} {a:A} {l1 l2} : 
      disjoint (a :: l1) l2 -> disjoint l1 l2 /\ ~ In a l2.
    Proof.
      unfold disjoint; simpl; intuition.
      apply (H x); intuition.
      specialize (H a); intuition.
    Qed.

    Lemma disjoint_app_l {A} (l1 l2 l3:list A) :
    disjoint (l1 ++ l2) l3 <-> (disjoint l1 l3 /\ disjoint l2 l3).
  Proof.
    unfold disjoint; intuition.
    eapply H; try rewrite in_app_iff; eauto.
    eapply H; try rewrite in_app_iff; eauto.
    rewrite in_app_iff in H.
    intuition; eauto.
  Qed.

   Lemma disjoint_app_r {A} (l1 l2 l3:list A) :
    disjoint l1 (l2 ++ l3) <-> (disjoint l1 l2 /\ disjoint l1 l3).
   Proof.
    unfold disjoint; intuition.
    eapply H; try rewrite in_app_iff; eauto.
    eapply H; try rewrite in_app_iff; eauto.
    rewrite in_app_iff in H2.
    intuition; eauto.
  Qed.


    Lemma NoDup_app {A:Type} {a b:list A} :
      disjoint a b -> NoDup a -> NoDup b -> NoDup (a++b).
    Proof.
      revert b;
      induction a; intuition.
      simpl; inversion H0; subst.
      apply disjoint_cons_inv1 in H.
      constructor; intuition.
      apply in_app_or in H2. intuition.
    Qed.

    Global Instance disjoint_sym {A:Type} : Symmetric (@disjoint A).
    Proof.
      red; unfold disjoint; firstorder.
    Qed.

  End disj.

  Lemma unmap_NoDup {A B} (f:A->B) l :
    NoDup (map f l) -> NoDup l.
  Proof.
    induction l; simpl.
    - constructor.
    - inversion 1; subst.
      econstructor; eauto.
      intros inn; apply H2.
      apply in_map_iff.
      eauto.
  Qed.
  
  Lemma map_inj_NoDup {A B} (f:A->B) 
            (inj:forall x y, f x = f y -> x = y) (l:list A) :
        NoDup l ->
        NoDup (map f l).
  Proof.
    induction l; simpl.
    - constructor.
    - inversion 1; subst.
      econstructor; eauto.
      intros inn; apply H2.
      apply in_map_iff in inn.
      destruct inn as [x [xeq xin]].
      rewrite <- (inj _ _ xeq).
      trivial.
  Qed.

  Lemma filter_NoDup {A} (f:A->bool) l :
    NoDup l -> NoDup (filter f l).
  Proof.
    induction l; simpl; trivial.
    match_destr; intros.
    - inversion H; constructor; subst; trivial.
      + rewrite filter_In.
        intuition.
      + auto.
    - inversion H; subst; auto.
  Qed.

  Fixpoint zip {A B} (l1:list A) (l2: list B) : option (list (A * B)) :=
    match l1 with
    | nil =>
      match l2 with
      | nil => Some nil
      | _ => None
      end
    | x1 :: l1' =>
      match l2 with
      | nil => None
      | x2 :: l2' =>
        match zip l1' l2' with
        | None => None
        | Some l3 =>
          Some ((x1, x2) :: l3)
        end
      end
    end.
    
End RList.

(* 
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "QCert")) ***
*** End: ***
*)
