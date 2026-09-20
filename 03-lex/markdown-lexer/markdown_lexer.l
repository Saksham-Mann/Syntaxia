%{
/*
 * ==============================================================================
 * Markdown to Clean HTML Lexer
 * Language: C (C99 Standard) using Flex (Lexical Analyzer Generator)
 * ==============================================================================
 *
 * WHAT THIS FILE DOES:
 * --------------------
 * This file is a Lexical Analyzer (lexer / scanner). It reads a Markdown file
 * character-by-character and translates Markdown formatting into clean HTML5.
 *
 * HOW FLEX WORKS:
 * ---------------
 * Flex turns the regular expressions defined below into a C function called
 * yylex(). Whenever Flex matches a pattern in the text, it executes the C code
 * inside the curly braces { ... }.
 *
 * We use two main states (Start Conditions):
 * 1. LINE_START - Active only at the start of a line. This is where we detect
 *    block-level items like headings (#), lists (-, 1.), blockquotes (>),
 *    code fences (```), and blank lines.
 * 2. INITIAL    - Active while reading normal text inside a line. This is where
 *    we detect inline styling like **bold**, *italic*, `code`, links, and images.
 * 3. CODE_BLOCK - An exclusive state for fenced code blocks (```). While inside
 *    code blocks, all markdown formatting is disabled and <, >, & are escaped.
 * ==============================================================================
 */

#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

/*
 * ListType keeps track of whether we are inside:
 * - LIST_NONE: Not inside any list
 * - LIST_UL:   Inside an unordered bullet list (<ul>)
 * - LIST_OL:   Inside an ordered numbered list (<ol>)
 */
typedef enum {
    LIST_NONE = 0,
    LIST_UL,
    LIST_OL
} ListType;

/*
 * State tracking flags for block-level elements:
 * These variables remember what HTML tags are currently open so we can
 * close them properly when a block ends or when the file finishes.
 */
static int in_paragraph = 0;       /* 1 if we are currently inside a <p> tag, 0 otherwise */
static int pending_newline = 0;     /* Remembers to print a newline only if the paragraph continues */
static ListType current_list = LIST_NONE; /* Tracks if <ul> or <ol> is open */
static int in_li = 0;              /* 1 if an <li> item is currently open */
static int in_blockquote = 0;      /* 1 if a <blockquote> tag is currently open */
static int in_heading = 0;         /* Stores the heading level (1 for <h1>, 2 for <h2>, etc., 0 if none) */

/*
 * State tracking flags for inline text formatting:
 * When we see an opening delimiter (like **), we turn on bold. When we see
 * the matching delimiter later, we turn it off and close the HTML tag.
 */
static int in_bold_star = 0;    /* Tracks **bold** (using asterisks) */
static int in_bold_under = 0;   /* Tracks __bold__ (using underscores) */
static int in_italic_star = 0;  /* Tracks *italic* (using asterisks) */
static int in_italic_under = 0; /* Tracks _italic_ (using underscores) */
static int in_strike = 0;       /* Tracks ~~strikethrough~~ */

/* Remembers where a fenced code block started, so we can warn the user if they forgot to close it */
static int code_block_start_line = 0;

/*
 * check_paragraph_newline():
 * If we are inside a multi-line paragraph and previous line ended,
 * we emit the deferred newline now because new text has arrived on the next line.
 */
static void check_paragraph_newline(void) {
    if (in_paragraph && pending_newline) {
        fputc('\n', yyout);
        pending_newline = 0;
    }
}

/*
 * close_inline_tags():
 * Closes any inline styling tags (<em>, <strong>, <del>) that were left unclosed.
 * This prevents unclosed styling tags from spilling over into other blocks or lines.
 */
static void close_inline_tags(void) {
    if (in_italic_star) {
        fputs("</em>", yyout);
        in_italic_star = 0;
    }
    if (in_italic_under) {
        fputs("</em>", yyout);
        in_italic_under = 0;
    }
    if (in_bold_star) {
        fputs("</strong>", yyout);
        in_bold_star = 0;
    }
    if (in_bold_under) {
        fputs("</strong>", yyout);
        in_bold_under = 0;
    }
    if (in_strike) {
        fputs("</del>", yyout);
        in_strike = 0;
    }
}

/*
 * close_li():
 * Closes the current list item </li> if one is open.
 */
static void close_li(void) {
    if (in_li) {
        close_inline_tags();
        fputs("</li>\n", yyout);
        in_li = 0;
    }
}

/*
 * close_list():
 * Closes the active list (</ul> or </ol>) and resets list tracking.
 */
static void close_list(void) {
    close_li();
    if (current_list == LIST_UL) {
        fputs("</ul>\n", yyout);
        current_list = LIST_NONE;
    } else if (current_list == LIST_OL) {
        fputs("</ol>\n", yyout);
        current_list = LIST_NONE;
    }
}

/*
 * close_blockquote():
 * Closes the active blockquote (</blockquote>) if one is open.
 */
static void close_blockquote(void) {
    if (in_blockquote) {
        close_inline_tags();
        fputs("</blockquote>\n", yyout);
        in_blockquote = 0;
    }
}

/*
 * close_paragraph():
 * Closes the active paragraph (<p>) with </p>\n if one is open.
 */
static void close_paragraph(void) {
    if (in_paragraph) {
        close_inline_tags();
        fputs("</p>\n", yyout);
        in_paragraph = 0;
        pending_newline = 0;
    }
}

/*
 * close_all_blocks():
 * Convenience helper to close all currently open block elements:
 * paragraphs, lists, blockquotes, and headings.
 * Called on blank lines, new headings, code blocks, and at End-of-File (EOF).
 */
static void close_all_blocks(void) {
    close_paragraph();
    close_list();
    close_blockquote();
    if (in_heading > 0) {
        close_inline_tags();
        fprintf(yyout, "</h%d>\n", in_heading);
        in_heading = 0;
    }
}

/*
 * Toggling functions for inline emphasis:
 * If the tag is closed, open it. If it is already open, close it.
 */

/* Toggles *** (both bold and italic at once) */
static void toggle_bold_italic(void) {
    if (!in_bold_star && !in_italic_star) {
        fputs("<strong><em>", yyout);
        in_bold_star = 1;
        in_italic_star = 1;
    } else if (in_bold_star && in_italic_star) {
        fputs("</em></strong>", yyout);
        in_bold_star = 0;
        in_italic_star = 0;
    } else if (in_bold_star) {
        fputs("</strong><em>", yyout);
        in_bold_star = 0;
        in_italic_star = 1;
    } else {
        fputs("</em><strong>", yyout);
        in_italic_star = 0;
        in_bold_star = 1;
    }
}

/* Toggles **bold** */
static void toggle_bold_star(void) {
    if (!in_bold_star) {
        fputs("<strong>", yyout);
        in_bold_star = 1;
    } else {
        fputs("</strong>", yyout);
        in_bold_star = 0;
    }
}

/* Toggles __bold__ */
static void toggle_bold_under(void) {
    if (!in_bold_under) {
        fputs("<strong>", yyout);
        in_bold_under = 1;
    } else {
        fputs("</strong>", yyout);
        in_bold_under = 0;
    }
}

/* Toggles *italic* */
static void toggle_italic_star(void) {
    if (!in_italic_star) {
        fputs("<em>", yyout);
        in_italic_star = 1;
    } else {
        fputs("</em>", yyout);
        in_italic_star = 0;
    }
}

/* Toggles _italic_ */
static void toggle_italic_under(void) {
    if (!in_italic_under) {
        fputs("<em>", yyout);
        in_italic_under = 1;
    } else {
        fputs("</em>", yyout);
        in_italic_under = 0;
    }
}

/* Toggles ~~strikethrough~~ */
static void toggle_strike(void) {
    if (!in_strike) {
        fputs("<del>", yyout);
        in_strike = 1;
    } else {
        fputs("</del>", yyout);
        in_strike = 0;
    }
}

/*
 * emit_inline_code():
 * Emits inline `code` wrapped inside <code>...</code>.
 * Special HTML characters (<, >, &) are safely converted to &lt;, &gt;, &amp;.
 */
static void emit_inline_code(const char *str, int len) {
    fputs("<code>", yyout);
    for (int i = 0; i < len; i++) {
        switch (str[i]) {
            case '<': fputs("&lt;", yyout); break;
            case '>': fputs("&gt;", yyout); break;
            case '&': fputs("&amp;", yyout); break;
            default:  fputc(str[i], yyout); break;
        }
    }
    fputs("</code>", yyout);
}

/*
 * emit_link():
 * Parses [text](url) and emits <a href="url">text</a>.
 */
static void emit_link(const char *raw, int len) {
    (void)len;
    const char *close_sq = strchr(raw, ']');
    if (!close_sq) {
        fputs(raw, yyout);
        return;
    }
    const char *open_paren = strchr(close_sq, '(');
    const char *close_paren = strrchr(close_sq, ')');
    if (!open_paren || !close_paren || close_paren <= open_paren) {
        fputs(raw, yyout);
        return;
    }

    char text[1024];
    char url[2048];

    int text_len = (int)(close_sq - (raw + 1));
    if (text_len < 0) text_len = 0;
    if (text_len >= (int)sizeof(text)) text_len = sizeof(text) - 1;
    strncpy(text, raw + 1, (size_t)text_len);
    text[text_len] = '\0';

    int url_len = (int)(close_paren - (open_paren + 1));
    if (url_len < 0) url_len = 0;
    if (url_len >= (int)sizeof(url)) url_len = sizeof(url) - 1;
    strncpy(url, open_paren + 1, (size_t)url_len);
    url[url_len] = '\0';

    fprintf(yyout, "<a href=\"%s\">%s</a>", url, text);
}

/*
 * emit_image():
 * Parses ![alt](url) and emits <img src="url" alt="alt" />.
 */
static void emit_image(const char *raw, int len) {
    (void)len;
    const char *close_sq = strchr(raw + 1, ']');
    if (!close_sq) {
        fputs(raw, yyout);
        return;
    }
    const char *open_paren = strchr(close_sq, '(');
    const char *close_paren = strrchr(close_sq, ')');
    if (!open_paren || !close_paren || close_paren <= open_paren) {
        fputs(raw, yyout);
        return;
    }

    char alt[1024];
    char url[2048];

    int alt_len = (int)(close_sq - (raw + 2));
    if (alt_len < 0) alt_len = 0;
    if (alt_len >= (int)sizeof(alt)) alt_len = sizeof(alt) - 1;
    strncpy(alt, raw + 2, (size_t)alt_len);
    alt[alt_len] = '\0';

    int url_len = (int)(close_paren - (open_paren + 1));
    if (url_len < 0) url_len = 0;
    if (url_len >= (int)sizeof(url)) url_len = sizeof(url) - 1;
    strncpy(url, open_paren + 1, (size_t)url_len);
    url[url_len] = '\0';

    fprintf(yyout, "<img src=\"%s\" alt=\"%s\" />", url, alt);
}
%}

