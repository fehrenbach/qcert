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

Section DNNRC.

  Require Import String.
  Require Import List.
  Require Import Arith.
  Require Import EquivDec.
  Require Import Morphisms.

  Require Import Utils BasicRuntime.
  Require Import DData.

  Context {fruntime:foreign_runtime}.
  
  (** Named Nested Relational Calculus *)
  
  Definition var := string.

  Section plug.
    Context {plug_type:Set}.

    Definition coll_bindings := list (string * (list data)).

    Definition bindings_of_coll_bindings (cb:coll_bindings) : bindings :=
      map (fun xy => (fst xy, dcoll (snd xy))) cb.
    
    Class AlgPlug :=
      mkAlgPlug {
          plug_eval : brand_relation_t -> coll_bindings -> plug_type -> option data
          ; plug_normalized :
            forall (h:brand_relation_t) (op:plug_type), forall (constant_env:coll_bindings) (o:data),
                Forall (fun x => data_normalized h (snd x)) (bindings_of_coll_bindings constant_env) ->
                plug_eval h constant_env op = Some o -> data_normalized h o;
(*        plug_equiv {h} (op1 op2:T) :
            forall (env:bindings),
              Forall (data_normalized h) (map snd env) ->
              plug_eval h env op1 = plug_eval h env op2 *)
        }.

  End plug.
  Global Arguments AlgPlug : clear implicits. 
  
  Section GenDNNRC.
    (* Type for DNRC AST annotations *)
    Context {A plug_type:Set}.

    Unset Elimination Schemes.

    Inductive dnrc  : Set :=
    | DNRCVar : A -> var -> dnrc
    | DNRCConst : A -> data -> dnrc
    | DNRCBinop : A -> binOp -> dnrc -> dnrc -> dnrc
    | DNRCUnop : A -> unaryOp -> dnrc -> dnrc
    | DNRCLet : A -> var -> dnrc -> dnrc -> dnrc
    | DNRCFor : A -> var -> dnrc -> dnrc -> dnrc
    | DNRCIf : A -> dnrc -> dnrc -> dnrc -> dnrc
    | DNRCEither : A -> dnrc -> var -> dnrc -> var -> dnrc -> dnrc
    | DNRCCollect : A -> dnrc -> dnrc
    | DNRCDispatch : A -> dnrc -> dnrc
    | DNRCAlg : A -> plug_type -> list (string * dnrc) -> dnrc.

    Set Elimination Schemes.

    (** Induction principles used as backbone for inductive proofs on dnrc *)

    Definition dnrc_rect (P : dnrc -> Type)
               (fdvar : forall a, forall v, P (DNRCVar a v))
               (fdconst : forall a, forall d : data, P (DNRCConst a d))
               (fdbinop : forall a, forall b, forall n1 n2 : dnrc, P n1 -> P n2 -> P (DNRCBinop a b n1 n2))
               (fdunop : forall a, forall u, forall n : dnrc, P n -> P (DNRCUnop a u n))
               (fdlet : forall a, forall v, forall n1 n2 : dnrc, P n1 -> P n2 -> P (DNRCLet a v n1 n2))
               (fdfor : forall a, forall v, forall n1 n2 : dnrc, P n1 -> P n2 -> P (DNRCFor a v n1 n2))
               (fdif : forall a, forall n1 n2 n3 : dnrc, P n1 -> P n2 -> P n3 -> P (DNRCIf a n1 n2 n3))
               (fdeither : forall a, forall n0 n1 n2, forall v1 v2,
                       P n0 -> P n1 -> P n2 -> P (DNRCEither a n0 v1 n1 v2 n2))
               (fdcollect : forall a, forall n : dnrc, P n -> P (DNRCCollect a n))
               (fddispatch : forall a, forall n : dnrc, P n -> P (DNRCDispatch a n))
               (fdalg : forall a, forall op:plug_type, forall r : list (string*dnrc), Forallt (fun n => P (snd n)) r -> P (DNRCAlg a op r))
      :=
        fix F (n : dnrc) : P n :=
          match n as n0 return (P n0) with
          | DNRCVar a v => fdvar a v
          | DNRCConst a d => fdconst a d
          | DNRCBinop a b n1 n2 => fdbinop a b n1 n2 (F n1) (F n2)
          | DNRCUnop a u n => fdunop a u n (F n)
          | DNRCLet a v n1 n2 => fdlet a v n1 n2 (F n1) (F n2)
          | DNRCFor a v n1 n2 => fdfor a v n1 n2 (F n1) (F n2)
          | DNRCIf a n1 n2 n3 => fdif a n1 n2 n3 (F n1) (F n2) (F n3)
          | DNRCEither a n0 v1 n1 v2 n2 => fdeither a n0 n1 n2 v1 v2 (F n0) (F n1) (F n2)
          | DNRCCollect a n => fdcollect a n (F n)
          | DNRCDispatch a n => fddispatch a n (F n)
          | DNRCAlg a op r =>
            fdalg a op r ((fix F3 (r : list (string * dnrc)) : Forallt (fun n => P (snd n)) r :=
                             match r as c0 with
                             | nil => Forallt_nil _
                             | cons n c0 => @Forallt_cons _ _ _ _ (F (snd n)) (F3 c0)
                             end) r)
          end.

    (** Induction principles used as backbone for inductive proofs on dnrc *)
    Definition dnrc_ind (P : dnrc -> Prop)
               (fdvar : forall a, forall v, P (DNRCVar a v))
               (fdconst : forall a, forall d : data, P (DNRCConst a d))
               (fdbinop : forall a, forall b, forall n1 n2 : dnrc, P n1 -> P n2 -> P (DNRCBinop a b n1 n2))
               (fdunop : forall a, forall u, forall n : dnrc, P n -> P (DNRCUnop a u n))
               (fdlet : forall a, forall v, forall n1 n2 : dnrc, P n1 -> P n2 -> P (DNRCLet a v n1 n2))
               (fdfor : forall a, forall v, forall n1 n2 : dnrc, P n1 -> P n2 -> P (DNRCFor a v n1 n2))
               (fdif : forall a, forall n1 n2 n3 : dnrc, P n1 -> P n2 -> P n3 -> P (DNRCIf a n1 n2 n3))
               (fdeither : forall a, forall n0 n1 n2, forall v1 v2,
                       P n0 -> P n1 -> P n2 -> P (DNRCEither a n0 v1 n1 v2 n2))
               (fdcollect : forall a, forall n : dnrc, P n -> P (DNRCCollect a n))
               (fddispatch : forall a, forall n : dnrc, P n -> P (DNRCDispatch a n))
               (fdalg : forall a, forall op:plug_type, forall r : list (string*dnrc), Forall (fun n => P (snd n)) r -> P (DNRCAlg a op r))
      :=
        fix F (n : dnrc) : P n :=
          match n as n0 return (P n0) with
          | DNRCVar a v => fdvar a v
          | DNRCConst a d => fdconst a d
          | DNRCBinop a b n1 n2 => fdbinop a b n1 n2 (F n1) (F n2)
          | DNRCUnop a u n => fdunop a u n (F n)
          | DNRCLet a v n1 n2 => fdlet a v n1 n2 (F n1) (F n2)
          | DNRCFor a v n1 n2 => fdfor a v n1 n2 (F n1) (F n2)
          | DNRCIf a n1 n2 n3 => fdif a n1 n2 n3 (F n1) (F n2) (F n3)
          | DNRCEither a n0 v1 n1 v2 n2 => fdeither a n0 n1 n2 v1 v2 (F n0) (F n1) (F n2)
          | DNRCCollect a n => fdcollect a n (F n)
          | DNRCDispatch a n => fddispatch a n (F n)
          | DNRCAlg a op r =>
            fdalg a op r ((fix F3 (r : list (string*dnrc)) : Forall (fun n => P (snd n)) r :=
                             match r as c0 with
                             | nil => Forall_nil _
                             | cons n c0 => @Forall_cons _ _ _ _ (F (snd n)) (F3 c0)
                             end) r)
          end.

    Definition dnrc_rec (P:dnrc->Set) := @dnrc_rect P.

    Lemma dnrcInd2 (P : dnrc -> Prop)
          (fdvar : forall a, forall v, P (DNRCVar a v))
          (fdconst : forall a, forall d : data, P (DNRCConst a d))
          (fdbinop : forall a, forall b, forall n1 n2 : dnrc, P (DNRCBinop a b n1 n2))
          (fdunop : forall a, forall u, forall n : dnrc, P (DNRCUnop a u n))
          (fdlet : forall a, forall v, forall n1 n2 : dnrc, P (DNRCLet a v n1 n2))
          (fdfor : forall a, forall v, forall n1 n2 : dnrc, P (DNRCFor a v n1 n2))
          (fdif : forall a, forall n1 n2 n3 : dnrc, P (DNRCIf a n1 n2 n3))
          (fdeither : forall a, forall n0 n1 n2, forall v1 v2,
                  P (DNRCEither a n0 v1 n1 v2 n2))
          (fdcollect : forall a, forall n : dnrc, P (DNRCCollect a n))
          (fddispatch : forall a, forall n : dnrc, P (DNRCDispatch a n))
          (fdalg : forall a, forall op:plug_type, forall r : list (string*dnrc), Forall (fun n => P (snd n)) r -> P (DNRCAlg a op r))
