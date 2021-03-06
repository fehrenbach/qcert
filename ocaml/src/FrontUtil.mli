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

(* Front end utilities *)

open ConfigUtil
open Compiler.EnhancedCompiler

(* Parse/translate input *)

(* val camp_of_rule_string : string -> (string * CompDriver.camp) *)

(* val nraenv_of_rule : string -> (string * CompDriver.nraenv) *)
(* val nraenv_of_rule_string : string -> (string * CompDriver.nraenv) *)
(* val nraenv_of_oql : string -> (string * CompDriver.nraenv) *)
(* val nraenv_of_oql_string : string -> (string * CompDriver.nraenv) *)

val nraenv_of_input : lang_config -> string -> (string * CompDriver.nraenv)

