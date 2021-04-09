%{

#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"

int env_xpand = 0;
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
ANYCHAR            [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
ENV                 [$][{]
ENVEND              [}]

%%
<string_condition>{ANYCHAR}+     { yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]          {BEGIN(INITIAL);}

[ ]		            { }
bye                 { return BYE; }
cd		            { return CD; }
alias		        { return ALIAS; }
setenv              { return SETENV; }
printenv            { return PRINTENV; }
unsetenv            { return UNSETENV; }
"\n"		        { return END; }
[\"]                { BEGIN(string_condition); }
{ENV}               { 
                        //ensure next string is treated as a expansion
                        env_xpand = 1; 
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
                        else if (env_xpand) 
                        {
                            printf("yytext: %s\n", yytext);
                            // search table for variable
                            char *dupWord = strdup(yytext);
                            if(ifENV(yytext, &dupWord))
                            {
                                for ( int i = strlen(dupWord) - 1; i >= 0; --i )
                                    unput( dupWord[i] );
                            }
                            env_xpand = 0;
                        }
                        else 
                        {
                            printf("yytext: %s\n", yytext);
                            yylval.string = strdup(yytext);
                            return STRING;
                        };
                    }
%%

// char *yycopy = "";
                        // char *yyenv = "";
                        
                        // //begin reading chars until closing bracket found or
                        // // empty input
                        
                        // char c[1];
                        // c[0] = input();
                        // int cnt = 0;
                        
                        // while(c[0] != '}' && c[0] != '\n' && cnt < 512)
                        // {
                        //     cnt++;
                        //     printf("%s",c);
                        //     strcat(yyenv, c);
                        //     c[0] = input();

                        //     if (cnt > 512)
                        //     {
                        //         break;
                        //     }
                        // }
                        // printf("Found an env var: %s\n", yyenv);
                        // yylval.string = strdup(yyenv);
                        // return STRING;