# ANSI SQL Lexical Analyzer & Query Tokenizer

A high-performance C lexical analyzer built with **Flex** that scans standard ANSI SQL queries and decomposes them into a stream of categorized tokens with exact line and column coordinate tracking.

---

## 1. Features
- **DDL / DML Keywords**: Recognizes statements and clauses (`SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `DROP`, `ALTER`, `TABLE`, `JOIN`, `WHERE`, `GROUP BY`, `ORDER BY`, `HAVING`, `LIMIT`, etc.) with case insensitivity (`%option caseless`).
- **Data Types**: Identifies standard SQL data types (`INT`, `VARCHAR`, `DECIMAL`, `DATE`, `TIMESTAMP`, `BOOLEAN`, etc.).
- **Operators & Predicates**: Tokenizes comparison (`=`, `<>`, `!=`, `<=`, `>=`), arithmetic (`+`, `-`, `*`, `/`, `%`), string concatenation (`||`), and logical operators (`AND`, `OR`, `NOT`, `LIKE`, `IN`, `BETWEEN`, `IS NULL`).
- **Literals & Identifiers**: Handles single-quoted strings (with escaped quotes), integers, floating-point numbers, scientific notation, and bare/quoted identifiers.
- **Comments**: Filters single-line (`--`) and multi-line (`/* ... */`) comments while accurately tracking line and column offsets.
- **Metrics Summary**: Generates a token distribution summary table upon completion.

---

## 2. Compilation & Execution

```bash
# Build tokenizer executable
cd 03-lex/sql-tokenizer
make

# Run tests on sample SQL input
make test

# Tokenize an arbitrary SQL file
./sql_tokenizer my_query.sql

# Tokenize interactively via standard input
./sql_tokenizer < input.sql
```
