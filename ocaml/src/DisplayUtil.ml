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

open Compiler.EnhancedCompiler
open Util
open ConfigUtil
open PrettyIL

(* Display ILs *)

let display_to_string conf modelandtype op =
  let opt_nraenv = CompDriver.nraenv_optim op in
  let opt_nnrc = CompDriver.nraenv_optim_to_nnrc_optim op in
  let opt_nnrcmr = CompDriver.nraenv_optim_to_nnrc_optim_to_nnrcmr_comptop_optim op in
  let nnrcmr_spark = CompDriver.nnrcmr_to_nnrcmr_spark_prepare opt_nnrcmr in
  let nnrcmr_cldmr = CompDriver.nnrcmr_to_nnrcmr_cldmr_prepare opt_nnrcmr in
  let nrastring = PrettyIL.pretty_nraenv (get_charset_bool conf) (get_margin conf) opt_nraenv in
  let nrcstring = PrettyIL.pretty_nnrc (get_charset_bool conf) (get_margin conf) opt_nnrc in
  let nrcmrstring = PrettyIL.pretty_nnrcmr (get_charset_bool conf) (get_margin conf) opt_nnrcmr in
  let nrcmr_spark_string = PrettyIL.pretty_nnrcmr (get_charset_bool conf) (get_margin conf) nnrcmr_spark in
  let nrcmr_cldmr_string = PrettyIL.pretty_nnrcmr (get_charset_bool conf) (get_margin conf) nnrcmr_cldmr in
  let untyped_dnrc_string_thunk (_:unit) =
    PrettyIL.pretty_dnrc
      PrettyIL.pretty_annotate_ignore
      (PrettyIL.pretty_plug_dataset (get_charset_bool conf))
      (get_charset_bool conf) (get_margin conf)
      (CompDriver.nraenv_optim_to_nnrc_optim_to_dnnrc CompUtil.mkDistLoc op) in
  let opt_dnrc_dataset_string =
    begin
      match modelandtype with
      | Some (brand_model, inputType) ->
	  begin
	    match
	      CompDriver.dnnrc_dataset_to_dnnrc_typed_dataset
		brand_model
		(Enhanced.Model.foreign_typing brand_model)
		(CompDriver.nraenv_optim_to_nnrc_optim_to_dnnrc CompUtil.mkDistLoc op)
		inputType
	    with
	    | Some ds -> PrettyIL.pretty_dnrc
		  (PrettyIL.pretty_annotate_annotated_rtype
		     (get_charset_bool conf) PrettyIL.pretty_annotate_ignore)
		  (PrettyIL.pretty_plug_dataset (get_charset_bool conf))
		  (get_charset_bool conf) (get_margin conf) ds
	    | None -> "DNRC expression was not well typed.  The untyped/unoptimized dnrc expression is:\n" ^ untyped_dnrc_string_thunk ()
	  end
      | None -> "Optimized DNRC expression can't be determined without a schema.  The untyped/unoptimized dnrc expression is:\n" ^ untyped_dnrc_string_thunk ()
    end
  in (nrastring,nrcstring, nrcmrstring, nrcmr_spark_string, nrcmr_cldmr_string, opt_dnrc_dataset_string)

let get_display_fname conf fname =
  let fpref = Filename.chop_extension fname in
  target_f (get_display_dir conf) fpref

let make_pretty_config charkind margin =
  let dpc = default_pretty_config () in
  begin
    match charkind with
    | Ascii -> set_ascii dpc ()
    | Greek -> set_greek dpc ()
  end;
  set_margin dpc margin;
  dpc

