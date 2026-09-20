%{
/*
 * ==============================================================================
 * Matrix & Vector Arithmetic Interpreter - Lexical Analyzer (Flex)
 * Language: C (C99 Standard) using Flex
 * ==============================================================================
 *
 * WHAT THIS LEXER DOES:
 * ---------------------
 * Scans input text and converts characters into tokens:
 * - Numbers: Integers and floats (e.g. 10, 3.14, 1e-3)
 * - Identifiers: Variable names (e.g. A, B, s1, v_sum)
 * - Keywords: 'det' / 'DET'
 * - Transpose Operators: `'`, `.T`, `^T`
 * - Punctuation & Delimiters: `[`, `]`, `;`, `,`, `=`, `(`, `)`
 * ==============================================================================
 */

#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylineno;
void yyerror(const char *s);
%}

%option noyywrap
%option yylineno
%option nounput
%option noinput

DIGIT       [0-9]
INT         {DIGIT}+
FLOAT       {DIGIT}+\.{DIGIT}*|\.{DIGIT}+
EXPONENT    [eE][+-]?{DIGIT}+
NUMBER      ({INT}|{FLOAT}){EXPONENT}?
IDENT       [a-zA-Z_][a-zA-Z0-9_]*

%%

    /* Whitespace and comments */
[ \t\r]+                { /* Ignore spaces, tabs, and carriage returns */ }
"//".*                  { /* Ignore single-line comments */ }
"/*"([^*]|\*+[^*/])*\*+"/" { /* Ignore multi-line comments */ }

    /* Built-in function */
"det"|"DET"             { return DET; }

    /* Numbers (converted directly to double) */
{NUMBER}                {
                            yylval.num = atof(yytext);
                            return NUMBER;
                        }

    /* Transpose representations */
"^T"|"^t"|".T"|"'"      { return TRANSPOSE; }
"^"                     { return '^'; }

    /* Arithmetic and assignment operators */
"+"                     { return '+'; }
"-"                     { return '-'; }
"*"                     { return '*'; }
"="                     { return '='; }

    /* Brackets and delimiters */
"("                     { return '('; }
")"                     { return ')'; }
"["                     { return '['; }
"]"                     { return ']'; }
";"                     { return ';'; }
","                     { return ','; }

    /* Line breaks */
"\n"                    { return '\n'; }

    /* Variable identifiers */
{IDENT}                 {
                            strncpy(yylval.id, yytext, 31);
                            yylval.id[31] = '\0';
                            return IDENT;
                        }

    /* Fallback */
.                       { return yytext[0]; }

%%
