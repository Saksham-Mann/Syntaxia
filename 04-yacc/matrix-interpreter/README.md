# Matrix & Vector Arithmetic Grammar Interpreter

A streamlined, self-contained interactive interpreter and calculator for multidimensional matrix and vector linear algebra, implemented using **Flex (Lexer)**, **GNU Bison / Yacc (LALR(1) Parser)**, and standard **C99**.

---

## 1. Theoretical Foundations & Compiler Architecture

The interpreter processes mathematical expressions across the classic front-end compiler pipeline:

```text
  User Input / Script File (test_input.txt)
                     │
                     ▼
  ┌───────────────────────────────────────┐
  │         Flex Lexical Analyzer         │  ──> Emits terminal token stream:
  │               (matrix.l)              │      NUMBER, IDENT, DET, TRANSPOSE, '+', '*', '[', etc.
  └───────────────────────────────────────┘
                     │
                     ▼
  ┌───────────────────────────────────────┐
  │         Bison LALR(1) Parser          │  ──> Evaluates Syntax-Directed Definitions (SDD)
  │               (matrix.y)              │      via bottom-up shift-reduce parsing
  └───────────────────────────────────────┘
                     │
                     ▼
  ┌───────────────────────────────────────┐
  │       Self-Contained Math Engine      │  ──> Pass-by-value static 2D struct (zero malloc/free),
  │         (Inline in matrix.y)          │      flat symbol table, and Gaussian elimination
  └───────────────────────────────────────┘
                     │
                     ▼
           Evaluated Matrix /
             Scalar Output
```

### 1. Chomsky Classification: Context-Free Language (Type-2)
Matrix literals and arbitrary arithmetic expressions with matching brackets, parentheses, and operator precedence cannot be recognized by regular expressions or finite automata alone because they require arbitrary nesting depth (a stack memory model). They belong to **Type-2 Context-Free Languages** recognized by a **Pushdown Automaton (PDA)**.

### 2. Static Memory Architecture (Zero Dynamic Allocation)
Unlike complex dynamic matrix libraries that require nested pointer allocations (`double **data`) and manual garbage deallocation, this interpreter uses a clean static data structure:
```c
typedef struct {
    int rows;
    int cols;
    double data[10][10];  /* Static buffer for up to 10x10 matrices */
} Matrix;
```
- **Pass-by-Value**: Matrices are copied directly on the Yacc parsing stack.
- **Zero Memory Leaks**: No calls to `malloc()` or `free()`; immune to pointer errors and memory fragmentation.
- **Unified Representation**: Scalars are represented simply as $1 \times 1$ matrices (`rows = 1, cols = 1`).

### 3. LALR(1) Shift-Reduce Parsing
Bison constructs an **LALR(1)** (Lookahead LR with 1 token lookahead) finite state machine. Operator precedence and associativity declarations resolve potential shift-reduce conflicts in arithmetic expressions:

| Operator | Associativity | Precedence Level | Description |
| :--- | :--- | :--- | :--- |
| `+`, `-` | Left | Low | Matrix and scalar addition / subtraction |
| `*` | Left | Medium | Scalar scaling, matrix multiplication, matrix-vector product |
| `UMINUS` (`-`) | Right | High | Unary arithmetic negation |
| `'`, `.T`, `^T` | Left | Highest | Matrix transposition |

---

## 2. Supported Linear Algebra Operations

### 1. Matrix & Vector Literal Syntaxes
Supports both standard scientific computing notations:
- **MATLAB / Julia Semicolon Syntax**: `[1, 2; 3, 4]`
- **Python / NumPy Nested Bracket Syntax**: `[[1, 2], [3, 4]]`
- **1D Row Vectors**: `[1, 2, 3]` (1 × 3)
- **1D Column Vectors**: `[2; 3]` (2 × 1)