let display_nraenv_top (ck:charkind) (margin:int) modelandtype (ios:string option) (dfname:string) op =
  let modelandtype' =
    begin
    match modelandtype with
    | Some bm -> Some bm
    | None ->
	begin
	  match ios with
	  | Some io ->
              let sch = TypeUtil.schema_of_io_json (ParseString.parse_io_from_string io) in
              let brand_model = sch.TypeUtil.sch_brand_model in
              let wmRType = sch.TypeUtil.sch_camp_type in
	      Some (brand_model, wmRType)
	  | None -> None
	end
    end
  in
  let (display_nra,display_nrc,display_nrcmr,display_nrcmr_spark,display_nrcmr_cldmr, display_opt_dnrc_dataset) =
    display_to_string (make_pretty_config ck margin) modelandtype' op
  in
  let fout_nra = outname dfname (suffix_nraenv ()) in
  let fout_nrc = outname dfname (suffix_nnrc ()) in
  let fout_nrcmr = outname dfname (suffix_nnrcmr ()) in
  let fout_nrcmr_spark = outname dfname (suffix_nnrcmr_spark ()) in
  let fout_nrcmr_cldmr = outname dfname (suffix_nnrcmr_cldmr ()) in
  let fout_dnrc_dataset = outname dfname (suffix_dnnrc_dataset ()) in
  begin
    make_file fout_nra display_nra;
    make_file fout_nrc display_nrc;
    make_file fout_nrcmr display_nrcmr;
    make_file fout_nrcmr_spark display_nrcmr_spark;
    make_file fout_nrcmr_cldmr display_nrcmr_cldmr;
    make_file fout_dnrc_dataset display_opt_dnrc_dataset;
  end

(* S-expression hooks *)

let sexp_string_to_camp s = ParseString.parse_camp_sexp_from_string s
let camp_to_sexp_string p = SExp.sexp_to_string (AstsToSExp.camp_to_sexp p)

let sexp_string_to_nraenv s = ParseString.parse_nraenv_sexp_from_string s
let nraenv_to_sexp_string op = SExp.sexp_to_string (AstsToSExp.nraenv_to_sexp op)

let sexp_string_to_nnrc s = ParseString.parse_nnrc_sexp_from_string s
let nnrc_to_sexp_string n = SExp.sexp_to_string (AstsToSExp.nnrc_to_sexp n)

let sexp_string_to_nnrcmr s = ParseString.parse_nnrcmr_sexp_from_string s
let nnrcmr_to_sexp_string n = SExp.sexp_to_string (AstsToSExp.nnrcmr_to_sexp n)

let sexp_string_to_cldmr s = ParseString.parse_cldmr_sexp_from_string s
let cldmr_to_sexp_string n = SExp.sexp_to_string (AstsToSExp.cldmr_to_sexp n)

(* Top-level *)

let sexp_nraenv_top dfname op =
  let opt_nnrc = CompDriver.nraenv_optim_to_nnrc_optim op in
  let display_nra = nraenv_to_sexp_string op in
  let display_nrc = nnrc_to_sexp_string opt_nnrc in
  let nnrcmr = CompDriver.nraenv_optim_to_nnrc_optim_to_nnrcmr_comptop_optim op in
  let nrcmr_spark = CompDriver.nnrcmr_to_nnrcmr_spark_prepare nnrcmr in
  let nrcmr_cldmr = CompDriver.nnrcmr_to_nnrcmr_cldmr_prepare nnrcmr in
  let display_nrcmr_spark = nnrcmr_to_sexp_string nrcmr_spark in
  let display_nrcmr_cldmr = nnrcmr_to_sexp_string nrcmr_cldmr in
  let fout_nra = outname dfname (suffix_nrasexp ()) in
  let fout_nrc = outname dfname (suffix_nnrcsexp ()) in
  let fout_nrcmr_spark = outname dfname (suffix_nnrcmr_sparksexp ()) in
  let fout_nrcmr_cldmr = outname dfname (suffix_nnrcmr_cldmrsexp ()) in
  begin
    make_file fout_nra display_nra;
    make_file fout_nrc display_nrc;
    make_file fout_nrcmr_spark display_nrcmr_spark;
    make_file fout_nrcmr_cldmr display_nrcmr_cldmr
  end

(* SData section *)

let display_sdata (conf : data_config) (fname:string) (sdata:string list) =
  let fpref = Filename.chop_extension fname in
  let fout_sdata = outname (target_f (get_data_dir conf) fpref) (suffix_sdata ()) in
  let sdata =
    String.concat "\n" sdata
  in
  make_file fout_sdata sdata
