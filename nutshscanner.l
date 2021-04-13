%{

#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"

// int *env_xpand = &envTable.env_xpand;
// int *max_xpand = &envTable.max_xpand;
// envTable.env_xpand = 0;
// envTable.max_xpand = 1;
int alias_xpand = 0;
char *stringSaver;
int alias_xpand = 0;
bool isUnalias = false;
bool moreChars = false;
bool firstWord = true;
int env_xpand = 0;

char* getCmdPath(char *cmd){
    char *paths[] = {".","/fake/path","/bin","/usr/bin","/usr/local/bin"}; 
    char *fullpath;
    for (int i=0; i < 5; i++)
    {
        fullpath = strdup(paths[i]);
        if (fullpath[strlen(fullpath)-1] != '/')
        {
            strcat(fullpath, "/");
        }
        strcat(fullpath, cmd);
        if (access(fullpath, F_OK)==0){ // does path exist?
            return fullpath;
        }
    }
    return cmd;
}


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
%x cmd_condition

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR         [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][}{)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
ENV             [$][{]
ENVEND          [}]
PIPE            "|"
RUNINBG         "&"
fileName        [A-Za-z0-9\/_-][A-Za-z0-9\/_-]*"."[A-Za-z0-9\/_-][A-Za-z0-9\/_-]*
pathName

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
                                            // yylval.string = strdup(dupWord);
                                            // return STRING;
                                            for ( int i = strlen(dupWord) - 1; i > 0; --i )
                                                unput( dupWord[i] );
                                            free(dupWord);
                                        }
                                    }
                                }
<env_condition>{ENVEND}         { BEGIN(INITIAL); } // skip to next token setenv th "cd ${HOME}"


[ ]		            { }
bye                 { firstWord=false; return BYE; }
cd		            { firstWord=false; return CD; }
alias		        { firstWord=false; alias_xpand++; return ALIAS; }
unalias             { firstWord=false; isUnalias=true; return UNALIAS; }
setenv              { firstWord=false; return SETENV; moreChars = true; }
printenv            { firstWord=false; return PRINTENV; }
unsetenv            { firstWord=false; return UNSETENV; }
"\n"		        { firstWord=true; max_xpand = 1; return END; }
[\"]                { BEGIN(string_condition); }
{ENV}               { 
                        firstWord=false;
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
{CHAR}+             {
                        char *binPath;
                        if(ifAlias(yytext) && !isUnalias && alias_xpand == 0) {
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
                        else if ((access(binPath=strdup(getCmdPath(yytext)), X_OK) == 0) && firstWord)
                        {   // can the file be executed? If yes, its a command
                            //printf("found cmd: %s\n", binPath);
                            firstWord=false;

                            p.cmd[p.cmdCounter].cmd = strdup(binPath);
                            initCmd(&p.cmd[p.cmdCounter]);
                            cmdIndex++;
                            
                            if (cmdIndex == 1)
                                return CMD;
                        }
                        else if (cmdIndex > 0)  // all command args here
                        {
                            struct Command *c = &p.cmd[p.cmdCounter];
                            c->args[c->aIndex] = strdup(yytext);

                            //printf("new arg: %s\n", c->args[c->aIndex]);

                            c->aIndex++;
                        }
                        else 
                        {
                            firstWord=false;
                            printf("yytext: %s\n", yytext);
                            yylval.string = strdup(yytext);
                            return STRING;
                        };
                    }
{fileName}          {
                        if (cmdIndex > 0)
                        {
                            struct Command *c = &p.cmd[p.cmdCounter];
                            c->args[c->aIndex] = strdup(yytext);

                            //printf("new arg: %s\n", c->args[c->aIndex]);

                            c->aIndex++;
                        }
                        else
                        {
                            firstWord=false;
                            printf("yytext: %s\n", yytext);
                            yylval.string = strdup(yytext);
                            return STRING;
                        }
                    }
{PIPE}              {
                        p.bg = true;
                        p.cmdCounter++;
                        firstWord=true;
                    }                  
{RUNINBG}"\n"       { firstWord=true; p.bg = true; return END; }

%%

// todo: cmdform         cmd [arg]* [|cmd [arg]*]* [ >[>] fn2 ] [ 2>fn3 || 2>&1 ] [&]
