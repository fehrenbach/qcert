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

(* This is main interface for CALib, the CAMP Compiler library *)

open Util
open ParseString
open CloudantUtil
open Stats
open DisplayUtil
open Compiler.EnhancedCompiler


(* Schema Section *)

type schema = RType.brand_model * RType.camp_type

let schema_of_io (io:string) =
  let sch = TypeUtil.schema_of_io_json (ParseString.parse_io_from_string io) in
  let brand_model = sch.TypeUtil.sch_brand_model in
  let camp_type = sch.TypeUtil.sch_camp_type in
  (brand_model, camp_type)

(* Abstract AST types *)

type camp = CompDriver.camp
type nraenv = CompDriver.nraenv
type nnrc = CompDriver.nnrc
type dnnrc_dataset = CompDriver.dnnrc_dataset
type dnnrc_typed_dataset = CompDriver.dnnrc_typed_dataset
type nnrcmr = CompDriver.nnrcmr
type cldmr = CompDriver.cldmr

let dlocal_conv l =
  if l then Compiler.Vlocal else Compiler.Vdistr

let dvar_conv x =
  (Util.char_list_of_string x, Compiler.Vdistr)

(*
 *  Frontend section
 *)

(* From source to CAMP *)

let rule_to_camp (s:string) : camp =
  begin match ParseString.parse_rule_from_string s with
  | _, CompDriver.Q_rule q -> CompDriver.rule_to_camp q
  | _, CompDriver.Q_camp q -> q
  | _, CompDriver.Q_error err -> raise (CACo_Error (string_of_char_list err))
  | _ -> assert false
  end




(* From camp to NRAEnv *)

let camp_to_nraenv (c:camp) =
  CompDriver.camp_to_nraenv c

(* From source to NRAEnv *)

let rule_to_nraenv_name (s:string) : string =
  fst (ParseString.parse_rule_from_string s)

let rule_to_nraenv (s:string) : nraenv =
  begin match ParseString.parse_rule_from_string s with
  | _, CompDriver.Q_rule q -> CompDriver.rule_to_nraenv q
  | _, CompDriver.Q_camp q -> CompDriver.camp_to_nraenv q
  | _, CompDriver.Q_error err -> raise (CACo_Error (string_of_char_list err))
  | _ -> assert false
  end

let oql_to_nraenv_name (s:string) : string =
  "OQL"

let oql_to_nraenv (s:string) : nraenv =
  let q = ParseString.parse_oql_from_string s in
  CompDriver.oql_to_nraenv q

(*
 *  Core compiler section
 *)

(* Translations *)

let translate_nraenv_to_nnrc (q:nraenv) : nnrc = CompDriver.nraenv_to_nnrc q
let translate_nnrc_to_nnrcmr (q:nnrc) : nnrcmr = CompDriver.nnrc_to_nnrcmr_comptop Compiler.init_vinit q
let translate_nnrc_to_dnnrc (n:nnrc) : dnnrc_dataset = CompDriver.nnrc_to_dnnrc_dataset CompUtil.mkDistLoc n

let translate_nraenv_to_dnnrc_typed_dataset (sc:schema) (op:nraenv) : dnnrc_typed_dataset =
  match
    let (brand_model,wmRType) = sc in
    (CompDriver.dnnrc_dataset_to_dnnrc_typed_dataset
       brand_model
       (Enhanced.Model.foreign_typing brand_model)
       (CompDriver.nraenv_optim_to_nnrc_optim_to_dnnrc CompUtil.mkDistLoc op)
       wmRType)
  with
  | Some x -> x
  | None -> raise (CACo_Error "Spark2 target compilation failed")

let dnnrc_typed_dataset_to_spark2 (nrule:string) (sc:schema) (e:dnnrc_typed_dataset) : string =
  let (brand_model,wmRType) = sc in
  string_of_char_list
    (CompDriver.dnnrc_typed_dataset_to_spark2
       brand_model
       wmRType (Util.char_list_of_string nrule) e)

(* NRAEnv Optimizer *)
let optimize_nraenv (op:nraenv) = CompDriver.nraenv_optim op

(* NNRC Optimizer *)
let optimize_nnrc (n:nnrc) = CompDriver.nnrc_optim n

(* NNRCMR Optimizer *)
let optimize_nnrcmr (n:nnrcmr) = CompDriver.nnrcmr_optim n

let optimize_nnrcmr_for_cloudant (n:nnrcmr) = CompDriver.nnrcmr_to_nnrcmr_cldmr_prepare n
let optimize_nnrcmr_for_spark (n:nnrcmr) = CompDriver.nnrcmr_to_nnrcmr_spark_prepare n

(* For convenience *)
(* Note: This includes optimization phases *)

let compile_nraenv_to_nnrc (op:nraenv) = CompDriver.nraenv_optim_to_nnrc_optim op
let compile_nraenv_to_nnrcmr (op:nraenv) = CompDriver.nraenv_optim_to_nnrc_optim_to_nnrcmr_comptop_optim op


(*
 *  Backend section
 *)

let nnrc_to_js (n:nnrc) =
  string_of_char_list
    (CompDriver.nnrc_to_javascript n)
let nnrc_to_java (basename:string) (imports:string) (n:nnrc) =
  string_of_char_list
    (CompDriver.nnrc_to_java
       (Util.char_list_of_string basename)
       (Util.char_list_of_string imports) n)
