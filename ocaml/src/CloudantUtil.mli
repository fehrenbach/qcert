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

(* Some Cloudant Utils *)

open Compiler.EnhancedCompiler

(* Cloudant format *)

type cld_config

val default_cld_config : unit -> cld_config

val get_prefix : cld_config -> string
val set_prefix : cld_config -> string -> unit

(* Javascript harness (for inlining in Cloudant) *)

val get_harness : cld_config -> string
val set_harness : cld_config -> string -> unit

(* Important functions *)
val add_harness : string -> Data.json -> CompDriver.cloudant -> CompDriver.cloudant
val string_of_cloudant : CompDriver.cloudant -> string

(* Cloudant stuff *)

val idioticize : string -> string -> string

(* Convenience function *)

val cloudant_compile_from_nra : string -> string -> CompDriver.nraenv -> Data.json -> string
val cloudant_compile_from_nnrcmr : string -> string -> CompDriver.nnrcmr -> Data.json -> string

val cloudant_compile_no_harness_from_nra : string -> CompDriver.nraenv -> string
val cloudant_compile_no_harness_from_nnrcmr : string -> CompDriver.nnrcmr -> string

val cloudant_translate_no_harness : CompDriver.nnrcmr -> CompDriver.cldmr
val cloudant_code_gen_no_harness : string -> CompDriver.cldmr -> string

