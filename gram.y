/*A Bison parser for the programming language Pascal.
  Copyright (C) 1989-2002 Free Software Foundation, Inc.

  Authors: Jukka Virtanen <jtv@hut.fi>
           Helsinki University of Technology
           Computing Centre
           Finland

           Peter Gerwinski <peter@gerwinski.de>
           Essen, Germany

           Bill Cox <bill@cygnus.com> (error recovery rules)

           Frank Heckenbach <frank@pascal.gnu.de>

  This file is part of GNU Pascal.

  GNU Pascal is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published
  by the Free Software Foundation; either version 1, or (at your
  option) any later version.

  GNU Pascal is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with GNU Pascal; see the file COPYING. If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA. */

/* Bison parser for ISO 7185 Pascal originally written on
 * 3 Feb 1987 by Jukka Virtanen <jtv@hut.fi>
 *
 * Modified for use at the University of South Carolina's CSCE 531
 * (Compiler Construction) course (Spring 2005) by Stephen Fenner
 * <fenner@cse.sc.edu>
 *
 * SHIFT/REDUCE CONFLICTS
 *
 * The dangling else will not cause a shift/reduce conflict - it's
 * solved by precedence rules.
 */

%{

/* Cause the `yydebug' variable to be defined.  */
#include "tree.h"
#include "encode.h"
#define YYDEBUG 1

void set_yydebug(int);
void yyerror(char *);

/* Function stack variables */
ST_ID func_id_stack[BS_DEPTH];
int fi_top = -1;

/* Base offset stack */
int base_offset_stack[BS_DEPTH];
int bo_top = -1;

/* case record stack */
int case_record_stack[BS_DEPTH];
int case_top = -1;

/* Like YYERROR but do call yyerror */
#define YYERROR1 { yyerror ("syntax error"); YYERROR; }
%}

/* Start symbol for the grammar */

%start pascal_program

/* The union representing a semantic stack entry */
%union {
    char        *y_string;
    long         y_int;
    int          y_cint;
    double       y_real;
    ST_ID        y_stid;
    TYPE         y_type;
    PARAM_LIST   y_paramlist;
    INDEX_LIST   y_indexlist;
    PARAM        y_param;
    VAR_ID_LIST  y_varidlist;
    EXPR	 y_expr;
    EXPR_LIST	 y_exprlist;
    EXPR_NULLOP  y_nullop;
    EXPR_UNOP    y_unop;
    EXPR_BINOP   y_binop;
    EXPR_ID      y_exprid;
    FUNC_HEAD    y_funchead;
    DIRECTIVE    y_dir;
    VAL_LIST     y_valuelist;
    CASE_RECORD  y_caserec;
}

/* updated token types and non-terminal types */
%type <y_expr> unsigned_number number constant constant_literal
%type <y_expr> expression actual_parameter static_expression
%type <y_expr> boolean_expression index_expression_item
%type <y_expr> simple_expression term signed_primary primary factor
%type <y_expr> signed_factor variable_or_function_access predefined_literal
%type <y_expr> variable_or_function_access_no_as standard_functions
%type <y_expr> variable_or_function_access_no_standard_function
%type <y_expr> variable_or_function_access_no_id rest_of_statement
%type <y_expr> assignment_or_call_statement standard_procedure_statement
%type <y_expr> variable_access_or_typename optional_par_actual_parameter

%type <y_exprlist> actual_parameter_list optional_par_actual_parameter_list
%type <y_exprlist> index_expression_list

%type <y_nullop> rts_fun_optpar
%type <y_unop> sign rts_fun_onepar rts_fun_parlist
%type <y_binop> relational_operator multiplying_operator adding_operator

%type <y_exprid> variable_or_function_access_maybe_assignment
%type <y_funchead> function_heading
%type <y_dir> directive_list directive
%type <y_caserec> case_element_list case_element
%type <y_valuelist> case_constant_list one_case_constant

%type <y_cint> variable_declaration_part variable_declaration_list
%type <y_cint> variable_declaration simple_decl any_decl any_declaration_part
%type <y_cint> repetitive_statement for_direction

%token <y_string> LEX_ID
%type <y_string>  new_identifier_1 string combined_string
%type <y_string> simple_if if_statement case_statement conditional_statement

%type <y_type> typename type_denoter type_denoter_1 new_ordinal_type
%type <y_type> subrange_type new_procedural_type ordinal_index_type
%type <y_type> array_type unpacked_structured_type new_structured_type
%type <y_type> functiontype new_pointer_type pointer_domain_type
%type <y_type> parameter_form

%type <y_paramlist> optional_procedural_type_formal_parameter_list
%type <y_paramlist> procedural_type_formal_parameter_list
%type <y_paramlist> procedural_type_formal_parameter
%type <y_indexlist> array_index_list
%type <y_stid> identifier new_identifier
%type <y_varidlist> id_list optional_par_id_list

/* Reserved words. */