let nnrcmr_to_spark (nrule:string) (n:nnrcmr) =
  string_of_char_list
    (CompDriver.nnrcmr_prepared_to_spark
       (Util.char_list_of_string nrule) n)

let translate_nnrcmr_to_cldmr (n:nnrcmr) : cldmr =
  CloudantUtil.cloudant_translate_no_harness n

let cldmr_to_cloudant (prefix:string) (nrule:string) (cl:cldmr) : string =
  CloudantUtil.cloudant_code_gen_no_harness (idioticize prefix nrule) cl

(* For convenience *)
      
let compile_nraenv_to_js (op:nraenv) : string =
  string_of_char_list (CompDriver.nnrc_to_javascript
			 (CompDriver.nraenv_optim_to_nnrc_optim op))

let compile_nraenv_to_java (basename:string) (imports:string) (op:nraenv) : string =
  string_of_char_list (CompDriver.nnrc_to_java
			 (Util.char_list_of_string basename)
			 (Util.char_list_of_string imports)
			 (CompDriver.nraenv_optim_to_nnrc_optim op))

let compile_nraenv_to_spark (nrule:string) (op:nraenv) : string =
  string_of_char_list (CompDriver.nnrcmr_to_spark
			 (Util.char_list_of_string nrule)
			 (CompDriver.nraenv_optim_to_nnrc_optim_to_nnrcmr_comptop_optim op))

let compile_nraenv_to_cloudant (prefix:string) (nrule:string) (op:nraenv) : string =
  cloudant_compile_no_harness_from_nra (idioticize prefix nrule) op

let compile_nraenv_to_cloudant_with_harness (harness:string) (cldrule:string) (op:nraenv) (io:string) =
  cloudant_compile_from_nra harness cldrule op (DataUtil.get_hierarchy_cloudant (Some (ParseString.parse_io_from_string io)))

let compile_nraenv_to_cloudant_with_harness_no_hierarchy (harness:string) (cldrule:string) (op:nraenv) =
  cloudant_compile_from_nra harness cldrule op (DataUtil.get_hierarchy_cloudant None)

let compile_nnrcmr_to_cloudant (prefix:string) (nrule:string) (n:nnrcmr) : string =
  cloudant_compile_no_harness_from_nnrcmr (idioticize prefix nrule) n
  
(*
 *  ASTs support
 *)

(* Import/Export ASTs *)
(* WARNING: Not supported yet *)

(* Import/Export ASTs *)

let export_camp (p:camp) = DisplayUtil.camp_to_sexp_string p
let import_camp (ps:string) = DisplayUtil.sexp_string_to_camp ps

let export_nraenv (op:nraenv) = DisplayUtil.nraenv_to_sexp_string op
let import_nraenv (ops:string) = DisplayUtil.sexp_string_to_nraenv ops

let export_nnrc (n:nnrc) = DisplayUtil.nnrc_to_sexp_string n
let import_nnrc (ns:string) = DisplayUtil.sexp_string_to_nnrc ns

let export_nnrcmr (n:nnrcmr) = DisplayUtil.nnrcmr_to_sexp_string n
let import_nnrcmr (ns:string) = DisplayUtil.sexp_string_to_nnrcmr ns

let export_cldmr (n:cldmr) = DisplayUtil.cldmr_to_sexp_string n
let import_cldmr (ns:string) = DisplayUtil.sexp_string_to_cldmr ns


(* Pretties *)

let pretty_nraenv (greek:bool) (margin:int) (op:nraenv) = PrettyIL.pretty_nraenv greek margin op
let pretty_nnrc (greek:bool) (margin:int) (n:nnrc) = PrettyIL.pretty_nnrc greek margin n
let pretty_nnrcmr_for_spark (greek:bool) (margin:int) (nmr:nnrcmr) =
  PrettyIL.pretty_nnrcmr greek margin (CompDriver.nnrcmr_to_nnrcmr_spark_prepare nmr)
let pretty_nnrcmr_for_cloudant (greek:bool) (margin:int) (nmr:nnrcmr) =
  PrettyIL.pretty_nnrcmr greek margin (CompDriver.nnrcmr_to_nnrcmr_cldmr_prepare nmr)

(* Options *)

let set_optim_trace = Logger.set_trace
let unset_optim_trace = Logger.unset_trace

(* Display *)

let display_nraenv (charbool:bool) (margin:int) modelandtype io dfname op =
  if charbool
  then display_nraenv_top PrettyIL.Greek margin (Some modelandtype) (Some io) dfname op
  else display_nraenv_top PrettyIL.Ascii margin (Some modelandtype) (Some io) dfname op

let display_nraenv_no_schema (charbool:bool) (margin:int) io dfname op =
  if charbool
  then display_nraenv_top PrettyIL.Greek margin None (Some io) dfname op
  else display_nraenv_top PrettyIL.Ascii margin None (Some io) dfname op

let display_nraenv_no_io (charbool:bool) (margin:int) modelandtype dfname op =
  if charbool
  then display_nraenv_top PrettyIL.Greek margin (Some modelandtype) None dfname op
  else display_nraenv_top PrettyIL.Ascii margin (Some modelandtype) None dfname op

let display_nraenv_no_schema_no_io (charbool:bool) (margin:int) dfname op =
  if charbool
  then display_nraenv_top PrettyIL.Greek margin None None dfname op
  else display_nraenv_top PrettyIL.Ascii margin None None dfname op

let display_nraenv_sexp dfname op =
  sexp_nraenv_top dfname op

