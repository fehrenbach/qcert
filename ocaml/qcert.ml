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

open Util
open QcertConfig
open Compiler.EnhancedCompiler

(* Command line args *)

let args_list gconf =
  Arg.align
    [ ("-source", Arg.String (QcertArg.set_source gconf),
       "<lang> Indicates the language for of thesource file (default: Rule)");
      ("-target", Arg.String (QcertArg.set_target gconf),
       "<lang> Indicates the language for the target query (default: js)");
      ("-path", Arg.String (QcertArg.add_path gconf),
       "<lang> Specify an intermediate language in the compilation path");
      ("-exact-path", Arg.Unit (QcertArg.set_exact_path gconf),
       " Use exactly the given path (do not infer intermediate steps nor add optimization)");
      ("-dir", Arg.String (QcertArg.set_dir gconf),
       "<dir> Directory for the emited code");
      ("-dir-target", Arg.String (QcertArg.set_dir_target gconf),
       "<dir> Directory for the emitied code of target (if not specified use the one given by -dir)");
      ("-js-runtime", Arg.String (CloudantUtil.set_harness gconf.gconf_cld_conf),
       "<harness.js> JavaScript runtime");
      ("-io", Arg.String (QcertArg.set_io gconf),
       "<file.io> Schema and inputs data for evaluation");
      (* ("-stats", Arg.Unit (set_stats conf), *)
      (*    " Produce statistics for the target query"); *)
      (* ("-stats-all", Arg.Unit (set_stats conf), *)
      (*    " Produce statistics for all intermediate queries"); *)
      ("-emit-all", Arg.Unit (QcertArg.set_emit_all gconf),
       " Emit generated code of all intermediate queries");
      ("-emit-sexp", Arg.Unit (QcertArg.set_emit_sexp gconf),
       " Emit the target query as an s-expression");
      ("-emit-sexp-all", Arg.Unit (QcertArg.set_emit_sexp_all gconf),
       " Emit all intermediate queries as s-expressions");
      (* ("-log-optims", Arg.Unit (Logger.set_trace), *)
      (*  " Logs the optimizations/rewrites during compilation"); *)
      ("-ascii", Arg.Unit (PrettyIL.set_ascii gconf.gconf_pretty_config),
       " Avoid unicode symbols in emited queries");
      ("-margin", Arg.Int (PrettyIL.set_margin gconf.gconf_pretty_config),
       "<n> Set right margin for emited queries");
      ("-cld-prefix", Arg.String (CloudantUtil.set_prefix gconf.gconf_cld_conf),
       "<pref> Cloudant DB prefix");
      ("-java-imports", Arg.String (QcertArg.set_java_imports gconf),
       "<imports> Additional imports for the Java runtime");
      (* ("-eval", Arg.Unit XXX, "Evaluate the target query"); *)
      (* ("-eval-all", Arg.Unit XXX, "Evaluate all the intermediate queries"); *)
      ("-vinit", Arg.String (QcertArg.set_vinit gconf),
       "<init> Set the name init variable for the map-reduce backends");
      ("-vdistr", Arg.String (QcertArg.add_vdirst gconf),
       "<x> Declare x as a distributed variable");
      ("-vlocal", Arg.String (QcertArg.add_vlocal gconf),
       "<x> Declare x as a local variable");
    ]

let anon_args gconf f = QcertArg.add_input_file gconf f

let languages =
  [ CompDriver.L_rule;
    CompDriver.L_camp;
    CompDriver.L_oql;
    CompDriver.L_nra;
    CompDriver.L_nraenv;
    CompDriver.L_nnrc;
    CompDriver.L_nnrcmr;
    CompDriver.L_cldmr;
    CompDriver.L_dnnrc_dataset;
    CompDriver.L_dnnrc_typed_dataset;
    CompDriver.L_javascript;
    CompDriver.L_java;
    CompDriver.L_spark;
    CompDriver.L_spark2;
    CompDriver.L_cloudant; ]

let string_of_path sep path =
  let buff = Buffer.create 128 in
  let str_ff = Format.formatter_of_buffer buff in
  let () =
    Format.fprintf str_ff "%a"
      (Format.pp_print_list
         ~pp_sep:(fun ff () -> Format.fprintf ff "%(%)" sep)
         (fun ff lang -> Format.fprintf ff "%s" (QcertUtil.name_of_language lang)))
      path
  in
  Format.pp_print_flush str_ff ();
  Buffer.contents buff


let languages_string =
  string_of_path ", " languages

let usage =
  "Q*cert - Query compiler\n"^
  "Supported languages are:\n"^
  "  "^languages_string^
  "\n"^
  "Usage: "^Sys.argv.(0)^" [options] query1 query2 ..."


