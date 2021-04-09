%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "global.h"

int yylex(void);
int yyerror(char *s);
int runCD(char* arg);
int runSetAlias(char *name, char *word);
int runSetenv(char *var, char *word);
int printenvTable();
int runUnsetenv(char *var);
int runEnvXpand(char *var);
%}

%union {char *string;}

%start cmd_line
%token <string> BYE CD STRING ALIAS SETENV PRINTENV UNSETENV ENV END

%%
cmd_line    :
	BYE END 		                {exit(1); return 1;}
	| CD END                        {runCD(" "); return 1;}
	| CD STRING END        			{runCD($2); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
	| SETENV STRING STRING END		{runSetenv($2, $3); return 1;}
	| PRINTENV END					{printenvTable(); return 1;}
	| UNSETENV STRING END			{runUnsetenv($2); return 1;}
	| ENV							{runEnvXpand($1); return 1;}

%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

int runCD(char* arg) {
	if (arg[0] == ' ') { 
		// no arg available
    	// move to home directory
        
    }
	else if (arg[0] != '/') { // arg is relative path

		strcat(envTable.word[0], "/");
		strcat(envTable.word[0], arg);

		if(chdir(envTable.word[0]) == 0) {
			return 1;
		}
		else {
			getcwd(cwd, sizeof(cwd));
			strcpy(envTable.word[0], cwd);
			printf("Directory not found\n");
			return 1;
		}
	}
	else { // arg is absolute path
		if(chdir(arg) == 0){
			strcpy(envTable.word[0], arg);
			return 1;
		}
		else {
			printf("Directory not found\n");
                       	return 1;
		}
	}
}

int runSetAlias(char *name, char *word) {
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(name, word) == 0){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if(strcmp(aliasTable.name[i], name) == 0) {
			strcpy(aliasTable.word[i], word);
			return 1;
		}
	}
	strcpy(aliasTable.name[aliasIndex], name);
	strcpy(aliasTable.word[aliasIndex], word);
	aliasIndex++;

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
int runSetenv(char *var, char *word) {

	// check length of var/word string
	if ((strlen(var) >= maxCharsEV) || (strlen(word) >= maxCharsEV))
	{
		printf("Error: var/word length should be <%d.\n", maxCharsEV);
		return -1;
	}

	// search for existing environment variable name
	// if yes, replace existing word and return
	for (int i = 0; i < envIndex; i++) {

		if(strcmp(envTable.var[i], var) == 0) 
		{
			strcpy(envTable.word[i], word);
			return 1;
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