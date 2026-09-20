# Markdown to Clean HTML Lexer

A fast, lightweight Markdown to HTML lexer and translator built with **Flex** and **C (C99)**. It converts standard Markdown formatting into clean, semantic HTML5 tags with zero external runtime dependencies.

---

## What It Converts

| Markdown Syntax | Generated HTML Output | Description |
| :--- | :--- | :--- |
| `# Heading 1` | `<h1>Heading 1</h1>` | Headings from `#` (H1) down to `######` (H6) |
| `**bold**` or `__bold__` | `<strong>bold</strong>` | Bold text |
| `*italic*` or `_italic_` | `<em>italic</em>` | Italic text |
| `***bold italic***` | `<strong><em>bold italic</em></strong>` | Combined bold and italic |
| `~~strikethrough~~` | `<del>strikethrough</del>` | Strikethrough text |
| `` `code` `` | `<code>code</code>` | Inline code (escapes `<`, `>`, and `&`) |
| `[Title](url)` | `<a href="url">Title</a>` | Hyperlinks |
| `![Alt](url)` | `<img src="url" alt="Alt" />` | Embedded images |
| `> Quote text` | `<blockquote>...</blockquote>` | Single and multi-line blockquotes |
| `- item` or `* item` | `<ul>\n  <li>item</li>\n</ul>` | Unordered bullet lists |
| `1. item` | `<ol>\n  <li>item</li>\n</ol>` | Ordered numbered lists |
| `---` or `***` | `<hr />` | Horizontal rules |
| `Text paragraph` | `<p>Text paragraph</p>` | Regular text separated by blank lines |
| ```` ```c ... ``` ```` | `<pre><code class="language-c">...</code></pre>` | Fenced code blocks (escapes code entities) |
| `<kbd>Ctrl</kbd>`, `&copy;` | `<kbd>Ctrl</kbd>`, `&copy;` | Raw HTML tags and entities pass through |

---

## How to Build the Program

You only need `gcc`, `flex`, and `make`.

```bash
# Navigate to the project directory
cd 03-lex/markdown-lexer

# Build the executable
make
```

This compiles `markdown_lexer.l` into `markdown_lexer` using `flex` and `gcc -Wall -Wextra -std=c99`.

---

## How to Run the Program

### Basic Syntax
```bash
./markdown_lexer [input.md] [options]
```

### Available Command Line Options

| Option | Description |
| :--- | :--- |
| `-o <file>` | Save HTML output to a target file instead of printing to terminal |
| `-h`, `--help` | Show command usage and options |
| `-v`, `--version` | Display program version |

If no input file is given, the program automatically reads from standard input (`stdin`).

---

## Examples & Test Cases

### 1. Convert a Markdown File to HTML (Print to Terminal)
```bash
./markdown_lexer test_input.md
```

### 2. Convert and Save Directly to a File
```bash
./markdown_lexer test_input.md -o output.html
```

### 3. Stream from Standard Input (Piping)
```bash
cat test_input.md | ./markdown_lexer > output.html
```

### 4. Run the Automated Test Suite
Runs the lexer on `test_input.md` and checks the output against `expected_output.html`:
```bash
make test
```

### 5. Clean Up Build Files
Removes compiled binaries and temporary files:
```bash
make clean
```

---

## How the Code Works (Simple Overview)

1. **Line-Start State (`LINE_START`)**:
   At the beginning of each line, the lexer looks for block structures like `# Headings`, `- List items`, `> Quotes`, `---` horizontal rules, and ```` ``` ```` code fences.
2. **Text State (`INITIAL`)**:
   Inside a line, the lexer scans words and inline formatting like `**bold**`, `*italic*`, `` `inline code` ``, links, and images.
3. **Fenced Code Block State (`CODE_BLOCK`)**:
   When ```` ``` ```` is encountered, the lexer switches to an exclusive state. It turns off all regular Markdown rules so code syntax isn't altered, and converts `<` to `&lt;`, `>` to `&gt;`, and `&` to `&amp;`.
4. **Tag Balancing**:
   The C driver tracks open tags (`in_paragraph`, `in_li`, `in_blockquote`) so every opened HTML tag is properly closed when a blank line arrives or when the file ends.
