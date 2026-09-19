#include "matrix_ops.h"
#include <string.h>

/* ==============================================================================
 * 1. MEMORY MANAGEMENT & CONSTRUCTORS
 * ============================================================================== */

/* Allocates a matrix with the given number of rows and columns, initialized to 0.0 */
Matrix* matrix_create(int rows, int cols) {
    if (rows <= 0 || cols <= 0) {
        return NULL;
    }

    Matrix *m = (Matrix*)malloc(sizeof(Matrix));
    if (!m) {
        fprintf(stderr, "[Memory Error] Failed to allocate Matrix struct\n");
        exit(1);
    }

    m->rows = rows;
    m->cols = cols;
    m->data = (double**)malloc(rows * sizeof(double*));
    if (!m->data) {
        fprintf(stderr, "[Memory Error] Failed to allocate Matrix rows\n");
        free(m);
        exit(1);
    }

    for (int i = 0; i < rows; i++) {
        m->data[i] = (double*)calloc(cols, sizeof(double));
        if (!m->data[i]) {
            fprintf(stderr, "[Memory Error] Failed to allocate Matrix columns\n");
            for (int j = 0; j < i; j++) {
                free(m->data[j]);
            }
            free(m->data);
            free(m);
            exit(1);
        }
    }

    return m;
}

/* Wraps a single scalar value into a 1x1 Matrix */
Matrix* matrix_from_scalar(double val) {
    Matrix *m = matrix_create(1, 1);
    m->data[0][0] = val;
    return m;
}

/* Creates a deep copy of an existing matrix */
Matrix* matrix_clone(const Matrix *m) {
    if (!m) return NULL;
    Matrix *copy = matrix_create(m->rows, m->cols);
    for (int i = 0; i < m->rows; i++) {
        for (int j = 0; j < m->cols; j++) {
            copy->data[i][j] = m->data[i][j];
        }
    }
    return copy;
}

/* Safely frees all memory associated with a matrix */
void matrix_free(Matrix *m) {
    if (!m) return;
    if (m->data) {
        for (int i = 0; i < m->rows; i++) {
            if (m->data[i]) {
                free(m->data[i]);
            }
        }
        free(m->data);
    }
    free(m);
}

/* ==============================================================================
 * 2. MATRIX BUILDER (FOR PARSING LITERALS)
 * Handles row-by-row syntax like [1, 2; 3, 4] or [[1, 2], [3, 4]]
 * ============================================================================== */

RowNode* row_create(void) {
    RowNode *r = (RowNode*)malloc(sizeof(RowNode));
    r->capacity = 4;
    r->count = 0;
    r->values = (double*)malloc(r->capacity * sizeof(double));
    r->next = NULL;
    return r;
}

void row_append(RowNode *r, double val) {
    if (!r) return;
    if (r->count >= r->capacity) {
        r->capacity *= 2;
        r->values = (double*)realloc(r->values, r->capacity * sizeof(double));
    }
    r->values[r->count++] = val;
}

MatrixBuilder* builder_create(void) {
    MatrixBuilder *b = (MatrixBuilder*)malloc(sizeof(MatrixBuilder));
    b->head = NULL;
    b->tail = NULL;
    b->row_count = 0;
    b->col_count = -1;
    return b;
}

void builder_add_row(MatrixBuilder *b, RowNode *row) {
    if (!b || !row) return;

    if (b->col_count == -1) {
        b->col_count = row->count;
    } else if (b->col_count != row->count) {
        fprintf(stderr, "[Syntax Error] Inconsistent row length in matrix: expected %d columns, got %d\n",
                b->col_count, row->count);
    }

    if (!b->head) {
        b->head = row;
        b->tail = row;
    } else {
        b->tail->next = row;
        b->tail = row;
    }
    b->row_count++;
}

Matrix* builder_to_matrix(MatrixBuilder *b) {
    if (!b || b->row_count == 0 || b->col_count <= 0) {
        builder_free(b);
        return NULL;
    }

    Matrix *m = matrix_create(b->row_count, b->col_count);
    RowNode *curr = b->head;
    int r = 0;

    while (curr && r < b->row_count) {
        int items_to_copy = (curr->count < b->col_count) ? curr->count : b->col_count;
        for (int c = 0; c < items_to_copy; c++) {
            m->data[r][c] = curr->values[c];
        }
        curr = curr->next;
        r++;
    }

    builder_free(b);
    return m;
}

void builder_free(MatrixBuilder *b) {
    if (!b) return;
    RowNode *curr = b->head;
    while (curr) {
        RowNode *next = curr->next;
        free(curr->values);
        free(curr);
        curr = next;
    }
    free(b);
}

/* ==============================================================================
 * 3. ARITHMETIC & LINEAR ALGEBRA OPERATIONS
 * ============================================================================== */

