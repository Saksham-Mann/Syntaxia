# Syntaxia
### Models of Computation, Automata Theory & Compiler Design Suite

[![Language - Python 3](https://img.shields.io/badge/Language-Python%203.9+-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Tool - Lex / Flex](https://img.shields.io/badge/Lexer-Lex%20%2F%20Flex-orange)](#03-lex)
[![Tool - Bison / Yacc](https://img.shields.io/badge/Parser-Bison%2FYacc-blue)](#04-yacc)
[![Tool - JFLAP](https://img.shields.io/badge/Automata-JFLAP%20v7.1-green)](#02-jflap)
[![Status - Active Development](https://img.shields.io/badge/Status-Active%20Development-brightgreen)](#)

**Syntaxia** is a structured, end-to-end laboratory and reference suite demonstrating the principles of **Formal Languages, Automata Theory, and Compiler Construction**. From pattern matching via regular expressions and state-transition automata in JFLAP, to production-grade lexical analysis with Lex/Flex and LALR(1) parsing with Yacc/Bison, Syntaxia bridges pure mathematical computation models with practical systems engineering.

---

## Theoretical Foundations & The Chomsky Hierarchy

| Level | Language Class | Automaton Model | Grammar Type | Syntaxia Component |
| :--- | :--- | :--- | :--- | :--- |
| **Type-3** | **Regular Languages** | Finite State Automata (DFA / NFA) | Regular Grammar | `01-regex/`, `02-jflap/literal-lexer-dfa`, `03-lex/` |
| **Type-2** | **Context-Free Languages** | Pushdown Automata (PDA) | Context-Free Grammar (CFG) | `02-jflap/syntax-pda`, `04-yacc/` |
| **Type-1** | **Context-Sensitive Languages** | Linear Bounded Automata (LBA) | Context-Sensitive Grammar | Semantic Analysis & Type Checking |
| **Type-0** | **Recursively Enumerable** | Turing Machine (TM) | Unrestricted Grammar | Intermediate Code (3AC) & Execution |

---

## Repository Architecture

```text
Syntaxia/
├── 01-regex/
│   ├── README.md                # Regular language theory, engines, and ReDoS safety
│   ├── secret-scanner/          # Project 1: Zero-dependency security credential scanner (Python)
│   │   ├── README.md
│   │   ├── secret_scanner.py
│   │   └── fixtures/
│   └── log-analyzer/            # Project 2: Web & system log analyzer specification
│       └── README.md
├── 02-jflap/
│   ├── README.md                # Automata design and state transition specifications
│   ├── syntax-pda/              # Project 1: Balanced syntax & expression pushdown automaton
│   └── literal-lexer-dfa/       # Project 2: Numerical and string literal deterministic finite automaton
├── 03-lex/
│   ├── README.md                # Lexical analysis architecture & token streaming
│   ├── markdown-lexer/          # Project 1: Markdown markup tokenizer (.l + Makefile)
│   └── sql-tokenizer/           # Project 2: SQL query dialect tokenizer (.l + Makefile)
├── 04-yacc/
│   ├── README.md                # LALR(1) shift-reduce parsing & syntax-directed translation
│   ├── matrix-interpreter/      # Project 1: Matrix arithmetic grammar interpreter (.l, .y, + Makefile)
│   └── mini-c-to-3ac/           # Project 2: Mini-C compiler front-end emitting Three-Address Code
├── docs/                        # Formal proofs, state diagrams, grammar specifications, and lab reports
└── README.md                    # Root documentation and execution instructions
```

---

## Module Overview

### [01. Regular Expressions (`01-regex/`)](01-regex/)
Explores regular expression compilation, non-deterministic finite automata (NFA) simulation, and Catastrophic Backtracking (ReDoS) mitigation using Python's standard library.
- **[Secret Scanner](01-regex/secret-scanner/)**: Scans source code and configuration files for leaked AWS, GitHub, Stripe, Slack, and generic credentials with zero dependencies and regex safety lookarounds.
- **[Log Analyzer](01-regex/log-analyzer/)**: Ingests Common/Combined Nginx/Apache logs and Syslog files, extracting structured metrics and detecting web attack patterns (SQL injection, path traversal, XSS, sensitive resource enumeration).

### [02. Automata Modeling with JFLAP (`02-jflap/`)](02-jflap/)
Visual and mathematical modeling of state machines using JFLAP v7.1.
- **Syntax PDA (`syntax-pda`)**: A non-deterministic/deterministic pushdown automaton verifying nested parentheses, brackets, and arithmetic syntax validity.
- **Literal Lexer DFA (`literal-lexer-dfa`)**: A minimal DFA that categorizes integer, floating-point, hexadecimal, and string literals with escape sequences.

### [03. Lexical Analysis with Lex (`03-lex/`)](03-lex/)
Generates high-performance C lexical analyzers using Lex / Flex.
- **Markdown Lexer (`markdown-lexer`)**: Converts raw Markdown documents into structural tokens (headers, blockquotes, code fences, emphasis, tables).
- **SQL Tokenizer (`sql-tokenizer`)**: Tokenizes ANSI SQL queries into keywords, operators, identifiers, and literals with source position tracking.

### [04. Syntax Analysis & Translation with Yacc (`04-yacc/`)](04-yacc/)
Parser generation, syntax tree evaluation, and intermediate representation using Bison/Yacc.
- **Matrix Interpreter (`matrix-interpreter`)**: Evaluates multidimensional matrix arithmetic expressions (addition, multiplication, scalar scaling, transposition) using an LALR(1) grammar.
- **Mini-C to 3AC (`mini-c-to-3ac`)**: Compiles a subset of C (control flow, variable declarations, arithmetic) into linearized Three-Address Code (3AC) quadruples.

---

## Prerequisites & Installation

### Requirements
- **Python**: 3.9 or higher (standard library only for `01-regex`)
- **C Compiler**: GCC / Clang
- **Lexer & Parser Generators**: `flex` and `bison` (or `byacc`)
- **Automata Visualizer**: [JFLAP 7.1](https://www.jflap.org/) (requires Java JRE 8+)
- **Build Tool**: GNU `make`

### Quick Start (Regex Projects)

```bash
# Clone repository
git clone https://github.com/Saksham-Mann/Syntaxia.git
cd Syntaxia

# Run Secret Scanner self-tests
python 01-regex/secret-scanner/secret_scanner.py --test

# Scan sample fixtures for credentials
python 01-regex/secret-scanner/secret_scanner.py 01-regex/secret-scanner/fixtures
```

---

## License & Acknowledgments

Developed as part of academic coursework in **Models of Computation / Formal Languages and Automata Theory**.  
Released under the [MIT License](LICENSE).
