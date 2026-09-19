# Matrix & Vector Arithmetic Grammar Interpreter

A high-performance interactive interpreter and calculator for multidimensional matrix and vector linear algebra, implemented using **Flex (Lexer)**, **GNU Bison / Yacc (LALR(1) Parser)**, and standard **C99**.

---

## Theoretical Foundations & Compiler Architecture

The interpreter processes mathematical expressions across the classic front-end compiler pipeline:

```text
  User Input / Script File
             │
             ▼
  ┌───────────────────────┐
  │  Flex Lexical Analyzer│  ──> Emits terminal token stream:
  │        (matrix.l)     │      NUMBER, IDENT, DET, TRANSPOSE, '+', '*', '[', etc.
  └───────────────────────┘
             │
             ▼
  ┌───────────────────────┐
  │    Bison LALR(1)      │  ──> Builds parse tree & evaluates Syntax-Directed
  │    Syntax Analyzer    │      Definitions (SDD) with bottom-up shift-reduce parsing
  │       (matrix.y)      │
  └───────────────────────┘
             │
             ▼
  ┌───────────────────────┐
  │ Linear Algebra Engine │  ──> Dynamic memory allocation, dimension compatibility checks,
  │    (matrix_ops.c)     │      Gaussian elimination, and runtime symbol table
  └───────────────────────┘
             │
             ▼
     Evaluated Matrix /
     Scalar Output
```

### 1. Chomsky Classification: Context-Free Language (Type-2)
Matrix literals and arbitrary arithmetic expressions with matching brackets, parentheses, and operator precedence cannot be recognized by regular expressions or finite automata alone because they require arbitrary nesting depth (a stack memory model). They belong to **Type-2 Context-Free Languages** recognized by a **Pushdown Automaton (PDA)**.

### 2. LALR(1) Shift-Reduce Parsing
Bison constructs an **LALR(1)** (Lookahead LR with 1 token lookahead) finite state machine. Operator precedence and associativity declarations resolve potential shift-reduce conflicts in arithmetic expressions:

| Operator | Associativity | Precedence Level | Description |
| :--- | :--- | :--- | :--- |
| `+`, `-` | Left | Low | Matrix and scalar addition / subtraction |
| `*` | Left | Medium | Scalar scaling, matrix multiplication, matrix-vector product |
| `'`, `.T`, `^T` | Left | High | Matrix transposition |
| `UMINUS` (`-`) | Right | Highest | Unary arithmetic negation |

---

## Features & Supported Linear Algebra Operations

### 1. Matrix & Vector Literal Syntaxes
Supports both standard scientific computing notations:
- **MATLAB / Julia Semicolon Syntax**: `[1, 2; 3, 4]`
- **Python / NumPy Nested Bracket Syntax**: `[[1, 2], [3, 4]]`
- **1D Row Vectors**: `[1, 2, 3]` (1 × 3)
- **1D Column Vectors**: `[1; 2; 3]` (3 × 1)

### 2. Arithmetic & Transformations
- **Matrix Addition & Subtraction**: $A + B$, $A - B$ with shape checking ($m \times n \equiv m \times n$).
- **Matrix Multiplication**: $A \times B$ ($m \times k$ and $k \times n \to m \times n$).
- **Matrix-Vector Product**: Matrix transformation of column vectors ($m \times n \times n \times 1 \to m \times 1$).
- **Scalar Scaling**: Commutative scalar multiplication ($s \times A$ and $A \times s$).
- **Transposition**: Multiple interchangeable formats:
  - Prime notation: `A'`
  - Attribute notation: `A.T`
  - Caret notation: `A^T` or `A ^ T`
- **Determinant Evaluation**: `det(A)` computes $|A|$ via Gaussian elimination with partial pivoting in $O(n^3)$ time.
- **Variable Storage & Symbol Table**: Persists assigned variables across statements (`A = [1, 2; 3, 4];`).

---

## Project Structure & Deliverables

```text
04-yacc/matrix-interpreter/
├── Makefile            # Automated compilation and cross-platform test pipeline
├── matrix.l            # Flex specification (tokens, regexes, comments, line tracking)
├── matrix.y            # Bison LALR(1) grammar, precedence rules, and SDT actions
├── matrix_ops.h        # Data structures, builder definitions, and function declarations
├── matrix_ops.c        # Dynamic 2D arrays, linear algebra routines, and symbol table
└── test_input.txt      # Automated regression test suite covering all operations
```

