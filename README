This is cdecl, the C gibberish translator. This version has been enhanced
by ridiculous_fish to support Apple's blocks syntax.

Visit https://cdecl.org to use it online.

Original README follows:

			Cdecl version 2.5

Cdecl is a program which will turn English-like phrases such as "declare
foo as array 5 of pointer to function returning int" into C declarations
such as "int (*foo[5])()".  It can also translate the C into the pseudo-
English.  And it handles typecasts, too.  Plus C++.  And in this version
it has command line editing and history with the GNU readline library.

The files in this distribution are:

cdecl.c		The cdecl source code.
cdlex.l		The lex source for the cdecl lexer.
cdgram.y	The yacc source for the cdecl parser.
cdecl.1		The cdecl man page.
c++decl.1	The c++decl man page (really just cdecl.1).
testset		A script to test the operation of cdecl.
testset++	A script to test the operation of c++decl.
Makefile	The makefile to build and install cdecl.
README		See file README for description of this file.

If you have the GNU readline library and its headers in readline/*.h and
termcap then you can install cdecl by "make" followed by "make install".
To compile without readline and termcap, you must edit the Makefile and
remove -DUSE_READLINE from the CFLAGS and -lreadline and -ltermcap from
the LIBS.  You will, unfortunately, lose the command line editing,
history, and keyword completion.  By default cdecl installs in /usr/bin,
but this is configurable in the Makefile.

I debated with myself whether to provide a precompiled libreadline.a and
associated headers with the cdecl distribution, however that would have
made the tar file *much* bigger, so I have decided not to.  If you think
I should, or you would like me to send you readline, please get in touch
with me at conrad@detroit.freenet.org.  You can find the source for
readline in the bash distribution on prep.ai.mit.edu:/pub/gnu or on
ftp.uu.net:/pub/gnu, or wherever fine GNU source isn't sold.

You should also be able to find a ready-to-run ELF binary of cdecl in the
same place you got this from.  It should be on sunsite.unc.edu in the
directory /pub/Linux/devel/lang/c/, or on any of the many sunsite mirrors.
My three favorites are ftp.cc.gatech.edu, ftp.cdrom.com, and
uiarchive.cso.uiuc.edu.

You may well be wondering what the status of cdecl is.  So am I.  It was
twice posted to comp.sources.unix, but neither edition carried any mention
of copyright.  This version is derived from the second edition.  I have
no reason to believe there are any limitations on its use, and strongly
believe it to be in the Public Domain.  GNU readline is, of course,
covered by the GNU General Public License.

I was inspired to port cdecl to Linux as there was no version of it
available in the various Linux software archives that I am aware of.
The addition of GNU readline support seemed like a logical extension
of the program.  Be warned, however, that linking with readline more
than doubles the size of the program.  Those whose main concern is
space might wish to build a version without readline.

David R. Conrad
conrad@detroit.freenet.org
Detroit, Michigan, USA
16 January 1996