/* Reserved words in Standard Pascal */
%token LEX_ARRAY LEX_BEGIN LEX_CASE LEX_CONST LEX_DO LEX_DOWNTO LEX_END
%token LEX_FILE LEX_FOR LEX_FUNCTION LEX_GOTO LEX_IF LEX_LABEL LEX_NIL
%token LEX_OF LEX_PACKED LEX_PROCEDURE LEX_PROGRAM LEX_RECORD LEX_REPEAT
%token LEX_SET LEX_THEN LEX_TO LEX_TYPE LEX_UNTIL LEX_VAR LEX_WHILE LEX_WITH
%token LEX_FORWARD

/* The following ones are not tokens used in the parser.
 * However they are used in the same context as some tokens,
 * so assign unique numbers to them.
 */
%token pp_SIN pp_COS pp_EXP pp_LN pp_SQRT pp_ARCTAN rr_POW rr_EXPON
%token r_WRITE r_READ r_INITFDR r_LAZYTRYGET r_LAZYGET r_LAZYUNGET r_POW r_EXPON
%token z_ABS z_ARCTAN z_COS z_EXP z_LN z_SIN z_SQRT z_POW z_EXPON
%token set_card set_isempty set_equal set_le set_less set_in set_clear
%token set_include set_exclude set_include_range set_copy
%token set_intersection set_union set_diff set_symdiff
%token p_DONEFDR gpc_IOCHECK gpc_RUNTIME_ERROR

/* Redefinable identifiers. */

/* Redefinable identifiers in Standard Pascal */
%token <y_string> p_INPUT p_OUTPUT p_REWRITE p_RESET p_PUT p_GET p_WRITE p_READ
%token <y_string> p_WRITELN p_READLN p_PAGE p_NEW p_DISPOSE
%token <y_string> p_ABS p_SQR p_SIN p_COS p_EXP p_LN p_SQRT p_ARCTAN
%token <y_string> p_TRUNC p_ROUND p_PACK p_UNPACK p_ORD p_CHR p_SUCC p_PRED
%token <y_string> p_ODD p_EOF p_EOLN p_MAXINT p_TRUE p_FALSE

/* Additional redefinable identifiers for Borland Pascal */
%token bp_RANDOM bp_RANDOMIZE 
%token <y_string> BREAK CONTINUE

/* redefinable keyword extensions */
%token <y_string> RETURN_ RESULT EXIT FAIL 
%token p_CLOSE CONJUGATE p_DEFINESIZE 
%token <y_string> SIZEOF
%token <y_string> BITSIZEOF 
%token ALIGNOF TYPEOF gpc_RETURNADDRESS gpc_FRAMEADDRESS
%token LEX_LABEL_ADDR

/* GPC internal tokens */
%token <y_int> LEX_INTCONST
%token <y_string> LEX_STRCONST
%token <y_real> LEX_REALCONST
%token LEX_RANGE LEX_ELLIPSIS

/* We don't declare precedences for operators etc. We don't need
   them since our rules define precedence implicitly, and too many
   precedences increase the chances of real conflicts going unnoticed. */
%token LEX_ASSIGN
%token '<' '=' '>' LEX_IN LEX_NE LEX_GE LEX_LE
%token '-' '+' LEX_OR LEX_OR_ELSE LEX_CEIL_PLUS LEX_CEIL_MINUS LEX_FLOOR_PLUS LEX_FLOOR_MINUS
%token '/' '*' LEX_DIV LEX_MOD LEX_AND LEX_AND_THEN LEX_SHL LEX_SHR LEX_XOR LEX_CEIL_MULT LEX_CEIL_DIV LEX_FLOOR_MULT LEX_FLOOR_DIV
%token LEX_POW LEX_POWER LEX_IS LEX_AS
%token LEX_NOT

/* Various extra tokens */
%token LEX_EXTERNAL ucsd_STR p_MARK p_RELEASE p_UPDATE p_GETTIMESTAMP p_UNBIND
%token p_EXTEND bp_APPEND p_BIND p_SEEKREAD p_SEEKWRITE p_SEEKUPDATE LEX_SYMDIFF
%token p_ARG p_CARD p_EMPTY p_POSITION p_LASTPOSITION p_LENGTH p_TRIM p_BINDING
%token p_DATE p_TIME LEX_RENAME LEX_IMPORT LEX_USES LEX_QUALIFIED LEX_ONLY

/* Precedence rules */

/* The following precedence declarations are just to avoid the dangling
   else shift-reduce conflict. We use prec_if rather than LEX_IF to
   avoid possible conflicts elsewhere involving LEX_IF going unnoticed. */
%nonassoc prec_if
%nonassoc LEX_ELSE

/* These tokens help avoid S/R conflicts from error recovery rules. */
%nonassoc lower_than_error
%nonassoc error

%%

/* Pascal parser starts here */

pascal_program:
    /* empty */  {}
  | program_component_list  {}
  ;

program_component_list:
    program_component  {}
  | program_component_list program_component  {}
  ;

program_component:
    main_program_declaration '.'  {}
  ;

main_program_declaration:
    program_heading semi import_or_any_declaration_part { enter_main_body(); }
    statement_part  { exit_main_body(); }
  ;

