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
open DataUtil
open Compiler.EnhancedCompiler

(* Data utils for the Camp evaluator and compiler *)

type io_schema = {
    io_brand_model : (string * string) list;
    io_name : string;
    io_brand_type : (string * string) list;
    io_type_definitions : (string * rtype_content) list;
  }

type schema = {
    sch_brand_model : RType.brand_model;
    sch_camp_type : RType.camp_type;
    sch_foreign_typing : Compiler.foreign_typing;
    sch_io_schema : io_schema option;
  }

val empty_schema : schema

val schema_of_io_json : Data.json -> schema

val brand_relation_of_brand_model : RType.brand_model -> Compiler.brand_relation
