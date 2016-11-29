/*
 * cdecl - ANSI C and C++ declaration composer & decoder
 *
 *	originally written
 *		Graham Ross
 *		once at tektronix!tekmdp!grahamr
 *		now at Context, Inc.
 *
 *	modified to provide hints for unsupported types
 *	added argument lists for functions
 *	added 'explain cast' grammar
 *	added #ifdef for 'create program' feature
 *		???? (sorry, I lost your name and login)
 *
 *	conversion to ANSI C
 *		David Wolverton
 *		ihnp4!houxs!daw
 *
 *	merged D. Wolverton's ANSI C version w/ ????'s version
 *	added function prototypes
 *	added C++ declarations
 *	made type combination checking table driven
 *	added checks for void variable combinations
 *	made 'create program' feature a runtime option
 *	added file parsing as well as just stdin
 *	added help message at beginning
 *	added prompts when on a TTY or in interactive mode
 *	added getopt() usage
 *	added -a, -r, -p, -c, -d, -D, -V, -i and -+ options
 *	delinted
 *	added #defines for those without getopt or void
 *	added 'set options' command
 *	added 'quit/exit' command
 *	added synonyms
 *		Tony Hansen
 *		attmail!tony, ihnp4!pegasus!hansen
 *
 *	added extern, register, static
 *	added links to explain, cast, declare
 *	separately developed ANSI C support
 *		Merlyn LeRoy
 *		merlyn@rose3.rosemount.com
 *
 *	merged versions from LeRoy
 *	added tmpfile() support
 *	allow more parts to be missing during explanations
 *		Tony Hansen
 *		attmail!tony, ihnp4!pegasus!hansen
 *
 *	added GNU readline() support
 *	added dotmpfile_from_string() to support readline()
 *	outdented C help text to prevent line from wrapping
 *	minor tweaking of makefile && mv makefile Makefile
 *	took out interactive and nointeractive commands when
 *	    compiled with readline support
 *	added prompt and noprompt commands, -q option
 *		Dave Conrad
 *		conrad@detroit.freenet.org
 *
 *	added support for Apple's "blocks"
 *          Peter Ammon
 *          cdecl@ridiculousfish.com
 */

char cdeclsccsid[] = "@(#)cdecl.c	2.5 1/15/96";

#include <stdio.h>
#include <ctype.h>
#if __STDC__ || defined(DOS)
# include <stdlib.h>
# include <stddef.h>
# include <string.h>
# include <stdarg.h>
# include <errno.h>
#else
# ifndef NOVARARGS
#  include <varargs.h>
# endif /* ndef NOVARARGS */
char *malloc();
void free(), exit(), perror();
# ifdef BSD
#  include <strings.h>
   extern int errno;
#  define strrchr rindex
#  define NOTMPFILE
# else
#  include <string.h>
#  include <errno.h>
# endif /* BSD */
# ifdef NOVOID
#  define void int
# endif /* NOVOID */
#endif /* __STDC__ || DOS */

#ifdef USE_READLINE
# include <readline/readline.h>
  /* prototypes for functions related to readline() */
  char * getline();
  char ** attempt_completion(char *, int, int);
  char * keyword_completion(char *, int);
  char * command_completion(char *, int);
#endif

/* maximum # of chars from progname to display in prompt */
#define MAX_NAME 32

/* this is the prompt for readline() to display */
char cdecl_prompt[MAX_NAME+3];

/* backup copy of prompt to save it while prompting is off */
char real_prompt[MAX_NAME+3];

#define	MB_SHORT	0001
#define	MB_LONG		0002
#define	MB_UNSIGNED	0004
#define MB_INT		0010
#define MB_CHAR		0020
#define MB_FLOAT	0040
#define MB_DOUBLE	0100
#define MB_VOID		0200
#define	MB_SIGNED	0400

#define NullCP ((char*)NULL)
#ifdef dodebug
# define Debug(x) do { if (DebugFlag) (void) fprintf x; } while (0)
#else
# define Debug(x) /* nothing */
#endif

#if __STDC__
  char *ds(char *), *cat(char *, ...), *visible(int);
  int main(int, char **);
  int yywrap(void);
  int dostdin(void);
  void mbcheck(void), dohelp(void), usage(void);
  void prompt(void), doprompt(void), noprompt(void);
  void unsupp(char *, char *);
  void notsupported(char *, char *, char *);
  void yyerror(char *);
  void doset(char *);
  void dodeclare(char*, char*, char*, char*, char*);
  void docast(char*, char*, char*, char*);
  void dodexplain(char*, char*, char*, char*, char*);
  void docexplain(char*, char*, char*, char*);
  void cdecl_setprogname(char *);
  int dotmpfile(int, char**), dofileargs(int, char**);
#else
  char *ds(), *cat(), *visible();
  int getopt();
  void mbcheck(), dohelp(), usage();
  void prompt(), doprompt(), noprompt();
  void unsupp(), notsupported();
  void yyerror();
  void doset(), dodeclare(), docast(), dodexplain(), docexplain();
  void cdecl_setprogname();
  int dotmpfile(), dofileargs();