program_heading:
    LEX_PROGRAM new_identifier optional_par_id_list  {}
  ;

optional_par_id_list:
    /* empty */  {}
  | '(' id_list ')'  { $$ = $2; }
  ;
  
id_list:
    new_identifier  { $$ = build_var_id_list(NULL, $1); }
  | id_list ',' new_identifier  { $$ = build_var_id_list($1, $3); } 
  ;

typename:
    LEX_ID  { $$ = check_typename(st_enter_id($1)); } 
  ;

identifier:
    LEX_ID  { $$ = st_enter_id($1); }
  ;

new_identifier:
    new_identifier_1  { $$ = $1; }
  ;

new_identifier_1: /* default actions for all */
LEX_ID  { $$ = st_enter_id($1); }
/* Standard Pascal constants */
  | p_MAXINT  
  | p_FALSE  
| p_TRUE  
/* Standard Pascal I/O */
  | p_INPUT  
  | p_OUTPUT  
  | p_REWRITE  
  | p_RESET 
  | p_PUT 
  | p_GET  
  | p_WRITE  
  | p_READ
  | p_WRITELN 
  | p_READLN
  | p_PAGE
  | p_EOF 
  | p_EOLN
/* Standard Pascal heap handling */
  | p_NEW 
  | p_DISPOSE 
/* Standard Pascal arithmetic */
  | p_ABS  
  | p_SQR  
  | p_SIN  
  | p_COS  
  | p_EXP 
  | p_LN
  | p_SQRT
  | p_ARCTAN
  | p_TRUNC  
  | p_ROUND  
/* Standard Pascal transfer functions */
  | p_PACK
  | p_UNPACK
/* Standard Pascal ordinal functions */
  | p_ORD 
  | p_CHR  
  | p_SUCC
  | p_PRED  
  | p_ODD  
/* Other extensions */
  | BREAK  
  | CONTINUE  
  | RETURN_  
  | RESULT  
  | EXIT  
  | FAIL  
  | SIZEOF  
  | BITSIZEOF 
  ;

import_or_any_declaration_part:
    any_declaration_import_part  {}
  ;

any_declaration_import_part:
    /* empty */  {}
  | any_declaration_import_part any_or_import_decl  {}
  ;

any_or_import_decl:
    import_part  {}
  | any_decl  {}
  ;

any_declaration_part: //cint
    /* empty */  { $$ = 0; }
  | any_declaration_part any_decl  { $$ = $1 + $2; }
  ;

any_decl: //cint
    simple_decl  { $$ = $1; }
  | function_declaration  { $$ = 0; }
  ;

simple_decl: //cint
    label_declaration_part  {} //ignore
  | constant_definition_part  {} //ignore
  | type_definition_part  {}
  | variable_declaration_part  { $$ = $1; }
  ;

/* Label declaration part */

label_declaration_part:
    LEX_LABEL label_list semi  {}
  ;

label_list:
    label  {}
  | label_list ',' label  {}
  ;

/* Labels are returned as identifier nodes for compatibility with gcc */
label:
    LEX_INTCONST  {}
  | new_identifier  {}
  ;

/* constant definition part */

constant_definition_part:
    LEX_CONST constant_definition_list  {}
  ;

constant_definition_list:
    constant_definition  {}
  | constant_definition_list constant_definition  {}
  ;

constant_definition:
    new_identifier '=' static_expression semi  {}
  ;

constant: //type is expr
    identifier  {}
  | sign identifier  { }
  | number  { $$ = $1; }
  | constant_literal  { $$ = $1; }
  ;

number: //type is expr
    sign unsigned_number  { $$ = make_un_expr($1, $2); }
  | unsigned_number  { $$ = $1; }
  ;

unsigned_number: //type is expr
    LEX_INTCONST  { $$ = make_intconst_expr($1, ty_build_basic(TYSIGNEDLONGINT)); }
  | LEX_REALCONST  { $$ = make_realconst_expr( (double)$1); }
  ;

sign:
    '+'  { $$ = UPLUS_OP; }
  | '-'  { $$ = NEG_OP; }
  ;

constant_literal: //type is expr
    combined_string  { $$ = make_strconst_expr($1); }
  | predefined_literal  { $$ = $1; }
  ;

predefined_literal: //type is expr
    LEX_NIL  { $$ = make_null_expr(NIL_OP); }
  | p_FALSE  { $$ = make_intconst_expr(0, ty_build_basic(TYSIGNEDCHAR)); }
  | p_TRUE  { $$ = make_intconst_expr(1, ty_build_basic(TYSIGNEDCHAR)); }
  ;

combined_string: //type is string
    string  { $$ = $1; }
  ;

string:
    LEX_STRCONST  { $$ = $1; }
  | string LEX_STRCONST  { $$ = $2; }
  ;

type_definition_part:
    LEX_TYPE type_definition_list semi  { resolve_all_ptr(); }
  ;

type_definition_list:
    type_definition  {}
  | type_definition_list semi type_definition  {}
  ;

type_definition:
    new_identifier '=' type_denoter  { create_typename( $1, $3 ); }