let parse_args () =
  let gconf =
    { gconf_source = CompDriver.L_rule;
      gconf_target = CompDriver.L_javascript;
      gconf_path = [];
      gconf_exact_path = false;
      gconf_dir = None;
      gconf_dir_target = None;
      gconf_io = None;
      gconf_schema = TypeUtil.empty_schema;
      gconf_cld_conf = CloudantUtil.default_cld_config ();
      gconf_emit_all = false;
      gconf_emit_sexp = false;
      gconf_emit_sexp_all = false;
      gconf_pretty_config = PrettyIL.default_pretty_config ();
      gconf_java_imports = "";
      gconf_input_files = [];
      gconf_mr_vinit = "init";
      gconf_vdbindings = []; }
  in
  Arg.parse (args_list gconf) (anon_args gconf) usage;
  complet_configuration gconf

(* Parsing *)

let parse_file (gconf: QcertConfig.global_config) (file_name: string) =
  let slang = gconf.gconf_source in
  let qname, q =
    ParseFile.parse_query_from_file slang file_name
  in
  (qname, q)

(* Message *)

let print_comilation_path gconf =
  let spath = string_of_path " -> " gconf.gconf_path in
  Format.printf "Compiling from %s to %s:@\n"
    (QcertUtil.name_of_language gconf.gconf_source)
    (QcertUtil.name_of_language gconf.gconf_target);
  Format.printf "  %s@." spath

(* Compilation *)

let compile_file (dv_conf: CompDriver.driver_config) (schema: TypeUtil.schema) (path: CompDriver.language list) (q: CompDriver.query) : CompDriver.query list =
  let brand_model = schema.TypeUtil.sch_brand_model in
  let foreign_typing = schema.TypeUtil.sch_foreign_typing in
  let dv = CompDriver.driver_of_path brand_model dv_conf path in
  let () = QcertUtil.driver_no_error dv in
  let dv = CompDriver.fix_driver brand_model dv q in
  let queries = CompDriver.compile brand_model foreign_typing dv q in
  let () = List.iter QcertUtil.query_no_error queries in
  queries

(* Emit *)

let emit_file (dv_conf: CompDriver.driver_config) (schema: TypeUtil.schema) pretty_conf dir file_name q =
  let s = PrettyIL.pretty_query pretty_conf q in
  let brand_model = schema.TypeUtil.sch_brand_model in
  let fpref = Filename.chop_extension file_name in
  let ext = ConfigUtil.suffix_of_language (CompDriver.language_of_query brand_model q) in
  let fout = outname (target_f dir fpref) ext in
  make_file fout s


(* Emit s-expr *)

let emit_sexpr_file (schema: TypeUtil.schema) dir file_name q =
  let sexp = AstsToSExp.query_to_sexp q in
  let s = SExp.sexp_to_string sexp in
  let brand_model = schema.TypeUtil.sch_brand_model in
  let fpref = Filename.chop_extension file_name in
  let fpost = QcertUtil.name_of_language (CompDriver.language_of_query brand_model q) in
  let fout = outname (target_f dir (fpref^"_"^fpost)) ".sexp" in
  make_file fout s


(* Main *)

let main_one_file gconf file_name =
  let schema = gconf.gconf_schema in
  let brand_model = schema.TypeUtil.sch_brand_model in
  let (qname, q_source) = parse_file gconf file_name in
  let cname = (Filename.basename (Filename.chop_extension file_name)) in (* for Java code generation *)
  let dv_conf = QcertConfig.driver_conf_of_global_conf gconf (* schema *) qname (* class name *) cname in
  let queries = compile_file dv_conf schema gconf.gconf_path q_source in
  let q_target =
    begin match List.rev queries with
    | q :: _ -> q
    | _ -> raise (CACo_Error "No compilation result!")
    end
  in
  let () =
    (* emit compiled query *)
    let pconf = gconf.gconf_pretty_config in
    let dir =
      begin match gconf.gconf_dir_target with
      | Some dir -> Some dir
      | None -> gconf.gconf_dir
      end
    in
    emit_file dv_conf schema pconf dir file_name q_target
  in
  let () =
    (* Emit intermediate queries *)
    if gconf.gconf_emit_all then begin
      let _ =
        List.fold_left
          (fun fname q ->
            let pconf = gconf.gconf_pretty_config in
            let dir = gconf.gconf_dir in
            emit_file dv_conf schema pconf dir fname q;
            let suff =
              ConfigUtil.suffix_of_language (CompDriver.language_of_query brand_model q)
            in
            (Filename.chop_extension fname)^suff)
          file_name queries
      in ()
    end
  in
  let () =
    (* emit-sexp compiled query *)
    if gconf.gconf_emit_sexp then begin
      emit_sexpr_file schema gconf.gconf_dir file_name q_target
    end
  in
  let () =
    (* emit-sexp-all intermediate queries *)
    if gconf.gconf_emit_sexp_all then begin
      let _ =
        List.fold_left
          (fun fname q ->
            emit_sexpr_file schema gconf.gconf_dir fname q;
            let suff =
              ConfigUtil.suffix_of_language (CompDriver.language_of_query brand_model q)
            in
            (Filename.chop_extension fname)^suff)
          file_name queries
      in ()
    end
  in
  ()

let () =
  let gconf = parse_args () in
  print_comilation_path gconf;
  List.iter
    (fun file_name -> main_one_file gconf file_name)
    gconf.gconf_input_files
