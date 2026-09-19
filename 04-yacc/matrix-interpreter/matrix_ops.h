#ifndef MATRIX_OPS_H
#define MATRIX_OPS_H

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>

/* ==============================================================================
 * DATA STRUCTURES
 * We represent scalars, vectors, and matrices uniformly using the Matrix struct.
 * - Scalar:       rows == 1, cols == 1
 * - Row Vector:   rows == 1, cols > 1
 * - Column Vector: rows > 1, cols == 1
 * - 2D Matrix:    rows > 1, cols > 1
 * ============================================================================== */

typedef struct {
    int rows;
    int cols;
    double **data;
} Matrix;

/* Symbol table node: stores variable name and its assigned Matrix */
typedef struct Symbol {
    char *name;
    Matrix *mat;
    struct Symbol *next;
} Symbol;

/* Helper structures for building matrices row-by-row during parsing */
typedef struct RowNode {
    double *values;
    int count;
    int capacity;
    struct RowNode *next;
} RowNode;

typedef struct MatrixBuilder {
    RowNode *head;
    RowNode *tail;
    int row_count;
    int col_count;
} MatrixBuilder;

/* ==============================================================================
 * MEMORY MANAGEMENT & CONSTRUCTORS
 * ============================================================================== */

Matrix* matrix_create(int rows, int cols);
Matrix* matrix_from_scalar(double val);
Matrix* matrix_clone(const Matrix *m);
void matrix_free(Matrix *m);

/* Matrix builder routines used by the parser */
MatrixBuilder* builder_create(void);
void builder_add_row(MatrixBuilder *b, RowNode *row);
RowNode* row_create(void);
void row_append(RowNode *r, double val);
Matrix* builder_to_matrix(MatrixBuilder *b);
void builder_free(MatrixBuilder *b);

/* ==============================================================================
 * LINEAR ALGEBRA & ARITHMETIC OPERATIONS
 * ============================================================================== */

Matrix* matrix_add(const Matrix *a, const Matrix *b);
Matrix* matrix_sub(const Matrix *a, const Matrix *b);
Matrix* matrix_mul(const Matrix *a, const Matrix *b);
Matrix* matrix_transpose(const Matrix *a);
Matrix* matrix_negate(const Matrix *a);
Matrix* matrix_det(const Matrix *a);

/* ==============================================================================
 * SYMBOL TABLE & I/O
 * ============================================================================== */

void symtab_set(const char *name, Matrix *m);
Matrix* symtab_get(const char *name);
void symtab_free_all(void);

void print_matrix(const Matrix *m);

#endif /* MATRIX_OPS_H */