type_denoter: /* default actions to pass TYPE through */
    typename  { $$ = $1; }
  | type_denoter_1  { $$ = $1; }
  ;

type_denoter_1: /* default actions to pass TYPE through */
    new_ordinal_type  { $$ = $1;}
  | new_pointer_type  { $$ = $1; }
  | new_procedural_type  { $$ = $1; }
  | new_structured_type  { $$ = $1; }
  ;

new_ordinal_type: /* default actions to pass TYPE through */
    enumerated_type  {}
  | subrange_type  { $$ = $1; }
  ;

enumerated_type:
    '(' enum_list ')'  {}
  ;

enum_list:
    enumerator  {}
  | enum_list ',' enumerator  {}
  ;

enumerator:
    new_identifier  {}
  ;

subrange_type: /* builds subrange TYPE */
    constant LEX_RANGE constant  { $$ = check_subrange($1,$3); }

  ;

new_pointer_type: /* builds pointer TYPE */
    pointer_char pointer_domain_type  { $$ = $2 ; }
  ;

pointer_char:
    '^'  {}
  | '@'  {}
  ;

pointer_domain_type:
    new_identifier      { $$ = ty_build_ptr($1, NULL); }
  | new_procedural_type  { $$ = ty_build_ptr(NULL, $1); };
  ;

new_procedural_type: /* builds FUNC TYPE */
    LEX_PROCEDURE optional_procedural_type_formal_parameter_list  { $$ = ty_build_func(ty_build_basic(TYVOID), $2, TRUE); }
  | LEX_FUNCTION optional_procedural_type_formal_parameter_list functiontype  { $$ = ty_build_func($3, $2, TRUE); }
  ;

optional_procedural_type_formal_parameter_list:
    /* empty */  {$$ = NULL;}
  | '(' procedural_type_formal_parameter_list ')'  {$$ = check_param($2);};
  ;

procedural_type_formal_parameter_list:
    procedural_type_formal_parameter  { $$ = $1; }
  | procedural_type_formal_parameter_list semi procedural_type_formal_parameter  { $$ = concatenate_param_list ($1, $3); }
  ;

procedural_type_formal_parameter:
    id_list  {$$=build_param_list($1,ty_build_basic(TYERROR),FALSE);}
  | id_list ':' typename  { $$ = build_param_list($1, $3, FALSE); }
  | LEX_VAR id_list ':' typename  { $$ = build_param_list($2, $4, TRUE); }
  | LEX_VAR id_list  {$$=build_param_list($2,ty_build_basic(TYERROR),TRUE); /*treat as semantic errors*/};

  ;

new_structured_type: /* pass TYPE through */
    LEX_PACKED unpacked_structured_type  { $$ = $2; }
  | unpacked_structured_type  { $$ = $1; }
  ;

unpacked_structured_type: /* pass TYPE through */ 
    array_type  { $$ = $1; }
  | file_type  {}
  | set_type  {}
  | record_type  {}
  ;

/* Array */

array_type: /* builds array TYPE */
    LEX_ARRAY '[' array_index_list ']' LEX_OF type_denoter  { $$ = check_array($6, $3); }
  ;

array_index_list: 
    ordinal_index_type  { $$ = create_list_from_type( $1 ); }
  | array_index_list ',' ordinal_index_type  { $$ = concatenate_index_lists($1, $3); }
  ;


ordinal_index_type: /* default actions to pass TYPE through */
    new_ordinal_type  { $$ = $1; }
  | typename  { $$ = $1; }
  ;

/* FILE */
file_type:
    LEX_FILE direct_access_index_type LEX_OF type_denoter  {}
  ;

direct_access_index_type:
    /* empty */  {}
  | '[' ordinal_index_type ']'  {}
  ;


/* sets */
set_type:
    LEX_SET LEX_OF type_denoter  {}
  ;

record_type:
    LEX_RECORD record_field_list LEX_END  {}
  ;

record_field_list:
    /* empty */  {}
  | fixed_part optional_semicolon  {}
  | fixed_part semi variant_part  {}
  | variant_part  {}
  ;

fixed_part:
    record_section  {}
  | fixed_part semi record_section  {}
  ;

record_section:
    id_list ':' type_denoter  {}
  ;

variant_part:
    LEX_CASE variant_selector LEX_OF variant_list rest_of_variant  {}
  ;

rest_of_variant:
    optional_semicolon  {}
  | case_default '(' record_field_list ')' optional_semicolon  {}
  ;

variant_selector:
    new_identifier ':' variant_type  {}
  | variant_type  {}
  ;

variant_type:
    typename  {}
  | new_ordinal_type  {}
  ;

variant_list:
    variant  {}
  | variant_list semi variant  {}
  ;

variant:
    case_constant_list ':' '(' record_field_list ')'  {}
  ;

case_constant_list:
    one_case_constant {$$ = $1;} 
  | case_constant_list ',' one_case_constant  {}
  ;

one_case_constant:
    static_expression  { TYPETAG type; long val;
                         if (get_case_value($1, &val, &type) == TRUE) {  
                            $$ = new_case_value(type, val, val);
                         }
                         else {
                            $$ = NULL;
                         }
                        }
  | static_expression LEX_RANGE static_expression  {}
  ;

