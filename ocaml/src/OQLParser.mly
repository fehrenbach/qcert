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

%{
  open Compiler.EnhancedCompiler
%}

%token <int> INT
%token <float> FLOAT
%token <string> STRING
%token <string> IDENT

%token SELECT DISTINCT FROM WHERE
%token AS IN

%token OR AND NOT
%token STRUCT FLATTEN
%token AVG SUM COUNT MIN MAX

%token NIL

%token EQUAL NEQUAL
%token PLUS STAR MINUS
%token DOT ARROW COMMA COLON
%token LPAREN RPAREN
%token EOF

%right FROM IN AS WHERE
%right COMMA
%right EQUAL NEQUAL
%right PLUS MINUS
%right AND OR
%right STAR
%left DOT ARROW

%start <Compiler.EnhancedCompiler.OQL.expr> main

%%

main:
| q = query EOF
    { q }

query:
| e = expr
    { e }

expr:
(* Parenthesized expression *)
| LPAREN e = expr RPAREN
    { e }
(* Constants *)
| NIL
    { OQL.oconst Data.dunit }
| i = INT
    { OQL.oconst (Data.dnat (Util.coq_Z_of_int i)) }
| f = FLOAT
    { OQL.oconst (Enhanced.Data.dfloat f) }
| s = STRING
    { OQL.oconst (Data.dstring (Util.char_list_of_string s)) }
(* Select from where ... *)
| SELECT e = expr FROM fc = from_clause 
    { OQL.osfw (OQL.oselect e) fc OQL.otrue }
| SELECT e = expr FROM fc = from_clause WHERE w = expr
    { OQL.osfw (OQL.oselect e) fc (OQL.owhere w) }
| SELECT DISTINCT e = expr FROM fc = from_clause
    { OQL.osfw (OQL.oselectdistinct e) fc OQL.otrue }
| SELECT DISTINCT e = expr FROM fc = from_clause WHERE w = expr
    { OQL.osfw (OQL.oselectdistinct e) fc (OQL.owhere e) }
(* Expressions *)
| v = IDENT
    { OQL.ovar (Util.char_list_of_string v) }
| e = expr DOT a = IDENT
    { OQL.odot (Util.char_list_of_string a) e }
| e = expr ARROW a = IDENT
    { OQL.oarrow (Util.char_list_of_string a) e }
| STRUCT LPAREN r = reclist RPAREN
    { OQL.ostruct r }
(* Functions *)
| NOT LPAREN e = expr RPAREN
    { OQL.ounop Ops.Unary.aneg e }
| FLATTEN LPAREN e = expr RPAREN
    { OQL.ounop Ops.Unary.aflatten e }
| SUM LPAREN e = expr RPAREN
    { OQL.ounop Ops.Unary.asum e }
| AVG LPAREN e = expr RPAREN
    { OQL.ounop Ops.Unary.aarithmean e }
| COUNT LPAREN e = expr RPAREN
    { OQL.ounop Ops.Unary.acount e }
| MAX LPAREN e = expr RPAREN
    { OQL.ounop Ops.Unary.anummax e }
| MIN LPAREN e = expr RPAREN
    { OQL.ounop Ops.Unary.anummin e }
(* Binary operators *)
| e1 = expr EQUAL e2 = expr
    { OQL.obinop Ops.Binary.aeq e1 e2 }
| e1 = expr NEQUAL e2 = expr
    { OQL.ounop Ops.Unary.aneg (OQL.obinop Ops.Binary.aeq e1 e2) }
| e1 = expr MINUS e2 = expr
    { OQL.obinop Ops.Binary.ZArith.aminus e1 e2 }
| e1 = expr PLUS e2 = expr
    { OQL.obinop Ops.Binary.ZArith.aplus e1 e2 }
| e1 = expr STAR e2 = expr
    { OQL.obinop Ops.Binary.ZArith.amult e1 e2 }
| e1 = expr AND e2 = expr
    { OQL.obinop Ops.Binary.aand e1 e2 }
| e1 = expr OR e2 = expr
    { OQL.obinop Ops.Binary.aor e1 e2 }

from_clause:
| v = IDENT IN e = expr
    { (OQL.oin (Util.char_list_of_string v) e) :: [] }
| v = IDENT AS e = expr
    { (OQL.oin (Util.char_list_of_string v) e) :: [] }
| v = IDENT IN e = expr COMMA fr = from_clause
    { (OQL.oin (Util.char_list_of_string v) e) :: fr }
| v = IDENT AS e = expr COMMA fr = from_clause
    { (OQL.oin (Util.char_list_of_string v) e) :: fr }

reclist:
| 
    { [] }
| r = recatt
    { [r] }
| r = recatt COMMA rl = reclist
    { r :: rl }

recatt:
| a = IDENT COLON e = expr
    { (Util.char_list_of_string a, e) }
    
