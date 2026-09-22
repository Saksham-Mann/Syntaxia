# ==============================================================================
# Makefile: ANSI SQL Lexical Analyzer & Query Tokenizer
# Tools: Flex (Fast Lexical Analyzer Generator), GCC (C99 Compiler)
# ==============================================================================

CC = gcc
CFLAGS = -Wall -Wextra -std=c99
LEX = flex
TARGET = sql_tokenizer

.SUFFIXES:
.PHONY: all clean test

all: $(TARGET)

lex.yy.c: sql_tokenizer.l
	$(LEX) sql_tokenizer.l

$(TARGET): lex.yy.c
	$(CC) $(CFLAGS) lex.yy.c -o $(TARGET)

test: $(TARGET)
	./$(TARGET) test_input.sql

clean:
ifeq ($(OS),Windows_NT)
	cmd /c "if exist $(TARGET) del /f /q $(TARGET)"
	cmd /c "if exist $(TARGET).exe del /f /q $(TARGET).exe"
	cmd /c "if exist lex.yy.c del /f /q lex.yy.c"
	cmd /c "if exist *.o del /f /q *.o"
else
	rm -f $(TARGET) $(TARGET).exe lex.yy.c *.o
endif
