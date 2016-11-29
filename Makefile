# @(#)makefile	2.3 1/16/96
# the following can be added to CFLAGS for various things
#
# add -DNOVOID		If your compiler can not handle the void keyword.
# add -DBSD		For BSD4.[23] UNIX Systems.
# add -DDOS		For MS-DOS/PC-DOS Systems, Micro-Soft C 4.0, Turbo C
#				Use the ANSI option.
# add -DNOGETOPT	If your library doesn't have getopt().
#				Another routine will be used in its place.
# add -DNOVARARGS	If you have neither <stdarg.h> (ANSI C) or
#				<varargs.h> (pre-ANSI C).
#				Another method will be compiled instead.
# add -Ddodebug		To compile in debugging trace statements.
# add -Ddoyydebug	To compile in yacc trace statements.
#
# add -DUSE_READLINE	To compile in support for the GNU readline library.

CFLAGS= -g -O2 -std=c89 
# CFLAGS+= -Ddodebug=1
CC= gcc
LIBS= 
ALLFILES= makefile cdgram.y cdlex.l cdecl.c cdecl.1 testset testset++
BINDIR= /usr/bin
MANDIR= /usr/man/man1
CATDIR= /usr/man/cat1
INSTALL= install -c
INSTALL_DATA= install -c -m 644

cdecl: c++decl
	ln -s c++decl cdecl

c++decl: cdgram.c cdlex.c cdecl.c
	$(CC) $(CFLAGS) -o c++decl cdecl.c $(LIBS)
	rm -f cdecl

cdlex.c: cdlex.l
	lex cdlex.l && mv lex.yy.c cdlex.c

cdgram.c: cdgram.y
	yacc cdgram.y && mv y.tab.c cdgram.c

test: cdecl
	@./cdecl < testset | diff -U 3 - test_expected_output.txt \
	  || ( echo "** Test failed **" && false ) \
	  && echo "Tests passed"

test_cpp: c++decl
	./c++decl < testset++

install: cdecl
	$(INSTALL) cdecl $(BINDIR)
	ln -s cdecl $(BINDIR)/c++decl
	$(INSTALL_DATA) cdecl.1 $(MANDIR)
	$(INSTALL_DATA) c++decl.1 $(MANDIR)

clean:
	rm -f cdgram.c cdlex.c cdecl y.output c++decl

clobber: clean
	rm -f $(BINDIR)/cdecl $(BINDIR)/c++decl
	rm -f $(MANDIR)/cdecl.1 $(MANDIR)/c++decl.1
	rm -f $(CATDIR)/cdecl.1.gz

cdecl.cpio: $(ALLFILES)
	ls $(ALLFILES) | cpio -ocv > cdecl.cpio

cdecl.shar: $(ALLFILES)
	shar $(ALLFILES) > cdecl.shar
