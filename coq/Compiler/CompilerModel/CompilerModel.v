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

Require Import String.
Require Import CompilerRuntime Utils BasicSystem.
Require Import ForeignToJava ForeignToJavascript ForeignToJSON ForeignTypeToJSON.
Require Import ForeignReduceOps ForeignToReduceOps.
Require Import ForeignToSpark.
Require Import ForeignCloudant ForeignToCloudant.
Require Import OptimizerLogger.
Require Import ForeignType ForeignDataTyping.
Require Import RAlgEnv NNRC.

Module Type CompilerModel.
  Axiom compiler_basic_model : basic_model.
  Axiom compiler_model_foreign_to_java : foreign_to_java.
  Axiom compiler_model_foreign_to_javascript : foreign_to_javascript.
  Axiom compiler_model_foreign_to_JSON : foreign_to_JSON.
  Axiom compiler_model_foreign_type_to_JSON : foreign_type_to_JSON.
  Axiom compiler_model_foreign_reduce_op : foreign_reduce_op.
  Axiom compiler_model_foreign_to_reduce_op : foreign_to_reduce_op.
  Axiom compiler_model_foreign_to_spark : foreign_to_spark.
  Axiom compiler_model_foreign_cloudant : foreign_cloudant.
  Axiom compiler_model_foreign_to_cloudant : foreign_to_cloudant.
  Axiom compiler_model_nra_optimizer_logger : optimizer_logger string algenv.
  Axiom compiler_model_nrc_optimizer_logger : optimizer_logger string nrc.
  Axiom compiler_model_foreign_data_typing : foreign_data_typing.
End CompilerModel.

Module CompilerModelRuntime(model:CompilerModel) <: CompilerRuntime.
  Definition compiler_foreign_type : foreign_type
    := basic_model_foreign_type.
  Definition compiler_foreign_runtime : foreign_runtime
    := basic_model_runtime.
  Definition compiler_foreign_to_javascript : foreign_to_javascript
    := model.compiler_model_foreign_to_javascript.
  Definition compiler_foreign_to_java : foreign_to_java
    := model.compiler_model_foreign_to_java.
  Definition compiler_foreign_to_JSON : foreign_to_JSON
    := model.compiler_model_foreign_to_JSON.
  Definition compiler_foreign_type_to_JSON : foreign_type_to_JSON
    := model.compiler_model_foreign_type_to_JSON.
  Definition compiler_foreign_reduce_op : foreign_reduce_op
    := model.compiler_model_foreign_reduce_op.
  Definition compiler_foreign_to_reduce_op : foreign_to_reduce_op
    := model.compiler_model_foreign_to_reduce_op.
  Definition compiler_foreign_to_spark : foreign_to_spark
    := model.compiler_model_foreign_to_spark.
  Definition compiler_foreign_cloudant : foreign_cloudant
    := model.compiler_model_foreign_cloudant.
  Definition compiler_foreign_to_cloudant : foreign_to_cloudant
    := model.compiler_model_foreign_to_cloudant.
  Definition compiler_nra_optimizer_logger : optimizer_logger string algenv
    :=  model.compiler_model_nra_optimizer_logger.
  Definition compiler_nrc_optimizer_logger : optimizer_logger string nrc
    :=  model.compiler_model_nrc_optimizer_logger.
  Definition compiler_foreign_data_typing : foreign_data_typing
    := model.compiler_model_foreign_data_typing.
End CompilerModelRuntime.

(* Useful utility module functors that create a CompilerModel *)
Module Type CompilerForeignType.
  Axiom compiler_foreign_type : foreign_type.
End CompilerForeignType.
Module Type CompilerBrandModel(ftype:CompilerForeignType).
  Axiom compiler_brand_model : brand_model.
End CompilerBrandModel.

(* 
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "QCert")) ***
*** End: ***
*)
