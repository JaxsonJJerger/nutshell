%{

#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"

int env_xpand = 0;
int max_xpand = 1;
bool moreChars = false;
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

bool ifENV(char *var, char **dupWord){
    for (int i = 0; i < envIndex; i++) {
        if(strcmp(envTable.var[i], var) == 0) {
            *dupWord = strdup(envTable.word[i]);
            return true;
        }
    }
    return false;
}

%}

%array
%option noyywrap
%x string_condition
%x env_expansion

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR         [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
ENV             [$][{]
ENVEND          [}]

%%
<string_condition>{ANYCHAR}+     { yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]          {BEGIN(INITIAL);}

[ ]		            { }
bye                 { return BYE; }
cd		            { return CD; }
alias		        { return ALIAS; }
setenv              { return SETENV; moreChars = true; }
printenv            { return PRINTENV; }
unsetenv            { return UNSETENV; }
"\n"		        { max_xpand = 1; return END; }
[\"]                { BEGIN(string_condition); }
{ENV}               { 
                        //ensure next string is treated as a expansion
                        // only finds env vars that are separate words
                        if (max_xpand > 0)
                        {
                            env_xpand = 1;
                        }
                        else
                        {
                            // take rest of input and return string
                        }
                    }
{ENVEND}            {
                        if (env_xpand != 1)
                        {
                            //sytax error
                        }
                    }
{CHAR}+             {if(ifAlias(yytext)) {
                            printf("yytext: %s\n", yytext);
                            //source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                            char *yycopy = strdup( subAliases(yytext) );
                            for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                                unput( yycopy[i] );
                            free( yycopy );
                        }
                        else if (env_xpand && max_xpand) 
                        {
                            printf("yytext: %s\n", yytext);

                            // search table for variable
                            char *dupWord = strdup(yytext);
                            if(ifENV(yytext, &dupWord))
                            {
                                for ( int i = strlen(dupWord) - 1; i >= 0; --i )
                                    unput( dupWord[i] );
                            }
                            max_xpand = 0;
                            env_xpand = 0;
                        }
                        else 
                        {
                            printf("yytext: %s\n", yytext);
                            yylval.string = strdup(yytext);
                            if (max_xpand == 1)
                            {
                                return STRING;
                            }
                            else if (max_xpand == 0)
                            {
                                //return ENVX;
                            }
                        };
                    }
%%
