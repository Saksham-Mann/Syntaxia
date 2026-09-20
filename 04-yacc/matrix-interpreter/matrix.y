%code requires {
/*
 * ==============================================================================
 * Matrix & Vector Arithmetic Interpreter - Parser & Evaluator (Bison/Yacc)
 * Language: C (C99 Standard) using GNU Bison
 * ==============================================================================
 *
 * Placed in %code requires so all types and prototypes are placed into both
 * parser.tab.h and parser.tab.c before %union. Zero external headers needed!
 */

#define MAX_ROWS 10
#define MAX_COLS 10
#define MAX_VARS 64

typedef struct {
    int rows;
    int cols;
    double data[MAX_ROWS][MAX_COLS];
} Matrix;

typedef struct {
    int count;
    double data[MAX_COLS];
} Row;

/* Function prototypes for linear algebra and symbol table operations */
Matrix mat_create(int r, int c);
Matrix mat_scalar(double val);
Row row_create(double val);
Row row_append(Row r, double val);
Matrix mat_from_row(Row r);
Matrix mat_add_row(Matrix m, Row r);
void mat_print(const char *name, Matrix m);
Matrix mat_add(Matrix a, Matrix b);
Matrix mat_sub(Matrix a, Matrix b);
Matrix mat_neg(Matrix a);
Matrix mat_mul(Matrix a, Matrix b);
Matrix mat_transpose(Matrix a);
Matrix mat_det(Matrix a);
int sym_lookup(const char *name);
void sym_set(const char *name, Matrix m);
Matrix sym_get(const char *name);
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

extern FILE *yyin;
extern int yylineno;
int yylex(void);
void yyerror(const char *s);

static int is_interactive = 0;
%}

/* ==============================================================================
 * BISON DECLARATIONS
 * ============================================================================== */

%union {
    double num;
    char id[32];
    Row row;
    Matrix mat;
}

%token <num> NUMBER
%token <id> IDENT
%token DET TRANSPOSE

%type <mat> expr row_list nested_rows
%type <row> row
%type <num> scalar_expr

/* Operator Precedence (lowest to highest) */
%left '+' '-'
%left '*'
%right UMINUS
%left TRANSPOSE '\'' '^'

%%

/* ==============================================================================
 * GRAMMAR PRODUCTIONS
 * ============================================================================== */

program:
    /* empty */
    | program line
    ;

line:
    '\n'
    | ';'
    | stmt '\n'
    | stmt ';'
    | error '\n' { yyerrok; if (is_interactive) printf("matrix> "); }
    | error ';'  { yyerrok; if (is_interactive) printf("matrix> "); }
    ;

stmt:
    IDENT '=' expr {
        sym_set($1, $3);
        mat_print($1, $3);
        if (is_interactive) printf("matrix> ");
    }
    | expr {
        mat_print("ans", $1);
        if (is_interactive) printf("matrix> ");
    }
    ;

expr:
    expr '+' expr               { $$ = mat_add($1, $3); }
    | expr '-' expr             { $$ = mat_sub($1, $3); }
    | expr '*' expr             { $$ = mat_mul($1, $3); }
    | expr TRANSPOSE            { $$ = mat_transpose($1); }
    | expr '\''                 { $$ = mat_transpose($1); }
    | expr '^' IDENT {
        if (strcmp($3, "T") == 0 || strcmp($3, "t") == 0) {
            $$ = mat_transpose($1);
        } else {
            fprintf(stderr, "[Syntax Error] Unknown exponent operator '^%s' (expected '^T')\n", $3);
            $$ = $1;
        }
    }
    | DET '(' expr ')'          { $$ = mat_det($3); }
    | '-' expr %prec UMINUS     { $$ = mat_neg($2); }
    | '(' expr ')'              { $$ = $2; }
    | NUMBER                    { $$ = mat_scalar($1); }
    | IDENT                     { $$ = sym_get($1); }
    | '[' row_list ']'          { $$ = $2; }
    | '[' nested_rows ']'       { $$ = $2; }
    ;

/* Semicolon-separated rows: [1, 2; 3, 4] or [1, 2, 3] */
row_list:
    row                         { $$ = mat_from_row($1); }
    | row_list ';' row          { $$ = mat_add_row($1, $3); }
    ;

/* Python-style nested rows: [[1, 2], [3, 4]] */
nested_rows:
    '[' row ']'                 { $$ = mat_from_row($2); }
    | nested_rows ',' '[' row ']' { $$ = mat_add_row($1, $4); }
    ;

/* Single row of comma-separated scalar expressions */
row:
    scalar_expr                 { $$ = row_create($1); }
    | row ',' scalar_expr       { $$ = row_append($1, $3); }
    ;

