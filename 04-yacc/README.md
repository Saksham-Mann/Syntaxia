# 04-yacc: Syntax Analysis & Translation (Yacc / Bison)

This module implements **Syntax Analysis (Parsing)** and **Syntax-Directed Translation (SDT)** using **Yacc (Yet Another Compiler-Compiler) / GNU Bison** alongside Flex.

---

## Compiler Front-End Architecture

```text
  Source Code
       |
       v
+--------------+
|  Flex Lexer  |  --> Emits stream of terminal tokens (IDENT, NUM, PLUS, etc.)
+--------------+
       |
       v
+--------------+
|  Yacc Parser |  --> Builds Parse Tree via LALR(1) Shift-Reduce Parsing
+--------------+
       |
       +---> [Project 1: Matrix Interpreter]   --> Evaluates expression directly
       |
       +---> [Project 2: Mini-C to 3AC]        --> Emits Linearized Intermediate Code
```

### Key Theoretical Concepts
1. **LALR(1) Parsing**: Lookahead LR parsing with 1 token of lookahead, constructing finite state tables over LR(0) items with merged lookahead sets.
2. **Conflict Resolution**: Resolving *shift/reduce* (e.g., dangling-else problem) and *reduce/reduce* conflicts using explicit operator precedence (`%left`, `%right`, `%nonassoc`).
3. **Syntax-Directed Definition (SDD)**: Augmenting grammar production rules with semantic action blocks in C (`$$ = $1 + $3;`) to compute values or construct Abstract Syntax Trees (AST).

---

## Planned Projects

### 1. `matrix-interpreter/` (.l, .y, + Makefile)
- **Objective**: An interactive calculator/interpreter for matrix linear algebra expressions:
  - Matrix literals: `[[1, 2], [3, 4]]`
  - Matrix Addition (`+`) and Subtraction (`-`)
  - Matrix Multiplication (`*`) and Scalar Multiplication
  - Transposition operator (`A^T`) and Determinant evaluation (`det(A)`)
  - Dimension compatibility semantic checks at parse time.
- **Deliverables**: `matrix.l`, `matrix.y`, `matrix_ops.c`, `matrix_ops.h`, `Makefile`.

---

### 2. `mini-c-to-3ac/` (.l, .y, + Makefile)
- **Objective**: Front-end compiler for a subset of C that performs semantic analysis and translates high-level code into **Three-Address Code (3AC)** quadruples:
  - Variable declarations (`int`, `float`) and symbol table management.
  - Arithmetic and Boolean expressions with temporary variable generation (`t1 = a + b`).
  - Control flow translation: `if-else` branching and `while` loops with synthetic labels (`L1:`, `goto L2`).
  - Intermediate representation generation ready for optimization and target code generation.
- **Deliverables**: `mini_c.l`, `mini_c.y`, `symtab.c`, `codegen.c`, `Makefile`, and sample C programs.

---

## Building and Running Yacc Projects

```bash
# Verify bison and gcc
bison --version
gcc --version

# Build matrix interpreter
cd 04-yacc/matrix-interpreter
make

# Run interactive interpreter
./matrix_interpreter
```