#endif /* __STDC__ */
  FILE *tmpfile();

/* variables used during parsing */
unsigned modbits = 0;
int arbdims = 1;
char *savedname = 0;
char unknown_name[] = "unknown_name";
char prev = 0;		/* the current type of the variable being examined */
			/*    values	type				   */
			/*	p	pointer				   */
			/*	r	reference			   */
			/*	f	function			   */
			/*	a	array (of arbitrary dimensions)    */
			/*	A	array with dimensions		   */
			/*	n	name				   */
			/*	v	void				   */
			/*	s	struct | class			   */
			/*	t	simple type (int, long, etc.)	   */

/* options */
int RitchieFlag = 0;		/* -r, assume Ritchie PDP C language */
int MkProgramFlag = 0;		/* -c, output {} and ; after declarations */
int PreANSIFlag = 0;		/* -p, assume pre-ANSI C language */
int CplusplusFlag = 0;		/* -+, assume C++ language */
int OnATty = 0;			/* stdin is coming from a terminal */
int Interactive = 0;		/* -i, overrides OnATty */
int KeywordName = 0;		/* $0 is a keyword (declare, explain, cast) */
char *progname = "cdecl";	/* $0 */
int quiet = 0;                  /* -q, quiets prompt and initial help msg */

#if dodebug
int DebugFlag = 0;		/* -d, output debugging trace info */
#endif

#ifdef doyydebug		/* compile in yacc trace statements */
#define YYDEBUG 1
#endif /* doyydebug */

#include "cdgram.c"
#include "cdlex.c"

/* definitions (and abbreviations) for type combinations cross check table */
#define ALWAYS	0	/* combo always okay */
#define _	ALWAYS
#define NEVER	1	/* combo never allowed */
#define X	NEVER
#define RITCHIE	2	/* combo not allowed in Ritchie compiler */
#define R	RITCHIE
#define PREANSI	3	/* combo not allowed in Pre-ANSI compiler */
#define P	PREANSI
#define ANSI	4	/* combo not allowed anymore in ANSI compiler */
#define A	ANSI

/* This is an lower left triangular array. If we needed */
/* to save 9 bytes, the "long" row can be removed. */
char crosscheck[9][9] = {
    /*			L, I, S, C, V, U, S, F, D, */
    /* long */		_, _, _, _, _, _, _, _, _,
    /* int */		_, _, _, _, _, _, _, _, _,
    /* short */		X, _, _, _, _, _, _, _, _,
    /* char */		X, X, X, _, _, _, _, _, _,
    /* void */		X, X, X, X, _, _, _, _, _,
    /* unsigned */	R, _, R, R, X, _, _, _, _,
    /* signed */	P, P, P, P, X, X, _, _, _,
    /* float */		A, X, X, X, X, X, X, _, _,
    /* double */	P, X, X, X, X, X, X, X, _
};

/* the names and bits checked for each row in the above array */
struct
    {
    char *name;
    int bit;
    } crosstypes[9] =
	{
	    { "long",		MB_LONG		},
	    { "int",		MB_INT		},
	    { "short",		MB_SHORT	},
	    { "char",		MB_CHAR		},
	    { "void",		MB_VOID		},
	    { "unsigned",	MB_UNSIGNED	},
	    { "signed",		MB_SIGNED	},
	    { "float",		MB_FLOAT	},
	    { "double",		MB_DOUBLE	}
	};

/* Run through the crosscheck array looking */
/* for unsupported combinations of types. */
void mbcheck()
{
    register int i, j, restrict;
    char *t1, *t2;

    /* Loop through the types */
    /* (skip the "long" row) */
    for (i = 1; i < 9; i++)
	{
	/* if this type is in use */
	if ((modbits & crosstypes[i].bit) != 0)
	    {
	    /* check for other types also in use */
	    for (j = 0; j < i; j++)
		{
		/* this type is not in use */
		if (!(modbits & crosstypes[j].bit))
		    continue;
		/* check the type of restriction */
		restrict = crosscheck[i][j];
		if (restrict == ALWAYS)
		    continue;
		t1 = crosstypes[i].name;
		t2 = crosstypes[j].name;
		if (restrict == NEVER)
		    {
		    notsupported("", t1, t2);
		    }
		else if (restrict == RITCHIE)
		    {
		    if (RitchieFlag)
			notsupported(" (Ritchie Compiler)", t1, t2);
		    }
		else if (restrict == PREANSI)
		    {
		    if (PreANSIFlag || RitchieFlag)
			notsupported(" (Pre-ANSI Compiler)", t1, t2);
		    }
		else if (restrict == ANSI)
		    {
		    if (!RitchieFlag && !PreANSIFlag)
			notsupported(" (ANSI Compiler)", t1, t2);
		    }
		else
		    {
		    (void) fprintf (stderr,
			"%s: Internal error in crosscheck[%d,%d]=%d!\n",
			progname, i, j, restrict);
		    exit(1); /* NOTREACHED */
		    }
		}
	    }
	}
}

