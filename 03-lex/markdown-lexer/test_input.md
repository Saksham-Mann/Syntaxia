# Compiler Design & Formal Grammars

A comprehensive test suite for the **Flex-based Markdown Lexer** written in standard C99.

## Overview & Architecture

Markdown is a lightweight markup language with a plain-text formatting syntax. This lexer transforms raw text streams into semantic HTML5.

### Supported ATX Heading Levels
#### Heading Level 4
##### Heading Level 5
###### Heading Level 6

---

## Typography and Text Styling

Here is a paragraph demonstrating *italic text with asterisks*, _italic with underscores_, **bold text with asterisks**, and __bold with underscores__.

You can also combine formatting: ***bold and italic combined***, or write ~~strikethrough text~~ with tildes.
Mathematical expressions like 5 * 10 = 50 and identifiers like user_id_count remain unaffected by emphasis rules.

Inline code is protected: `int count = (x < 10 && y > 20);` with escaped entities.

Here is an inline link to [Compiler Suite Documentation](https://github.com/compiler-suite) and an image:
![Compiler Pipeline Diagram](https://example.org/assets/compiler-pipeline.png)

***

## Structural Code Blocks

```c
#include <stdio.h>

int main(void) {
    int alpha = 42;
    if (alpha > 0 && alpha < 100) {
        printf("Value is valid: %d & active!\n", alpha);
    }
    return 0;
}
```

```html
<div class="compiler-box">
  <span id="badge">Status & Progress</span>
</div>
```

```
Generic fenced block without a language specifier.
No markdown parsing *here* or **there**!
```

---

## Blockquotes & Citations

> The purpose of computing is insight, not numbers.
> Simple quotes can span multiple lines seamlessly.

> A second isolated quote block.

---

## Lists & Enumerations

### Unordered Features
- Deterministic finite automaton lookup tables
- High-throughput O(n) stream processing
- Robust memory management with C99 standard

### Alternative Bullets
* Star bullet one
* Star bullet two with **strong emphasis**
* Star bullet three

### Ordered Pipeline Steps
1. Lexical Analysis (Scanning with Flex)
2. Syntactic Analysis (Parsing with Bison)
3. Intermediate Representation generation
4. Target Code Generation

Raw HTML like <kbd>Ctrl+C</kbd> and entities like &copy; 2026 &amp; &lt;models&gt; pass through cleanly.