/* Flex Options */
%option noyywrap
%option nounput
%option noinput
%option yylineno

/*
 * Start Conditions (States):
 * - LINE_START: Active at the start of every line to match block-level elements
 * - CODE_BLOCK: Exclusive (%x) state for multi-line fenced code blocks (```)
 */
%x LINE_START
%x CODE_BLOCK

%%

    /* =========================================================================
     * SECTION 1: LINE_START State Rules
     * These rules only trigger at the beginning of a line.
     * ========================================================================= */

    /* Rule 1.1: Blank line (empty or spaces only) - Closes any open paragraph, list, or blockquote */
<LINE_START>^[ \t]*\r?\n {
    close_all_blocks();
}

    /* Rule 1.2: Fenced code block opening (```c, ```html, or ```) */
<LINE_START>^"```"([a-zA-Z0-9_-]*)[ \t]*\r?\n {
    close_all_blocks();

    /* Extract optional language tag (e.g., "c", "python", "html") */
    char lang[64] = {0};
    const char *p = yytext + 3;
    while (*p == ' ' || *p == '\t') p++;
    int i = 0;
    while (*p && *p != ' ' && *p != '\t' && *p != '\r' && *p != '\n' && i < 63) {
        lang[i++] = *p++;
    }
    lang[i] = '\0';

    /* Output <pre><code class="language-xyz"> if a language was given */
    if (i > 0) {
        fprintf(yyout, "<pre><code class=\"language-%s\">", lang);
    } else {
        fputs("<pre><code>", yyout);
    }

    code_block_start_line = yylineno;
    BEGIN(CODE_BLOCK); /* Enter exclusive code block state */
}

    /* Rule 1.3: ATX Headings (# through ######) */
