%{

#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"

// int *env_xpand = &envTable.env_xpand;
// int *max_xpand = &envTable.max_xpand;
// envTable.env_xpand = 0;
// envTable.max_xpand = 1;
char *stringSaver;

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

bool ifENV(char *var){
    for (int i = 0; i < envIndex; i++) {
        if(strcmp(envTable.var[i], var) == 0) {
            return true;
        }
    }
    printf("Error: \"%s\" not found in environment table!\n", var);
    return false;
}

char* getENV(char *var){
    for (int i = 0; i < envIndex; i++) {
        // printf("%s\n", envTable.var[i]);

        if(strcmp(envTable.var[i], var) == 0) {
            return envTable.word[i];
        }
    }
    return NULL;
}

char* strFindEnv(char *str){
    char temp[512] = {};
	char *envVar;
	char *envWord;
	bool ENDFOUND = false;
    
	if (max_xpand)
	{
		for( int i=0; i < strlen(str); i++ )
		{
			//printf("%c\n",str[i]);
			if (str[i] == '$')
			{
				if (i+1 < strlen(str))
				{
					//printf("%c\n",str[i+1]);
					if (str[i+1] == '{')
					{
						i += 2;
                        int j;
						for(j=0; i+j < strlen(str); j++ )
						{
							//printf("%c\n",str[i+j]);
							if (str[i+j] == '}')
							{
								ENDFOUND = true;
								break;
							}
						}
                        envVar = strndup(&str[i],j);
                        i += j;

						if (ENDFOUND)
						{
							if(ifENV(envVar))
							{
								strcat(temp, getENV(envVar));
							}
							else
							{
                                return strdup(str);
								
							}
						}
						else
						{
                            return strdup(str);
						}
					}
				}
				
			}
			else 
			{
				strncat(temp, &str[i], 1);
			}
		}
		printf("StrXpand_parser: %s\n", temp);
		return strdup(temp);
	}
	else
	{
		return strdup(str);
	}
}

// %array option supposedly causes yytext to be immune to unput()
%}

%array
%option noyywrap
%x string_condition
%x env_condition

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR         [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][}{)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
ENV             [$][{]
ENVEND          [}]

%%
<string_condition>{ANYCHAR}+    {
                                    yylval.string = strdup(strFindEnv(yytext));
                                    printf("yytext_str_c: %s\n", yylval.string);
                                    return STRING;
                                }
<string_condition>[\"]          {BEGIN(INITIAL);}
<env_condition>{CHAR}+{ENVEND}? {
                                    if (env_xpand && max_xpand) 
                                    {
                                        
                                        //printf("yytext_env_c: %s\n", yytext);
                                        char *env;
                                        if (yytext[yyleng-1] == '}'){
                                            env = strndup(yytext, yyleng-1);
                                        }
                                        else
                                        {
                                            printf("${%s missing '}' for expansion...", yytext);
                                            BEGIN(INITIAL);
                                        }
                                        // search table for variable
                                        if(ifENV(env))
                                        {
                                            max_xpand = 0;
                                            env_xpand = 0;
                                            char *yycopy = strdup( getENV(env) );
                                            printf("%s=%s\n", env, yycopy);
                                            // return STRING;
                                            for ( int i = strlen( getENV(env) )-1; i >= 0; --i )
                                            {
                                                unput( yycopy[i] );
                                            }
                                            free(yycopy);
                                            free(env);
                                        }
                                        else
                                        {
                                            env_xpand = 0;
                                        }
                                    }
                                    BEGIN(INITIAL);
                                }


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
                        // only finds env vars that are separate words
                        if (max_xpand > 0)
                        {
                            env_xpand = 1;
                            BEGIN(env_condition);
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
                            unput('}');
                        }
                        else
                        {
                            env_xpand = 0;
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
                        else 
                        {
                            printf("yytext: %s\n", yytext);
                            yylval.string = strdup(yytext);
                            return STRING;
                        };
                    }
%%