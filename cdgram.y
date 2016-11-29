%{
/* Yacc grammar for ANSI and C++ cdecl. */
/* The output of this file is included */
/* into the C file cdecl.c. */
char cdgramsccsid[] = "@(#)cdgram.y	2.2 3/30/88";
%}

%union {
	char *dynstr;
	struct {
		char *left;
		char *right;
		char *type;
	} halves;
}

%token ARRAY AS CAST COMMA DECLARE DOUBLECOLON EXPLAIN FUNCTION BLOCK
%token HELP INTO OF MEMBER POINTER REFERENCE RETURNING SET TO
%token <dynstr> CHAR CLASS CONSTVOLATILE DOUBLE ENUM FLOAT INT LONG NAME
%token <dynstr> NUMBER SHORT SIGNED STRUCT UNION UNSIGNED VOID
%token <dynstr> AUTO EXTERN REGISTER STATIC
%type <dynstr> adecllist adims c_type cast castlist cdecl cdecl1 cdims
%type <dynstr> constvol_list ClassStruct mod_list mod_list1 modifier
%type <dynstr> opt_constvol_list optNAME opt_storage storage StrClaUniEnum
%type <dynstr> tname type
%type <halves> adecl

%start prog

%%
prog		: /* empty */
		| prog stmt
			{
			prompt();
			prev = 0;
			}
		;

stmt		: HELP NL
			{
			Debug((stderr, "stmt: help\n"));
			dohelp();
			}

		| DECLARE NAME AS opt_storage adecl NL
			{
			Debug((stderr, "stmt: DECLARE NAME AS opt_storage adecl\n"));
			Debug((stderr, "\tNAME='%s'\n", $2));
			Debug((stderr, "\topt_storage='%s'\n", $4));
			Debug((stderr, "\tacdecl.left='%s'\n", $5.left));
			Debug((stderr, "\tacdecl.right='%s'\n", $5.right));
			Debug((stderr, "\tacdecl.type='%s'\n", $5.type));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			dodeclare($2, $4, $5.left, $5.right, $5.type);
			}

		| DECLARE opt_storage adecl NL
			{
			Debug((stderr, "stmt: DECLARE opt_storage adecl\n"));
			Debug((stderr, "\topt_storage='%s'\n", $2));
			Debug((stderr, "\tacdecl.left='%s'\n", $3.left));
			Debug((stderr, "\tacdecl.right='%s'\n", $3.right));
			Debug((stderr, "\tacdecl.type='%s'\n", $3.type));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			dodeclare(NullCP, $2, $3.left, $3.right, $3.type);
			}

		| CAST NAME INTO adecl NL
			{
			Debug((stderr, "stmt: CAST NAME AS adecl\n"));
			Debug((stderr, "\tNAME='%s'\n", $2));
			Debug((stderr, "\tacdecl.left='%s'\n", $4.left));
			Debug((stderr, "\tacdecl.right='%s'\n", $4.right));
			Debug((stderr, "\tacdecl.type='%s'\n", $4.type));
			docast($2, $4.left, $4.right, $4.type);
			}

		| CAST adecl NL
			{
			Debug((stderr, "stmt: CAST adecl\n"));
			Debug((stderr, "\tacdecl.left='%s'\n", $2.left));
			Debug((stderr, "\tacdecl.right='%s'\n", $2.right));
			Debug((stderr, "\tacdecl.type='%s'\n", $2.type));
			docast(NullCP, $2.left, $2.right, $2.type);
			}

		| EXPLAIN opt_storage opt_constvol_list type opt_constvol_list cdecl NL
			{
			Debug((stderr, "stmt: EXPLAIN opt_storage opt_constvol_list type cdecl\n"));
			Debug((stderr, "\topt_storage='%s'\n", $2));
			Debug((stderr, "\topt_constvol_list='%s'\n", $3));
			Debug((stderr, "\ttype='%s'\n", $4));
			Debug((stderr, "\tcdecl='%s'\n", $6));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			dodexplain($2, $3, $5, $4, $6);
			}

		| EXPLAIN storage opt_constvol_list cdecl NL
			{
			Debug((stderr, "stmt: EXPLAIN storage opt_constvol_list cdecl\n"));
			Debug((stderr, "\tstorage='%s'\n", $2));
			Debug((stderr, "\topt_constvol_list='%s'\n", $3));
			Debug((stderr, "\tcdecl='%s'\n", $4));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			dodexplain($2, $3, NullCP, NullCP, $4);
			}

		| EXPLAIN opt_storage constvol_list cdecl NL
			{
			Debug((stderr, "stmt: EXPLAIN opt_storage constvol_list cdecl\n"));
			Debug((stderr, "\topt_storage='%s'\n", $2));
			Debug((stderr, "\tconstvol_list='%s'\n", $3));
			Debug((stderr, "\tcdecl='%s'\n", $4));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			dodexplain($2, $3, NullCP, NullCP, $4);
			}

		| EXPLAIN '(' opt_constvol_list type cast ')' optNAME NL
			{
			Debug((stderr, "stmt: EXPLAIN ( opt_constvol_list type cast ) optNAME\n"));
			Debug((stderr, "\topt_constvol_list='%s'\n", $3));
			Debug((stderr, "\ttype='%s'\n", $4));
			Debug((stderr, "\tcast='%s'\n", $5));
			Debug((stderr, "\tNAME='%s'\n", $7));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			docexplain($3, $4, $5, $7);
			}

		| SET optNAME NL
			{
			Debug((stderr, "stmt: SET optNAME\n"));
			Debug((stderr, "\toptNAME='%s'\n", $2));
			doset($2);
			}

		| NL
		| error NL
			{
			yyerrok;
			}
		;

