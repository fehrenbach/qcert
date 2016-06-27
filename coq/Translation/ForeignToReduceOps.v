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

Section ForeignToReduceOps.

  Require Import EquivDec.

  Require Import Utils.
  Require Import BasicRuntime.
  Require Import NNRCMRRuntime.

  Class foreign_to_reduce_op
        {fruntime:foreign_runtime}
        {fredop:foreign_reduce_op}
      : Type
      := mk_foreign_to_reduce_op {
             foreign_to_reduce_op_of_unary_op
               (uop:unaryOp) : option reduce_op
             ; foreign_to_reduce_op_of_unary_op_correct
                 (uop:unaryOp) (rop:reduce_op)
                 (br:brand_relation_t)
                 (dl:list data) :
                 foreign_to_reduce_op_of_unary_op uop = Some rop ->
                 fun_of_unaryop br uop (dcoll dl) = 
                 reduce_op_eval br rop dl
         }.

End ForeignToReduceOps.


(*
*** Local Variables: ***
*** coq-load-path: (("../../coq" "QCert")) ***
*** End: ***
*)