/* variable declaration part */

variable_declaration_part: //cint
    LEX_VAR variable_declaration_list  { $$ = $2; }
  ;

variable_declaration_list: //cint
    variable_declaration  { $$ = $1; }
  | variable_declaration_list variable_declaration  { $$ = $1 + $2; }
  ;

variable_declaration: //type is cint
   /* id_list ':' type_denoter semi  { /*create_gdecl($1, $3); decl($3, $1); */
                                 //    $$ = process_var_decl($1, $3, b_get_local_var_offset()); }

 id_list ':' type_denoter semi  {
      if (st_get_cur_block() < 1) {
	create_gdecl($1,$3);
	$$ = base_offset_stack[bo_top];
      } else {
	$$ = process_var_decl($1, $3, base_offset_stack[bo_top]);
      }
      resolve_all_ptr();
    }
  ;
  ;

function_declaration: 
    function_heading semi directive_list semi  { build_func_decl($1.id, $1.type, $3); }
  | function_heading semi { $<y_cint>$ = enter_function($1.id, $1.type, st_get_id_str($1.id)); }
    any_declaration_part  { enter_func_body(st_get_id_str($1.id), $1.type, $<y_cint>3); }
    statement_part semi   { exit_func_body(st_get_id_str($1.id), $1.type); }
  ;

function_heading:
    LEX_PROCEDURE new_identifier optional_par_formal_parameter_list  { $$.id = $2; $$.type = ty_build_func(ty_build_basic(TYVOID),NULL, FALSE);}
  | LEX_FUNCTION new_identifier optional_par_formal_parameter_list functiontype  { $$.id = $2; $$.type = ty_build_func($4, NULL ,FALSE); }
  ;

directive_list:
    directive  { $$ = $1; }
  | directive_list semi directive  {}
  ;

directive:
    LEX_FORWARD  { $$ = DIR_FORWARD;  } 
  | LEX_EXTERNAL { $$ = DIR_EXTERNAL; }
  ;

functiontype:
    /* empty */   {} 
  | ':' typename  { $$ = check_function_type($2); }
  ;

/* parameter specification section */

optional_par_formal_parameter_list:
    /* empty */  {}
  | '(' formal_parameter_list ')'  {}
  ;

formal_parameter_list:
    formal_parameter  {}
  | formal_parameter_list semi formal_parameter  {}
  ;

formal_parameter:
    id_list ':' parameter_form  {}
  | LEX_VAR id_list ':' parameter_form  {}
  | function_heading  {}
  | id_list ':' conformant_array_schema  {}
  | LEX_VAR id_list ':' conformant_array_schema  {}
  ;

parameter_form:
    typename  {}
  | open_array  {}
  ;

conformant_array_schema:
    packed_conformant_array_schema  {}
  | unpacked_conformant_array_schema  {}
  ;

typename_or_conformant_array_schema:
    typename  {}
  | packed_conformant_array_schema  {}
  | unpacked_conformant_array_schema  {}
  ;

packed_conformant_array_schema:
    LEX_PACKED LEX_ARRAY '[' index_type_specification ']' LEX_OF typename_or_conformant_array_schema  {}
  ;

unpacked_conformant_array_schema:
    LEX_ARRAY '[' index_type_specification_list ']' LEX_OF typename_or_conformant_array_schema  {}
  ;

index_type_specification:
    new_identifier LEX_RANGE new_identifier ':' typename  {}
  ;

index_type_specification_list:
    index_type_specification  {}
  | index_type_specification_list semi index_type_specification  {}
  ;

open_array:
    LEX_ARRAY LEX_OF typename  {}
  ;

statement_part:
    compound_statement  {}
  ;

compound_statement:
    LEX_BEGIN statement_sequence LEX_END  {}
  ;

statement_sequence:
    statement  {}
  | statement_sequence semi statement  {}
  ;

statement:
    label ':' unlabelled_statement  {} /* ignore */
  | unlabelled_statement  {}
  ;

unlabelled_statement:
    structured_statement  {}
  | simple_statement  {}
  ;

structured_statement:
    compound_statement  {}
  | with_statement  {}
  | conditional_statement  {}
  | repetitive_statement  {}
  ;

with_statement:
    LEX_WITH structured_variable_list LEX_DO statement  {}
  ;

structured_variable_list:
    structured_variable  {}
  | structured_variable_list ',' structured_variable  {}
  ;

structured_variable:
    variable_or_function_access  {}
  ;

conditional_statement:
    if_statement  { $$ = $1;}
  | case_statement  {}
  ;

simple_if:
    LEX_IF boolean_expression { if (ty_query($2->type) == TYSIGNEDCHAR) {
                                   encode_expr($2);
                                   char* end_if = new_symbol();
                                   b_cond_jump(TYSIGNEDCHAR,B_ZERO,end_if); //jump if false
                                   $<y_string>$ = end_if; 
                                 }
                                 else {
                                    error("Non-Boolean expression");
                                 }
                              }
    LEX_THEN statement        { $$ = $<y_string>3; }
  ;

