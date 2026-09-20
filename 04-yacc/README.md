# 04-yacc: Syntax Analysis & Translation (Yacc / Bison)

This module implements **Syntax Analysis (Parsing)** and **Syntax-Directed Translation (SDT)** using **GNU Bison / Yacc (LALR(1) Parser)** alongside **Flex**.

---

## Compiler Front-End Architecture

```text
  Source Code / Input Stream
              │
              ▼
  ┌───────────────────────┐
  │      Flex Lexer       │  ──> Emits stream of terminal tokens:
  │       (*.l files)     │      IDENT, NUM, PLUS, WHILE, IF, DET, etc.
  └───────────────────────┘
              │
              ▼
  ┌───────────────────────┐
  │   Bison LALR(1) Parser│  ──> Builds Parse Tree via bottom-up shift-reduce parsing
  │       (*.y files)     │      and executes Syntax-Directed Translation (SDT)
  └───────────────────────┘
              │
              ├─────────────────────────────┐
              ▼                             ▼
  [Project 1: Matrix Interpreter]   [Project 2: Mini-C to 3AC]
  Interactive calculator evaluating Intermediate representation generator
  linear algebra expressions        emitting linearized Three-Address Code
```

### Key Theoretical Concepts
1. **LALR(1) Parsing**: Lookahead LR parsing with 1 token of lookahead, constructing finite state tables over LR(0) items with merged lookahead sets.
2. **Conflict Resolution**: Resolving *shift/reduce* (e.g., dangling-else problem, operator chaining) and *reduce/reduce* conflicts using explicit operator precedence declarations (`%left`, `%right`, `%nonassoc`).
3. **Syntax-Directed Translation (SDT)**: Augmenting context-free grammar production rules with semantic action blocks in C to compute mathematical values or emit intermediate representation code.

---

## Implemented Projects

### 1. [`matrix-interpreter/`](matrix-interpreter/) (Self-Contained Matrix & Vector Calculator)
- **Objective**: An interactive calculator and script runner for multidimensional matrix and vector linear algebra.
- **Key Features**:
  - Matrix literals in both MATLAB semicolon (`[1, 2; 3, 4]`) and Python nested bracket (`[[1, 2], [3, 4]]`) notations.
  - Matrix addition (`+`), subtraction (`-`), multiplication (`*`), and scalar scaling.
  - Matrix transposition (`A'`, `A.T`, `A^T`) and determinant evaluation (`det(A)` via Gaussian elimination with partial pivoting).
  - Pass-by-value static 2D struct representation (`Matrix` and `Row`) with zero dynamic `malloc()`/`free()` overhead.
  - Interactive REPL mode and batch file script execution.
- **Source Files**: `matrix.l`, `matrix.y`, `Makefile`, `README.md`, `test_input.txt`.

---

### 2. [`mini-c-to-3ac/`](mini-c-to-3ac/) (Mini-C to Three-Address Code Generator)
- **Objective**: Front-end compiler for an imperative subset of C ("Mini-C") translating high-level control flow and expressions into linearized **Three-Address Code (3AC)**.
- **Key Features**:
  - Arithmetic (`+`, `-`, `*`, `/`), relational (`>`, `<`), and boolean (`&&`, `||`) expressions with temporary register generation (`t1, t2, ...`).
  - Control flow translation for `if-else` branching and `while` loops with symbolic jump labels (`L1:`, `goto L2`, `iffalse t1 goto L3`).
  - Bison mid-rule actions for emitting conditional jump targets before and around statement blocks.
- **Source Files**: `lexer.l`, `parser.y`, `Makefile`, `README.md`, `input.txt`.

---

## Building and Running Yacc Projects

### Prerequisites
- **GCC**: `gcc (MinGW-W64 / Linux POSIX C99)`
- **Flex**: `flex 2.6+`
- **Bison**: `bison (GNU Bison) 3.8+`
- **Make**: `GNU Make 4.0+`

### Matrix Interpreter Quick Start
```bash
cd 04-yacc/matrix-interpreter

# Build executable
make

# Run automated test suite
make test

# Launch interactive calculator REPL
./matrix_interpreter
```

### Mini-C to 3AC Compiler Quick Start
```bash
cd 04-yacc/mini-c-to-3ac

# Build executable
make

# Run compiler on sample input
make test

# Translate custom source file
./compiler input.txt
```
