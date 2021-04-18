%{

#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"

char *stringSaver;
int alias_xpand = 1;
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

char* getFirstTwo(char* path){
    char* temp;
    strncpy(temp, path, 2);
    temp[2] = '\0';
    // printf("First two of path: %s", temp);
    return temp;
}

char* getParentDir(char* path){
    char* substr;
    char slash = '/';
    int length = strlen(path);
    int index = -1;

    // check if beginning == END

    // parse cwd for '/' in string that is not the END
    for(int i = 0; i <= length; i++)
    {
        if(path[i] == slash)
        {
            index = i;
        }
    }
    int pos = index + 1;

    // take substring of string up to the last /
    for(int i = 0; i < pos; i++)
    {
        substr[i] = path[i];
    }

    // printf("Substring: \"%s\"\n", substr); // '\"' to print "
    
    // assign substring to pwd environment variable
    runCD(substr);

  	return 0;
}

int addCmdArg(struct Command *c, char *toInsert)
{
    c->args[c->aIndex] = strdup(toInsert);
    c->aIndex++;
    return 1;
}

int addCmdFile(char *toInsert)
{
    // printf("io_bits:%i\n", p.io_bits);
    // printf("io_bits:%s\n", toInsert);

    if ((p.io_bits & IO_in) && (p.ioFile[0] == NULL))
        { p.ioFile[0] = strdup(toInsert); }
    else if ((p.io_bits & (IO_out | IO_outa)) && (p.ioFile[1] == NULL))
        { p.ioFile[1] = strdup(toInsert); }
    else if ((p.io_bits & IO_errf) && (p.ioFile[2] == NULL))
        { p.ioFile[2] = strdup(toInsert); }
    else
        { return -1; }
    
    // for (int i = 0; i < 3; i++)
	// 	printf("io_files: %s\n", p.ioFile[i]);

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
    fprintf(stderr, "Error: \"%s\" not found in environment table!\n", var);
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
		//printf("StrXpand_parser: %s\n", temp);
		return strdup(temp);
	}
	else
	{
		return strdup(str);
	}
}

// %array option supposedly causes yytext to be immune to unput()
// IO redirection help
// RDRCTI           <      accept input from file
// RDRCTO           >[>]   >truncate to zero and write OR >>append to file
// RDRCTERF         2>     stderr to file "filename"
// RDRCTERO         2>&1   redirects stderr to stdout
%}

%array
%option noyywrap
%x string_condition
%x env_condition
%x cmd_condition

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/:_-~]*
ANYCHAR         [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][}{)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
ENV             [$][{]
ENVEND          [}]
PIPE            "|"
RUNINBG         "&"
RDRCTI          "<"
RDRCTO          ">"[>]*
RDRCTERF        "2>"
RDRCTERO        "2>&1"
CR              "\r"

%%
<string_condition>{ANYCHAR}+    {
                                    yylval.string = strdup(strFindEnv(yytext));
                                    //printf("yytext_str_c: %s\n", yylval.string);
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
                                            //printf("%s=%s\n", env, yycopy);
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
alias		        { firstWord=false; alias_xpand = 0; return ALIAS; }
unalias             { firstWord=false; isUnalias=true; return UNALIAS; }
setenv              { firstWord=false; return SETENV; moreChars = true; }
printenv            { firstWord=false; return PRINTENV; }
unsetenv            { firstWord=false; return UNSETENV; }
{CR}?"\n"		    { firstWord=true; alias_xpand = 1; max_xpand = 1; return END; }
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
                        if(ifAlias(yytext) && !isUnalias && alias_xpand == 1) {
                            char *yycopy = strdup(subAliases(yytext));
                            for(int i = strlen(subAliases(yytext)) - 1; i >= 0; --i)
                            {
                                unput(yycopy[i]);
                            }
                            free(yycopy);
                            alias_xpand = 0;
                        }
                        else if (isUnalias) {
                            //printf("UNALIAS yytext: %s\n", yytext);
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
                        else if (p.io_bits & (IO_errf|IO_outa|IO_out|IO_in))
                        {
                            char *file;
                            // if file redirection, save next arg as a file for I/O
                            if (access(yytext, F_OK) == 0)
                                addCmdFile(yytext);
                            else if (access(file = getCmdPath(yytext),F_OK) == 0)
                                addCmdFile(file);
                            else {

                            }
                        }
                        else if (cmdIndex > 0)  // all command args here
                        {
                            
                            addCmdArg(&p.cmd[p.cmdCounter], yytext);
                            //printf("cmd_arg: %s\n", yytext);
                        }
                        else 
                        {
                            firstWord=false;
                            //printf("yytext: %s\n", yytext);
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

{RDRCTI}|{RDRCTO}|{RDRCTERF}|{RDRCTERO} {
                        if (!firstWord)
                        { 
                            if (strcmp(yytext,"<") == 0)
                                p.io_bits |= IO_in;
                            else if (strcmp(yytext,">") == 0)
                                p.io_bits |= IO_out; 
                            else if (strcmp(yytext,">>") == 0)
                                p.io_bits |= IO_outa;
                            else if (strcmp(yytext,"2>") == 0)
                                p.io_bits |= IO_errf; 
                            else if (strcmp(yytext,"2>&1") == 0)
                                p.io_bits |= IO_errout;
                            
                            //printf("IO:%i\n", p.io_bits);

                        } 
                    }

{RUNINBG}"\n"       { firstWord=true; p.bg = true; return END; }

%%

// IO redirection help
// RDRCTI           <      accept input from file
// RDRCTO           >[>]*  >truncate to zero and write OR >>append to file
// RDRCTERF         2>     stderr to file "filename"
// RDRCTERO         2>&1   redirects stderr to stdout


// todo: cmdform         cmd [arg]* [|cmd [arg]*]* [ >[>] fn2 ] [ 2>fn3 || 2>&1 ] [&]