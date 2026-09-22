%{
/*
 * ==============================================================================
 * ANSI SQL Lexical Analyzer (Tokenizer)
 * Tools: Flex (Fast Lexical Analyzer Generator) / C99
 * ==============================================================================
 *
 * WHAT THIS TOKENIZER DOES:
 * -------------------------
 * Scans standard ANSI SQL queries and tokenizes the source stream into structured,
 * classified lexical tokens with exact line and column coordinate tracking.
 *
 * TOKEN CATEGORIES:
 * -----------------
 * 1. Keywords (DDL/DML): SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, TABLE,
 *                        FROM, WHERE, JOIN, GROUP BY, ORDER BY, HAVING, etc.
 * 2. Data Types:         INT, VARCHAR, CHAR, TEXT, FLOAT, DECIMAL, DATE, BOOLEAN
 * 3. Logical & Ops:      AND, OR, NOT, LIKE, IN, BETWEEN, IS, NULL, EXISTS
 * 4. Comparison Ops:     =, <>, !=, <, >, <=, >=
 * 5. Arithmetic Ops:     +, -, *, /, %
 * 6. Delimiters:         ;, ,, (, ), .
 * 7. String Literals:    'Single-quoted text' (supports '' and \' escapes)
 * 8. Numeric Literals:   Integers, floating-point numbers, scientific notation
 * 9. Identifiers:        Column/table names (bare or backtick/double-quoted)
 * 10. Comments:          Single-line (-- ...) and block comments (slash-star ... star-slash)
 * ==============================================================================
 */

#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Global coordinate and metric tracking */
static int current_col = 1;
static int total_tokens = 0;
static int count_keywords = 0;
static int count_identifiers = 0;
static int count_literals = 0;
static int count_operators = 0;
static int count_delimiters = 0;
static int count_comments = 0;

/* Helper to log token output with position */
static void emit_token(const char *category, const char *lexeme) {
    total_tokens++;
    printf("[%4d:%-3d] %-20s : %s\n", yylineno, current_col, category, lexeme);
    current_col += yyleng;
}

/* Helper for multi-line comments updating line/column counts */
static void track_multiline_comment(const char *text) {
    count_comments++;
    printf("[%4d:%-3d] %-20s : /* ... */ (%zu bytes)\n", yylineno, current_col, "BLOCK_COMMENT", strlen(text));
    for (size_t i = 0; text[i] != '\0'; i++) {
        if (text[i] == '\n') {
            current_col = 1;
        } else {
            current_col++;
        }
    }
}
%}

/* Flex Scanner Options */
%option noyywrap
%option yylineno
%option nounput
%option noinput
%option caseless