/* undefine these as they are no longer needed */
#undef _
#undef ALWAYS
#undef X
#undef NEVER
#undef R
#undef RITCHIE
#undef P
#undef PREANSI
#undef A
#undef ANSI

#ifdef USE_READLINE

/* this section contains functions and declarations used with readline() */

/* the readline info pages make this clearer than any comments possibly
 * could, so see them for more information
 */

char *commands[] = {
  "declare",
  "explain",
  "cast",
  "help",
  "set",
  "exit",
  "quit",
  NULL
};

char *keywords[] = {
  "function",
  "returning",
  "array",
  "pointer",
  "reference",
  "member",
  "const",
  "volatile",
  "noalias",
  "struct",
  "union",
  "enum",
  "class",
  "extern",
  "static",
  "auto",
  "register",
  "short",
  "long",
  "signed",
  "unsigned",
  "char",
  "float",
  "double",
  "void",
  NULL
};

char *options[] = {
  "options",
  "create",
  "nocreate",
  "prompt",
  "noprompt",
#if 0
  "interactive",
  "nointeractive",
#endif
  "ritchie",
  "preansi",
  "ansi",
  "cplusplus",
  NULL
};

/* A static variable for holding the line. */
static char *line_read = NULL;

/* Read a string, and return a pointer to it.  Returns NULL on EOF. */
char * getline ()
{
  /* If the buffer has already been allocated, return the memory
     to the free pool. */
  if (line_read != NULL)
    {
      free (line_read);
      line_read = NULL;
    }

  /* Get a line from the user. */
  line_read = readline (cdecl_prompt);

  /* If the line has any text in it, save it on the history. */
  if (line_read && *line_read)
    add_history (line_read);

  return (line_read);
}

char ** attempt_completion(char *text, int start, int end)
{
  char **matches = NULL;

  if (start == 0) matches = completion_matches(text, command_completion);

  return matches;
}

char * command_completion(char *text, int flag)
{
  static int index, len;
  char *command;

  if (!flag) {
    index = 0;
    len = strlen(text);
  }

  while (command = commands[index]) {
    index++;
    if (!strncmp(command, text, len)) return strdup(command);
  }
  return NULL;
}

char * keyword_completion(char *text, int flag)
{
  static int index, len, set, into;
  char *keyword, *option;

  if (!flag) {
    index = 0;
    len = strlen(text);
    /* completion works differently if the line begins with "set" */
    set = !strncmp(rl_line_buffer, "set", 3);
    into = 0;
  }

  if (set) {
    while (option = options[index]) {
      index++;
      if (!strncmp(option, text, len)) return strdup(option);
    }
  } else {
    /* handle "int" and "into" as special cases */
    if (!into) {
      into = 1;
      if (!strncmp(text, "into", len) && strncmp(text, "int", len))
        return strdup("into");
      if (strncmp(text, "int", len)) return keyword_completion(text, into);
      /* normally "int" and "into" would conflict with one another when
       * completing; cdecl tries to guess which one you wanted, and it
       * always guesses correctly
       */
      if (!strncmp(rl_line_buffer, "cast", 4)
          && !strstr(rl_line_buffer, "into"))
        return strdup("into");
      else
        return strdup("int");
    } else while (keyword = keywords[index]) {
      index++;
      if (!strncmp(keyword, text, len)) return strdup(keyword);
    }
  }
  return NULL;
}
#endif /* USE_READLINE */

/* Write out a message about something */
/* being unsupported, possibly with a hint. */
void unsupp(s,hint)
char *s,*hint;
{
    notsupported("", s, NullCP);
    if (hint)
	(void) fprintf(stderr, "\t(maybe you mean \"%s\")\n", hint);
}

/* Write out a message about something */
/* being unsupported on a particular compiler. */
void notsupported(compiler, type1, type2)
char *compiler, *type1, *type2;
{
    if (type2)
	(void) fprintf(stderr,
	    "Warning: Unsupported in%s C%s -- '%s' with '%s'\n",
	    compiler, CplusplusFlag ? "++" : "", type1, type2);
    else
	(void) fprintf(stderr,
	    "Warning: Unsupported in%s C%s -- '%s'\n",
	    compiler, CplusplusFlag ? "++" : "", type1);
}

/* Called by the yacc grammar */
void yyerror(s)
char *s;
{
    (void) printf("%s\n",s);
    Debug((stdout, "yychar=%d\n", yychar));
}

/* Called by the yacc grammar */
int yywrap()
{
    return 1;
}

/*
 * Support for dynamic strings:
 * cat() creates a string from the concatenation
 * of a null terminated list of input strings.
 * The input strings are free()'d by cat()
 * (so they better have been malloc()'d).
 *
 * the different methods of <stdarg.h> and
 * <vararg.h> are handled within these macros
 */
