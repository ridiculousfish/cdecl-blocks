%{
/* Lexical analyzer description for ANSI and C++ cdecl. */
/* The output of this file is included */
/* into the C file cdecl.c. */
char cdlexsccsid[] = "@(#)cdlex.l	2.2 3/30/88";
%}

N	[0-9]
A	[A-Z_a-z]
AN	[0-9A-Z_a-z]

%%
array		return ARRAY;
as		return AS;
cast		return CAST;
declare		return DECLARE;
exit		return 0;
explain		return EXPLAIN;
function	return FUNCTION;
func		return FUNCTION;
block           return BLOCK;
help		return HELP;
into		return INTO;
member		return MEMBER;
of		return OF;
pointer		return POINTER;
ptr		return POINTER;
quit		return 0;
reference	return REFERENCE;
ref		return REFERENCE;
returning	return RETURNING;
ret		return RETURNING;
set		return SET;
to		return TO;
vector		return ARRAY;
::		return DOUBLECOLON;
[?]		return HELP;
[,]		return COMMA;

auto		{ yylval.dynstr = ds(yytext);	return AUTO; }
character	{ yylval.dynstr = ds("char");	return CHAR; }
char		{ yylval.dynstr = ds(yytext);	return CHAR; }
class		{ yylval.dynstr = ds(yytext);	return CLASS; }
constant	{ yylval.dynstr = ds("const");	return CONSTVOLATILE; }
const		{ yylval.dynstr = ds(yytext);	return CONSTVOLATILE; }
double		{ yylval.dynstr = ds(yytext);	return DOUBLE; }
enumeration	{ yylval.dynstr = ds("enum");	return ENUM; }
enum		{ yylval.dynstr = ds(yytext);	return ENUM; }
extern		{ yylval.dynstr = ds(yytext);	return EXTERN; }
float		{ yylval.dynstr = ds(yytext);	return FLOAT; }
integer		{ yylval.dynstr = ds("int");	return INT; }
int		{ yylval.dynstr = ds(yytext);	return INT; }
long		{ yylval.dynstr = ds(yytext);	return LONG; }
noalias		{ yylval.dynstr = ds(yytext);	return CONSTVOLATILE; }
register	{ yylval.dynstr = ds(yytext);	return REGISTER; }
short		{ yylval.dynstr = ds(yytext);	return SHORT; }
signed		{ yylval.dynstr = ds(yytext);	return SIGNED; }
static		{ yylval.dynstr = ds(yytext);	return STATIC; }
structure	{ yylval.dynstr = ds("struct");	return STRUCT; }
struct		{ yylval.dynstr = ds(yytext);	return STRUCT; }
union		{ yylval.dynstr = ds(yytext);	return UNION; }
unsigned	{ yylval.dynstr = ds(yytext);	return UNSIGNED; }
void		{ yylval.dynstr = ds(yytext);	return VOID; }
volatile	{ yylval.dynstr = ds(yytext);	return CONSTVOLATILE; }

{A}{AN}*	{ yylval.dynstr = ds(yytext);	return NAME; }
{N}+		{ yylval.dynstr = ds(yytext);	return NUMBER; }

[#].*		;
[\t ]		;
[&*[\]();^\n]	return *yytext;
.		{
			(void) printf("bad character '%s'\n",visible(*yytext));
			return *yytext;
		}
%%
