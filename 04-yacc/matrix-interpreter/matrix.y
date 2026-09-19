%{
#include "matrix_ops.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);
extern int yylineno;
extern FILE *yyin;

int is_interactive = 0;
%}

%union {
    double num;
    char *id;
    Matrix *matrix;
    RowNode *row;
    MatrixBuilder *builder;
}

/* Tokens */
%token <num> NUMBER
%token <id> IDENT
%token DET TRANSPOSE

/* Non-terminal types */
%type <matrix> expr
%type <row> row
%type <builder> row_list nested_rows
%type <num> scalar_expr

/* Operator Precedence and Associativity */
%left '+' '-'
%left '*'
%left TRANSPOSE '\'' '^'
%right UMINUS

%%

/* ==============================================================================
 * TOP-LEVEL PROGRAM & STATEMENTS
 * Supports both REPL interactive execution and scripted file input
 * ============================================================================== */

program
    : /* empty */
    | program statement
    ;

statement
    : '\n'
        {
            if (is_interactive) printf("matrix> ");
        }
    | ';'
        {
            if (is_interactive) printf("matrix> ");
        }
    | expr '\n'
        {
            if ($1) {
                print_matrix($1);
                matrix_free($1);
            }
            if (is_interactive) printf("matrix> ");
        }
    | expr ';'
        {
            if ($1) {
                print_matrix($1);
                matrix_free($1);
            }
            if (is_interactive) printf("matrix> ");
        }
    | IDENT '=' expr '\n'
        {
            if ($3) {
                symtab_set($1, $3);
                printf("  %s =\n", $1);
                print_matrix($3);
                matrix_free($3);
            }
            free($1);
            if (is_interactive) printf("matrix> ");
        }
    | IDENT '=' expr ';'
        {
            if ($3) {
                symtab_set($1, $3);
                printf("  %s =\n", $1);
                print_matrix($3);
                matrix_free($3);
            }
            free($1);
            if (is_interactive) printf("matrix> ");
        }
    | error '\n'
        {
            yyerrok;
            if (is_interactive) printf("matrix> ");
        }
    | error ';'
        {
            yyerrok;
            if (is_interactive) printf("matrix> ");
        }
    ;

/* ==============================================================================
 * EXPRESSION GRAMMAR RULES
 * ============================================================================== */

expr
    : expr '+' expr
        {
            $$ = matrix_add($1, $3);
            matrix_free($1);
            matrix_free($3);
        }
    | expr '-' expr
        {
            $$ = matrix_sub($1, $3);
            matrix_free($1);
            matrix_free($3);
        }
    | expr '*' expr
        {
            $$ = matrix_mul($1, $3);
            matrix_free($1);
            matrix_free($3);
        }
    | expr TRANSPOSE
        {
            $$ = matrix_transpose($1);
            matrix_free($1);
        }
    | expr '\''
        {
            $$ = matrix_transpose($1);
            matrix_free($1);
        }
    | expr '^' IDENT
        {
            if (strcmp($3, "T") == 0 || strcmp($3, "t") == 0) {
                $$ = matrix_transpose($1);
                matrix_free($1);
            } else {
                fprintf(stderr, "[Syntax Error] Unknown superscript operator '^%s' (expected '^T')\n", $3);
                $$ = $1;
            }
            free($3);
        }
    | DET '(' expr ')'
        {
            $$ = matrix_det($3);
            matrix_free($3);
        }
    | '-' expr %prec UMINUS
        {
            $$ = matrix_negate($2);
            matrix_free($2);
        }
    | '(' expr ')'
        {
            $$ = $2;
        }
    | NUMBER
        {
            $$ = matrix_from_scalar($1);
        }
    | IDENT
        {
            $$ = symtab_get($1);
            free($1);
        }
    | '[' row_list ']'
        {
            $$ = builder_to_matrix($2);
        }
    | '[' nested_rows ']'
        {
            $$ = builder_to_matrix($2);
        }
    ;

/* ==============================================================================
 * MATRIX LITERAL GRAMMAR RULES
 * Form 1: Semicolon or Vector syntax: [1, 2; 3, 4] or [1, 2, 3]
 * Form 2: Nested bracket syntax: [[1, 2], [3, 4]]
 * ============================================================================== */

row_list
    : row
        {
            $$ = builder_create();
            builder_add_row($$, $1);
        }
    | row_list ';' row
        {
            $$ = $1;
            builder_add_row($$, $3);
        }
    ;

nested_rows
    : '[' row ']'
        {
            $$ = builder_create();
            builder_add_row($$, $2);
        }
    | nested_rows ',' '[' row ']'
        {
            $$ = $1;
            builder_add_row($$, $4);
        }
    ;

row
    : scalar_expr
        {
            $$ = row_create();
            row_append($$, $1);
        }
    | row ',' scalar_expr
        {
            $$ = $1;
            row_append($$, $3);
        }
    ;

/* Evaluates scalar expressions embedded inside matrix rows */
scalar_expr
    : NUMBER
        {
            $$ = $1;
        }
    | IDENT
        {
            Matrix *m = symtab_get($1);
            if (m) {
                if (m->rows == 1 && m->cols == 1) {
                    $$ = m->data[0][0];
                } else {
                    fprintf(stderr, "[Semantic Error] Variable '%s' is not a scalar\n", $1);
                    $$ = 0.0;
                }
                matrix_free(m);
            } else {
                $$ = 0.0;
            }
            free($1);
        }
    | '(' scalar_expr ')'
        {
            $$ = $2;
        }
    | '-' scalar_expr %prec UMINUS
        {
            $$ = -$2;
        }
    | scalar_expr '+' scalar_expr
        {
            $$ = $1 + $3;
        }
    | scalar_expr '-' scalar_expr
        {
            $$ = $1 - $3;
        }
    | scalar_expr '*' scalar_expr
        {
            $$ = $1 * $3;
        }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "[Parse Error] Line %d: %s\n", yylineno, s);
}

int main(int argc, char **argv) {
    printf("============================================================\n");
    printf("     Scientific Matrix & Vector Arithmetic Interpreter     \n");
    printf("============================================================\n");

    if (argc > 1) {
        FILE *f = fopen(argv[1], "r");
        if (!f) {
            fprintf(stderr, "[File Error] Cannot open input file '%s'\n", argv[1]);
            return 1;
        }
        yyin = f;
        is_interactive = 0;
        printf("Executing script file: %s\n\n", argv[1]);
        yyparse();
        fclose(f);
    } else {
        is_interactive = 1;
        printf("Interactive REPL Mode (Type expressions or 'Ctrl+C' to exit)\n");
        printf("matrix> ");
        yyparse();
        printf("\nExiting interpreter.\n");
    }

    symtab_free_all();
    return 0;
}