if_statement:
    simple_if LEX_ELSE        { char* end_else = new_symbol();
                                b_jump(end_else);
                                b_label($1);
                                $<y_string>$ = end_else;
                              }
    statement                 { b_label($<y_string>3);}
  | simple_if %prec prec_if   { b_label($1);}
  ;

case_statement:
    LEX_CASE expression LEX_OF case_element_list optional_semicolon_or_else_branch LEX_END  {}
  ;

optional_semicolon_or_else_branch:
    optional_semicolon  {}
  | case_default statement_sequence  {}
  ;

case_element_list:
    case_element  {}
  | case_element_list semi case_element  {}
  ;

case_element:
    case_constant_list  {}
  ;

case_default:
    LEX_ELSE  {}
  | semi LEX_ELSE  {}
  ;

repetitive_statement:
    repeat_statement  {}
  | while_statement  {}
  | for_statement  {}
  ;

repeat_statement:
    LEX_REPEAT statement_sequence LEX_UNTIL boolean_expression  {}
  ;

while_statement:
    LEX_WHILE boolean_expression LEX_DO { if (ty_query($2->type) == TYSIGNEDCHAR) {
                                             new_exit_label();
                                             char* start_while = new_symbol();
                                             b_label(start_while);
                                             encode_expr($2);
                                             $<y_string>$ = start_while;
                                             b_cond_jump(TYSIGNEDCHAR,B_ZERO,current_exit_label());
                                          }
                                          else {
                                             error("Non-Boolean expression");
                                          }
                                        }
    statement                    { if (ty_query($2->type) == TYSIGNEDCHAR) {
                                      b_jump($<y_string>4); //jumps to start of loop
                                      b_label(old_exit_label());
                                   }
                                 }
  ;

for_statement:
    LEX_FOR variable_or_function_access LEX_ASSIGN expression for_direction expression LEX_DO statement  {}
  ;

for_direction:
    LEX_TO  {}
  | LEX_DOWNTO  {}
  ;

simple_statement:
    empty_statement  {}
  | goto_statement  {}
  | assignment_or_call_statement  { encode_expr($1);}
  | standard_procedure_statement  { encode_expr($1);}
  | statement_extensions  {}
  ;

empty_statement:
    /* empty */ %prec lower_than_error  {}
  ;

goto_statement:
    LEX_GOTO label  {}
  ;

/* function calls */

optional_par_actual_parameter_list:
    /* empty */  { $$ = NULL; }
  | '(' actual_parameter_list ')'  { $$ = expr_list_reverse($2); }
  ;

actual_parameter_list: //type is expr_list
    actual_parameter  { $$ = expr_prepend($1, NULL); }
  | actual_parameter_list ',' actual_parameter  { $$ = expr_prepend($3, $1); }
  ;

actual_parameter: //type is expr
    expression  { $$ = $1; }
  ;

/* ASSIGNMENT and procedure calls */

assignment_or_call_statement: //type is expr
    variable_or_function_access_maybe_assignment rest_of_statement  { $$ = check_assign_or_proc_call($1.expr, $1.id, $2); }
  ;

variable_or_function_access_maybe_assignment:
    identifier  { $$.expr = make_id_expr($1); $$.id = $1;}
  | address_operator variable_or_function_access  {} /* ignore for now */
  | variable_or_function_access_no_id  { $$.expr = $1; $$.id = NULL; }
  ;

rest_of_statement:
    /* Empty */  { $$ = NULL; }
  | LEX_ASSIGN expression  { $$ = $2; } 
  ;

standard_procedure_statement:
    rts_proc_onepar '(' actual_parameter ')'  {}
  | rts_proc_parlist '(' actual_parameter_list ')'  {}
  | p_WRITE optional_par_write_parameter_list  {}
  | p_WRITELN optional_par_write_parameter_list  {}
  | p_READ optional_par_actual_parameter_list  {}
  | p_READLN optional_par_actual_parameter_list  {}
  | p_PAGE optional_par_actual_parameter_list  {}
  | ucsd_STR '(' write_actual_parameter_list ')'  {}
  | p_DISPOSE '(' actual_parameter ')'  { $$ = make_un_expr(DISPOSE_OP, $3); }
  | p_DISPOSE '(' actual_parameter ',' actual_parameter_list ')'  {}
  ;

optional_par_write_parameter_list:
    /* empty */  {}
  | '(' write_actual_parameter_list ')'  {}
  ;

write_actual_parameter_list:
    write_actual_parameter  {}
  | write_actual_parameter_list ',' write_actual_parameter  {}
  ;

write_actual_parameter:
    actual_parameter  {}
  | actual_parameter ':' expression  {}
  | actual_parameter ':' expression ':' expression  {}
  ;

/* run time system calls with one parameter */
rts_proc_onepar:
    p_PUT  {}
  | p_GET  {}
  | p_MARK  {}
  | p_RELEASE  {}
  | p_CLOSE  {}
  | p_UPDATE  {}
  | p_GETTIMESTAMP  {}
  | p_UNBIND  {}
  ;

