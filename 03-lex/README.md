# 03-lex: Lexical Analysis with Lex / Flex

This module explores industrial-grade **Lexical Analysis (Scanning)** using **Lex / Flex**. It bridges formal regular expressions with compiled C scanner engines that feed parsers.

---

## How Lex / Flex Works

Lex translates high-level regular expression pattern rules into a deterministic finite automaton represented as compact C lookup tables:

```text
  +------------------+
  |  scanner.l file  |  (Regex definitions, rules & C code actions)
  +------------------+
           |
           v [flex scanner.l or lex scanner.l]
  +------------------+
  |    lex.yy.c      |  (Generated C source file containing yylex())
  +------------------+
           |
           v [gcc lex.yy.c -lfl -o scanner]
  +------------------+
  | Compiled Scanner |  (Fast O(n) linear stream tokenizer)
  +------------------+
```

### Core Lexer Principles Demonstrated:
1. **Maximal Munch (Longest Match Rule)**: The scanner greedily matches the longest possible valid prefix.
2. **First Rule Priority**: If two patterns match identical prefixes, the rule declared earliest in the `.l` file takes precedence.
3. **Start Conditions (`%x` Exclusive / `%s` Inclusive)**: Implements mini-state machines within the lexer (e.g. tracking multi-line comments or raw string literals).

---

## Planned Projects

### 1. `markdown-lexer/` (.l + Makefile)
- **Objective**: Tokenize structured Markdown documents into an annotated stream of formatting tokens:
  - Headers (`#` through `######`)
  - Unordered / Ordered Lists (`-`, `*`, `1.`)
  - Blockquotes (`>`)
  - Fenced Code Blocks (```)
  - Inline code (`` `inline` ``), bold (`**`), and italic (`*`)
  - Hyperlinks and Markdown tables
- **Deliverables**: `markdown_lexer.l`, `Makefile`, sample input Markdown files, and automated token output validation tests.

---

### 2. `sql-tokenizer/` (.l + Makefile)
- **Objective**: Tokenize standard ANSI SQL queries:
  - DDL / DML Keywords (`SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `TABLE`, `JOIN`, `WHERE`, etc.)
  - Operators (`=`, `<>`, `<=`, `>=`, `AND`, `OR`, `NOT`, `LIKE`, `IN`)
  - Identifiers, string literals (`'value'`), numeric literals, and SQL comments (`--` and `/* ... */`)
  - Precise line and column coordinate tracking for compiler error reporting.
- **Deliverables**: `sql_tokenizer.l`, `Makefile`, and sample SQL query benchmark scripts.

---

## Building and Running Lex Projects

```bash
# Ensure flex/lex and gcc are installed
flex --version
gcc --version

# Build a project
cd 03-lex/markdown-lexer
make

# Run the compiled tokenizer on sample input
./markdown_lexer < sample.md
```

