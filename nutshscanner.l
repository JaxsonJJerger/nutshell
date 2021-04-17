%{

#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"

char *stringSaver;
int alias_xpand = 0;
bool isUnalias = false;
bool isPath = false;
bool moreChars = false;
bool firstWord = true;

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

const char* getHomeDir(){
    homedir = getpwuid(getuid())->pw_dir;
    return homedir;
}
 
char* getParentDir(){
    // char* test = "root/usr/bin/parent";
    char* test = "/parent";
    char* substr;
    char slash = '/';
    int length = strlen(test);
    int index = -1;

    // check if beginning == END

    // parse cwd for '/' in string that is not the END
    for(int i = 0; i <= length; i++)
    {
        if(test[i] == slash)
        {
            index = i;
        }
    }
    int pos = index + 1;
    if(index == -1)
  	{
  		printf("\n Error: Element '%c' does not exist.\n", slash);
	}
	else
	{
		printf("\n The Last '%c' in the string is at position %d.\n", slash, pos);
	}

    // take substring of string up to the last /
    int c = 0;
    while(c < length) {
        substr[c] = test[pos + c - 1];
        c++;
    }
    substr[c] = '\0';
    printf("Substring: \"%s\"\n", substr); // '\"' to print "

  	return 0;
}

int addCmdArg(struct Command *c, char *toInsert)
{
    c->args[c->aIndex] = strdup(toInsert);
    c->aIndex++;
    return 1;
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
%x cmd_condition

DOTTIL          "."|".."|"~"{CHAR}*
CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/:_-]*
ANYCHAR         [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][}{)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
ENV             [$][{]
ENVEND          [}]
PIPE            "|"
RUNINBG         "&"

%%
<string_condition>{ANYCHAR}+    {
                                    yylval.string = strdup(strFindEnv(yytext));
                                    printf("yytext_str_c: %s\n", yylval.string);
                                    if (cmdIndex <= 0)
                                    {
                                        return STRING;
                                    }
                                    else
                                    {
                                        addCmdArg(&p.cmd[p.cmdCounter], yylval.string);
                                    }
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
{DOTTIL}            {
                        char *yycopy = strdup(yytext);
                        if(strcmp(yytext, "..") == 0) {
                            printf("PARENT\n");
                            // yycopy = strdup(getParentDir());
                            getParentDir();
                            // return STRING;
                        }
                        else if(strcmp(yytext, ".") == 0) {
                            printf("CURRDIRR\n");
                            yycopy = strdup(getcwd(cwd, sizeof(cwd)));
                            printf("currdir found: %s\n", yycopy);
                            // return STRING;
                        }
                        else if(strcmp(yytext, "~") == 0) {
                            printf("TILDE\n");
                            yycopy = strdup(getHomeDir());
                            printf("homedir found: %s\n", homedir);
                            // return STRING;
                        }
                        free(yycopy);
                        return STRING;
                    }
{CHAR}+             {
                        char *binPath;

                        if(yytext[0] == '~') {
                            printf("TILDE FOUND IN CHAR+: %s", yytext); 
                        }

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
                            // #### COMMAND ADDED ##### //

                            // #### ADD COMMAND PATH TO ARGS #### //
                            addCmdArg(&p.cmd[p.cmdCounter], binPath);

                            if (cmdIndex == 1)
                                return CMD;
                        }
                        else if (cmdIndex > 0)  // all command args here
                        {
                            addCmdArg(&p.cmd[p.cmdCounter], yytext);
                            //printf("cmd_arg: %s\n", yytext);
                        }
                        else 
                        {
                            firstWord=false;
                            printf("yytext: %s\n", yytext);
                            yylval.string = strdup(yytext);
                            return STRING;
                        };
                    }
{PIPE}              {
                        // add NULL character in case there are no args
                        // besides the cmd path
                        addCmdArg(&p.cmd[p.cmdCounter], NULL);

                        // we expect another command
                        p.cmdCounter++;
                        firstWord=true;
                    }               
                
{RUNINBG}"\n"       { firstWord=true; p.bg = true; return END; }

%%

// todo: cmdform         cmd [arg]* [|cmd [arg]*]* [ >[>] fn2 ] [ 2>fn3 || 2>&1 ] [&]