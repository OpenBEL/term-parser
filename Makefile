# variables
CC="gcc"
CFLAGS=-ggdb -Wall
RAGEL_OPTS=-G2 -L
TEST_LIBS=-lcheck

all:              clean main test

main:             bel-parser.o
	          $(CC) $(CFLAGS) bel-ast.o bel-node-stack.o bel-parser.o term-parser.c -o term-parser

test:             bel-parser.o tests.o
	          $(CC) $(CFLAGS) -o run-tests bel-ast.o bel-node-stack.o bel-parser.o tests.o $(TEST_LIBS)
	          CK_VERBOSITY=verbose ./run-tests

bel-parser.o:     bel-ast.o bel-node-stack.o ragel
	          $(CC) $(CFLAGS) bel-ast.o bel-node-stack.o -c bel-parser.c

bel-node-stack.o: bel-ast.o
	          $(CC) $(CFLAGS) bel-ast.o -c bel-node-stack.c

bel-ast.o:
	          $(CC) $(CFLAGS) -c bel-ast.c

ragel:
	          ragel $(RAGEL_OPTS) bel-parser.rl -o bel-parser.c

tests.o:
	          checkmk *-test.c > tests.c
	          $(CC) $(CFLAGS) -c tests.c

clean:
	          rm -f bel-parser.c tests.c bel-ast.o bel-node-stack.o bel-parser.o tests.o run-tests term-parser

check-ragel:
	          ragel -v
