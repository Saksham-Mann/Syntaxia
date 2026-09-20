# ==============================================================================
# Makefile: Mini-C to Three-Address Code (3AC) Compiler
# Tools: Flex (Lexer), Bison (Parser), GCC (C99 Compiler)
# ==============================================================================

CC = gcc
CFLAGS = -Wall -Wextra -std=c99
LEX = flex
YACC = bison -d

TARGET = compiler

.SUFFIXES:

.PHONY: all clean test

all: $(TARGET)

parser.tab.c parser.tab.h: parser.y
	$(YACC) parser.y

lex.yy.c: lexer.l parser.tab.h
	$(LEX) lexer.l

$(TARGET): parser.tab.c lex.yy.c
	$(CC) $(CFLAGS) lex.yy.c parser.tab.c -o $(TARGET)

test: $(TARGET)
	./$(TARGET) input.txt

clean:
ifeq ($(OS),Windows_NT)
	cmd /c "if exist $(TARGET) del /f /q $(TARGET)"
	cmd /c "if exist $(TARGET).exe del /f /q $(TARGET).exe"
	cmd /c "if exist parser.tab.c del /f /q parser.tab.c"
	cmd /c "if exist parser.tab.h del /f /q parser.tab.h"
	cmd /c "if exist lex.yy.c del /f /q lex.yy.c"
	cmd /c "if exist *.o del /f /q *.o"
else
	rm -f $(TARGET) $(TARGET).exe parser.tab.c parser.tab.h lex.yy.c *.o
endif