#if __STDC__
#  define VA_DCL(type,var)		(type var,...)
#  define VA_START(list,var,type)	((va_start(list,var)) , (var))
#else
#if defined(DOS)
#  define VA_DCL(type,var)		(var,...) type var;
#  define VA_START(list,var,type)	((va_start(list,var)) , (var))
#else
#ifndef NOVARARGS
# define VA_DCL(type,var)		(va_alist) va_dcl
# define VA_START(list,var,type)	((va_start(list)) , va_arg(list,type))
#else
   /*
    *	it is assumed here that machines which don't have either
    *	<varargs.h> or <stdarg.h> will put its arguments on
    *	the stack in the "usual" way and consequently can grab
    *	the arguments using the "take the address of the first
    *	parameter and increment by sizeof" trick.
    */
# define VA_DCL(type,var)		(var) type var;
# define VA_START(list,var,type)	(list = (va_list)&(var) , (var))
# define va_arg(list,type)		((type *)(list += sizeof(type)))[-1]
# define va_end(p)			/* nothing */
typedef char *va_list;
#endif /* NOVARARGS */
#endif /* DOS */
#endif /* __STDC__ */

/* VARARGS */
char *cat
VA_DCL(char*, s1)
{
    register char *newstr;
    register unsigned len = 1;
    char *str;
    va_list args;

    /* find the length which needs to be allocated */
    str = VA_START(args, s1, char*);
    for ( ; str; str = va_arg(args, char*))
	len += strlen(str);
    va_end(args);

    /* allocate it */
    newstr = malloc(len);
    if (newstr == 0)
	{
	(void) fprintf (stderr, "%s: out of malloc space within cat()!\n",
	    progname);
	exit(1);
	}
    newstr[0] = '\0';

    /* copy in the strings */
    str = VA_START(args, s1, char*);
    for ( ; str; str = va_arg(args, char*))
	{
	(void) strcat(newstr,str);
	free(str);
	}
    va_end(args);

    Debug((stderr, "\tcat created '%s'\n", newstr));
    return newstr;
}

/*
 * ds() makes a malloc()'d string from one that's not.
 */
char *ds(s)
char *s;
{
    register char *p = malloc((unsigned)(strlen(s)+1));

    if (p)
	(void) strcpy(p,s);
    else
	{
	(void) fprintf (stderr, "%s: malloc() failed!\n", progname);
	exit(1);
	}
    return p;
}

/* return a visible representation of a character */
char *visible(c)
int c;
{
    static char buf[5];

    c &= 0377;
    if (isprint(c))
	{
	buf[0] = c;
	buf[1] = '\0';
	}
    else
	(void) sprintf(buf,"\\%03o",c);
    return buf;
}

#ifdef NOTMPFILE
/* provide a conservative version of tmpfile() */
/* for those systems without it. */
/* tmpfile() returns a FILE* of a file opened */
/* for read&write. It is supposed to be */
/* automatically removed when it gets closed, */
/* but here we provide a separate rmtmpfile() */
/* function to perform that function. */
/* Also provide several possible file names to */
/* try for opening. */
static char *file4tmpfile = 0;

FILE *tmpfile()
{
    static char *listtmpfiles[] =
	{
	"/usr/tmp/cdeclXXXXXX",
	"/tmp/cdeclXXXXXX",
	"/cdeclXXXXXX",
	"cdeclXXXXXX",
	0
	};

    char **listp = listtmpfiles;
    for ( ; *listp; listp++)
	{
	FILE *retfp;
	(void) mktemp(*listp);
	retfp = fopen(*listp, "w+");
	if (!retfp)
	    continue;
	file4tmpfile = *listp;
	return retfp;
	}

    return 0;
}

void rmtmpfile()
{
    if (file4tmpfile)
	(void) unlink(file4tmpfile);
}
#else
/* provide a mock rmtmpfile() for normal systems */
# define rmtmpfile()	/* nothing */
#endif /* NOTMPFILE */

#ifndef NOGETOPT
extern int optind;
#else
/* This is a miniature version of getopt() which will */
/* do just barely enough for us to get by below. */
/* Options are not allowed to be bunched up together. */
/* Option arguments are not supported. */
int optind = 1;

int getopt(argc,argv,optstring)
char **argv;
char *optstring;
{
    int ret;
    char *p;

    if ((argv[optind][0] != '-')
#ifdef DOS
	&& (argv[optind][0] != '/')
#endif /* DOS */
	)
	return EOF;

    ret = argv[optind][1];
    optind++;

    for (p = optstring; *p; p++)
	if (*p == ret)
	    return ret;

    (void) fprintf (stderr, "%s: illegal option -- %s\n",
	progname, visible(ret));

    return '?';
}
#endif