<LINE_START>^(#{1,6})[ \t]+ {
    close_all_blocks();

    /* Count how many '#' characters were matched to determine the heading level */
    int level = 0;
    while (yytext[level] == '#') level++;
    in_heading = level;
    fprintf(yyout, "<h%d>", level);
    BEGIN(INITIAL); /* Switch to INITIAL state to parse inline text inside the heading */
}

    /* Rule 1.4: Horizontal Rule (---, ***, or ___) */
<LINE_START>^[ \t]*(\*\*\*|---|___)[ \t]*(\r?\n|$) {
    close_all_blocks();
    fputs("<hr />\n", yyout);
}

    /* Rule 1.5: Unordered List Item (- item, * item, + item) */
<LINE_START>^[ \t]*[-*+][ \t]+ {
    close_paragraph();
    close_blockquote();

    /* If we were in an ordered list, close it first */
    if (current_list == LIST_OL) {
        close_list();
    }
    /* If this is the start of a new unordered list, open <ul> */
    if (current_list == LIST_NONE) {
        fputs("<ul>\n", yyout);
        current_list = LIST_UL;
    }
    /* If a previous list item is still open, close it */
    if (in_li) {
        close_li();
    }
    fputs("  <li>", yyout);
    in_li = 1;
    BEGIN(INITIAL); /* Switch to INITIAL to parse list item content */
}

    /* Rule 1.6: Ordered List Item (1. item, 2. item) */
