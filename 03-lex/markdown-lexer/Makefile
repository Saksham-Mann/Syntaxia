# ==============================================================================
# Makefile: Standalone Markdown to Clean HTML Lexer
# Tools: Flex (Fast Lexical Analyzer), GCC (C99 Compiler)
# ==============================================================================

CC = gcc
CFLAGS = -Wall -Wextra -std=c99
LEX = flex
TARGET = markdown_lexer

.SUFFIXES:
.PHONY: all clean test

all: $(TARGET)

lex.yy.c: markdown_lexer.l
	$(LEX) markdown_lexer.l

$(TARGET): lex.yy.c
	$(CC) $(CFLAGS) lex.yy.c -o $(TARGET)

test: $(TARGET)
	./$(TARGET) test_input.md -o test_output.html
ifeq ($(OS),Windows_NT)
	fc.exe test_output.html expected_output.html
else
	diff -u test_output.html expected_output.html
endif
	@echo [SUCCESS] Regression test passed: Output matches reference HTML.

clean:
ifeq ($(OS),Windows_NT)
	cmd /c "if exist $(TARGET) del /f /q $(TARGET)"
	cmd /c "if exist $(TARGET).exe del /f /q $(TARGET).exe"
	cmd /c "if exist lex.yy.c del /f /q lex.yy.c"
	cmd /c "if exist test_output.html del /f /q test_output.html"
	cmd /c "if exist *.o del /f /q *.o"
else
	rm -f $(TARGET) $(TARGET).exe lex.yy.c test_output.html *.o
endif