/* the help messages */
struct helpstruct
    {
	char *text;	/* generic text */
	char *cpptext;	/* C++ specific text */
    } helptext[] =
    {	/* up-to 23 lines of help text so it fits on (24x80) screens */
/*  1 */{ "[] means optional; {} means 1 or more; <> means defined elsewhere", 0 },
/*  2 */{ "  commands are separated by ';' and newlines", 0 },
/*  3 */{ "command:", 0 },
/*  4 */{ "  declare <name> as <english>", 0 },
/*  5 */{ "  cast <name> into <english>", 0 },
/*  6 */{ "  explain <gibberish>", 0 },
/*  7 */{ "  set or set options", 0 },
/*  8 */{ "  help, ?", 0 },
/*  9 */{ "  quit or exit", 0 },
/* 10 */{ "english:", 0 },
/* 11 */{ "  function [( <decl-list> )] returning <english>", 0 },
/* 12 */{ "  block [( <decl-list> )] returning <english>", 0 },
/* 13 */{ "  array [<number>] of <english>", 0 },
/* 14 */{ "  [{ const | volatile | noalias }] pointer to <english>",
	  "  [{const|volatile}] {pointer|reference} to [member of class <name>] <english>" },
/* 15 */{ "  <type>", 0 },
/* 16 */{ "type:", 0 },
/* 17 */{ "  {[<storage-class>] [{<modifier>}] [<C-type>]}", 0 },
/* 18 */{ "  { struct | union | enum } <name>",
	  "  {struct|class|union|enum} <name>" },
/* 19 */{ "decllist: a comma separated list of <name>, <english> or <name> as <english>", 0 },
/* 20 */{ "name: a C identifier", 0 },
/* 21 */{ "gibberish: a C declaration, like 'int *x', or cast, like '(int *)x'", 0 },
/* 22 */{ "storage-class: extern, static, auto, register", 0 },
/* 23 */{ "C-type: int, char, float, double, or void", 0 },
/* 24 */{ "modifier: short, long, signed, unsigned, const, volatile, or noalias",
	  "modifier: short, long, signed, unsigned, const, or volatile" },
	{ 0, 0 }
    };

/* Print out the help text */
void dohelp()
{
    register struct helpstruct *p;
    register char *fmt = CplusplusFlag ? " %s\n" : "  %s\n";

    for (p = helptext; p->text; p++)
	if (CplusplusFlag && p->cpptext)
	    (void) printf(fmt, p->cpptext);
	else
	    (void) printf(fmt, p->text);
}

/* Tell how to invoke cdecl. */
void usage()
{
    (void) fprintf (stderr, "Usage: %s [-r|-p|-a|-+] [-ciq%s%s] [files...]\n",
	progname,
#ifdef dodebug
	"d",
#else
	"",
#endif /* dodebug */
#ifdef doyydebug
	"D"
#else
	""
#endif /* doyydebug */
	);
    (void) fprintf (stderr, "\t-r Check against Ritchie PDP C Compiler\n");
    (void) fprintf (stderr, "\t-p Check against Pre-ANSI C Compiler\n");
    (void) fprintf (stderr, "\t-a Check against ANSI C Compiler%s\n",
	CplusplusFlag ? "" : " (the default)");
    (void) fprintf (stderr, "\t-+ Check against C++ Compiler%s\n",
	CplusplusFlag ? " (the default)" : "");
    (void) fprintf (stderr, "\t-c Create compilable output (include ; and {})\n");
    (void) fprintf (stderr, "\t-i Force interactive mode\n");
    (void) fprintf (stderr, "\t-q Quiet prompt\n");
#ifdef dodebug
    (void) fprintf (stderr, "\t-d Turn on debugging mode\n");
#endif /* dodebug */
#ifdef doyydebug
    (void) fprintf (stderr, "\t-D Turn on YACC debugging mode\n");
#endif /* doyydebug */
    exit(1);
    /* NOTREACHED */
}

/* Manage the prompts. */
static int prompting;

void doprompt() { prompting = 1; }
void noprompt() { prompting = 0; }

void prompt()
{
#ifndef USE_READLINE
    if ((OnATty || Interactive) && prompting) {
	(void) printf("%s", cdecl_prompt);
# if 0
	(void) printf("%s> ", progname);
# endif /* that was the old way to display the prompt */
	(void) fflush(stdout);
    }
#endif
}

/* Save away the name of the program from argv[0] */
void cdecl_setprogname(char *argv0)
{
#ifdef DOS
    char *dot;
#endif /* DOS */

    progname = strrchr(argv0, '/');

#ifdef DOS
    if (!progname)
	progname = strrchr(argv0, '\\');
#endif /* DOS */

    if (progname)
	progname++;
    else
	progname = argv0;

#ifdef DOS
    dot = strchr(progname, '.');
    if (dot)
	*dot = '\0';
    for (dot = progname; *dot; dot++)
	*dot = tolower(*dot);
#endif /* DOS */
    /* this sets up the prompt, which is on by default */
    {
	int len;

	len = strlen(progname);
	if (len > MAX_NAME) len = MAX_NAME;
	strncpy(real_prompt, progname, len);
	real_prompt[len] = '>';
	real_prompt[len+1] = ' ';
	real_prompt[len+2] = '\0';
    }
}