rts_proc_parlist:
    p_REWRITE     /* Up to three args */  {}
  | p_RESET       /* Up to three args */  {}
  | p_EXTEND      /* Up to three args */  {}
  | bp_APPEND     /* Up to three args */  {}
  | p_PACK        /* Three args */  {}
  | p_UNPACK      /* Three args */  {}
  | p_BIND        /* Two args */  {}
  | p_SEEKREAD  {}
  | p_SEEKWRITE  {}
  | p_SEEKUPDATE  {}
  | p_DEFINESIZE  /* Two args */  {}
  | LEX_AND           /* Two args */  {}
  | LEX_OR            /* Two args */  {}
  | LEX_NOT           /* One arg */  {}
  | LEX_XOR        /* Two args */  {}
  | LEX_SHL           /* Two args */  {}
  | LEX_SHR           /* Two args */  {}
  ;

statement_extensions:
    return_statement  {}
  | continue_statement  {}
  | break_statement  { if (is_exit_label() == FALSE) { //loop does not exist
                          error("Break statement not inside loop");                       }
                       else { //exits closest surrounding loop
                          b_jump(current_exit_label());
                       }
                     }
  ;

return_statement:
    RETURN_  {}
  | RETURN_ expression  {}
  | EXIT  {}
  | FAIL  {}
  ;

break_statement:
    BREAK  {}
  ;

continue_statement:
    CONTINUE  {}
  ;

variable_access_or_typename:
    variable_or_function_access_no_id  {}
  | LEX_ID  { $$ = make_id_expr(st_enter_id($1)); }
  ;

index_expression_list:
    index_expression_item  { $$ = expr_prepend($1, NULL); }
  | index_expression_list ',' index_expression_item  { $$ = expr_prepend($3, $1); }
  ;

index_expression_item: //expr type
    expression  { $$ = $1; }
  | expression LEX_RANGE expression  { $$ = $1; } //default for now
  ;

/* expressions */

static_expression:
    expression  { $$ = $1; }
  ;

boolean_expression:
    expression  { $$ = $1; }
  ;

expression: //type is expression
    expression relational_operator simple_expression  { $$ = make_bin_expr($2, $1, $3); }
  | expression LEX_IN simple_expression  {}
  | simple_expression  { $$ = $1; }
  ;

simple_expression:
    term  { $$ = $1; }
  | simple_expression adding_operator term  { $$ = make_bin_expr($2, $1, $3); }
  | simple_expression LEX_SYMDIFF term  { $$ = make_bin_expr(SYMDIFF_OP, $1, $3); }
  | simple_expression LEX_OR term  { $$ = make_bin_expr(OR_OP, $1, $3); }
  | simple_expression LEX_XOR term  { $$ = make_bin_expr(XOR_OP, $1, $3); }
  ;

term:
    signed_primary  { $$ = $1; }
  | term multiplying_operator signed_primary  { $$ = make_bin_expr($2, $1, $3); }
  | term LEX_AND signed_primary  { $$ = make_bin_expr(AND_OP, $1, $3); }
  ;

signed_primary:
    primary  { $$ = $1; }
  | sign signed_primary  { $$ = make_un_expr($1, $2); }
  ;

primary:
    factor  { $$ = $1; }
  | primary LEX_POW factor  {}
  | primary LEX_POWER factor  {}
  | primary LEX_IS typename  {}
  ;

signed_factor:
    factor  {$$ = $1; }
  | sign signed_factor  {$$ = make_un_expr($1, $2); }
  ;

factor:
    variable_or_function_access  { if (ty_query($1->type) == TYFUNC) {
                                      $$ = make_fcall_expr($1, NULL);
                                   } else { $$ = $1; }
                                 }
  | constant_literal  { $$ = $1; }
  | unsigned_number  { $$ = $1; }
  | set_constructor  {}
  | LEX_NOT signed_factor  { $$ = make_un_expr(NOT_OP, $2); }
  | address_operator factor  { $$ = make_un_expr(ADDRESS_OP, $2); }
  ;

address_operator:
    '@'  {}
  ;

variable_or_function_access:
    variable_or_function_access_no_as  { $$ = $1; }
  | variable_or_function_access LEX_AS typename  {}
  ;

variable_or_function_access_no_as:
    variable_or_function_access_no_standard_function  { $$ = $1; }
  | standard_functions  { $$ = $1; }
  ;

variable_or_function_access_no_standard_function:
    identifier  { $$ = make_id_expr($1); }
  | variable_or_function_access_no_id  { $$ = $1; }
  ;

variable_or_function_access_no_id:
    p_OUTPUT  {}
  | p_INPUT  {}
  | variable_or_function_access_no_as '.' new_identifier  {} /* ignore */
  | '(' expression ')'  { $$ = $2; }
  | variable_or_function_access pointer_char  { $$ = make_un_expr(INDIR_OP, $1); } /* indir */
  | variable_or_function_access '[' index_expression_list ']'  { $$ = make_array_access_expr($1, $3); }
  | variable_or_function_access_no_standard_function '(' actual_parameter_list ')'  {} /* ignore */
  | p_NEW '(' variable_access_or_typename ')'  { $$ = make_un_expr(NEW_OP, $3); }
  ;