/* Addition: Matrix + Matrix, Vector + Vector, or Scalar + Scalar */
Matrix* matrix_add(const Matrix *a, const Matrix *b) {
    if (!a || !b) return NULL;

    if (a->rows != b->rows || a->cols != b->cols) {
        fprintf(stderr, "[Runtime Error] Dimension mismatch in addition: (%dx%d) + (%dx%d)\n",
                a->rows, a->cols, b->rows, b->cols);
        return NULL;
    }

    Matrix *res = matrix_create(a->rows, a->cols);
    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < a->cols; j++) {
            res->data[i][j] = a->data[i][j] + b->data[i][j];
        }
    }
    return res;
}

/* Subtraction: Matrix - Matrix, Vector - Vector, or Scalar - Scalar */
Matrix* matrix_sub(const Matrix *a, const Matrix *b) {
    if (!a || !b) return NULL;

    if (a->rows != b->rows || a->cols != b->cols) {
        fprintf(stderr, "[Runtime Error] Dimension mismatch in subtraction: (%dx%d) - (%dx%d)\n",
                a->rows, a->cols, b->rows, b->cols);
        return NULL;
    }

    Matrix *res = matrix_create(a->rows, a->cols);
    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < a->cols; j++) {
            res->data[i][j] = a->data[i][j] - b->data[i][j];
        }
    }
    return res;
}

/* Multiplication: Handles scalar scaling, matrix multiplication, and matrix * vector */
Matrix* matrix_mul(const Matrix *a, const Matrix *b) {
    if (!a || !b) return NULL;

    /* Case 1: Scalar * Matrix (a is 1x1) */
    if (a->rows == 1 && a->cols == 1) {
        double scalar = a->data[0][0];
        Matrix *res = matrix_create(b->rows, b->cols);
        for (int i = 0; i < b->rows; i++) {
            for (int j = 0; j < b->cols; j++) {
                res->data[i][j] = scalar * b->data[i][j];
            }
        }
        return res;
    }

    /* Case 2: Matrix * Scalar (b is 1x1) */
    if (b->rows == 1 && b->cols == 1) {
        double scalar = b->data[0][0];
        Matrix *res = matrix_create(a->rows, a->cols);
        for (int i = 0; i < a->rows; i++) {
            for (int j = 0; j < a->cols; j++) {
                res->data[i][j] = a->data[i][j] * scalar;
            }
        }
        return res;
    }

    /* Case 3: Standard Matrix Multiplication (m x k) * (k x n) -> (m x n) */
    if (a->cols == b->rows) {
        Matrix *res = matrix_create(a->rows, b->cols);
        for (int i = 0; i < a->rows; i++) {
            for (int j = 0; j < b->cols; j++) {
                double sum = 0.0;
                for (int k = 0; k < a->cols; k++) {
                    sum += a->data[i][k] * b->data[k][j];
                }
                res->data[i][j] = sum;
            }
        }
        return res;
    }

    /* Case 4: Matrix * Row-Vector (m x k) * (1 x k) -> treats vector as column (k x 1) */
    if (b->rows == 1 && a->cols == b->cols) {
        Matrix *res = matrix_create(a->rows, 1);
        for (int i = 0; i < a->rows; i++) {
            double sum = 0.0;
            for (int k = 0; k < a->cols; k++) {
                sum += a->data[i][k] * b->data[0][k];
            }
            res->data[i][0] = sum;
        }
        return res;
    }

    fprintf(stderr, "[Runtime Error] Incompatible dimensions for multiplication: (%dx%d) * (%dx%d)\n",
            a->rows, a->cols, b->rows, b->cols);
    return NULL;
}

/* Transposition: Swaps rows and columns (m x n) -> (n x m) */
Matrix* matrix_transpose(const Matrix *a) {
    if (!a) return NULL;

    Matrix *res = matrix_create(a->cols, a->rows);
    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < a->cols; j++) {
            res->data[j][i] = a->data[i][j];
        }
    }
    return res;
}

/* Unary Negation: Negates all matrix elements */
Matrix* matrix_negate(const Matrix *a) {
    if (!a) return NULL;

    Matrix *res = matrix_create(a->rows, a->cols);
    for (int i = 0; i < a->rows; i++) {
        for (int j = 0; j < a->cols; j++) {
            res->data[i][j] = -a->data[i][j];
        }
    }
    return res;
}

/* ==============================================================================
 * Determinant Evaluation: det(A)
 * Evaluates determinant using Gaussian elimination with partial pivoting.
 * Returns a 1x1 scalar Matrix*, or NULL on dimension mismatch / error.
 * ============================================================================== */