/* Run down the list of keywords to see if the */
/* program is being called named as one of them */
/* or the first argument is one of them. */
int namedkeyword(argn)
char *argn;
{
    static char *cmdlist[] =
	{
	"explain", "declare", "cast", "help", "?", "set", 0
	};

    /* first check the program name */
    char **cmdptr = cmdlist;
    for ( ; *cmdptr; cmdptr++)
	if (strcmp(*cmdptr, progname) == 0)
	    {
	    KeywordName = 1;
	    return 1;
	    }

    /* now check $1 */
    for (cmdptr = cmdlist; *cmdptr; cmdptr++)
	if (strcmp(*cmdptr, argn) == 0)
	    return 1;

    /* nope, must be file name arguments */
    return 0;
}

/* Read from standard input, turning */
/* on prompting if necessary. */
int dostdin()
{
    int ret;
    if (OnATty || Interactive)
	{
#ifndef USE_READLINE
	if (!quiet) (void) printf("Type `help' or `?' for help\n");
	prompt();
#else
	char *line, *oldline;
	int len, newline;

	if (!quiet) (void) printf("Type `help' or `?' for help\n");
	ret = 0;
	while ((line = getline())) {
	    if (!strcmp(line, "quit") || !strcmp(line, "exit")) {
		free(line);
		return ret;
	    }
	    newline = 0;
	    /* readline() strips newline, we add semicolon if necessary */
	    len = strlen(line);
	    if (len && line[len-1] != '\n' && line[len-1] != ';') {
		newline = 1;
		oldline = line;
		line = malloc(len+2);
		strcpy(line, oldline);
		line[len] = ';';
		line[len+1] = '\0';
	    }
	    if (len) ret = dotmpfile_from_string(line);
	    if (newline) free(line);
	}
	puts("");
	return ret;
#endif
	}

    yyin = stdin;
    ret = yyparse();
    OnATty = 0;
    return ret;
}

#ifdef USE_READLINE
/* Write a string into a file and treat that file as the input. */
int dotmpfile_from_string(s)
char *s;
{
    int ret = 0;
    FILE *tmpfp = tmpfile();
    if (!tmpfp)
	{
	int sverrno = errno;
	(void) fprintf (stderr, "%s: cannot open temp file\n",
	    progname);
	errno = sverrno;
	perror(progname);
	return 1;
	}

    if (fputs(s, tmpfp) == EOF)
	{
	int sverrno;
	sverrno = errno;
	(void) fprintf (stderr, "%s: error writing to temp file\n",
	    progname);
	errno = sverrno;
	perror(progname);
	(void) fclose(tmpfp);
	rmtmpfile();
	return 1;
	}

    rewind(tmpfp);
    yyin = tmpfp;
    ret += yyparse();
    (void) fclose(tmpfp);
    rmtmpfile();

    return ret;
}
#endif /* USE_READLINE */

/* Write the arguments into a file */
/* and treat that file as the input. */
int dotmpfile(argc, argv)
int argc;
char **argv;
{
    int ret = 0;
    FILE *tmpfp = tmpfile();
    if (!tmpfp)
	{
	int sverrno = errno;
	(void) fprintf (stderr, "%s: cannot open temp file\n",
	    progname);
	errno = sverrno;
	perror(progname);
	return 1;
	}

    if (KeywordName)
	if (fputs(progname, tmpfp) == EOF)
	    {
	    int sverrno;
	errwrite:
	    sverrno = errno;
	    (void) fprintf (stderr, "%s: error writing to temp file\n",
		progname);
	    errno = sverrno;
	    perror(progname);
	    (void) fclose(tmpfp);
	    rmtmpfile();
	    return 1;
	    }

    for ( ; optind < argc; optind++)
	if (fprintf(tmpfp, " %s", argv[optind]) == EOF)
	    goto errwrite;

    if (putc('\n', tmpfp) == EOF)
	goto errwrite;

    rewind(tmpfp);
    yyin = tmpfp;
    ret += yyparse();
    (void) fclose(tmpfp);
    rmtmpfile();

    return ret;
}

/* Read each of the named files for input. */
int dofileargs(argc, argv)
int argc;
char **argv;
{
    FILE *ifp;
    int ret = 0;

    for ( ; optind < argc; optind++)
	if (strcmp(argv[optind], "-") == 0)
	    ret += dostdin();

	else if ((ifp = fopen(argv[optind], "r")) == NULL)
	    {
	    int sverrno = errno;
	    (void) fprintf (stderr, "%s: cannot open %s\n",
		progname, argv[optind]);
	    errno = sverrno;
	    perror(argv[optind]);
	    ret++;
	    }

	else
	    {
	    yyin = ifp;
	    ret += yyparse();
	    }

    return ret;
}