set_constructor:
    '[' ']'  {}
  | '[' set_constructor_element_list ']'  {}
  ;

set_constructor_element_list:
    member_designator  {}
  | set_constructor_element_list ',' member_designator  {}
  ;

member_designator:
    expression  {}
  | expression LEX_RANGE expression  {}
  ;

standard_functions:
    rts_fun_onepar '(' actual_parameter ')'  { $$ = make_un_expr($1, $3); }
  | rts_fun_optpar optional_par_actual_parameter  { $$ = make_null_expr($1); }
  | rts_fun_parlist '(' actual_parameter_list ')'  { $$ = make_un_expr($1, $3->expr); }
  ;

optional_par_actual_parameter:
    /* empty */  {}
  |  '(' actual_parameter ')'  { $$ = $2; }
  ;

rts_fun_optpar:
    p_EOF  { $$ = NULL_EOF_OP; }
  | p_EOLN  { $$ = NULL_EOLN_OP; }
  ;

rts_fun_onepar:
    p_ABS  { $$ = ABS_OP; }
  | p_SQR  { $$ = SQR_OP; }
  | p_SIN  { $$ = SIN_OP; }
  | p_COS  { $$ = COS_OP; }
  | p_EXP  { $$ = EXP_OP; }
  | p_LN  { $$ = LN_OP; }
  | p_SQRT  { $$ = SQRT_OP; }
  | p_ARCTAN  { $$ = ARCTAN_OP; }
  | p_ARG  { $$ = ARG_OP; }
  | p_TRUNC  { $$ = TRUNC_OP; }
  | p_ROUND  { $$ = ROUND_OP; }
  | p_CARD  { $$ = CARD_OP; }
  | p_ORD  { $$ = ORD_OP; }
  | p_CHR  { $$ = CHR_OP; }
  | p_ODD  { $$ = ODD_OP; }
  | p_EMPTY  { $$ = EMPTY_OP; }
  | p_POSITION  { $$ = POSITION_OP; }
  | p_LASTPOSITION  { $$ = LASTPOSITION_OP; }
  | p_LENGTH  { $$ = LENGTH_OP; }
  | p_TRIM  { $$ = TRIM_OP; }
  | p_BINDING  { $$ = BINDING_OP; }
  | p_DATE  { $$ = DATE_OP; }
  | p_TIME  { $$ = TIME_OP; }
  ;

rts_fun_parlist:
    p_SUCC        /* One or two args */  { $$ = UN_SUCC_OP; }
  | p_PRED        /* One or two args */  { $$ = UN_PRED_OP; }
  ;

relational_operator:
    LEX_NE  { $$ = NE_OP;        }
  | LEX_LE  { $$ = LE_OP;        }
  | LEX_GE  { $$ = GE_OP;        }
  | '='     { $$ = EQ_OP;        }
  | '<'     { $$ = LESS_OP;      }
  | '>'     { $$ = GREATER_OP;   }
  ;

multiplying_operator:
    LEX_DIV  { $$ = DIV_OP;     }
  | LEX_MOD  { $$ = MOD_OP;     }
  | '/'      { $$ = REALDIV_OP; }
  | '*'      { $$ = MUL_OP;     }
  ;

adding_operator:
    '-'  { $$ = SUB_OP; }
  | '+'  { $$ = ADD_OP; }
  ;

semi:
    ';'  {}
  ;

optional_semicolon:
    /* empty */  {}
  | ';'  {}
  ;

optional_rename:
    /* empty */  {}
  | LEX_RENAME new_identifier  {}
  ;

import_part:
    LEX_IMPORT import_specification_list semi  {}
  | LEX_USES uses_list semi  {}
  ;

import_specification_list:
    import_specification  {}
  | import_specification_list semi import_specification  {}
  ;

uses_list:
    import_specification  {}
  | uses_list ',' import_specification  {}
  ;

import_specification:
    new_identifier optional_access_qualifier optional_import_qualifier optional_unit_filename  {}
  ;

optional_access_qualifier:
    /* Empty */  {}
  | LEX_QUALIFIED  {}
  ;

optional_import_qualifier:
    /* Empty */  {}
  | '(' import_clause_list ')'  {}
  | LEX_ONLY '(' import_clause_list ')'  {}
  ;

optional_unit_filename:
    /* Empty */  {}
  | LEX_IN combined_string  {}
  ;

import_clause_list:
    import_clause  {}
  | import_clause_list ',' import_clause  {}
  ;

import_clause:
    new_identifier optional_rename  {}
  ;

%%

void yyerror(char *msg)
{
    error(msg);
}

/* Sets the value of the 'yydebug' variable to VALUE.
   This is a function so we don't have to have YYDEBUG defined
   in order to build the compiler.  */
void
set_yydebug (int value)
{
#if YYDEBUG != 0
  yydebug = value;
#else
  warning ("YYDEBUG not defined.");
#endif
}
