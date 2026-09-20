%{
/*
 * ==============================================================================
 * Mini-C to Three-Address Code (3AC) Compiler - Parser & SDT Engine (Bison/Yacc)
 * Tools: Bison (LALR(1) Parser Generator) / C99
 * ==============================================================================
 *
 * WHAT THIS PARSER DOES:
 * ----------------------
 * 1. Performs syntax analysis on Mini-C token streams using LALR(1) parsing.
 * 2. Executes Syntax-Directed Translation (SDT) to generate linearized
 *    Three-Address Code (3AC) intermediate representations.
 * 3. Synthesizes temporary variable names (t1, t2, ...) for sub-expressions.
 * 4. Synthesizes unique symbolic jump labels (L1, L2, ...) for conditional
 *    branches (if-else) and iteration constructs (while loops).
 *
 * 3AC INSTRUCTION FORMATS EMITTED:
 * --------------------------------
 * - Binary Arithmetic/Logic:   t_dest = src1 op src2
 * - Assignment:                var = src
 * - Conditional Branch:        iffalse cond goto label
 * - Unconditional Jump:        goto label
 * - Label Definition:          label:
 * ==============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Lexer and error handler prototypes */
int yylex(void);
void yyerror(const char *s);

/* Externals provided by Flex scanner */
extern FILE *yyin;
extern int yylineno;

/* Monotonically increasing counters for unique temporary and label generation */
static int temp_count = 1;
static int label_count = 1;

/*
 * newtemp():
 * Generates and returns a dynamically allocated temporary variable name
 * of the form "t1", "t2", "t3", etc.
 */
char* newtemp(void) {
    char* temp = (char*)malloc(16);
    if (!temp) {
        fprintf(stderr, "Error: Memory allocation failed in newtemp()\n");
        exit(EXIT_FAILURE);
    }
    sprintf(temp, "t%d", temp_count++);
    return temp;
}

/*
 * newlabel():
 * Generates and returns a dynamically allocated symbolic jump label
 * of the form "L1", "L2", "L3", etc.
 */
char* newlabel(void) {
    char* label = (char*)malloc(16);
    if (!label) {
        fprintf(stderr, "Error: Memory allocation failed in newlabel()\n");
        exit(EXIT_FAILURE);
    }
    sprintf(label, "L%d", label_count++);
    return label;
}
%}

/*
 * Semantic Value Type Definition (%union):
 * Tokens and non-terminals pass string pointers (variable names, constants,
 * temporary names, or labels) across grammar actions.
 */
%union {
    char* str;
}

/* Terminal Token Declarations */
%token <str> ID NUM
%token IF ELSE WHILE ASSIGN PLUS MINUS MULT DIV GREATER LESS AND OR SEMICOLON LBRACE RBRACE LPAREN RPAREN

/* Non-Terminal Type Declarations */
%type <str> expr

/*
 * Operator Precedence and Associativity:
 * Listed from LOWEST to HIGHEST precedence to prevent shift/reduce conflicts:
 * 1. OR (||)                       - Lowest precedence
 * 2. AND (&&)
 * 3. Relational (> , <)
 * 4. Additive (+ , -)
 * 5. Multiplicative (* , /)        - Highest precedence
 */
%left OR
%left AND
%left GREATER LESS
%left PLUS MINUS
%left MULT DIV

%%

/* ==============================================================================
 * GRAMMAR PRODUCTIONS & SYNTAX-DIRECTED TRANSLATION RULES
 * ============================================================================== */

/* Root rule: A Mini-C program is a sequence of statements */
program:
    stmt_list
    ;

/* Statement list: Recursively matches one or more statements */
stmt_list:
    stmt_list stmt
    | stmt
    ;