<LINE_START>^[ \t]*[0-9]+\.[ \t]+ {
    close_paragraph();
    close_blockquote();

    /* If we were in an unordered list, close it first */
    if (current_list == LIST_UL) {
        close_list();
    }
    /* If this is the start of a new ordered list, open <ol> */
    if (current_list == LIST_NONE) {
        fputs("<ol>\n", yyout);
        current_list = LIST_OL;
    }
    /* If a previous list item is still open, close it */
    if (in_li) {
        close_li();
    }
    fputs("  <li>", yyout);
    in_li = 1;
    BEGIN(INITIAL); /* Switch to INITIAL to parse list item content */
}

    /* Rule 1.7: Blockquote Line (> Quote text) */
<LINE_START>^[ \t]*>[ \t]? {
    close_paragraph();
    close_list();

    /* If this is the first line of the quote, open <blockquote> */
    if (!in_blockquote) {
        fputs("<blockquote>\n", yyout);
        in_blockquote = 1;
    }
    fputs("  ", yyout);
    BEGIN(INITIAL); /* Switch to INITIAL to parse quote text */
}

    /* Rule 1.8: Regular Text Line (Default fallback) */
<LINE_START>. {
    /* Push back the character we matched so it can be re-read in INITIAL state */
    yyless(0);

    /* Close any lingering list or blockquote because this line is regular text */
    close_list();
    close_blockquote();

    /* If we are not already in a paragraph, open <p> */
    if (!in_paragraph) {
        fputs("<p>", yyout);
        in_paragraph = 1;
        pending_newline = 0;
    }
    BEGIN(INITIAL);
}

    /* Rule 1.9: End of File reached at start of a line */
<LINE_START><<EOF>> {
    close_all_blocks();
    yyterminate();
}

    /* =========================================================================
     * SECTION 2: CODE_BLOCK Exclusive State Rules
     * Inside ``` code fences. Normal Markdown formatting is completely ignored.
     * All characters <, >, & are escaped to prevent raw HTML injection.
     * ========================================================================= */

    /* Closing code fence: ``` */
<CODE_BLOCK>^"```"[ \t]*(\r?\n|$) {
    fputs("</code></pre>\n", yyout);
    BEGIN(LINE_START); /* Return to line start state */
}

    /* Escape HTML special characters inside code */
<CODE_BLOCK>"<" { fputs("&lt;", yyout); }
<CODE_BLOCK>">" { fputs("&gt;", yyout); }
<CODE_BLOCK>"&" { fputs("&amp;", yyout); }
<CODE_BLOCK>\r  { /* ignore carriage return on Windows */ }
<CODE_BLOCK>\n  { fputc('\n', yyout); }
<CODE_BLOCK>.   { fputc(yytext[0], yyout); }

    /* Warning if the file ends without closing the code fence */
