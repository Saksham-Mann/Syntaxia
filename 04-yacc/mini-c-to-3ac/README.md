# Mini-C to Three-Address Code (3AC) Compiler

An intermediate code generator for a subset of C ("Mini-C") implemented using **Flex (Lexer)**, **GNU Bison / Yacc (LALR(1) Parser)**, and standard **C99**. It translates high-level imperative constructs (control flow and expressions) into linearized **Three-Address Code (3AC)**.

---

## 1. Theoretical Foundations & Compiler Architecture

### Front-End Pipeline

```text
       Mini-C Source Code (input.txt)
                     │
                     ▼
       ┌───────────────────────────┐
       │   Flex Lexical Analyzer   │  ──> Token Stream:
       │         (lexer.l)         │      ID, NUM, WHILE, IF, ELSE, ASSIGN, etc.
       └───────────────────────────┘
                     │
                     ▼
       ┌───────────────────────────┐
       │  Bison LALR(1) Parser     │  ──> Bottom-Up Shift-Reduce Parsing with
       │         (parser.y)        │      Syntax-Directed Translation (SDT)
       └───────────────────────────┘
                     │
                     ▼
       ┌───────────────────────────┐
       │  3AC Code Generator (SDT) │  ──> Temporary variables (t1, t2, ...) &
       │  (Mid-Rule Semantic Engine)│     Symbolic labels (L1, L2, ...)
       └───────────────────────────┘
                     │
                     ▼
       Linearized Three-Address Code (3AC)
```

### Role of Intermediate Code in Compiler Design
In modern compiler architecture, intermediate representations serve as the abstraction barrier between the front-end (source language syntax and type checking) and the back-end (instruction selection, register allocation, and machine code generation):
1. **Machine Independence**: 3AC decouples source language syntax from hardware register constraints.
2. **Optimization Pass**: Dataflow analysis, common subexpression elimination (CSE), dead code removal, and loop-invariant code motion operate directly on linearized 3AC basic blocks.

---

## 2. Three-Address Code (3AC) Formal Specification

Each 3AC instruction contains at most one operator and at most three address references (two operands and one result):

| Instruction Type | Quadruple Format | Semantic Meaning |
| :--- | :--- | :--- |
| **Binary Operation** | `t_dest = src1 op src2` | Evaluates binary arithmetic, relational, or logical operation into a new temporary. |
| **Direct Assignment** | `dest = src` | Copies value of variable, literal, or temporary to an identifier. |
| **Conditional Jump** | `iffalse cond goto label` | Branches to target label if condition operand evaluates to false (0). |
| **Unconditional Jump** | `goto label` | Unconditionally redirects control flow to target label. |
| **Label Marker** | `label:` | Marks a symbolic branch target in the instruction stream. |

---

## 3. Syntax-Directed Translation (SDT) Scheme

### Grammar Productions & Semantic Actions

| High-Level Construct | Production Rule | Semantic Action (3AC Emission) |
| :--- | :--- | :--- |
| **Assignment** | `stmt -> ID = expr ;` | `printf("%s = %s\n", $1, $3);` |
| **Binary Ops** | `expr -> expr op expr` | `$$ = newtemp(); printf("%s = %s op %s\n", $$, $1, $3);` |
| **Sub-expression**| `expr -> ( expr )` | `$$ = $2;` |
| **Variable / Num**| `expr -> ID \| NUM` | `$$ = $1;` |

### Control Flow Translation with Mid-Rule Actions

Because control flow constructs (`if-else` and `while`) require jump labels before and around their nested statement bodies, the parser uses **Bison Mid-Rule Actions** to synthesize and emit labels during parsing:

