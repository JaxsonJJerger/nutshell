# Simple Makefile

CC=/usr/bin/cc

all:  flex-config bison-config nutshparser nutshscan nutshell nutshell-out


flex-config:
	flex nutshscanner.l

bison-config:
	bison -d nutshparser.y

nutshscan:  lex.yy.c
	$(CC) -c lex.yy.c -o nutshscan.lex.o


nutshparser:  nutshparser.tab.c 
	$(CC) -c nutshparser.tab.c -o nutshparser.y.o


nutshell:  nutshell.c
	$(CC) -g -c nutshell.c -o nutshell.o 

nutshell-out: 
	$(CC) -o nutshell nutshell.o nutshscan.lex.o nutshparser.y.o -ll -lm -lfl

clean:
	rm *.o
	rm *.tab.*
	rm nutshell
	rm *.yy.c