/* Individual statement translation */
stmt:
    /*
     * 1. Variable Assignment: ID = expr ;
     * Direct copy instruction: variable = evaluated_result
     */
    ID ASSIGN expr SEMICOLON {
        printf("%s = %s\n", $1, $3);
    }

    /*
     * 2. Conditional Statement: if (expr) { stmt_list } else { stmt_list }
     *
     * Translation Scheme:
     *   <evaluate expr into temp>
     *   iffalse <temp> goto L_else
     *   <then_stmt_list_3ac>
     *   goto L_exit
     * L_else:
     *   <else_stmt_list_3ac>
     * L_exit:
     */
    | IF LPAREN expr RPAREN {
        /* Mid-rule Action 1 ($<str>5):
         * Generate L_else label; emit branch to L_else if condition is false. */
        $<str>$ = newlabel(); 
        printf("iffalse %s goto %s\n", $3, $<str>$);
    } LBRACE stmt_list RBRACE {
        /* Mid-rule Action 2 ($<str>9):
         * Generate L_exit label; emit unconditional jump over else block;
         * emit L_else label to mark the beginning of the else branch. */
        $<str>$ = newlabel(); 
        printf("goto %s\n", $<str>$);
        printf("%s:\n", $<str>5);
    } ELSE LBRACE stmt_list RBRACE {
        /* Final Action:
         * Emit L_exit label to mark the end of the entire if-else statement. */
        printf("%s:\n", $<str>9);
    }

    /*
     * 3. Loop Statement: while (expr) { stmt_list }
     *
     * Translation Scheme:
     * L_start:
     *   <evaluate expr into temp>
     *   iffalse <temp> goto L_exit
     *   <loop_body_stmt_list_3ac>
     *   goto L_start
     * L_exit:
     */
    | WHILE {
        /* Mid-rule Action 1 ($<str>2):
         * Generate and emit L_start label before evaluating loop condition. */
        $<str>$ = newlabel();
        printf("%s:\n", $<str>$);
    } LPAREN expr RPAREN {
        /* Mid-rule Action 2 ($<str>6):
         * Generate L_exit label; emit branch to L_exit if condition is false. */
        $<str>$ = newlabel();
        printf("iffalse %s goto %s\n", $4, $<str>$);
    } LBRACE stmt_list RBRACE {
        /* Final Action:
         * Emit jump back to L_start; emit L_exit label to mark loop exit point. */
        printf("goto %s\n", $<str>2);
        printf("%s:\n", $<str>6);
    }
    ;

/* Expression evaluation: Emits 3AC quadruple instructions using temporaries */
expr:
    /* Addition */
    expr PLUS expr {
        $$ = newtemp();
        printf("%s = %s + %s\n", $$, $1, $3);
    }
    /* Subtraction */
    | expr MINUS expr {
        $$ = newtemp();
        printf("%s = %s - %s\n", $$, $1, $3);
    }
    /* Multiplication */
    | expr MULT expr {
        $$ = newtemp();
        printf("%s = %s * %s\n", $$, $1, $3);
    }
    /* Division */
    | expr DIV expr {
        $$ = newtemp();
        printf("%s = %s / %s\n", $$, $1, $3);
    }
    /* Greater-Than Comparison */
    | expr GREATER expr {
        $$ = newtemp();
        printf("%s = %s > %s\n", $$, $1, $3);
    }
    /* Less-Than Comparison */
    | expr LESS expr {
        $$ = newtemp();
        printf("%s = %s < %s\n", $$, $1, $3);
    }
    /* Logical AND */
    | expr AND expr {
        $$ = newtemp();
        printf("%s = %s && %s\n", $$, $1, $3);
    }
    /* Logical OR */
    | expr OR expr {
        $$ = newtemp();
        printf("%s = %s || %s\n", $$, $1, $3);
    }
    /* Parenthesized Sub-expression (passes inner result up) */
    | LPAREN expr RPAREN {
        $$ = $2;
    }
    /* Variable Identifier */
    | ID {
        $$ = $1;
    }
    /* Numeric Constant */
    | NUM {
        $$ = $1;
    }
    ;

%%

/*
 * yyerror():
 * Reports syntax errors encountered during parsing with line number information.
 */
void yyerror(const char *s) {
    fprintf(stderr, "[Syntax Error] Line %d: %s\n", yylineno, s);
}

/*
 * main():
 * Entry point for the Mini-C to 3AC compiler.
 * - If a file argument is provided, reads from that file.
 * - Otherwise, reads source code from standard input (stdin).
 */
int main(int argc, char *argv[]) {
    if (argc > 1) {
        FILE *fp = fopen(argv[1], "r");
        if (!fp) {
            fprintf(stderr, "[File Error] Cannot open source file '%s'\n", argv[1]);
            return EXIT_FAILURE;
        }
        yyin = fp;
    }

    /* Execute LALR(1) parser and syntax-directed translation */
    int status = yyparse();

    if (argc > 1 && yyin) {
        fclose(yyin);
    }

    return status;
}