#### If-Else Statement:
```yacc
stmt:
    IF '(' expr ')' {
        /* Mid-rule 1: allocate L_else; emit branch on false */
        $<str>$ = newlabel();
        printf("iffalse %s goto %s\n", $3, $<str>$);
    } '{' stmt_list '}' {
        /* Mid-rule 2: allocate L_exit; emit jump to L_exit; emit L_else */
        $<str>$ = newlabel();
        printf("goto %s\n", $<str>$);
        printf("%s:\n", $<str>5);
    } ELSE '{' stmt_list '}' {
        /* Final: emit L_exit */
        printf("%s:\n", $<str>9);
    }
```

#### While Loop Statement:
```yacc
stmt:
    WHILE {
        /* Mid-rule 1: allocate and emit loop test label L_start */
        $<str>$ = newlabel();
        printf("%s:\n", $<str>$);
    } '(' expr ')' {
        /* Mid-rule 2: allocate L_exit; emit branch on false */
        $<str>$ = newlabel();
        printf("iffalse %s goto %s\n", $4, $<str>$);
    } '{' stmt_list '}' {
        /* Final: jump back to L_start; emit loop exit label L_exit */
        printf("goto %s\n", $<str>2);
        printf("%s:\n", $<str>6);
    }
```

---

## 4. Operator Precedence & Associativity

To avoid ambiguity and shift/reduce conflicts, operator precedence is formally defined from lowest to highest:

| Precedence | Operators | Associativity | Description |
| :---: | :---: | :---: | :--- |
| **1 (Lowest)** | `\|\|` | Left | Logical OR |
| **2** | `&&` | Left | Logical AND |
| **3** | `>`, `<` | Left | Relational Comparisons |
| **4** | `+`, `-` | Left | Additive Arithmetic |
| **5 (Highest)**| `*`, `/` | Left | Multiplicative Arithmetic |

---

## 5. End-to-End Walkthrough: `input.txt`

### Input Mini-C Source Code:
```c
while (x > 0 && y < 10) {
    if (a > b) {
        x = x + 1;
    } else {
        y = y * 2;
    }
}
```

### Generated Three-Address Code (3AC):
```text
L1:
t1 = x > 0
t2 = y < 10
t3 = t1 && t2
iffalse t3 goto L2
t4 = a > b
iffalse t4 goto L3
t5 = x + 1
x = t5
goto L4
L3:
t6 = y * 2
y = t6
L4:
goto L1
L2:
```

### Trace Analysis:
1. `L1:` marks the start of the `while` loop condition check.
2. `t1 = x > 0`, `t2 = y < 10`, `t3 = t1 && t2` evaluate the compound loop guard.
3. `iffalse t3 goto L2` exits the loop to `L2:` if the condition is not met.
4. `t4 = a > b` evaluates the `if` guard.
5. `iffalse t4 goto L3` jumps to the `else` branch (`L3:`) if $a \le b$.
6. `t5 = x + 1; x = t5; goto L4` executes the `then` body and skips over the `else` block to `L4:`.
7. `L3: t6 = y * 2; y = t6;` executes the `else` body.
8. `L4:` is the post-conditional convergence point.
9. `goto L1` jumps back to re-evaluate the while loop guard.
10. `L2:` is the loop termination target.

---

## 6. Build and Execution Instructions

### Prerequisites
- **GCC**: `gcc (MinGW / POSIX C99)`
- **Flex**: Fast Lexical Analyzer (`flex 2.6+`)
- **GNU Bison**: LALR(1) Parser Generator (`bison 3.8+`)
- **GNU Make**: `make 4.0+`

### Quick Start with Make

```bash
# 1. Navigate to the project directory
cd 04-yacc/mini-c-to-3ac

# 2. Build the compiler executable
make

# 3. Run automated test on input.txt
make test

# 4. Clean up generated intermediate files and binary
make clean
```

### Manual Build & Run

```bash
# Generate parser C files from grammar
bison -d parser.y

# Generate lexical scanner C file from flex specification
flex lexer.l

# Compile and link into executable
gcc -Wall -Wextra -std=c99 lex.yy.c parser.tab.c -o compiler

# Run with file argument
./compiler input.txt

# Or run via standard input (stdin)
./compiler < input.txt
```