<CODE_BLOCK><<EOF>> {
    fprintf(stderr, "Warning: line %d: unclosed fenced code block starting at line %d\n",
            yylineno, code_block_start_line);
    fputs("</code></pre>\n", yyout);
    BEGIN(LINE_START);
    yyterminate();
}

    /* =========================================================================
     * SECTION 3: INITIAL State Rules
     * Active while parsing text inside headings, paragraphs, lists, and quotes.
     * ========================================================================= */

    /* Optional trailing hashes on ATX headings (e.g. "## Heading ##\n") */
<INITIAL>[ \t]+#+[ \t]*\r?\n {
    if (in_heading > 0) {
        close_inline_tags();
        fprintf(yyout, "</h%d>\n", in_heading);
        in_heading = 0;
        BEGIN(LINE_START);
    } else {
        check_paragraph_newline();
        fputs(yytext, yyout);
    }
}

    /* End-of-line newline handling */
<INITIAL>\r?\n {
    if (in_heading > 0) {
        close_inline_tags();
        fprintf(yyout, "</h%d>\n", in_heading);
        in_heading = 0;
        BEGIN(LINE_START);
    } else if (in_li) {
        close_inline_tags();
        fputs("</li>\n", yyout);
        in_li = 0;
        BEGIN(LINE_START);
    } else if (in_blockquote) {
        close_inline_tags();
        fputc('\n', yyout);
        BEGIN(LINE_START);
    } else if (in_paragraph) {
        close_inline_tags();
        pending_newline = 1; /* Defer newline: output only if paragraph continues */
        BEGIN(LINE_START);
    } else {
        close_inline_tags();
        fputc('\n', yyout);
        BEGIN(LINE_START);
    }
}

    /* Inline Code: `some code` */
<INITIAL>`([^`\r\n]+)` {
    check_paragraph_newline();
    emit_inline_code(yytext + 1, yyleng - 2);
}

    /* Images: ![alt](url) (must be placed before links so '!' is included) */
<INITIAL>!\[([^\]\r\n]*)\]\(([^)\r\n]+)\) {
    check_paragraph_newline();
    emit_image(yytext, yyleng);
}

    /* Hyperlinks: [text](url) */
<INITIAL>\[([^\]\r\n]+)\]\(([^)\r\n]+)\) {
    check_paragraph_newline();
    emit_link(yytext, yyleng);
}

    /* Combined Bold & Italic: ***text*** */
<INITIAL>\*\*\* {
    check_paragraph_newline();
    toggle_bold_italic();
}

    /* Bold: **text** */
<INITIAL>\*\* {
    check_paragraph_newline();
    toggle_bold_star();
}

    /* Bold: __text__ */
<INITIAL>__ {
    check_paragraph_newline();
    toggle_bold_under();
}

    /* Isolated asterisk with spaces around it (e.g. arithmetic "5 * 10") - Keep as literal '*' */
<INITIAL>[ \t]+\*[ \t]+ {
    check_paragraph_newline();
    fputs(yytext, yyout);
}

    /* Isolated underscore with spaces around it - Keep as literal '_' */
<INITIAL>[ \t]+_[ \t]+ {
    check_paragraph_newline();
    fputs(yytext, yyout);
}

    /* Identifiers with underscores (e.g. user_id_count) - Keep as literal text, not italic */
<INITIAL>[a-zA-Z0-9]+(_[a-zA-Z0-9]+)+ {
    check_paragraph_newline();
    fputs(yytext, yyout);
}

    /* Backslash escapes: \* \_ \~ \` \[ \] \\ -> print literal character */
<INITIAL>\\([*_\~`\[\]\\]) {
    check_paragraph_newline();
    fputc(yytext[1], yyout);
}

    /* Italic: *text* */
<INITIAL>\* {
    check_paragraph_newline();
    toggle_italic_star();
}

    /* Italic: _text_ */
<INITIAL>_ {
    check_paragraph_newline();
    toggle_italic_under();
}

    /* Strikethrough: ~~text~~ */
<INITIAL>~~ {
    check_paragraph_newline();
    toggle_strike();
}

    /* Passthrough for existing named HTML entities (e.g. &copy;, &amp;) */
<INITIAL>"&"[a-zA-Z0-9]+";" {
    check_paragraph_newline();
    fputs(yytext, yyout);
}

    /* Passthrough for decimal entities (e.g. &#160;) */
<INITIAL>"&#"[0-9]+";" {
    check_paragraph_newline();
    fputs(yytext, yyout);
}

    /* Passthrough for hex entities (e.g. &#xA0;) */