/* print out a cast */
void docast(name, left, right, type)
char *name, *left, *right, *type;
{
    int lenl = strlen(left), lenr = strlen(right);

    if (prev == 'f')
	    unsupp("Cast into function",
		    "cast into pointer to function");
    else if (prev=='A' || prev=='a')
	    unsupp("Cast into array","cast into pointer");
    (void) printf("(%s%*s%s)%s\n",
	    type, lenl+lenr?lenl+1:0,
	    left, right, name ? name : "expression");
    free(left);
    free(right);
    free(type);
    if (name)
        free(name);
}

/* print out a declaration */
void dodeclare(name, storage, left, right, type)
char *name, *storage, *left, *right, *type;
{
    if (prev == 'v')
	    unsupp("Variable of type void",
		    "variable of type pointer to void");

    if (*storage == 'r')
	switch (prev)
	    {
	    case 'f': unsupp("Register function", NullCP); break;
	    case 'A':
	    case 'a': unsupp("Register array", NullCP); break;
	    case 's': unsupp("Register struct/class", NullCP); break;
	    }

    if (*storage)
        (void) printf("%s ", storage);
    (void) printf("%s %s%s%s",
        type, left,
	name ? name : (prev == 'f') ? "f" : "var", right);
    if (MkProgramFlag) {
	    if ((prev == 'f') && (*storage != 'e'))
		    (void) printf(" { }\n");
	    else
		    (void) printf(";\n");
    } else {
	    (void) printf("\n");
    }
    free(storage);
    free(left);
    free(right);
    free(type);
    if (name)
        free(name);
}

void dodexplain(storage, constvol1, constvol2, type, decl)
char *storage, *constvol1, *constvol2, *type, *decl;
{
    if (type && (strcmp(type, "void") == 0)) {
	if (prev == 'n')
	    unsupp("Variable of type void",
		   "variable of type pointer to void");
	else if (prev == 'a')
	    unsupp("array of type void",
		   "array of type pointer to void");
	else if (prev == 'r')
	    unsupp("reference to type void",
		   "pointer to void");
    }

    if (*storage == 'r')
	switch (prev)
	    {
	    case 'f': unsupp("Register function", NullCP); break;
	    case 'A':
	    case 'a': unsupp("Register array", NullCP); break;
	    case 's': unsupp("Register struct/union/enum/class", NullCP); break;
	    }

    (void) printf("declare %s as ", savedname);
    if (*storage)
        (void) printf("%s ", storage);
    (void) printf("%s", decl);
    if (*constvol1)
	    (void) printf("%s ", constvol1);
    if (*constvol2)
        (void) printf("%s ", constvol2);
    (void) printf("%s\n", type ? type : "int");
}

void docexplain(constvol, type, cast, name)
char *constvol, *type, *cast, *name;
{
    if (strcmp(type, "void") == 0) {
	if (prev == 'a')
	    unsupp("array of type void",
		   "array of type pointer to void");
	else if (prev == 'r')
	    unsupp("reference to type void",
		   "pointer to void");
    }
    (void) printf("cast %s into %s", name, cast);
    if (strlen(constvol) > 0)
	    (void) printf("%s ", constvol);
    (void) printf("%s\n",type);
}