/* Scalar expressions inside matrix literals */
scalar_expr:
    NUMBER                      { $$ = $1; }
    | IDENT {
        Matrix m = sym_get($1);
        if (m.rows == 1 && m.cols == 1) {
            $$ = m.data[0][0];
        } else {
            fprintf(stderr, "[Runtime Error] '%s' is not a scalar variable\n", $1);
            $$ = 0.0;
        }
    }
    | '(' scalar_expr ')'       { $$ = $2; }
    | '-' scalar_expr %prec UMINUS { $$ = -$2; }
    | scalar_expr '+' scalar_expr { $$ = $1 + $3; }
    | scalar_expr '-' scalar_expr { $$ = $1 - $3; }
    | scalar_expr '*' scalar_expr { $$ = $1 * $3; }
    ;

%%

/* ==============================================================================
 * C SUBROUTINES: LINEAR ALGEBRA & SYMBOL TABLE ENGINE
 * ============================================================================== */

typedef struct {
    char name[32];
    Matrix mat;
} Symbol;

static Symbol symtab[MAX_VARS];
static int symtab_count = 0;

Matrix mat_create(int r, int c) {
    Matrix m;
    m.rows = r;
    m.cols = c;
    for (int i = 0; i < MAX_ROWS; i++)
        for (int j = 0; j < MAX_COLS; j++)
            m.data[i][j] = 0.0;
    return m;
}

Matrix mat_scalar(double val) {
    Matrix m = mat_create(1, 1);
    m.data[0][0] = val;
    return m;
}

Row row_create(double val) {
    Row r;
    r.count = 1;
    r.data[0] = val;
    return r;
}

Row row_append(Row r, double val) {
    if (r.count < MAX_COLS) {
        r.data[r.count++] = val;
    }
    return r;
}

Matrix mat_from_row(Row r) {
    Matrix m = mat_create(1, r.count);
    for (int j = 0; j < r.count; j++)
        m.data[0][j] = r.data[j];
    return m;
}

Matrix mat_add_row(Matrix m, Row r) {
    if (m.rows < MAX_ROWS) {
        if (m.cols == 0) m.cols = r.count;
        for (int j = 0; j < r.count && j < MAX_COLS; j++)
            m.data[m.rows][j] = r.data[j];
        m.rows++;
    }
    return m;
}

void mat_print(const char *name, Matrix m) {
    if (m.rows == 0 || m.cols == 0) return;
    if (m.rows == 1 && m.cols == 1) {
        printf("  %s = %g\n", name, m.data[0][0]);
    } else {
        printf("  %s (%dx%d) =\n", name, m.rows, m.cols);
        for (int i = 0; i < m.rows; i++) {
            printf("    ");
            for (int j = 0; j < m.cols; j++) {
                printf("%8.3f ", m.data[i][j]);
            }
            printf("\n");
        }
    }
}

Matrix mat_add(Matrix a, Matrix b) {
    if (a.rows == 0 || b.rows == 0) return mat_create(0, 0);
    if (a.rows != b.rows || a.cols != b.cols) {
        fprintf(stderr, "[Runtime Error] Dimension mismatch for addition: (%dx%d) vs (%dx%d)\n",
                a.rows, a.cols, b.rows, b.cols);
        return mat_create(0, 0);
    }
    Matrix r = mat_create(a.rows, a.cols);
    for (int i = 0; i < a.rows; i++)
        for (int j = 0; j < a.cols; j++)
            r.data[i][j] = a.data[i][j] + b.data[i][j];
    return r;
}

Matrix mat_sub(Matrix a, Matrix b) {
    if (a.rows == 0 || b.rows == 0) return mat_create(0, 0);
    if (a.rows != b.rows || a.cols != b.cols) {
        fprintf(stderr, "[Runtime Error] Dimension mismatch for subtraction: (%dx%d) vs (%dx%d)\n",
                a.rows, a.cols, b.rows, b.cols);
        return mat_create(0, 0);
    }
    Matrix r = mat_create(a.rows, a.cols);
    for (int i = 0; i < a.rows; i++)
        for (int j = 0; j < a.cols; j++)
            r.data[i][j] = a.data[i][j] - b.data[i][j];
    return r;
}

Matrix mat_neg(Matrix a) {
    Matrix r = a;
    for (int i = 0; i < a.rows; i++)
        for (int j = 0; j < a.cols; j++)
            r.data[i][j] = -a.data[i][j];
    return r;
}