### 2. Arithmetic & Transformations
- **Matrix Addition & Subtraction**: $A + B$, $A - B$ with shape checking ($m \times n \equiv m \times n$).
- **Matrix Multiplication**: $A \times B$ ($m \times k$ and $k \times n \to m \times n$).
- **Matrix-Vector Product**: Column vector transformation ($m \times n$ and $n \times 1 \to m \times 1$).
- **Scalar Scaling**: Commutative scalar multiplication ($s \times A$ and $A \times s$).
- **Transposition**: Multiple interchangeable formats:
  - Prime notation: `A'`
  - Attribute notation: `A.T`
  - Caret notation: `A^T` or `A ^ T`
- **Determinant (`det`)**: Evaluates $\det(A)$ for any square matrix ($N \times N$) using Gaussian elimination with partial pivoting.

---

## 3. Project File Structure

```text
04-yacc/matrix-interpreter/
├── Makefile       # Cross-platform build script (make, make test, make clean)
├── README.md      # Documentation & theoretical specification
├── matrix.l       # Flex lexical analyzer specification
├── matrix.y       # Bison parser, evaluator, and symbol table (100% self-contained)
└── test_input.txt # Comprehensive 11-category linear algebra test suite
```

---

## 4. Building and Running

### Prerequisites
- GCC (`gcc`)
- Flex (`flex 2.6+`)
- GNU Bison (`bison 3.8+`)
- GNU Make (`make 4.0+`)

### Build & Test Commands

```bash
# Navigate to directory
cd 04-yacc/matrix-interpreter

# Build executable
make

# Run test script
make test

# Clean build artifacts
make clean
```

### Interactive REPL Mode
```bash
./matrix_interpreter
```
Example interactive session:
```text
matrix> A = [1, 2; 3, 4]
  A (2x2) =
       1.000    2.000 
       3.000    4.000 
matrix> det(A)
  ans = -2
matrix> A'
  ans (2x2) =
       1.000    3.000 
       2.000    4.000 
```

---

## 5. Verification & Test Suite Output (`test_input.txt`)

Running `make test` executes all linear algebra features:

```text
============================================================
     Scientific Matrix & Vector Arithmetic Interpreter     
============================================================
Executing script file: test_input.txt

  s1 = 10.5
  s2 = 3.5
  s_sum = 14
  s_prod = 36.75
  v1 (1x3) =
       1.000    2.000    3.000 
  v2 (1x3) =
       4.000    5.000    6.000 
  v_sum (1x3) =
       5.000    7.000    9.000 
  v_scaled (1x3) =
       2.000    4.000    6.000 
  A (2x2) =
       1.000    2.000 
       3.000    4.000 
  B (2x2) =
       5.000    6.000 
       7.000    8.000 
  C (2x2) =
       6.000    8.000 
      10.000   12.000 
  D (2x2) =
       4.000    4.000 
       4.000    4.000 
  A_scaled (2x2) =
       3.000    6.000 
       9.000   12.000 
  A_transposed_prime (2x2) =
       1.000    3.000 
       2.000    4.000 
  A_transposed_dot (2x2) =
       1.000    3.000 
       2.000    4.000 
  A_transposed_caret (2x2) =
       1.000    3.000 
       2.000    4.000 
  A_transposed_spaced (2x2) =
       1.000    3.000 
       2.000    4.000 
  det_A = -2
  det_B = -2
  M3 (3x3) =
       1.000    2.000    3.000 
       0.000    1.000    4.000 
       5.000    6.000    0.000 
  det_M3 = 1
  M1 (2x3) =
       1.000    2.000    3.000 
       4.000    5.000    6.000 
  M2 (3x2) =
       7.000    8.000 
       9.000    1.000 
       2.000    3.000 
  M_prod (2x2) =
      31.000   19.000 
      85.000   55.000 
  u (2x1) =
       2.000 
       3.000 
  v_transformed (2x1) =
       8.000 
      18.000 
  complex_expr (2x2) =
     -12.600  -16.800 
     -21.000  -25.200 
  done = 1
```

### Safe Semantic Recovery on Incompatible Dimensions
Deliberately invalid operations emit diagnostic runtime error messages without crashing:
```text
[Runtime Error] Dimension mismatch for addition: (2x2) vs (2x3)
[Runtime Error] Dimension mismatch for multiplication: (2x3) * (2x2)
[Runtime Error] Determinant requires square matrix; got (2x3)
```
