# ==============================================================================
# Makefile: Scientific Matrix & Vector Arithmetic Interpreter
# Tools: Flex (Lexer), Bison (Parser), GCC (C99 Compiler)
# ==============================================================================

CC = gcc
CFLAGS = -Wall -Wextra -std=c99
LEX = flex
YACC = bison -d

TARGET = matrix_interpreter

.SUFFIXES:

.PHONY: all clean test

all: $(TARGET)

matrix.tab.c matrix.tab.h: matrix.y matrix_ops.h
	$(YACC) matrix.y

lex.yy.c: matrix.l matrix.tab.h matrix_ops.h
	$(LEX) matrix.l

$(TARGET): matrix.tab.c lex.yy.c matrix_ops.c matrix_ops.h
	$(CC) $(CFLAGS) matrix_ops.c lex.yy.c matrix.tab.c -o $(TARGET) -lm

test: $(TARGET)
	./$(TARGET) test_input.txt

clean:
ifeq ($(OS),Windows_NT)
	cmd /c "if exist $(TARGET) del /f /q $(TARGET)"
	cmd /c "if exist $(TARGET).exe del /f /q $(TARGET).exe"
	cmd /c "if exist matrix.tab.c del /f /q matrix.tab.c"
	cmd /c "if exist matrix.tab.h del /f /q matrix.tab.h"
	cmd /c "if exist lex.yy.c del /f /q lex.yy.c"
	cmd /c "if exist *.o del /f /q *.o"
else
	rm -f $(TARGET) $(TARGET).exe matrix.tab.c matrix.tab.h lex.yy.c *.o
endif