Matrix mat_mul(Matrix a, Matrix b) {
    if (a.rows == 0 || b.rows == 0) return mat_create(0, 0);
    /* Case 1: Scalar * Matrix */
    if (a.rows == 1 && a.cols == 1) {
        Matrix r = b;
        for (int i = 0; i < b.rows; i++)
            for (int j = 0; j < b.cols; j++)
                r.data[i][j] *= a.data[0][0];
        return r;
    }
    /* Case 2: Matrix * Scalar */
    if (b.rows == 1 && b.cols == 1) {
        Matrix r = a;
        for (int i = 0; i < a.rows; i++)
            for (int j = 0; j < a.cols; j++)
                r.data[i][j] *= b.data[0][0];
        return r;
    }
    /* Case 3: Matrix * Matrix */
    if (a.cols != b.rows) {
        fprintf(stderr, "[Runtime Error] Dimension mismatch for multiplication: (%dx%d) * (%dx%d)\n",
                a.rows, a.cols, b.rows, b.cols);
        return mat_create(0, 0);
    }
    Matrix r = mat_create(a.rows, b.cols);
    for (int i = 0; i < a.rows; i++) {
        for (int j = 0; j < b.cols; j++) {
            double sum = 0.0;
            for (int k = 0; k < a.cols; k++) {
                sum += a.data[i][k] * b.data[k][j];
            }
            r.data[i][j] = sum;
        }
    }
    return r;
}

Matrix mat_transpose(Matrix a) {
    if (a.rows == 0 || a.cols == 0) return a;
    Matrix r = mat_create(a.cols, a.rows);
    for (int i = 0; i < a.rows; i++)
        for (int j = 0; j < a.cols; j++)
            r.data[j][i] = a.data[i][j];
    return r;
}

Matrix mat_det(Matrix a) {
    if (a.rows == 0 || a.rows != a.cols) {
        fprintf(stderr, "[Runtime Error] Determinant requires square matrix; got (%dx%d)\n", a.rows, a.cols);
        return mat_create(0, 0);
    }
    int n = a.rows;
    if (n == 1) return mat_scalar(a.data[0][0]);
    if (n == 2) {
        double d = a.data[0][0] * a.data[1][1] - a.data[0][1] * a.data[1][0];
        return mat_scalar(d);
    }
    /* Gaussian Elimination with Partial Pivoting */
    double mat[MAX_ROWS][MAX_COLS];
    for (int i = 0; i < n; i++)
        for (int j = 0; j < n; j++)
            mat[i][j] = a.data[i][j];

    double det = 1.0;
    for (int i = 0; i < n; i++) {
        int pivot = i;
        for (int j = i + 1; j < n; j++) {
            if (fabs(mat[j][i]) > fabs(mat[pivot][i]))
                pivot = j;
        }
        if (fabs(mat[pivot][i]) < 1e-12) return mat_scalar(0.0);
        if (pivot != i) {
            for (int k = 0; k < n; k++) {
                double tmp = mat[i][k];
                mat[i][k] = mat[pivot][k];
                mat[pivot][k] = tmp;
            }
            det = -det;
        }
        det *= mat[i][i];
        for (int j = i + 1; j < n; j++) {
            double factor = mat[j][i] / mat[i][i];
            for (int k = i + 1; k < n; k++) {
                mat[j][k] -= factor * mat[i][k];
            }
        }
    }
    return mat_scalar(det);
}

int sym_lookup(const char *name) {
    for (int i = 0; i < symtab_count; i++) {
        if (strcmp(symtab[i].name, name) == 0)
            return i;
    }
    return -1;
}

void sym_set(const char *name, Matrix m) {
    int idx = sym_lookup(name);
    if (idx >= 0) {
        symtab[idx].mat = m;
    } else if (symtab_count < MAX_VARS) {
        strncpy(symtab[symtab_count].name, name, 31);
        symtab[symtab_count].name[31] = '\0';
        symtab[symtab_count].mat = m;
        symtab_count++;
    }
}

Matrix sym_get(const char *name) {
    int idx = sym_lookup(name);
    if (idx >= 0) {
        return symtab[idx].mat;
    }
    fprintf(stderr, "[Runtime Error] Undefined variable '%s'\n", name);
    return mat_create(0, 0);
}

void yyerror(const char *s) {
    fprintf(stderr, "[Syntax Error] Line %d: %s\n", yylineno, s);
}

int main(int argc, char *argv[]) {
    printf("============================================================\n");
    printf("     Scientific Matrix & Vector Arithmetic Interpreter     \n");
    printf("============================================================\n");
    fflush(stdout);

    if (argc > 1) {
        FILE *fp = fopen(argv[1], "r");
        if (!fp) {
            fprintf(stderr, "[File Error] Cannot open input file '%s'\n", argv[1]);
            return EXIT_FAILURE;
        }
        yyin = fp;
        is_interactive = 0;
        printf("Executing script file: %s\n\n", argv[1]);
        yyparse();
        fclose(fp);
    } else {
        is_interactive = 1;
        printf("Interactive REPL Mode (Type expressions or 'Ctrl+C' to exit)\n");
        printf("matrix> ");
        yyparse();
        printf("\nExiting interpreter.\n");
    }

    return 0;
}
