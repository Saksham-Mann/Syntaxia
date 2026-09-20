%{
/*
 * ==============================================================================
 * Mini-C to Three-Address Code (3AC) Compiler - Lexical Analyzer (Flex)
 * Tools: Flex (Fast Lexical Analyzer Generator) / C99
 * ==============================================================================
 *
 * WHAT THIS LEXER DOES:
 * ---------------------
 * Scans source code written in a subset of the C language ("Mini-C") and converts
 * the raw stream of characters into a sequence of classified terminal tokens
 * for the Yacc/Bison parser.
 *
 * TOKEN CATEGORIES:
 * -----------------
 * 1. Keywords:           'if', 'else', 'while'
 * 2. Identifiers:        Variable names matching [a-zA-Z_][a-zA-Z0-9_]*
 * 3. Numeric Literals:   Integer numbers [0-9]+
 * 4. Assignment:         '='
 * 5. Arithmetic Ops:     '+', '-', '*', '/'
 * 6. Relational Ops:     '>', '<'
 * 7. Logical Ops:        '&&', '||'
 * 8. Delimiters/Punct:   ';', '{', '}', '(', ')'
 * ==============================================================================
 */

#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Track line numbers for syntax error reporting */
extern int yylineno;
void yyerror(const char *s);
%}

/*
 * Flex Scanner Options:
 * - noyywrap: Avoids linking with external -lfl library; signals EOF when done.
 * - yylineno: Automatically increments yylineno on encountering newline characters.
 * - nounput / noinput: Suppresses unused static function compiler warnings.
 */
%option noyywrap
%option yylineno
%option nounput
%option noinput

/* ==============================================================================
 * REGULAR EXPRESSION DEFINITIONS
 * ============================================================================== */

DIGIT       [0-9]
LETTER      [a-zA-Z_]
IDENTIFIER  {LETTER}({LETTER}|{DIGIT})*
INTEGER     {DIGIT}+

%%

    /* -------------------------------------------------------------------------
     * 1. WHITESPACE & COMMENTS
     * ------------------------------------------------------------------------- */
[ \t\r]+                { /* Ignore whitespace (spaces, tabs, carriage returns) */ }
\n                      { /* Newlines are tracked automatically by %option yylineno */ }
"//".*                  { /* Ignore single-line comments */ }
"/*"([^*]|\*+[^*/])*\*+"/" { /* Ignore multi-line C-style block comments */ }

    /* -------------------------------------------------------------------------
     * 2. CONTROL FLOW KEYWORDS
     * ------------------------------------------------------------------------- */
"if"                    { return IF; }
"else"                  { return ELSE; }
"while"                 { return WHILE; }

    /* -------------------------------------------------------------------------
     * 3. IDENTIFIERS & LITERAL CONSTANTS
     * ------------------------------------------------------------------------- */
{IDENTIFIER}            {
                            /* Duplicate token string so parser can access identifier name */
                            yylval.str = strdup(yytext);
                            return ID;
                        }

{INTEGER}               {
                            /* Duplicate numeric string so parser can emit constant values */
                            yylval.str = strdup(yytext);
                            return NUM;
                        }

    /* -------------------------------------------------------------------------
     * 4. OPERATORS
     * ------------------------------------------------------------------------- */
"="                     { return ASSIGN; }
"+"                     { return PLUS; }
"-"                     { return MINUS; }
"*"                     { return MULT; }
"/"                     { return DIV; }
">"                     { return GREATER; }
"<"                     { return LESS; }
"&&"                    { return AND; }
"||"                    { return OR; }

    /* -------------------------------------------------------------------------
     * 5. DELIMITERS & PUNCTUATION
     * ------------------------------------------------------------------------- */
";"                     { return SEMICOLON; }
"{"                     { return LBRACE; }
"}"                     { return RBRACE; }
"("                     { return LPAREN; }
")"                     { return RPAREN; }

    /* -------------------------------------------------------------------------
     * 6. UNRECOGNIZED CHARACTERS (FALLTHROUGH)
     * ------------------------------------------------------------------------- */
.                       {
                            /* Return raw character to parser to trigger syntax error */
                            return yytext[0];
                        }

%%
