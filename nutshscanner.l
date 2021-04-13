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

bool ifENV(char *var, char **dupWord){
    for (int i = 0; i < envIndex; i++) {
        // printf("%s\n", envTable.var[i]);

        if(strcmp(envTable.var[i], var) == 0) {

            *dupWord = strdup(envTable.word[i]);
            // printf("%s\n", *dupWord);
            return true;
        }
    }
    printf("Error: \"%s\" not found in environment table!\n", var);
    return false;
}

void strFindEnv(char *str, char **outstr){
    char temp[512];
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
							if(ifENV(envVar, &envWord))
							{
								strcat(temp, envWord);
							}
							else
							{
                                *outstr = strdup(str);
								return;
							}
						}
						else
						{
                            *outstr = strdup(str);
							return;
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
		*outstr = strdup(temp);

        memset(temp, 0, sizeof(temp));
        free(envVar);
        free(envWord);

        return;
	}
	else
	{
		strcpy(*outstr,str);
        return;
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
<string_condition>{ANYCHAR}+    {   char *outstr = strdup(yytext);
                                    strFindEnv(yytext, &outstr);
                                    yylval.string = strdup(outstr);
                                    return STRING;
                                }
<string_condition>[\"]          {BEGIN(INITIAL);}
<env_condition>{CHAR}+          {
                                    if (env_xpand && max_xpand) 
                                    {
                                        printf("yytext: %s\n", yytext);

                                        // search table for variable
                                        char *dupWord = strdup(yytext);
                                        if(ifENV(yytext, &dupWord))
                                        {
                                            max_xpand = 0;
                                            env_xpand = 0;
                                            printf("env: %s\n", dupWord);
                                            yylval.string = strdup(dupWord);
                                            //return STRING;
                                            for ( int i = strlen(dupWord) - 1; i > 0; --i )
                                                unput( dupWord[i] );
                                            free(dupWord);
                                        }
                                    }
                                }
<env_condition>{ENVEND}         { BEGIN(INITIAL); } // skip to next token setenv th "cd ${HOME}"


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

