/* Definitions */

%{
// Only "alias name word", "cd word", and "bye" run.
#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"

int alias_xpand = 0;
bool isUnalias = false;

char* subAliases(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return aliasTable.word[i];
        }
    }
    return name;
}

bool ifAlias(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return true;
        }
    }
    return false;
}
%}

%array
%option noyywrap
%x string_condition

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR         [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*

%%
<string_condition>{ANYCHAR}+     { yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]          {BEGIN(INITIAL);}

[ ]		            { }
bye                 { return BYE; }
cd		            { return CD;}
alias		        { alias_xpand++; return ALIAS; }
unalias             { isUnalias = true; return UNALIAS; }
"\n"		        { return END; }
[\"]                 { BEGIN(string_condition); }
{CHAR}+              {if(ifAlias(yytext) && !isUnalias && alias_xpand == 0) {
                            char *yycopy = strdup(subAliases(yytext));
                            for(int i = strlen(subAliases(yytext)) - 1; i >= 0; --i)
                            {
                                unput(yycopy[i]);
                            }
                            free(yycopy);
                            alias_xpand = 0;
                        }
                        else if (isUnalias) {
                            printf("UNALIAS yytext: %s\n", yytext);
                            yylval.string = strdup(yytext);
                            isUnalias = false;
                            return STRING;
                        }
                        else {
                            printf("ELSE yytext: %s\n", yytext);
                            yylval.string = strdup(yytext);
                            return STRING;
                        };
                     }
%%
// subroutines