/* Do the appropriate things for the "set" command. */
void doset(opt)
char *opt;
{
    if (strcmp(opt, "create") == 0)
	{ MkProgramFlag = 1; }
    else if (strcmp(opt, "nocreate") == 0)
	{ MkProgramFlag = 0; }
    else if (strcmp(opt, "prompt") == 0)
	{ prompting = 1; strcpy(cdecl_prompt, real_prompt); }
    else if (strcmp(opt, "noprompt") == 0)
	{ prompting = 0; cdecl_prompt[0] = '\0'; }
#ifndef USE_READLINE
    /* I cannot seem to figure out what nointeractive was intended to do --
     * it didn't work well to begin with, and it causes problem with
     * readline, so I'm removing it, for now.  -i still works.
     */
    else if (strcmp(opt, "interactive") == 0)
	{ Interactive = 1; }
    else if (strcmp(opt, "nointeractive") == 0)
	{ Interactive = 0; OnATty = 0; }
#endif
    else if (strcmp(opt, "ritchie") == 0)
	{ CplusplusFlag=0; RitchieFlag=1; PreANSIFlag=0; }
    else if (strcmp(opt, "preansi") == 0)
	{ CplusplusFlag=0; RitchieFlag=0; PreANSIFlag=1; }
    else if (strcmp(opt, "ansi") == 0)
	{ CplusplusFlag=0; RitchieFlag=0; PreANSIFlag=0; }
    else if (strcmp(opt, "cplusplus") == 0)
	{ CplusplusFlag=1; RitchieFlag=0; PreANSIFlag=0; }
#ifdef dodebug
    else if (strcmp(opt, "debug") == 0)
	{ DebugFlag = 1; }
    else if (strcmp(opt, "nodebug") == 0)
	{ DebugFlag = 0; }
#endif /* dodebug */
#ifdef doyydebug
    else if (strcmp(opt, "yydebug") == 0)
	{ yydebug = 1; }
    else if (strcmp(opt, "noyydebug") == 0)
	{ yydebug = 0; }
#endif /* doyydebug */
    else
	{
	if ((strcmp(opt, unknown_name) != 0) &&
	    (strcmp(opt, "options") != 0))
	    (void) printf("Unknown set option: '%s'\n", opt);

	(void) printf("Valid set options (and command line equivalents) are:\n");
	(void) printf("\toptions\n");
	(void) printf("\tcreate (-c), nocreate\n");
	(void) printf("\tprompt, noprompt (-q)\n");
#ifndef USE_READLINE
	(void) printf("\tinteractive (-i), nointeractive\n");
#endif
	(void) printf("\tritchie (-r), preansi (-p), ansi (-a) or cplusplus (-+)\n");
#ifdef dodebug
	(void) printf("\tdebug (-d), nodebug\n");
#endif /* dodebug */
#ifdef doyydebug
	(void) printf("\tyydebug (-D), noyydebug\n");
#endif /* doyydebug */

	(void) printf("\nCurrent set values are:\n");
	(void) printf("\t%screate\n", MkProgramFlag ? "   " : " no");
	(void) printf("\t%sprompt\n", cdecl_prompt[0] ? "   " : " no");
	(void) printf("\t%sinteractive\n",
	    (OnATty || Interactive) ? "   " : " no");
	if (RitchieFlag)
	    (void) printf("\t   ritchie\n");
	else
	    (void) printf("\t(noritchie)\n");
	if (PreANSIFlag)
	    (void) printf("\t   preansi\n");
	else
	    (void) printf("\t(nopreansi)\n");
	if (!RitchieFlag && !PreANSIFlag && !CplusplusFlag)
	    (void) printf("\t   ansi\n");
	else
	    (void) printf("\t(noansi)\n");
	if (CplusplusFlag)
	    (void) printf("\t   cplusplus\n");
	else
	    (void) printf("\t(nocplusplus)\n");
#ifdef dodebug
	(void) printf("\t%sdebug\n", DebugFlag ? "   " : " no");
#endif /* dodebug */
#ifdef doyydebug
	(void) printf("\t%syydebug\n", yydebug ? "   " : " no");
#endif /* doyydebug */
	}
}

void versions()
{
    (void) printf("Version:\n\t%s\n\t%s\n\t%s\n",
	cdeclsccsid, cdgramsccsid, cdlexsccsid);
    exit(0);
}

int main(argc, argv)
char **argv;
{
    int c, ret = 0;

#ifdef USE_READLINE
    /* install completion handlers */
    rl_attempted_completion_function = (CPPFunction *)attempt_completion;
    rl_completion_entry_function = (Function *)keyword_completion;
#endif

    cdecl_setprogname(argv[0]);
#ifdef DOS
    if (strcmp(progname, "cppdecl") == 0)
#else
    if (strcmp(progname, "c++decl") == 0)
#endif /* DOS */
	CplusplusFlag = 1;

    prompting = OnATty = isatty(0);
    while ((c = getopt(argc, argv, "cipqrpa+dDV")) != EOF)
	switch (c)
	    {
	    case 'c': MkProgramFlag=1; break;
	    case 'i': Interactive=1; doprompt(); break;
	    case 'q': quiet=1; noprompt(); break;

	    /* The following are mutually exclusive. */
	    /* Only the last one set prevails. */
	    case 'r': CplusplusFlag=0; RitchieFlag=1; PreANSIFlag=0; break;
	    case 'p': CplusplusFlag=0; RitchieFlag=0; PreANSIFlag=1; break;
	    case 'a': CplusplusFlag=0; RitchieFlag=0; PreANSIFlag=0; break;
	    case '+': CplusplusFlag=1; RitchieFlag=0; PreANSIFlag=0; break;

#ifdef dodebug
	    case 'd': DebugFlag=1; break;
#endif /* dodebug */
#ifdef doyydebug
	    case 'D': yydebug=1; break;
#endif /* doyydebug */
	    case 'V': versions(); break;
	    case '?': usage(); break;
	    }

    /* Set up the prompt. */
    if (prompting)
	strcpy(cdecl_prompt, real_prompt);
    else
	cdecl_prompt[0] = '\0';

    /* Run down the list of arguments, parsing each one. */

    /* Use standard input if no file names or "-" is found. */
    if (optind == argc)
	ret += dostdin();

    /* If called as explain, declare or cast, or first */
    /* argument is one of those, use the command line */
    /* as the input. */
    else if (namedkeyword(argv[optind]))
	ret += dotmpfile(argc, argv);
    else
	ret += dofileargs(argc, argv);

    exit(ret);
    /* NOTREACHED */
}