---

## Building & Running

### Prerequisites
- **GCC / Clang** (C99 standard or higher)
- **Flex** (`flex`)
- **Bison** (`bison` or `yacc`)
- **GNU Make**

### 1. Compile the Project
```bash
make
```
This automatically invokes `bison -d matrix.y`, `flex matrix.l`, and compiles the resulting C files with `gcc` into the `matrix_interpreter` binary.

### 2. Run the Automated Test Suite
```bash
make test
```
Executes the interpreter against `test_input.txt`.

### 3. Interactive REPL Mode
Launch the interpreter without arguments for an interactive calculation session:
```bash
./matrix_interpreter
```

**Interactive REPL Example:**
```text
============================================================
     Scientific Matrix & Vector Arithmetic Interpreter     
============================================================
Interactive REPL Mode (Type expressions or 'Ctrl+C' to exit)
matrix> A = [1, 2; 3, 4]
  A =
  = [
      [ 1.0000, 2.0000 ]
      [ 3.0000, 4.0000 ]
    ]
matrix> A^T
  = [
      [ 1.0000, 3.0000 ]
      [ 2.0000, 4.0000 ]
    ]
matrix> det(A)
  = -2.0000
matrix> v = [2; 3]
  v =
  = [
      2.0000
      3.0000
    ]
matrix> A * v
  = [
      8.0000
      18.0000
    ]
matrix> 5.0 * A
  = [
      [ 5.0000, 10.0000 ]
      [ 15.0000, 20.0000 ]
    ]
```

### 4. Cleaning Build Artifacts
```bash
make clean
```
Removes generated parser C/H headers, object files, and compiled binaries.

---

## Verification & Test Results (`test_input.txt`)

When executing `make test`, the interpreter processes all 11 test categories:

```text
============================================================
     Scientific Matrix & Vector Arithmetic Interpreter     
============================================================
Executing script file: test_input.txt

  s1 = 10.5000
  s2 = 3.5000
  s_sum = 14.0000
  s_prod = 36.7500
  v1 = [ 1.0000, 2.0000, 3.0000 ]
  v2 = [ 4.0000, 5.0000, 6.0000 ]
  v_sum = [ 5.0000, 7.0000, 9.0000 ]
  v_scaled = [ 2.0000, 4.0000, 6.0000 ]
  A = [ [ 1.0000, 2.0000 ], [ 3.0000, 4.0000 ] ]
  B = [ [ 5.0000, 6.0000 ], [ 7.0000, 8.0000 ] ]
  C = [ [ 6.0000, 8.0000 ], [ 10.0000, 12.0000 ] ]
  D = [ [ 4.0000, 4.0000 ], [ 4.0000, 4.0000 ] ]
  A_scaled = [ [ 3.0000, 6.0000 ], [ 9.0000, 12.0000 ] ]
  A_transposed_prime = [ [ 1.0000, 3.0000 ], [ 2.0000, 4.0000 ] ]
  A_transposed_dot   = [ [ 1.0000, 3.0000 ], [ 2.0000, 4.0000 ] ]
  A_transposed_caret = [ [ 1.0000, 3.0000 ], [ 2.0000, 4.0000 ] ]
  det_A = -2.0000
  det_B = -2.0000
  det_M3 = 1.0000
  M_prod = [ [ 31.0000, 19.0000 ], [ 85.0000, 55.0000 ] ]
  v_transformed = [ 8.0000, 18.0000 ]
  complex_expr = [ [ -12.6000, -16.8000 ], [ -21.0000, -25.2000 ] ]
  done = 1.0000
```

### Semantic Error Handling & Recovery
Invalid operations (such as incompatible dimensions or non-square determinants) emit clear diagnostic runtime messages and recover gracefully without crashing:
```text
[Runtime Error] Dimension mismatch in addition: (2x2) + (2x3)
[Runtime Error] Incompatible dimensions for multiplication: (2x3) * (2x2)
[Runtime Error] Determinant requires a square matrix: got (2x3)
```
