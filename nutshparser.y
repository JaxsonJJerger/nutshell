%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "global.h"

int yylex(void);
int yyerror(char *s);
int cmdRunner();
int runCD(char* arg);
int runAlias();
int runSetAlias(char *name, char *word);
int runUnalias(char *name);
int runSetenv(char *var, char *word);
int printenvTable();
int runUnsetenv(char *var);
int runEnvXpand(char *var);
%}

%union {char *string;}

%start cmd_line

%token <string> BYE CD STRING ALIAS UNALIAS SETENV PRINTENV UNSETENV CMD ENV END

%%
cmd_line    :
	BYE END 		                {exit(1); return 1; }
	| CD END						{runCD(" "); return 1; }
	| CD STRING END        			{runCD($2); return 1;}
	| ALIAS END						{runAlias(" "); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
	| UNALIAS STRING END			{runUnalias($2); return 1;}
	| SETENV STRING STRING END		{runSetenv($2, $3); return 1;}
	| PRINTENV END					{printenvTable(); return 1;}
	| UNSETENV STRING END			{runUnsetenv($2); return 1;}
	| CMD END						{cmdRunner(); return 1;}
	| ENV							{runEnvXpand($1); return 1;}

%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

int cmdRunner(){
	for (int i=0; i <= p.cmdCounter; i++)
	{

		//printf("cmd: %s\n", p.cmd[i].cmd);

		struct Command *c = &p.cmd[i];
		char *args[22] = {p.cmd[i].cmd};
		int j;
		for (j=0; j < c->aIndex; j++)
		{
			//printf("arg: %s\n", c->args[j]);
			args[j+1] = c->args[j];
		}
		//args[j] = NULL;
		
		int child;
		if (child = fork() <= 0)
		{
			execv(p.cmd[i].cmd, args);
		}
		resetCmd(&p.cmd[i]);
	}

	cmdIndex = 0;
	resetCmdPipe(&p);
	return 1;

}

int runCD(char* arg) {
	int pwd = -1;

	// ensures that PWD is available for usage
	for (int i = 0; i < envIndex; i++) {
        if(strcmp(envTable.var[i], "PWD") == 0) {
			pwd = i;
        }
    }

	// if PWD is missing try to restore functionality and restart else fail
	if (pwd == -1)
	{
		printf("ERROR: internal error, PWD is missing\n");
		printf("Attempting to reinstate PWD (previous PWD will not be preserved)...");
		if (getcwd(cwd, sizeof(cwd)))
		{
			if (runSetenv("PWD", cwd))
			{
				printf("Success!\n");
				printf("Retrying cd command...\n");
				return runCD(arg);
			}
		}

		printf("Failed!\n");
		printf("Shell may need restart.\n");
		return -1;
	}

	if (arg[0] == ' ') { 
    	// move to home directory

		if (chdir(getENV("HOME")) == 0){
			strcpy(envTable.word[pwd], getENV("HOME"));
			return 1;
		}
		else
		{
			// only possible if corrupted table
			printf("HOME directory not found.\n");
			return -1;
		}
		
    }
	else if (arg[0] != '/') { // arg is relative path
		int pwdlength = strlen(envTable.word[pwd]) - 1;

		// onyl adds '/' when missing
		if (envTable.word[pwd][pwdlength] != '/')
			strcat(envTable.word[pwd], "/");
		
		char *env = strdup(envTable.word[pwd]);
		strcat(env, arg);

		if(chdir(env) == 0) {
			strcat(envTable.word[pwd], arg);
			return 1;
		}
		else {
			getcwd(cwd, sizeof(cwd));
			printf("'%s':No such file or directory\n", arg);
			return 1;
		}
	}
	else { // arg is absolute path
		if(chdir(arg) == 0){
			strcpy(envTable.word[pwd], arg);
			return 1;
		}
		else {
			printf("'%s':No such file or directory\n", arg);
            return 1;
		}
	}
}

bool recAliases(char* name, char* initial) {
   	for (int i = 0; i < aliasIndex; i++) {
		if((strcmp(aliasTable.name[i], name) == 0)) {
			if((strcmp(aliasTable.word[i], initial) == 0)) {
				return true;
			}
			return recAliases(aliasTable.word[i], initial);
		}
   	}
   	return false;
}

int runAlias() {
	if (aliasIndex > 0)
	{
		for (int i = 0; i < aliasIndex; i++)
		{
			printf("%s = %s\n", aliasTable.name[i], aliasTable.word[i]);
		}
	}

	return 1;
}

int runSetAlias(char *name, char *word) {
	if(strcmp(name, word) == 0){
		// alias a a
		printf("Error, expansion of \"%s\" would create a loop.\n", name);
		return 1;
	}

	for (int i = 0; i < aliasIndex; i++) {
		if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
			// alias a b
			// alias a b
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if(strcmp(aliasTable.name[i], name) == 0) {
			// alias a b
			// alias a c
			if(!(recAliases(word, name)))
			{
				strcpy(aliasTable.word[i], word);
				return 1;
			}
			else
			{
				printf("Error 1\n");
				return -1;
			}
		}
	}

	if(!(recAliases(word, name)))
	{
		strcpy(aliasTable.name[aliasIndex], name);
		strcpy(aliasTable.word[aliasIndex], word);
		aliasIndex++;
		return 1;
	}
	else
	{
		printf("Error 2\n");
		return -1;
	}

	return -1;
}

int runUnalias(char *name) {
	int newPos = 0;

	if (aliasIndex < 0) { return 1; }

	for(int i = 0; i < aliasIndex; ++i)
	{
		if(strcmp(aliasTable.name[i], name) == 0)
		{
			continue;
		}
		if (newPos != i) 
		{
			strcpy(aliasTable.name[newPos], aliasTable.name[i]);
			strcpy(aliasTable.word[newPos], aliasTable.word[i]);
		}
		newPos++;
	}

	aliasIndex = newPos;

	return 1;
}

/* todo (if required):
	- check for embedded aliases
		- if no known alias
			Options:
			- do nothing, but alert user to reconfigure comm.
			- add anyway and bring it up when used
		- if known alias
			Options:
			- expand to preserve current alias?
			- keep alias and expand using alias when env var called
	- check for unacceptable characters (if any)
		* using a ':' will have yytext separate (quotes do not work)
		* quotes will not stay with word, intended
	- should be able to place a quote in word?
*/

// parse path word:word:word
char* parsePath(char *path) {
	const char s[2] = ":"
	char *token;
	

	// get the first token
	token = strtok(str, s);

	// walk through other tokens
	while(token != NULL) 
	{
		// do something with tokens
		printf("%s\n", token);

		token = strtok(NULL, s);
	}
}

int runSetenv(char *var, char *word) {

	// check length of var/word string
	if ((strlen(var) >= maxCharsEV) || (strlen(word) >= maxCharsEV))
	{
		printf("Error: var/word length should be <%d.\n", maxCharsEV);
		return -1;
	}

	// may need to parse/recursively store path, we'll see
	char* temp = path; // to be placed in envTable

	// check if var is PATH
	// search for PATH environment variable
	if(strcmp(var, "PATH") == 0)
	{
		// check if first character is "."
		if (word[0] == ".")
		{
			// find PATH in table
			for (int i = 0; i < envIndex; i++) 
			{
				// store path to be parsed
				strcpy(envTable.word[i], word);
			}
		}
		else
		{
			return -1;
		}
	}
	// search for existing environment variable name
	// if yes, replace existing word and return
	else
	{
		for (int i = 0; i < envIndex; i++) {

			if(strcmp(envTable.var[i], var) == 0) 
			{
				strcpy(envTable.word[i], word);
				return 1;
			}
		}
	}
	
	// New env var to add to table if there is space, index wise
	if (envIndex < (sizeof(envTable.var)/sizeof(envTable.var[0])))
	{
		if (envIndex < (sizeof(envTable.word)/sizeof(envTable.word[0])))
		{
			strcpy(envTable.var[envIndex], var);
			strcpy(envTable.word[envIndex], word);
			envIndex++;
		}
		else
		{
			printf("Error: var size != word size. Internal error.");
			return -1;
		}
	}
	else // should no space be left, do nothing but print error
	{
		char *fullTable = "You have too many environment variables,"
							"consider unbinding some using:\n"
							"\tunsetenv [variable] \n";
		printf("%s", fullTable);
		return -1;
	}

	return 1;
}

/* due to the nature of strcpy, all chars in 2D table
 columns of a row are cleared, no leftover chars after
 setting a new variable */
int runUnsetenv(char *var) {
	if (var == "HOME")
	{
		printf("ERROR: unsetting HOME could lead to unstability. Reversing action...\n");
		return 0;
	}
	else if (var == "PATH")
	{
		printf("ERROR: unsetting PATH will break me. Please do not try again.\n");
		return 0;
	}
	// don't waste time if index is 0
	if (envIndex > 0)
	{
		// find variable to unbound
		for (int i = 0; i < envIndex; i++)
		{
			if (strcmp(envTable.var[i], var) == 0)
			{
				// unbind variable by shifting all up
				int next;
				for (int j = i; j < envIndex-1; j++)
				{
					next = j+1;
					strcpy(envTable.var[j], envTable.var[next]);
					strcpy(envTable.word[j], envTable.word[next]);
				}
				--envIndex; // remove unbinded variable index
				// next setenv will change data
				return 1;
			}
		}
	}
	return 1;
}

// relies on the accuracy of envIndex to print
int printenvTable() {

	if (envIndex > 0)
	{
		for (int i = 0; i < envIndex; i++)
		{
			printf("%s=%s\n", envTable.var[i], envTable.word[i]);
		}
	}
	else
	{
		printf("You have no environment variables...\n");
		printf("To add some, use:\n\tsetenv [variable] [value]\n");
	}
}

int runEnvXpand(char *var){
	// add to be concatenated
}