/* Regular Expression Sub-patterns */
DIGIT       [0-9]
INT_LIT     {DIGIT}+
FLOAT_LIT   {DIGIT}+\.{DIGIT}*|\.{DIGIT}+
EXPONENT    [eE][+-]?{DIGIT}+
NUM_LIT     ({INT_LIT}|{FLOAT_LIT}){EXPONENT}?
IDENT       [a-zA-Z_][a-zA-Z0-9_]*
QUOTED_ID   `[^`\n]+`|\"[^\"\n]+\"
STRING_LIT  '([^'\\]|\\.|'')*'

%%

    /* -------------------------------------------------------------------------
     * 1. WHITESPACE & NEWLINES
     * ------------------------------------------------------------------------- */
[ \t\r]+                { current_col += yyleng; /* Consume horizontal whitespace */ }
\n                      { current_col = 1; /* Reset column counter on line break */ }

    /* -------------------------------------------------------------------------
     * 2. SQL COMMENTS
     * ------------------------------------------------------------------------- */
"--".*                  {
                            count_comments++;
                            printf("[%4d:%-3d] %-20s : %s\n", yylineno, current_col, "LINE_COMMENT", yytext);
                            current_col += yyleng;
                        }
"/*"([^*]|\*+[^*/])*\*+"/" {
                            track_multiline_comment(yytext);
                        }

    /* -------------------------------------------------------------------------
     * 3. DDL / DML KEYWORDS
     * ------------------------------------------------------------------------- */
"SELECT"                { count_keywords++; emit_token("KW_SELECT", yytext); }
"FROM"                  { count_keywords++; emit_token("KW_FROM", yytext); }
"WHERE"                 { count_keywords++; emit_token("KW_WHERE", yytext); }
"INSERT"                { count_keywords++; emit_token("KW_INSERT", yytext); }
"INTO"                  { count_keywords++; emit_token("KW_INTO", yytext); }
"VALUES"                { count_keywords++; emit_token("KW_VALUES", yytext); }
"UPDATE"                { count_keywords++; emit_token("KW_UPDATE", yytext); }
"SET"                   { count_keywords++; emit_token("KW_SET", yytext); }
"DELETE"                { count_keywords++; emit_token("KW_DELETE", yytext); }
"CREATE"                { count_keywords++; emit_token("KW_CREATE", yytext); }
"DROP"                  { count_keywords++; emit_token("KW_DROP", yytext); }
"ALTER"                 { count_keywords++; emit_token("KW_ALTER", yytext); }
"TABLE"                 { count_keywords++; emit_token("KW_TABLE", yytext); }
"INDEX"                 { count_keywords++; emit_token("KW_INDEX", yytext); }
"VIEW"                  { count_keywords++; emit_token("KW_VIEW", yytext); }
"JOIN"                  { count_keywords++; emit_token("KW_JOIN", yytext); }
"INNER"                 { count_keywords++; emit_token("KW_INNER", yytext); }
"LEFT"                  { count_keywords++; emit_token("KW_LEFT", yytext); }
"RIGHT"                 { count_keywords++; emit_token("KW_RIGHT", yytext); }
"FULL"                  { count_keywords++; emit_token("KW_FULL", yytext); }
"CROSS"                 { count_keywords++; emit_token("KW_CROSS", yytext); }
"ON"                    { count_keywords++; emit_token("KW_ON", yytext); }
"AS"                    { count_keywords++; emit_token("KW_AS", yytext); }
"DISTINCT"              { count_keywords++; emit_token("KW_DISTINCT", yytext); }
"ALL"                   { count_keywords++; emit_token("KW_ALL", yytext); }
"UNION"                 { count_keywords++; emit_token("KW_UNION", yytext); }
"ORDER"                 { count_keywords++; emit_token("KW_ORDER", yytext); }
"GROUP"                 { count_keywords++; emit_token("KW_GROUP", yytext); }
"BY"                    { count_keywords++; emit_token("KW_BY", yytext); }
"HAVING"                { count_keywords++; emit_token("KW_HAVING", yytext); }
"LIMIT"                 { count_keywords++; emit_token("KW_LIMIT", yytext); }
"OFFSET"                { count_keywords++; emit_token("KW_OFFSET", yytext); }
"ASC"                   { count_keywords++; emit_token("KW_ASC", yytext); }
"DESC"                  { count_keywords++; emit_token("KW_DESC", yytext); }
"PRIMARY"               { count_keywords++; emit_token("KW_PRIMARY", yytext); }
"FOREIGN"               { count_keywords++; emit_token("KW_FOREIGN", yytext); }
"KEY"                   { count_keywords++; emit_token("KW_KEY", yytext); }
"REFERENCES"            { count_keywords++; emit_token("KW_REFERENCES", yytext); }
"DEFAULT"               { count_keywords++; emit_token("KW_DEFAULT", yytext); }
"CHECK"                 { count_keywords++; emit_token("KW_CHECK", yytext); }
"CONSTRAINT"            { count_keywords++; emit_token("KW_CONSTRAINT", yytext); }
"AUTO_INCREMENT"        { count_keywords++; emit_token("KW_AUTO_INC", yytext); }

    /* -------------------------------------------------------------------------
     * 4. DATA TYPES
     * ------------------------------------------------------------------------- */
"INT"|"INTEGER"         { count_keywords++; emit_token("TYPE_INT", yytext); }
"BIGINT"                { count_keywords++; emit_token("TYPE_BIGINT", yytext); }
"SMALLINT"              { count_keywords++; emit_token("TYPE_SMALLINT", yytext); }
"VARCHAR"               { count_keywords++; emit_token("TYPE_VARCHAR", yytext); }
"CHAR"                  { count_keywords++; emit_token("TYPE_CHAR", yytext); }
"TEXT"                  { count_keywords++; emit_token("TYPE_TEXT", yytext); }
"BOOLEAN"|"BOOL"        { count_keywords++; emit_token("TYPE_BOOL", yytext); }
"FLOAT"                 { count_keywords++; emit_token("TYPE_FLOAT", yytext); }
"DOUBLE"                { count_keywords++; emit_token("TYPE_DOUBLE", yytext); }
"DECIMAL"|"NUMERIC"     { count_keywords++; emit_token("TYPE_DECIMAL", yytext); }
"DATE"                  { count_keywords++; emit_token("TYPE_DATE", yytext); }
"DATETIME"|"TIMESTAMP"  { count_keywords++; emit_token("TYPE_TIMESTAMP", yytext); }
"BLOB"                  { count_keywords++; emit_token("TYPE_BLOB", yytext); }

    /* -------------------------------------------------------------------------
     * 5. LOGICAL, PREDICATE & CONDITIONAL KEYWORDS
     * ------------------------------------------------------------------------- */
"AND"                   { count_operators++; emit_token("OP_AND", yytext); }
"OR"                    { count_operators++; emit_token("OP_OR", yytext); }
"NOT"                   { count_operators++; emit_token("OP_NOT", yytext); }
"LIKE"                  { count_operators++; emit_token("OP_LIKE", yytext); }
"IN"                    { count_operators++; emit_token("OP_IN", yytext); }
"BETWEEN"               { count_operators++; emit_token("OP_BETWEEN", yytext); }
"IS"                    { count_operators++; emit_token("OP_IS", yytext); }
"NULL"                  { count_literals++;  emit_token("LIT_NULL", yytext); }
"TRUE"                  { count_literals++;  emit_token("LIT_TRUE", yytext); }
"FALSE"                 { count_literals++;  emit_token("LIT_FALSE", yytext); }
"EXISTS"                { count_keywords++; emit_token("KW_EXISTS", yytext); }
"CASE"                  { count_keywords++; emit_token("KW_CASE", yytext); }
"WHEN"                  { count_keywords++; emit_token("KW_WHEN", yytext); }
"THEN"                  { count_keywords++; emit_token("KW_THEN", yytext); }
"ELSE"                  { count_keywords++; emit_token("KW_ELSE", yytext); }
"END"                   { count_keywords++; emit_token("KW_END", yytext); }

    /* -------------------------------------------------------------------------
     * 6. COMPARISON & ARITHMETIC OPERATORS
     * ------------------------------------------------------------------------- */
"<="                    { count_operators++; emit_token("OP_LE", yytext); }
">="                    { count_operators++; emit_token("OP_GE", yytext); }
"<>"|"!="               { count_operators++; emit_token("OP_NE", yytext); }
"<"                     { count_operators++; emit_token("OP_LT", yytext); }
">"                     { count_operators++; emit_token("OP_GT", yytext); }
"="                     { count_operators++; emit_token("OP_EQ", yytext); }
"||"                    { count_operators++; emit_token("OP_CONCAT", yytext); }
"+"                     { count_operators++; emit_token("OP_PLUS", yytext); }
"-"                     { count_operators++; emit_token("OP_MINUS", yytext); }
"*"                     { count_operators++; emit_token("OP_STAR", yytext); }
"/"                     { count_operators++; emit_token("OP_DIV", yytext); }
"%"                     { count_operators++; emit_token("OP_MOD", yytext); }

    /* -------------------------------------------------------------------------
     * 7. PUNCTUATION & DELIMITERS
     * ------------------------------------------------------------------------- */
","                     { count_delimiters++; emit_token("DELIM_COMMA", yytext); }
";"                     { count_delimiters++; emit_token("DELIM_SEMICOLON", yytext); }
"("                     { count_delimiters++; emit_token("DELIM_LPAREN", yytext); }
")"                     { count_delimiters++; emit_token("DELIM_RPAREN", yytext); }
"."                     { count_delimiters++; emit_token("DELIM_DOT", yytext); }

    /* -------------------------------------------------------------------------
     * 8. LITERALS & IDENTIFIERS
     * ------------------------------------------------------------------------- */
{STRING_LIT}            { count_literals++; emit_token("LIT_STRING", yytext); }
{NUM_LIT}               { count_literals++; emit_token("LIT_NUMBER", yytext); }
{QUOTED_ID}             { count_identifiers++; emit_token("QUOTED_IDENT", yytext); }
{IDENT}                 { count_identifiers++; emit_token("IDENTIFIER", yytext); }

    /* -------------------------------------------------------------------------
     * 9. UNKNOWN / ERROR TOKENS
     * ------------------------------------------------------------------------- */
.                       {
                            printf("[%4d:%-3d] %-20s : %s\n", yylineno, current_col, "ERROR_UNKNOWN", yytext);
                            current_col += yyleng;
                        }

%%

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *f = fopen(argv[1], "r");
        if (!f) {
            fprintf(stderr, "Error: Cannot open input SQL file '%s'\n", argv[1]);
            return 1;
        }
        yyin = f;
    } else {
        yyin = stdin;
    }

    printf("============================================================\n");
    printf("        ANSI SQL Lexical Analyzer & Query Tokenizer        \n");
    printf("============================================================\n");
    printf("[LINE:COL ] TOKEN TYPE           : LEXEME                   \n");
    printf("------------------------------------------------------------\n");

    yylex();

    if (argc > 1) {
        fclose(yyin);
    }

    printf("============================================================\n");
    printf("                   TOKENIZATION SUMMARY                     \n");
    printf("============================================================\n");
    printf(" Total Tokens Scanned : %d\n", total_tokens);
    printf("   - Keywords         : %d\n", count_keywords);
    printf("   - Identifiers      : %d\n", count_identifiers);
    printf("   - Literals         : %d\n", count_literals);
    printf("   - Operators        : %d\n", count_operators);
    printf("   - Delimiters       : %d\n", count_delimiters);
    printf("   - Comments         : %d\n", count_comments);
    printf("============================================================\n");

    return 0;
}