: forall n, P n.
    Proof.
      intros.
      apply dnrc_ind; trivial.
    Qed.

    Definition dnrc_annotation_get (d:dnrc) : A
      := match d with
         | DNRCVar a _ => a
         | DNRCConst a _ => a
         | DNRCBinop a _ _ _ => a
         | DNRCUnop a _ _ => a
         | DNRCLet a _ _ _ => a
         | DNRCFor a _ _ _ => a
         | DNRCIf a _ _ _ => a
         | DNRCEither a _ _ _ _ _ => a
         | DNRCCollect a _ => a
         | DNRCDispatch a _ => a
         | DNRCAlg a _ _ => a
         end.

    Definition dnrc_annotation_update (f:A->A) (d:dnrc) : dnrc
      := match d with
         | DNRCVar a v => DNRCVar (f a) v
         | DNRCConst a c => DNRCConst (f a) c
         | DNRCBinop a b d₁ d₂ => DNRCBinop (f a) b d₁ d₂
         | DNRCUnop a u d₁ => DNRCUnop (f a) u d₁
         | DNRCLet a x d₁ d₂ => DNRCLet (f a) x d₁ d₂
         | DNRCFor a x d₁ d₂ => DNRCFor (f a) x d₁ d₂
         | DNRCIf a d₀ d₁ d₂ => DNRCIf (f a) d₀ d₁ d₂
         | DNRCEither a d₀ x₁ d₁ x₂ d₂ => DNRCEither (f a) d₀ x₁ d₁ x₂ d₂
         | DNRCCollect a d₀ => DNRCCollect (f a) d₀
         | DNRCDispatch a d₀ => DNRCDispatch (f a) d₀
         | DNRCAlg a p args => DNRCAlg (f a) p args
         end .

    Context (h:brand_relation_t).
    Fixpoint dnrc_eval `{plug: AlgPlug plug_type} (env:dbindings) (e:dnrc) : option ddata :=
      match e with
      | DNRCVar _ x =>
        lookup equiv_dec env x
      | DNRCConst _ d =>
        Some (Dlocal (normalize_data h d))
      | DNRCBinop _ bop e1 e2 =>
        olift2 (fun d1 d2 => lift Dlocal (fun_of_binop h bop d1 d2))
               (olift checkLocal (dnrc_eval env e1)) (olift checkLocal (dnrc_eval env e2))
      | DNRCUnop _ uop e1 =>
        olift (fun d1 => lift Dlocal (fun_of_unaryop h uop d1)) (olift checkLocal (dnrc_eval env e1))
      | DNRCLet _ x e1 e2 =>
        match dnrc_eval env e1 with
        | Some d => dnrc_eval ((x,d)::env) e2
        | _ => None
        end
      | DNRCFor _ x e1 e2 =>
        match dnrc_eval env e1 with
        | Some (Ddistr c1) =>
          let inner_eval d1 :=
              let env' := (x,Dlocal d1) :: env in olift checkLocal (dnrc_eval env' e2)
          in
          lift (fun coll => Ddistr coll) (rmap inner_eval c1)
        | Some (Dlocal (dcoll c1)) =>
          let inner_eval d1 :=
              let env' := (x,Dlocal d1) :: env in olift checkLocal (dnrc_eval env' e2)
          in
          lift (fun coll => Dlocal (dcoll coll)) (rmap inner_eval c1)
        | Some (Dlocal _) => None
        | None => None
        end
      | DNRCIf _ e1 e2 e3 =>
        let aux_if d :=
            match d with
            | dbool b =>
              if b then dnrc_eval env e2 else dnrc_eval env e3
            | _ => None
            end
        in olift aux_if (olift checkLocal (dnrc_eval env e1))
      | DNRCEither _ ed xl el xr er =>
        match olift checkLocal (dnrc_eval env ed) with
        | Some (dleft dl) =>
          dnrc_eval ((xl,Dlocal dl)::env) el
        | Some (dright dr) =>
          dnrc_eval ((xr,Dlocal dr)::env) er
        | _ => None
        end
      | DNRCCollect _ e1 =>
        let collected := olift checkDistrAndCollect (dnrc_eval env e1) in
        lift Dlocal collected
      | DNRCDispatch _ e1 =>
        match olift checkLocal (dnrc_eval env e1) with
        | Some (dcoll c1) =>
          Some (Ddistr c1)
        | _ => None
        end
      | DNRCAlg _ plug nrcbindings =>
        match listo_to_olist (map (fun x =>
               match dnrc_eval env (snd x) with
               | Some (Ddistr coll) => Some (fst x, coll)
               | _ => None
               end) nrcbindings) with 
        | Some args =>
          match plug_eval h args plug with
          | Some (dcoll c) => Some (Ddistr c)
          | _ => None
          end
        | None => None
        end
      end.

    (* evaluation preserves normalization *)
    Require Import DDataNorm.

    Lemma Forall_dcoll_map_lift l:
      Forall (fun x : string * (list data) => data_normalized h (dcoll (snd x))) l ->
      Forall (fun x : string * data => data_normalized h (snd x))
             (map (fun xy : string * list data => (fst xy, dcoll (snd xy))) l).
    Proof.
      intros; induction l; simpl in *.
      - apply Forall_nil.
      - rewrite Forall_forall in *; intros.
        simpl in *.
        assert (forall x : string * list data,
                   In x l -> data_normalized h (dcoll (snd x)))
          by (intros; apply H; auto).
        specialize (IHl H1).
        elim H0; clear H0; intros.
        subst; simpl.
        apply H.
        left; auto.
        rewrite Forall_forall in IHl.
        apply IHl.
        assumption.
    Qed.

    Lemma Forall_dcoll_map_lift2 l:
      Forall (fun x : string * data => data_normalized h (snd x))
             (map (fun xy : string * list data => (fst xy, dcoll (snd xy))) l) ->
      Forall (fun x : string * (list data) => data_normalized h (dcoll (snd x))) l.
    Proof.
      intros.
      induction l; simpl in *.
      - apply Forall_nil.
      - assert (Forall (fun x : string * data => data_normalized h (snd x))
                       (map (fun xy : string * list data => (fst xy, dcoll (snd xy))) l)).
        + clear IHl. rewrite Forall_forall in *; intros.
          apply H.
          simpl.
          auto.
        + specialize (IHl H0); clear H0.
          rewrite Forall_forall in *; intros.
          simpl in *.
          elim H0; clear H0; intros.
          subst.
          apply (H (fst x, (dcoll (snd x)))); left; auto.
          auto.
    Qed.

    Lemma Forall_dcoll_map_lift3 l:
      Forall (fun x : string * data => data_normalized h (snd x))
             (map (fun xy : string * list data => (fst xy, dcoll (snd xy))) l) <->
      Forall (fun x : string * (list data) => data_normalized h (dcoll (snd x))) l.
    Proof.
      split.
      apply Forall_dcoll_map_lift2.
      apply Forall_dcoll_map_lift.
    Qed.

    Lemma dnrc_alg_bindings_normalized {plug:AlgPlug plug_type} denv l r :
      Forall (ddata_normalized h) (map snd denv) ->
      Forall
        (fun n : string * dnrc =>
           forall (denv : dbindings) (o : ddata),
             dnrc_eval denv (snd n) = Some o ->
             Forall (ddata_normalized h) (map snd denv) -> ddata_normalized h o) r ->
      rmap
         (fun x : string * dnrc =>
          match dnrc_eval denv (snd x) with
          | Some (Dlocal _) => None
          | Some (Ddistr coll) => Some (fst x, coll)
          | None => None
          end) r = Some l ->
      Forall (fun x : string * (list data) => data_normalized h (dcoll (snd x))) l.
    Proof.
      revert r; induction l; intros; trivial.
      destruct r; simpl in * ; [invcs H1 | ] .
      invcs H0.
      case_eq (dnrc_eval denv (snd p))
      ; intros; rewrite H0 in H1
      ; try discriminate.
      destruct d; try discriminate.
      apply some_lift in H1.
      destruct H1 as [? req eqq].
      invcs eqq.
      specialize (IHl _ H H5 req).
      constructor; trivial.
      simpl.
      specialize (H4 _ _ H0 H).
      invcs H4.
      constructor; trivial.
    Qed.

    Lemma dnrc_eval_normalized {plug:AlgPlug plug_type} denv e {o} :
      dnrc_eval denv e = Some o ->
      Forall (ddata_normalized h) (map snd denv) ->
      ddata_normalized h o.
    Proof.
      revert denv o. induction e; intros; simpl in H.
      - rewrite Forall_forall in H0.
        apply lookup_in in H.
        apply (H0 o).
        rewrite in_map_iff.
        exists (v,o); eauto.
      - inversion H; subst; intros.
        apply dnormalize_normalizes_local.
      - case_eq (dnrc_eval denv e1); [intros ? eqq1 | intros eqq1];
        (rewrite eqq1 in *;
          case_eq (dnrc_eval denv e2); [intros ? eqq2 | intros eqq2];
          rewrite eqq2 in *); simpl in *; try discriminate.
         + destruct d; destruct d0; simpl in H; try congruence;
           destruct o; simpl in *; unfold lift in H;
           case_eq (fun_of_binop h b d d0); intros; rewrite H1 in *; try congruence;
           inversion H; subst; clear H;
           constructor;
           eapply fun_of_binop_normalized; eauto.
           specialize (IHe1 denv (Dlocal d) eqq1 H0);
           inversion IHe1; assumption.
           specialize (IHe2 denv (Dlocal d0) eqq2 H0);
           inversion IHe2; assumption.
         + unfold olift2 in H; simpl in H.
           destruct d; simpl in H; congruence.
      - case_eq (dnrc_eval denv e); [intros ? eqq1 | intros eqq1];
        rewrite eqq1 in *;
        simpl in *; try discriminate.
        destruct d; simpl in H; try congruence;
        destruct o; simpl in H; unfold lift in H;
        case_eq (fun_of_unaryop h u d); intros; rewrite H1 in H;
        inversion H; subst; clear H;
        constructor;
        eapply fun_of_unaryop_normalized; eauto.
        specialize (IHe denv (Dlocal d) eqq1 H0); inversion IHe; assumption.
      - case_eq (dnrc_eval denv e1); [intros ? eqq1 | intros eqq1];
        rewrite eqq1 in *;
        simpl in *; try discriminate;
        case_eq (dnrc_eval ((v,d)::denv) e2); [intros ? eqq2 | intros eqq2];
        rewrite eqq2 in *;
        simpl in *; try discriminate.
        inversion H; subst; clear H.
        eapply IHe2; eauto.
        constructor; eauto.
      - case_eq (dnrc_eval denv e1); [intros ? eqq1 | intros eqq1];
        rewrite eqq1 in *;
        simpl in *; try discriminate;
        unfold checkLocal in H; simpl in H.
        destruct d; try discriminate.
        { destruct d; try discriminate. (* Local case for DNRCFor *)
          specialize (IHe1 _ _ eqq1 H0).
          inversion IHe1; subst.
          apply some_lift in H.
          destruct H; subst.
          constructor; constructor.
          inversion H2; subst; clear H2.
          apply (rmap_Forall e H1); intros.
          case_eq (dnrc_eval ((v, Dlocal x0) :: denv) e2); intros;
          rewrite H3 in H; simpl in H; try congruence.
          destruct d; simpl in H; try congruence.
          inversion H; subst; clear H.
          specialize (IHe2 _ _ H3).
          assert (ddata_normalized h (Dlocal z)).
          apply IHe2.
          constructor; eauto.
          constructor; assumption.
          inversion H; assumption. }
        { specialize (IHe1 _ _ eqq1 H0). (* Distr case for DNRCFor *)
          inversion IHe1; subst.
          apply some_lift in H.
          destruct H; subst.
          constructor.
          apply (rmap_Forall e H2); intros.
          case_eq (dnrc_eval ((v, Dlocal x0) :: denv) e2); intros;
          rewrite H3 in H; simpl in H; try congruence.
          destruct d; simpl in H; try congruence.
          inversion H; subst; clear H.
          specialize (IHe2 _ _ H3).
          assert (ddata_normalized h (Dlocal z)).
          apply IHe2.
          constructor; eauto.
          constructor; assumption.
          inversion H; assumption. }
      - case_eq (dnrc_eval denv e1); [intros ? eqq1 | intros eqq1];
        rewrite eqq1 in *;
        simpl in *; try discriminate.
        destruct d; try discriminate.
        destruct d; try discriminate.
        simpl in *.
        destruct b; eauto.
      - case_eq (dnrc_eval denv e1); [intros ? eqq1 | intros eqq1];
        rewrite eqq1 in *;
        simpl in *; try discriminate.
        specialize (IHe1 _ _ eqq1 H0).
        destruct d; try discriminate.
        destruct d; simpl in H; try discriminate;
        inversion IHe1; subst.
        + eapply IHe2; eauto.
          constructor; eauto.
          constructor; eauto;
          inversion H2; assumption.
        + eapply IHe3; eauto.
          constructor; eauto.
          constructor; eauto.
          inversion H2; assumption.
      - unfold lift in H.
        case_eq (dnrc_eval denv e); intros; rewrite H1 in H; simpl in H;
        try discriminate.
        destruct d; simpl in *; try discriminate.
        inversion H; subst; clear H.
        specialize (IHe denv (Ddistr l) H1 H0).
        inversion IHe; constructor; constructor; assumption.
      - case_eq (dnrc_eval denv e); intros; rewrite H1 in H; simpl in H;
        try discriminate.
        destruct d; simpl in *; try discriminate.
        destruct d; simpl in *; try discriminate.
        inversion H; subst; clear H.
        specialize (IHe denv (Dlocal (dcoll l)) H1 H0).
        inversion IHe; inversion H2; constructor; assumption.
      - simpl in H0.
        rewrite <- listo_to_olist_simpl_rmap in H0.
        case_eq (rmap
           (fun x : string * dnrc =>
            match dnrc_eval denv (snd x) with
            | Some (Dlocal _) => None
            | Some (Ddistr coll) => Some (fst x, coll)
            | None => None
            end) r); intros; rewrite H2 in H0; try discriminate.
        case_eq (plug_eval h l op); intros;
        rewrite H3 in H0; simpl in *; try discriminate.
        destruct d; try discriminate.
        inversion H0; subst; clear H0.
        assert (data_normalized h (dcoll l0)).
        + apply (plug_normalized h op l (dcoll l0)); trivial.
          apply Forall_dcoll_map_lift.
          unfold bindings_of_coll_bindings.
          eapply dnrc_alg_bindings_normalized; eauto.
        + constructor; inversion H0; assumption.
    Qed.

    Corollary dnrc_eval_normalized_local {plug:AlgPlug plug_type} denv e {d} :
      dnrc_eval denv e = Some (Dlocal d) ->
      Forall (ddata_normalized h) (map snd denv) ->
      data_normalized h d.
    Proof.
      intros.
      assert (ddata_normalized h (Dlocal d)).
      apply (dnrc_eval_normalized denv e); assumption.
      inversion H1; assumption.
    Qed.
         
  End GenDNNRC.

  Section NraEnvPlug.
    Require Import RAlgEnv.
    
    Definition nraenv_eval h aconstant_env op :=
      let aenv := drec nil in (* empty local environment to start, which is an empty record *)
      let aid := dcoll ((drec nil)::nil) in (* to be checked *)
      fun_of_algenv h (bindings_of_coll_bindings aconstant_env) op aenv aid.

    Lemma nraenv_eval_normalized h :
      forall op:algenv, forall (constant_env:coll_bindings) (o:data),
      Forall (fun x => data_normalized h (snd x)) (bindings_of_coll_bindings constant_env) ->
      nraenv_eval h constant_env op = Some o ->
      data_normalized h o.
    Proof.
      intros.
      specialize (@fun_of_algenv_normalized _ h (bindings_of_coll_bindings constant_env) op (drec nil) (dcoll ((drec nil)::nil))); intros.
      unfold bindings_of_coll_bindings.
      apply H1; try assumption.
      repeat constructor.
      repeat constructor.
    Qed.

    Global Program Instance AlgEnvPlug : (@AlgPlug algenv) :=
      mkAlgPlug nraenv_eval nraenv_eval_normalized.

    Definition dnrc_algenv {A} := @dnrc A algenv.

  End NraEnvPlug.

End DNNRC.

Global Arguments AlgPlug {fruntime} plug_type : clear implicits. 
Global Arguments dnrc {fruntime} A plug_type: clear implicits. 

Tactic Notation "dnrc_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "DNRCVar"%string
  | Case_aux c "DNRCConst"%string
  | Case_aux c "DNRCBinop"%string
  | Case_aux c "DNRCUnop"%string
  | Case_aux c "DNRCLet"%string
  | Case_aux c "DNRCFor"%string
  | Case_aux c "DNRCIf"%string
  | Case_aux c "DNRCEither"%string
  | Case_aux c "DNRCCollect"%string
  | Case_aux c "DNRCDispatch"%string
  | Case_aux c "DNRCAlg"%string ].

(* end hide *)

(* 
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "QCert")) ***
*** End: ***
*)