Matrix* matrix_det(const Matrix *a) {
    if (!a) return NULL;

    if (a->rows != a->cols) {
        fprintf(stderr, "[Runtime Error] Determinant requires a square matrix: got (%dx%d)\n",
                a->rows, a->cols);
        return NULL;
    }

    int n = a->rows;
    if (n == 1) {
        return matrix_from_scalar(a->data[0][0]);
    }
    if (n == 2) {
        double d = a->data[0][0] * a->data[1][1] - a->data[0][1] * a->data[1][0];
        return matrix_from_scalar(d);
    }

    /* Allocate working copy for Gaussian elimination */
    double **temp = (double**)malloc(n * sizeof(double*));
    if (!temp) {
        fprintf(stderr, "[Memory Error] Failed to allocate memory for determinant\n");
        return NULL;
    }
    for (int i = 0; i < n; i++) {
        temp[i] = (double*)malloc(n * sizeof(double));
        if (!temp[i]) {
            for (int j = 0; j < i; j++) free(temp[j]);
            free(temp);
            return NULL;
        }
        for (int j = 0; j < n; j++) {
            temp[i][j] = a->data[i][j];
        }
    }

    double det = 1.0;
    for (int i = 0; i < n; i++) {
        /* Pivot selection */
        int pivot = i;
        double max_val = fabs(temp[i][i]);
        for (int r = i + 1; r < n; r++) {
            double val = fabs(temp[r][i]);
            if (val > max_val) {
                max_val = val;
                pivot = r;
            }
        }

        if (max_val < 1e-12) {
            det = 0.0;
            break;
        }

        if (pivot != i) {
            double *swap = temp[i];
            temp[i] = temp[pivot];
            temp[pivot] = swap;
            det = -det;
        }

        det *= temp[i][i];

        for (int r = i + 1; r < n; r++) {
            double factor = temp[r][i] / temp[i][i];
            for (int c = i; c < n; c++) {
                temp[r][c] -= factor * temp[i][c];
            }
        }
    }

    for (int i = 0; i < n; i++) {
        free(temp[i]);
    }
    free(temp);

    return matrix_from_scalar(det);
}

/* ==============================================================================
 * 4. SYMBOL TABLE IMPLEMENTATION
 * ============================================================================== */

static Symbol *symtab_head = NULL;

void symtab_set(const char *name, Matrix *m) {
    if (!name || !m) return;

    /* Check if variable already exists */
    Symbol *curr = symtab_head;
    while (curr) {
        if (strcmp(curr->name, name) == 0) {
            matrix_free(curr->mat);
            curr->mat = matrix_clone(m);
            return;
        }
        curr = curr->next;
    }

    /* Insert new variable at head */
    Symbol *node = (Symbol*)malloc(sizeof(Symbol));
    node->name = strdup(name);
    node->mat = matrix_clone(m);
    node->next = symtab_head;
    symtab_head = node;
}

Matrix* symtab_get(const char *name) {
    if (!name) return NULL;

    Symbol *curr = symtab_head;
    while (curr) {
        if (strcmp(curr->name, name) == 0) {
            return matrix_clone(curr->mat);
        }
        curr = curr->next;
    }

    fprintf(stderr, "[Runtime Error] Undefined variable '%s'\n", name);
    return NULL;
}

void symtab_free_all(void) {
    Symbol *curr = symtab_head;
    while (curr) {
        Symbol *next = curr->next;
        free(curr->name);
        matrix_free(curr->mat);
        free(curr);
        curr = next;
    }
    symtab_head = NULL;
}

/* ==============================================================================
 * 5. MATRIX PRINTING & FORMATTING
 * ============================================================================== */

void print_matrix(const Matrix *m) {
    if (!m) return;

    /* Scalar (1x1) */
    if (m->rows == 1 && m->cols == 1) {
        printf("  = %.4f\n", m->data[0][0]);
        return;
    }

    /* 1D Row Vector (1 x N) */
    if (m->rows == 1) {
        printf("  = [ ");
        for (int j = 0; j < m->cols; j++) {
            printf("%.4f%s", m->data[0][j], (j < m->cols - 1) ? ", " : " ");
        }
        printf("]\n");
        return;
    }

    /* 1D Column Vector (N x 1) */
    if (m->cols == 1) {
        printf("  = [\n");
        for (int i = 0; i < m->rows; i++) {
            printf("      %.4f\n", m->data[i][0]);
        }
        printf("    ]\n");
        return;
    }

    /* 2D Matrix (M x N) */
    printf("  = [\n");
    for (int i = 0; i < m->rows; i++) {
        printf("      [ ");
        for (int j = 0; j < m->cols; j++) {
            printf("%.4f%s", m->data[i][j], (j < m->cols - 1) ? ", " : " ");
        }
        printf("]\n");
    }
    printf("    ]\n");
}
