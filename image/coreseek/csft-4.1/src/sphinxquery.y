%{
#if USE_WINDOWS
#pragma warning(push,1)
#endif
%}

%lex-param		{ XQParser_t * pParser }
%parse-param	{ XQParser_t * pParser }
%pure-parser
%error-verbose

%union {
	XQNode_t *		pNode;			// tree node
	struct
	{
		int			iValue;
		int			iStrIndex;
	} tInt;
	struct							// field spec
	{
		CSphSmallBitvec		dMask;			// acceptable fields mask
		int			iMaxPos;		// max allowed position within field
	} tFieldLimit;
	int				iZoneVec;
};

%token <pNode>			TOK_KEYWORD
%token <tInt>			TOK_NEAR
%token <tInt>			TOK_INT
%token <tFieldLimit>	TOK_FIELDLIMIT
%token <iZoneVec>		TOK_ZONE
%token					TOK_BEFORE
%token					TOK_SENTENCE
%token					TOK_PARAGRAPH
%type <pNode>			rawkeyword
%type <pNode>			keyword
%type <pNode>			phrasetoken
%type <pNode>			phrase
%type <pNode>			sp_item
%type <pNode>			sentence
%type <pNode>			paragraph
%type <pNode>			atom
%type <pNode>			atomf
%type <pNode>			orlist
%type <pNode>			orlistf
%type <pNode>			beforelist
%type <pNode>			expr

%left TOK_BEFORE TOK_NEAR

%%

query:
	expr								{ pParser->AddQuery ( $1 ); }
	;

rawkeyword:
	TOK_KEYWORD							{ $$ = $1; }
	| TOK_INT							{ $$ = pParser->AddKeyword ( ( $1.iStrIndex>=0 ) ? pParser->m_dIntTokens[$1.iStrIndex].cstr() : NULL ); }
	;

keyword:
	rawkeyword
	| rawkeyword '$'			{ $$ = $1; assert ( $$->m_dWords.GetLength()==1 ); $$->m_dWords[0].m_bFieldEnd = true; }
	| '^' rawkeyword			{ $$ = $2; assert ( $$->m_dWords.GetLength()==1 ); $$->m_dWords[0].m_bFieldStart = true; }
	| '^' rawkeyword '$'		{ $$ = $2; assert ( $$->m_dWords.GetLength()==1 ); $$->m_dWords[0].m_bFieldStart = true; $$->m_dWords[0].m_bFieldEnd = true; }
	;

phrasetoken:
	keyword								{ $$ = $1; }
	| '('								{ $$ = NULL; }
	| ')'								{ $$ = NULL; }
	| '-'								{ $$ = NULL; }
	| '|'								{ $$ = NULL; }
	| '~'								{ $$ = NULL; }
	| '/'								{ $$ = NULL; }
	;

phrase:
	phrasetoken							{ $$ = $1; }
	| phrase phrasetoken				{ $$ = pParser->AddKeyword ( $1, $2 ); }
	;

sp_item:
	keyword								{ $$ = $1; }
	| '"' phrase '"'					{ $$ = $2; if ( $$ ) { assert ( $$->m_dWords.GetLength() ); $$->SetOp ( SPH_QUERY_PHRASE); } }
	;

sentence:
	sp_item TOK_SENTENCE sp_item		{ $$ = pParser->AddOp ( SPH_QUERY_SENTENCE, $1, $3 ); }
	| sentence TOK_SENTENCE sp_item		{ $$ = pParser->AddOp ( SPH_QUERY_SENTENCE, $1, $3 ); }
	;

paragraph:
	sp_item TOK_PARAGRAPH sp_item		{ $$ = pParser->AddOp ( SPH_QUERY_PARAGRAPH, $1, $3 ); }
	| paragraph TOK_PARAGRAPH sp_item	{ $$ = pParser->AddOp ( SPH_QUERY_PARAGRAPH, $1, $3 ); }
	;

atom:
	keyword								{ $$ = $1; }
	| sentence							{ $$ = $1; }
	| paragraph							{ $$ = $1; }
	| '"' '"'							{ $$ = NULL; }
	| '"' '"' '~' TOK_INT				{ $$ = NULL; }
	| '"' '"' '/' TOK_INT				{ $$ = NULL; }
	| '"' phrase '"'					{ $$ = $2; if ( $$ ) { assert ( $$->m_dWords.GetLength() ); $$->SetOp ( SPH_QUERY_PHRASE); } }
	| '"' phrase '"' '~' TOK_INT		{ $$ = $2; if ( $$ ) { assert ( $$->m_dWords.GetLength() ); $$->SetOp ( SPH_QUERY_PROXIMITY ); $$->m_iOpArg = $5.iValue; } }
	| '"' phrase '"' '/' TOK_INT		{ $$ = $2; if ( $$ ) { assert ( $$->m_dWords.GetLength() ); $$->SetOp ( SPH_QUERY_QUORUM ); $$->m_iOpArg = $5.iValue; } }
	| '(' expr ')'						{ $$ = $2; if ( $$ ) $$->m_bFieldSpec = false; }
	;

atomf:
	atom								{ $$ = $1; }
	| TOK_FIELDLIMIT atom				{ $$ = $2; if ( $$ ) $$->SetFieldSpec ( $1.dMask, $1.iMaxPos ); }
	| TOK_ZONE atom						{ $$ = $2; if ( $$ ) $$->SetZoneSpec ( pParser->GetZoneVec ( $1 ) ); }
	;

orlist:
	atomf								{ $$ = $1; }
	| orlist '|' atomf					{ $$ = pParser->AddOp ( SPH_QUERY_OR, $1, $3 ); }
	;

orlistf:
	orlist								{ $$ = $1; }
	| '-' orlist						{ $$ = pParser->AddOp ( SPH_QUERY_NOT, $2, NULL ); }
	| TOK_FIELDLIMIT '-' orlist			{ $$ = pParser->AddOp ( SPH_QUERY_NOT, $3, NULL ); $$->SetFieldSpec ( $1.dMask, $1.iMaxPos ); }
	;

beforelist:
	orlistf
	| beforelist TOK_BEFORE orlistf		{ $$ = pParser->AddOp ( SPH_QUERY_BEFORE, $1, $3 ); }
	| beforelist TOK_NEAR orlistf		{ $$ = pParser->AddOp ( SPH_QUERY_NEAR, $1, $3, $2.iValue ); }
	;

expr:
	beforelist							{ $$ = $1; }
	| expr beforelist					{ $$ = pParser->AddOp ( SPH_QUERY_AND, $1, $2 ); }
	;

%%

#if USE_WINDOWS
#pragma warning(pop)
#endif
