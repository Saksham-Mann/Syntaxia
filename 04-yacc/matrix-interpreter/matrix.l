%{
#include "matrix_ops.h"
#include "matrix.tab.h"
#include <string.h>
#include <stdlib.h>

/* yylineno tracks current line number for error reporting */
extern int yylineno;
void yyerror(const char *s);
%}

%option noyywrap
%option yylineno

/* ==============================================================================
 * REGULAR EXPRESSION DEFINITIONS
 * ============================================================================== */

DIGIT       [0-9]
INT         {DIGIT}+
FLOAT       {DIGIT}+\.{DIGIT}*|\.{DIGIT}+
EXPONENT    [eE][+-]?{DIGIT}+
NUMBER      ({INT}|{FLOAT}){EXPONENT}?
IDENT       [a-zA-Z_][a-zA-Z0-9_]*

%%

[ \t\r]+                { /* Ignore whitespace (spaces, tabs, carriage returns) */ }

"//".*                  { /* Single-line comment: ignore */ }
"/*"([^*]|\*+[^*/])*\*+"/" { /* Multi-line C-style comment: ignore */ }

"det"|"DET"             { return DET; }

{NUMBER}                {
                            yylval.num = atof(yytext);
                            return NUMBER;
                        }

"^T"|"^t"               { return TRANSPOSE; }
".T"                    { return TRANSPOSE; }
"'"                     { return TRANSPOSE; }
"^"                     { return '^'; }

"+"                     { return '+'; }
"-"                     { return '-'; }
"*"                     { return '*'; }
"="                     { return '='; }
"("                     { return '('; }
")"                     { return ')'; }
"["                     { return '['; }
"]"                     { return ']'; }
";"                     { return ';'; }
","                     { return ','; }

"\n"                    { return '\n'; }

{IDENT}                 {
                            yylval.id = strdup(yytext);
                            return IDENT;
                        }

.                       {
                            fprintf(stderr, "[Lexical Error] Unexpected character '%c' (ASCII %d) at line %d\n",
                                    yytext[0], yytext[0], yylineno);
                        }

%%