<INITIAL>"&#x"[0-9a-fA-F]+";" {
    check_paragraph_newline();
    fputs(yytext, yyout);
}

    /* Passthrough for inline HTML tags (e.g. <kbd>Ctrl+C</kbd>, <br />) */
<INITIAL>"<"[a-zA-Z/][^>\r\n]*">" {
    check_paragraph_newline();
    fputs(yytext, yyout);
}

    /* Convert bare < to &lt; */
<INITIAL>"<" {
    check_paragraph_newline();
    fputs("&lt;", yyout);
}

    /* Convert bare > to &gt; */
<INITIAL>">" {
    check_paragraph_newline();
    fputs("&gt;", yyout);
}

    /* Convert bare & to &amp; */
<INITIAL>"&" {
    check_paragraph_newline();
    fputs("&amp;", yyout);
}

    /* Normal alphanumeric words */
<INITIAL>[a-zA-Z0-9]+ {
    check_paragraph_newline();
    fputs(yytext, yyout);
}

    /* Spaces and tabs */
<INITIAL>[ \t]+ {
    check_paragraph_newline();
    fputs(yytext, yyout);
}

    /* Any other single character (punctuation, symbols) */
<INITIAL>. {
    check_paragraph_newline();
    fputc(yytext[0], yyout);
}

    /* End of file reached while inside INITIAL state */
<INITIAL><<EOF>> {
    close_inline_tags();
    if (in_heading > 0) {
        fprintf(yyout, "</h%d>\n", in_heading);
        in_heading = 0;
    }
    close_all_blocks();
    yyterminate();
}

%%

/* =============================================================================
 * SECTION 4: CLI Driver & main() Function
 * ============================================================================= */

/* Prints command line usage instructions */
static void print_usage(const char *prog_name) {
    fprintf(stderr,
        "Usage: %s [options] [input.md]\n"
        "A Markdown to Clean HTML Lexer built with Flex and C99.\n\n"
        "Options:\n"
        "  -o <file>       Write HTML output to <file> instead of stdout\n"
        "  -h, --help      Display this help message and exit\n"
        "  -v, --version   Display version information and exit\n\n"
        "If no input file is provided, input is read directly from standard input (stdin).\n",
        prog_name);
}

int main(int argc, char **argv) {
    const char *input_path = NULL;
    const char *output_path = NULL;

    /* Parse command-line flags and arguments */
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        } else if (strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "--version") == 0) {
            printf("markdown_lexer 1.0.0 (Flex / C99)\n");
            return 0;
        } else if (strcmp(argv[i], "-o") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Error: -o option requires an output filename argument\n");
                print_usage(argv[0]);
                return 1;
            }
            output_path = argv[++i];
        } else if (argv[i][0] == '-') {
            fprintf(stderr, "Error: unrecognized option '%s'\n", argv[i]);
            print_usage(argv[0]);
            return 1;
        } else {
            if (input_path == NULL) {
                input_path = argv[i];
            } else {
                fprintf(stderr, "Error: multiple input files specified: '%s' and '%s'\n",
                        input_path, argv[i]);
                print_usage(argv[0]);
                return 1;
            }
        }
    }

    /* Open input file, or default to stdin */
    if (input_path != NULL) {
        yyin = fopen(input_path, "r");
        if (!yyin) {
            fprintf(stderr, "Error: cannot open input file '%s'\n", input_path);
            perror("Reason");
            return 1;
        }
    } else {
        yyin = stdin;
    }

    /* Open output file, or default to stdout */
    if (output_path != NULL) {
        yyout = fopen(output_path, "w");
        if (!yyout) {
            fprintf(stderr, "Error: cannot open output file '%s'\n", output_path);
            perror("Reason");
            if (yyin != stdin) fclose(yyin);
            return 1;
        }
    } else {
        yyout = stdout;
    }

    /* Start scanning at the beginning of the first line */
    BEGIN(LINE_START);

    /* Run the Flex lexer until EOF */
    yylex();

    /* Flush and close any remaining open HTML blocks */
    close_all_blocks();

    /* Clean up file handles */
    if (yyin && yyin != stdin) {
        fclose(yyin);
    }
    if (yyout && yyout != stdout) {
        fclose(yyout);
    }

    /* Clean up internal Flex memory */
    yylex_destroy();
    return 0;
}