NL		: '\n'
			{
			doprompt();
			}
		| ';'
			{
			noprompt();
			}
		;

optNAME		: NAME
			{
			Debug((stderr, "optNAME: NAME\n"));
			Debug((stderr, "\tNAME='%s'\n", $1));
			$$ = $1;
			}

		| /* empty */
			{
			Debug((stderr, "optNAME: EMPTY\n"));
			$$ = ds(unknown_name);
			}
		;

cdecl		: cdecl1
		| '*' opt_constvol_list cdecl
			{
			Debug((stderr, "cdecl: * opt_constvol_list cdecl\n"));
			Debug((stderr, "\topt_constvol_list='%s'\n", $2));
			Debug((stderr, "\tcdecl='%s'\n", $3));
			$$ = cat($3,$2,ds(strlen($2)?" pointer to ":"pointer to "),NullCP);
			prev = 'p';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| NAME DOUBLECOLON '*' cdecl
			{
			Debug((stderr, "cdecl: NAME DOUBLECOLON '*' cdecl\n"));
			Debug((stderr, "\tNAME='%s'\n", $1));
			Debug((stderr, "\tcdecl='%s'\n", $4));
			if (!CplusplusFlag)
				unsupp("pointer to member of class", NullCP);
			$$ = cat($4,ds("pointer to member of class "),$1,ds(" "),NullCP);
			prev = 'p';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| '&' opt_constvol_list cdecl
			{
			Debug((stderr, "cdecl: & opt_constvol_list cdecl\n"));
			Debug((stderr, "\topt_constvol_list='%s'\n", $2));
			Debug((stderr, "\tcdecl='%s'\n", $3));
			if (!CplusplusFlag)
				unsupp("reference", NullCP);
			$$ = cat($3,$2,ds(strlen($2)?" reference to ":"reference to "),NullCP);
			prev = 'r';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}
		;

cdecl1		: cdecl1 '(' ')'
			{
			Debug((stderr, "cdecl1: cdecl1()\n"));
			Debug((stderr, "\tcdecl1='%s'\n", $1));
			$$ = cat($1,ds("function returning "),NullCP);
			prev = 'f';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}
                        
                | '(' '^' opt_constvol_list cdecl ')' '(' ')'
                        {
                            char *sp = "";
                            Debug((stderr, "cdecl1: (^ opt_constvol_list cdecl)()\n"));
                            Debug((stderr, "\topt_constvol_list='%s'\n", $3));
                            Debug((stderr, "\tcdecl='%s'\n", $4));
                            if (strlen($3) > 0)
                                sp = " ";
                            $$ = cat($4, $3, ds(sp), ds("block returning "), NullCP);
                            prev = 'b';
                        }
                        
                | '(' '^' opt_constvol_list cdecl ')' '(' castlist ')'
                        {
                            char *sp = "";
                            Debug((stderr, "cdecl1: (^ opt_constvol_list cdecl)( castlist )\n"));
                            Debug((stderr, "\topt_constvol_list='%s'\n", $3));
                            Debug((stderr, "\tcdecl='%s'\n", $4));
                            Debug((stderr, "\tcastlist='%s'\n", $7));
                            if (strlen($3) > 0)
                                sp = " ";
                            $$ = cat($4, $3, ds(sp), ds("block ("),
                                    $7, ds(") returning "), NullCP);
                            prev = 'b';
                        }

		| cdecl1 '(' castlist ')'
			{
			Debug((stderr, "cdecl1: cdecl1(castlist)\n"));
			Debug((stderr, "\tcdecl1='%s'\n", $1));
			Debug((stderr, "\tcastlist='%s'\n", $3));
			$$ = cat($1, ds("function ("),
				  $3, ds(") returning "), NullCP);
			prev = 'f';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| cdecl1 cdims
			{
			Debug((stderr, "cdecl1: cdecl1 cdims\n"));
			Debug((stderr, "\tcdecl1='%s'\n", $1));
			Debug((stderr, "\tcdims='%s'\n", $2));
			$$ = cat($1,ds("array "),$2,NullCP);
			prev = 'a';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| '(' cdecl ')'
			{
			Debug((stderr, "cdecl1: (cdecl)\n"));
			Debug((stderr, "\tcdecl='%s'\n", $2));
			$$ = $2;
			/* prev = prev; */
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| NAME
			{
			Debug((stderr, "cdecl1: NAME\n"));
			Debug((stderr, "\tNAME='%s'\n", $1));
			savedname = $1;
			$$ = ds("");
			prev = 'n';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}
		;

castlist	: castlist COMMA castlist
			{
			Debug((stderr, "castlist: castlist1, castlist2\n"));
			Debug((stderr, "\tcastlist1='%s'\n", $1));
			Debug((stderr, "\tcastlist2='%s'\n", $3));
			$$ = cat($1, ds(", "), $3, NullCP);
			}

		| opt_constvol_list type cast
			{
			Debug((stderr, "castlist: opt_constvol_list type cast\n"));
			Debug((stderr, "\topt_constvol_list='%s'\n", $1));
			Debug((stderr, "\ttype='%s'\n", $2));
			Debug((stderr, "\tcast='%s'\n", $3));
			$$ = cat($3, $1, ds(strlen($1) ? " " : ""), $2, NullCP);
			}

		| NAME
			{
			$$ = $1;
			}
		;

adecllist	: /* empty */
			{
			Debug((stderr, "adecllist: EMPTY\n"));
			$$ = ds("");
			}

		| adecllist COMMA adecllist
			{
			Debug((stderr, "adecllist: adecllist1, adecllist2\n"));
			Debug((stderr, "\tadecllist1='%s'\n", $1));
			Debug((stderr, "\tadecllist2='%s'\n", $3));
			$$ = cat($1, ds(", "), $3, NullCP);
			}

		| NAME
			{
			Debug((stderr, "adecllist: NAME\n"));
			Debug((stderr, "\tNAME='%s'\n", $1));
			$$ = $1;
			}

		| adecl
			{
			Debug((stderr, "adecllist: adecl\n"));
			Debug((stderr, "\tadecl.left='%s'\n", $1.left));
			Debug((stderr, "\tadecl.right='%s'\n", $1.right));
			Debug((stderr, "\tadecl.type='%s'\n", $1.type));
			$$ = cat($1.type, ds(" "), $1.left, $1.right, NullCP);
			}

		| NAME AS adecl
			{
			Debug((stderr, "adecllist: NAME AS adecl\n"));
			Debug((stderr, "\tNAME='%s'\n", $1));
			Debug((stderr, "\tadecl.left='%s'\n", $3.left));
			Debug((stderr, "\tadecl.right='%s'\n", $3.right));
			Debug((stderr, "\tadecl.type='%s'\n", $3.type));
			$$ = cat($3.type, ds(" "), $3.left, $1, $3.right, NullCP);
			}
		;

cast		: /* empty */
			{
			Debug((stderr, "cast: EMPTY\n"));
			$$ = ds("");
			/* prev = prev; */
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| '(' ')'
			{
			Debug((stderr, "cast: ()\n"));
			$$ = ds("function returning ");
			prev = 'f';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| '(' cast ')' '(' ')'
			{
			Debug((stderr, "cast: (cast)()\n"));
			Debug((stderr, "\tcast='%s'\n", $2));
			$$ = cat($2,ds("function returning "),NullCP);
			prev = 'f';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| '(' cast ')' '(' castlist ')'
			{
			Debug((stderr, "cast: (cast)(castlist)\n"));
			Debug((stderr, "\tcast='%s'\n", $2));
			Debug((stderr, "\tcastlist='%s'\n", $5));
			$$ = cat($2,ds("function ("),$5,ds(") returning "),NullCP);
			prev = 'f';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}
                        
                | '(' '^' cast ')' '(' ')'
                    {
			Debug((stderr, "cast: (^ cast)()\n"));
			Debug((stderr, "\tcast='%s'\n", $3));
			$$ = cat($3,ds("block returning "),NullCP);
			prev = 'b';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
                    }
                    
                | '(' '^' cast ')' '(' castlist ')'
                    {
			Debug((stderr, "cast: (^ cast)(castlist)\n"));
			Debug((stderr, "\tcast='%s'\n", $3));
			$$ = cat($3,ds("block ("), $6, ds(") returning "),NullCP);
			prev = 'b';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
                    }

		| '(' cast ')'
			{
			Debug((stderr, "cast: (cast)\n"));
			Debug((stderr, "\tcast='%s'\n", $2));
			$$ = $2;
			/* prev = prev; */
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| NAME DOUBLECOLON '*' cast
			{
			Debug((stderr, "cast: NAME::*cast\n"));
			Debug((stderr, "\tcast='%s'\n", $4));
			if (!CplusplusFlag)
				unsupp("pointer to member of class", NullCP);
			$$ = cat($4,ds("pointer to member of class "),$1,ds(" "),NullCP);
			prev = 'p';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| '*' cast
			{
			Debug((stderr, "cast: *cast\n"));
			Debug((stderr, "\tcast='%s'\n", $2));
			$$ = cat($2,ds("pointer to "),NullCP);
			prev = 'p';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| '&' cast
			{
			Debug((stderr, "cast: &cast\n"));
			Debug((stderr, "\tcast='%s'\n", $2));
			if (!CplusplusFlag)
				unsupp("reference", NullCP);
			$$ = cat($2,ds("reference to "),NullCP);
			prev = 'r';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| cast cdims
			{
			Debug((stderr, "cast: cast cdims\n"));
			Debug((stderr, "\tcast='%s'\n", $1));
			Debug((stderr, "\tcdims='%s'\n", $2));
			$$ = cat($1,ds("array "),$2,NullCP);
			prev = 'a';
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}
		;

cdims		: '[' ']'
			{
			Debug((stderr, "cdims: []\n"));
			$$ = ds("of ");
			}

		| '[' NUMBER ']'
			{
			Debug((stderr, "cdims: [NUMBER]\n"));
			Debug((stderr, "\tNUMBER='%s'\n", $2));
			$$ = cat($2,ds(" of "),NullCP);
			}
		;

adecl		: FUNCTION RETURNING adecl
			{
			Debug((stderr, "adecl: FUNCTION RETURNING adecl\n"));
			Debug((stderr, "\tadecl.left='%s'\n", $3.left));
			Debug((stderr, "\tadecl.right='%s'\n", $3.right));
			Debug((stderr, "\tadecl.type='%s'\n", $3.type));
			if (prev == 'f')
				unsupp("Function returning function",
				       "function returning pointer to function");
			else if (prev=='A' || prev=='a')
				unsupp("Function returning array",
				       "function returning pointer");
			$$.left = $3.left;
			$$.right = cat(ds("()"),$3.right,NullCP);
			$$.type = $3.type;
			prev = 'f';
			Debug((stderr, "\n\tadecl now =\n"));
			Debug((stderr, "\t\tadecl.left='%s'\n", $$.left));
			Debug((stderr, "\t\tadecl.right='%s'\n", $$.right));
			Debug((stderr, "\t\tadecl.type='%s'\n", $$.type));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| FUNCTION '(' adecllist ')' RETURNING adecl
			{
			Debug((stderr, "adecl: FUNCTION (adecllist) RETURNING adecl\n"));
			Debug((stderr, "\tadecllist='%s'\n", $3));
			Debug((stderr, "\tadecl.left='%s'\n", $6.left));
			Debug((stderr, "\tadecl.right='%s'\n", $6.right));
			Debug((stderr, "\tadecl.type='%s'\n", $6.type));
			if (prev == 'f')
				unsupp("Function returning function",
				       "function returning pointer to function");
			else if (prev=='A' || prev=='a')
				unsupp("Function returning array",
				       "function returning pointer");
			$$.left = $6.left;
			$$.right = cat(ds("("),$3,ds(")"),$6.right,NullCP);
			$$.type = $6.type;
			prev = 'f';
			Debug((stderr, "\n\tadecl now =\n"));
			Debug((stderr, "\t\tadecl.left='%s'\n", $$.left));
			Debug((stderr, "\t\tadecl.right='%s'\n", $$.right));
			Debug((stderr, "\t\tadecl.type='%s'\n", $$.type));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}
                        
                
                | opt_constvol_list BLOCK RETURNING adecl
                        {
                        char *sp = "";
			Debug((stderr, "adecl: opt_constvol_list BLOCK RETURNING adecl\n"));
			Debug((stderr, "\topt_constvol_list='%s'\n", $1));
			Debug((stderr, "\tadecl.left='%s'\n", $4.left));
			Debug((stderr, "\tadecl.right='%s'\n", $4.right));
			Debug((stderr, "\tadecl.type='%s'\n", $4.type));
			if (prev == 'f')
				unsupp("Block returning function",
				       "block returning pointer to function");
			else if (prev=='A' || prev=='a')
				unsupp("Block returning array",
				       "block returning pointer");
			if (strlen($1) != 0)
				sp = " ";
                        $$.left = cat($4.left, ds("(^"), ds(sp), $1, ds(sp), NullCP);
			$$.right = cat(ds(")()"),$4.right,NullCP);
			$$.type = $4.type;
			prev = 'b';

                        }
                
                | opt_constvol_list BLOCK '(' adecllist ')' RETURNING adecl
                        {
                        char *sp = "";
			Debug((stderr, "adecl: opt_constvol_list BLOCK RETURNING adecl\n"));
			Debug((stderr, "\topt_constvol_list='%s'\n", $1));
			Debug((stderr, "\tadecllist='%s'\n", $4));
			Debug((stderr, "\tadecl.left='%s'\n", $7.left));
			Debug((stderr, "\tadecl.right='%s'\n", $7.right));
			Debug((stderr, "\tadecl.type='%s'\n", $7.type));
			if (prev == 'f')
				unsupp("Block returning function",
				       "block returning pointer to function");
			else if (prev=='A' || prev=='a')
				unsupp("Block returning array",
				       "block returning pointer");
                        if (strlen($1) != 0)
                            sp = " ";
                        $$.left = cat($7.left, ds("(^"), ds(sp), $1, ds(sp), NullCP);
			$$.right = cat(ds(")("), $4, ds(")"), $7.right, NullCP);
                        $$.type = $7.type;
                        prev = 'b';
                        }

		| ARRAY adims OF adecl
			{
			Debug((stderr, "adecl: ARRAY adims OF adecl\n"));
			Debug((stderr, "\tadims='%s'\n", $2));
			Debug((stderr, "\tadecl.left='%s'\n", $4.left));
			Debug((stderr, "\tadecl.right='%s'\n", $4.right));
			Debug((stderr, "\tadecl.type='%s'\n", $4.type));
			if (prev == 'f')
				unsupp("Array of function",
				       "array of pointer to function");
			else if (prev == 'a')
				unsupp("Inner array of unspecified size",
				       "array of pointer");
			else if (prev == 'v')
				unsupp("Array of void",
				       "pointer to void");
			if (arbdims)
				prev = 'a';
			else
				prev = 'A';
			$$.left = $4.left;
			$$.right = cat($2,$4.right,NullCP);
			$$.type = $4.type;
			Debug((stderr, "\n\tadecl now =\n"));
			Debug((stderr, "\t\tadecl.left='%s'\n", $$.left));
			Debug((stderr, "\t\tadecl.right='%s'\n", $$.right));
			Debug((stderr, "\t\tadecl.type='%s'\n", $$.type));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| opt_constvol_list POINTER TO adecl
			{
			char *op = "", *cp = "", *sp = "";

			Debug((stderr, "adecl: opt_constvol_list POINTER TO adecl\n"));
			Debug((stderr, "\topt_constvol_list='%s'\n", $1));
			Debug((stderr, "\tadecl.left='%s'\n", $4.left));
			Debug((stderr, "\tadecl.right='%s'\n", $4.right));
			Debug((stderr, "\tadecl.type='%s'\n", $4.type));
			if (prev == 'a')
				unsupp("Pointer to array of unspecified dimension",
				       "pointer to object");
			if (prev=='a' || prev=='A' || prev=='f') {
				op = "(";
				cp = ")";
			}
			if (strlen($1) != 0)
				sp = " ";
			$$.left = cat($4.left,ds(op),ds("*"),
				       ds(sp),$1,ds(sp),NullCP);
			$$.right = cat(ds(cp),$4.right,NullCP);
			$$.type = $4.type;
			prev = 'p';
			Debug((stderr, "\n\tadecl now =\n"));
			Debug((stderr, "\t\tadecl.left='%s'\n", $$.left));
			Debug((stderr, "\t\tadecl.right='%s'\n", $$.right));
			Debug((stderr, "\t\tadecl.type='%s'\n", $$.type));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| opt_constvol_list POINTER TO MEMBER OF ClassStruct NAME adecl
			{
			char *op = "", *cp = "", *sp = "";

			Debug((stderr, "adecl: opt_constvol_list POINTER TO MEMBER OF ClassStruct NAME adecl\n"));
			Debug((stderr, "\topt_constvol_list='%s'\n", $1));
			Debug((stderr, "\tClassStruct='%s'\n", $6));
			Debug((stderr, "\tNAME='%s'\n", $7));
			Debug((stderr, "\tadecl.left='%s'\n", $8.left));
			Debug((stderr, "\tadecl.right='%s'\n", $8.right));
			Debug((stderr, "\tadecl.type='%s'\n", $8.type));
			if (!CplusplusFlag)
				unsupp("pointer to member of class", NullCP);
			if (prev == 'a')
				unsupp("Pointer to array of unspecified dimension",
				       "pointer to object");
			if (prev=='a' || prev=='A' || prev=='f') {
				op = "(";
				cp = ")";
			}
			if (strlen($1) != 0)
				sp = " ";
			$$.left = cat($8.left,ds(op),$7,ds("::*"),
				      ds(sp),$1,ds(sp),NullCP);
			$$.right = cat(ds(cp),$8.right,NullCP);
			$$.type = $8.type;
			prev = 'p';
			Debug((stderr, "\n\tadecl now =\n"));
			Debug((stderr, "\t\tadecl.left='%s'\n", $$.left));
			Debug((stderr, "\t\tadecl.right='%s'\n", $$.right));
			Debug((stderr, "\t\tadecl.type='%s'\n", $$.type));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| opt_constvol_list REFERENCE TO adecl
			{
			char *op = "", *cp = "", *sp = "";

			Debug((stderr, "adecl: opt_constvol_list REFERENCE TO adecl\n"));
			Debug((stderr, "\topt_constvol_list='%s'\n", $1));
			Debug((stderr, "\tadecl.left='%s'\n", $4.left));
			Debug((stderr, "\tadecl.right='%s'\n", $4.right));
			Debug((stderr, "\tadecl.type='%s'\n", $4.type));
			if (!CplusplusFlag)
				unsupp("reference", NullCP);
			if (prev == 'v')
				unsupp("Reference to void",
				       "pointer to void");
			else if (prev == 'a')
				unsupp("Reference to array of unspecified dimension",
				       "reference to object");
			if (prev=='a' || prev=='A' || prev=='f') {
				op = "(";
				cp = ")";
			}
			if (strlen($1) != 0)
				sp = " ";
			$$.left = cat($4.left,ds(op),ds("&"),
				       ds(sp),$1,ds(sp),NullCP);
			$$.right = cat(ds(cp),$4.right,NullCP);
			$$.type = $4.type;
			prev = 'r';
			Debug((stderr, "\n\tadecl now =\n"));
			Debug((stderr, "\t\tadecl.left='%s'\n", $$.left));
			Debug((stderr, "\t\tadecl.right='%s'\n", $$.right));
			Debug((stderr, "\t\tadecl.type='%s'\n", $$.type));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}

		| opt_constvol_list type
			{
			Debug((stderr, "adecl: opt_constvol_list type\n"));
			Debug((stderr, "\topt_constvol_list='%s'\n", $1));
			Debug((stderr, "\ttype='%s'\n", $2));
			$$.left = ds("");
			$$.right = ds("");
			$$.type = cat($1,ds(strlen($1)?" ":""),$2,NullCP);
			if (strcmp($2, "void") == 0)
			    prev = 'v';
			else if ((strncmp($2, "struct", 6) == 0) ||
			         (strncmp($2, "class", 5) == 0))
			    prev = 's';
			else
			    prev = 't';
			Debug((stderr, "\n\tadecl now =\n"));
			Debug((stderr, "\t\tadecl.left='%s'\n", $$.left));
			Debug((stderr, "\t\tadecl.right='%s'\n", $$.right));
			Debug((stderr, "\t\tadecl.type='%s'\n", $$.type));
			Debug((stderr, "\tprev = '%s'\n", visible(prev)));
			}
		;

adims		: /* empty */
			{
			Debug((stderr, "adims: EMPTY\n"));
			arbdims = 1;
			$$ = ds("[]");
			}

		| NUMBER
			{
			Debug((stderr, "adims: NUMBER\n"));
			Debug((stderr, "\tNUMBER='%s'\n", $1));
			arbdims = 0;
			$$ = cat(ds("["),$1,ds("]"),NullCP);
			}
		;

type		: tinit c_type
			{
			Debug((stderr, "type: tinit c_type\n"));
			Debug((stderr, "\ttinit=''\n"));
			Debug((stderr, "\tc_type='%s'\n", $2));
			mbcheck();
			$$ = $2;
			}
		;

tinit		: /* empty */
			{
			Debug((stderr, "tinit: EMPTY\n"));
			modbits = 0;
			}
		;

c_type		: mod_list
			{
			Debug((stderr, "c_type: mod_list\n"));
			Debug((stderr, "\tmod_list='%s'\n", $1));
			$$ = $1;
			}

		| tname
			{
			Debug((stderr, "c_type: tname\n"));
			Debug((stderr, "\ttname='%s'\n", $1));
			$$ = $1;
			}

		| mod_list tname
			{
			Debug((stderr, "c_type: mod_list tname\n"));
			Debug((stderr, "\tmod_list='%s'\n", $1));
			Debug((stderr, "\ttname='%s'\n", $2));
			$$ = cat($1,ds(" "),$2,NullCP);
			}

		| StrClaUniEnum NAME
			{
			Debug((stderr, "c_type: StrClaUniEnum NAME\n"));
			Debug((stderr, "\tStrClaUniEnum='%s'\n", $1));
			Debug((stderr, "\tNAME='%s'\n", $2));
			$$ = cat($1,ds(" "),$2,NullCP);
			}
		;

StrClaUniEnum	: ClassStruct
		| ENUM
		| UNION
			{
			$$ = $1;
			}
		;

ClassStruct	: STRUCT
		| CLASS
			{
			$$ = $1;
			}
		;

tname		: INT
			{
			Debug((stderr, "tname: INT\n"));
			Debug((stderr, "\tINT='%s'\n", $1));
			modbits |= MB_INT; $$ = $1;
			}

		| CHAR
			{
			Debug((stderr, "tname: CHAR\n"));
			Debug((stderr, "\tCHAR='%s'\n", $1));
			modbits |= MB_CHAR; $$ = $1;
			}

		| FLOAT
			{
			Debug((stderr, "tname: FLOAT\n"));
			Debug((stderr, "\tFLOAT='%s'\n", $1));
			modbits |= MB_FLOAT; $$ = $1;
			}

		| DOUBLE
			{
			Debug((stderr, "tname: DOUBLE\n"));
			Debug((stderr, "\tDOUBLE='%s'\n", $1));
			modbits |= MB_DOUBLE; $$ = $1;
			}

		| VOID
			{
			Debug((stderr, "tname: VOID\n"));
			Debug((stderr, "\tVOID='%s'\n", $1));
			modbits |= MB_VOID; $$ = $1;
			}
		;

mod_list	: modifier mod_list1
			{
			Debug((stderr, "mod_list: modifier mod_list1\n"));
			Debug((stderr, "\tmodifier='%s'\n", $1));
			Debug((stderr, "\tmod_list1='%s'\n", $2));
			$$ = cat($1,ds(" "),$2,NullCP);
			}

		| modifier
			{
			Debug((stderr, "mod_list: modifier\n"));
			Debug((stderr, "\tmodifier='%s'\n", $1));
			$$ = $1;
			}
		;

mod_list1	: mod_list
			{
			Debug((stderr, "mod_list1: mod_list\n"));
			Debug((stderr, "\tmod_list='%s'\n", $1));
			$$ = $1;
			}

		| CONSTVOLATILE
			{
			Debug((stderr, "mod_list1: CONSTVOLATILE\n"));
			Debug((stderr, "\tCONSTVOLATILE='%s'\n", $1));
			if (PreANSIFlag)
				notsupported(" (Pre-ANSI Compiler)", $1, NullCP);
			else if (RitchieFlag)
				notsupported(" (Ritchie Compiler)", $1, NullCP);
			else if ((strcmp($1, "noalias") == 0) && CplusplusFlag)
				unsupp($1, NullCP);
			$$ = $1;
			}
		;

modifier	: UNSIGNED
			{
			Debug((stderr, "modifier: UNSIGNED\n"));
			Debug((stderr, "\tUNSIGNED='%s'\n", $1));
			modbits |= MB_UNSIGNED; $$ = $1;
			}

		| SIGNED
			{
			Debug((stderr, "modifier: SIGNED\n"));
			Debug((stderr, "\tSIGNED='%s'\n", $1));
			modbits |= MB_SIGNED; $$ = $1;
			}

		| LONG
			{
			Debug((stderr, "modifier: LONG\n"));
			Debug((stderr, "\tLONG='%s'\n", $1));
			modbits |= MB_LONG; $$ = $1;
			}

		| SHORT
			{
			Debug((stderr, "modifier: SHORT\n"));
			Debug((stderr, "\tSHORT='%s'\n", $1));
			modbits |= MB_SHORT; $$ = $1;
			}
		;

opt_constvol_list: CONSTVOLATILE opt_constvol_list
			{
			Debug((stderr, "opt_constvol_list: CONSTVOLATILE opt_constvol_list\n"));
			Debug((stderr, "\tCONSTVOLATILE='%s'\n", $1));
			Debug((stderr, "\topt_constvol_list='%s'\n", $2));
			if (PreANSIFlag)
				notsupported(" (Pre-ANSI Compiler)", $1, NullCP);
			else if (RitchieFlag)
				notsupported(" (Ritchie Compiler)", $1, NullCP);
			else if ((strcmp($1, "noalias") == 0) && CplusplusFlag)
				unsupp($1, NullCP);
			$$ = cat($1,ds(strlen($2) ? " " : ""),$2,NullCP);
			}

		| /* empty */
			{
			Debug((stderr, "opt_constvol_list: EMPTY\n"));
			$$ = ds("");
			}
		;

constvol_list: CONSTVOLATILE opt_constvol_list
			{
			Debug((stderr, "constvol_list: CONSTVOLATILE opt_constvol_list\n"));
			Debug((stderr, "\tCONSTVOLATILE='%s'\n", $1));
			Debug((stderr, "\topt_constvol_list='%s'\n", $2));
			if (PreANSIFlag)
				notsupported(" (Pre-ANSI Compiler)", $1, NullCP);
			else if (RitchieFlag)
				notsupported(" (Ritchie Compiler)", $1, NullCP);
			else if ((strcmp($1, "noalias") == 0) && CplusplusFlag)
				unsupp($1, NullCP);
			$$ = cat($1,ds(strlen($2) ? " " : ""),$2,NullCP);
			}
		;

storage		: AUTO
		| EXTERN
		| REGISTER
		| STATIC
			{
			Debug((stderr, "storage: AUTO,EXTERN,STATIC,REGISTER (%s)\n", $1));
			$$ = $1;
			}
		;

opt_storage	: storage
			{
			Debug((stderr, "opt_storage: storage=%s\n", $1));
			$$ = $1;
			}

		| /* empty */
			{
			Debug((stderr, "opt_storage: EMPTY\n"));
			$$ = ds("");
			}
		;
%%
