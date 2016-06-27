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

(* This module contains parsing utilities *)

open Compiler.EnhancedCompiler

(********)
(* ASTs *)
(********)

type camp = Compiler.pat
type algenv = Compiler.algenv
type nrc = Compiler.nrc
type dnrc = (Compiler.__, algenv) Compiler.dnrc
type nrcmr = (Compiler.var * Compiler.localization) list * Compiler.nrcmr
type cldmr = Compiler.cld_mrl

type sexp_ast = SExp.sexp

type io_ast = Data.data
type json_ast = Data.data

type rule_ast = string * Rule.rule

type rORc_ast =
  | RuleAst of Rule.rule
  | CampAst of Compiler.pat
      
type oql_ast = OQL.expr

(* AST <-> S-Expr *)

val sexp_to_data : sexp_ast -> io_ast
val data_to_sexp : io_ast -> sexp_ast

val sexp_to_alg : sexp_ast -> algenv
val alg_to_sexp : algenv -> sexp_ast

val sexp_to_nrc : sexp_ast -> nrc
val nrc_to_sexp : nrc -> sexp_ast

val sexp_to_nrcmr : sexp_ast -> nrcmr
val nrcmr_to_sexp : nrcmr -> sexp_ast

val sexp_to_cldmr : sexp_ast -> cldmr
val cldmr_to_sexp : cldmr -> sexp_ast
