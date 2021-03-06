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

Section Dataset.

  Require Import Basics.
  Require Import String.
  Require Import List.
  Require Import Arith.
  Require Import ZArith.
  Require Import EquivDec.
  Require Import Morphisms.

  Require Import Utils BasicSystem.
  Require Import DData.
  Require Import RAlgEnv.

  Require Import RType.

  Context {fruntime:foreign_runtime}.
  Context {ftype: ForeignType.foreign_type}.
  Context {m : TBrandModel.brand_model}.

  Definition var := string.

  Inductive column :=
  | CCol   : string -> column
  | CDot   : string -> column -> column
  | CLit   : data * rtype₀ -> column
  | CPlus  : column -> column -> column
  | CEq    : column -> column -> column
  | CNeg   : column -> column
  (* NOTE we actually codegen to a UDF for this, not Spark's printing *)
  | CToString : column -> column
  | CSConcat : column -> column -> column
  (* In contrast to QCert cast, this takes the runtime brands as input (as a column),
   * not the data, and returns a boolean suitable for filtering, not left(data)/right(null). *)
  | CUDFCast : list string -> column -> column
  | CUDFUnbrand : rtype₀ -> column -> column.

  Inductive dataset :=
  | DSVar : string -> dataset
  | DSSelect : list (string * column) -> dataset -> dataset
  | DSFilter : column -> dataset -> dataset
  | DSCartesian : dataset -> dataset -> dataset
  | DSExplode : string -> dataset -> dataset.

  Section eval.
    Context (h:brand_relation_t).

    (** Evaluate a column expression in an environment of toplevel columns
     * i.e. a row in a dataset. *)
    Fixpoint fun_of_column (c: column) (row: list (string * data)) : option data :=
      let fc := flip fun_of_column row in
      match c with
      | CCol n =>
        lookup string_eqdec row n
      | CNeg c1 =>
        olift (unudbool negb) (fc c1)
      | CDot n c1 =>
        match fc c1 with
        | Some (drec fs) => edot fs n
        | _ => None
        end
      | CLit (d, _) => Some d
      | CPlus c1 c2 =>
        match fc c1, fc c2 with
        | Some (dnat l), Some (dnat r) => Some (dnat (Z.add l r))
        | _, _ => None
        end
      | CEq c1 c2 =>
        (* TODO We use QCert equality here. Define and use Spark equality.
         * Spark has a three-valued logic, meaning special treatment for NULL.
         * In contrast to QCert it also does not deal with brands, bags, open records, ... *)
        lift2 (fun x y => dbool (if data_eq_dec x y then true else false)) (fc c1) (fc c2)
      | CToString c1 =>
        lift (compose dstring dataToString) (fc c1)
      | CSConcat c1 c2 =>
        match fc c1, fc c2 with
        | Some (dstring l), Some (dstring r) => Some (dstring (l ++ r))
        | _, _ => None
        end
      | CUDFCast target_brands column_of_runtime_brands =>
        match fc column_of_runtime_brands with
        | Some (dcoll runtime_brand_strings) =>
          lift (fun runtime_brands =>
                  dbool (if sub_brands_dec h runtime_brands target_brands then true else false))
               (listo_to_olist (map (fun s => match s with dstring s => Some s | _ => None end) runtime_brand_strings))
        | _ => None
        end
      | CUDFUnbrand _ _ => None (* TODO *)
      end.

    Require Import DNNRC.
    Fixpoint dataset_eval (dsenv : coll_bindings) (e: dataset) : option (list data) :=
      match e with
      | DSVar s => lookup equiv_dec dsenv s
      | DSSelect cs d =>
        match dataset_eval dsenv d with
        | Some rows =>
          (* List of column names paired with their functions. *)
          let cfuns: list (string * (list (string * data) -> option data)) :=
              map (fun p => (fst p, fun_of_column (snd p))) cs in
          (* Call this function on every row in the input dataset.
           * It calls every column function in the context of the row. *)
          let rfun: data -> option (list (string * data)) :=
              fun row =>
                match row with
                | drec fs =>
                  listo_to_olist (map (fun p => lift (fun r => (fst p, r)) ((snd p) fs)) cfuns)
                | _ => None
                end
          in
          (* Call the row function on every row, and wrap the result in a record.
           * For the result to be a legal record in the QCert data model,
           * the field names must be in order and not contain duplicates. *)
          let results := map (compose (lift drec) rfun) rows in
          listo_to_olist results
        | _ => None
        end
      | DSFilter c d =>
        let cfun := fun_of_column c in
        lift (* TODO This silently swallows eval errors. Don't do that. *)
                  (filter (fun row =>
                             match row with
                             | drec fs =>
                               match cfun fs with
                               | Some (dbool true) => true
                               | _ => false
                               end
                             | _ => false
                             end))
                  (dataset_eval dsenv d)
      (* NOTE Spark / QCert semantics mismatch
       * Sparks join operation just appends the columns from the left side to the right,
       * and this is what the semantics model. For the result to be legal in QCert, great
       * care must be taken to ensure that this results in unique and sorted column names. *)
      | DSCartesian d1 d2 =>
        match dataset_eval dsenv d1, dataset_eval dsenv d2 with
        | Some rs1, Some rs2 =>
          let data :=
              flat_map (fun r1 => map (fun r2 =>
                                         match r1, r2 with
                                         | drec a, drec b => Some (drec (a ++ b))
                                         | _, _ => None
                                         end)
                                      rs2)
                       rs1 in
          listo_to_olist data
        | _, _ => None
        end
      | DSExplode s d1 =>
        match dataset_eval dsenv d1 with
        | Some l =>
          let data :=
              flat_map (fun row =>
                          match row with
                          | drec fields =>
                            match edot fields s with
                            | Some (dcoll inners) =>
                              map (fun inner =>
                                     orecconcat (drec fields) (drec ((s, inner)::nil)))
                                  inners
                            | _ => None::nil
                            end
                          | _ => None::nil
                          end)
                       l in
          listo_to_olist data
        | _ => None
        end
      end.
  End eval.

  Section DatasetPlug.

    Definition wrap_dataset_eval h dsenv q :=
      lift dcoll (@dataset_eval h dsenv q).

    Lemma dataset_eval_normalized h :
      forall q:dataset, forall (constant_env:coll_bindings) (o:data),
      Forall (fun x => data_normalized h (snd x)) (bindings_of_coll_bindings constant_env) ->
      wrap_dataset_eval h constant_env q = Some o ->
      data_normalized h o.
    Proof.
      intros.
      admit.
    Admitted.

    Global Program Instance SparkIRPlug : (@AlgPlug _ dataset) :=
      mkAlgPlug wrap_dataset_eval dataset_eval_normalized.

  End DatasetPlug.

End Dataset.

(*
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "QCert")) ***
*** End: ***
*)
