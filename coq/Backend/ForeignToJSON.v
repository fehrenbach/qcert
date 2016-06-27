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

Require Import List String.

Require Import Utils ForeignRuntime.
Require Import NNRCRuntime.

Local Open Scope string_scope.

Section ForeigntoJSON.

(* TODO: properties required to ensure round-tripping *)

Class foreign_to_JSON {fdata:foreign_data}: Type
  := mk_foreign_to_JSON {
         foreign_to_JSON_to_data
           (d:data) : option foreign_data_type
         ; foreign_to_JSON_from_data
             (fd:foreign_data_type) : data
       }.
  
End ForeigntoJSON.

(* 
*** Local Variables: ***
*** coq-load-path: (("../../coq" "QCert")) ***
*** End: ***
*)