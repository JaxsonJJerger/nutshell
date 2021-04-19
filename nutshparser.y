%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include "global.h"

int yylex(void);
int yyerror(char *s);
int cmdRunner();
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

%token <string> BYE CD STRING ALIAS UNALIAS SETENV PRINTENV UNSETENV CMD END

%%
cmd_line    :
	BYE END 		                {printf("\n"); exit(1); return 1; }
	| CD END						{runCD(" "); return 1; }
	| CD STRING END        			{runCD($2); return 1;}
	| ALIAS END						{runAlias(" "); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
	| UNALIAS STRING END			{runUnalias($2); return 1;}
	| SETENV STRING STRING END		{runSetenv($2, $3); return 1;}
	| PRINTENV END					{printenvTable(); return 1;}
	| UNSETENV STRING END			{runUnsetenv($2); return 1;}
	| CMD END						{cmdRunner(); return 1;}
	| END							{return 1;}

%%

int yyerror(char *s) {
  fprintf(stderr, "%s\n",s);
  return 0;
  }

int openFile(FILE **file){
	if (p.io_bits & IO_out)
		*file = fopen(p.ioFile[1], "w");
	else if (p.io_bits & IO_outa)
		*file = fopen(p.ioFile[1], "a");
	else
		*file = stdout;
	return 1;
}

int pipeliner(int cOut, int cIn){
	int pipeline[2], status, done=0;
	pipe(pipeline);

	pid_t procid, procid2;

	procid = fork();
	int i;
	if(procid == 0) // child
	{
		i = 0;

		dup2(pipeline[1], STDOUT_FILENO);
		execv(p.cmd[cOut].cmd, p.cmd[cOut].args);
		_exit(EXIT_FAILURE);
	}
	procid2 = fork();
	if(procid2 == 0) // child
	{
		i = 1;
		close(pipeline[1]);

		dup2(pipeline[0], STDIN_FILENO);
		execv(p.cmd[cIn].cmd, p.cmd[cIn].args);
		_exit(EXIT_FAILURE);
	}

	if (p.cmdCounter > cIn)
	{
		int child;
		if (child = fork() <= 0)
		{
			pipeliner(++cOut, ++cIn);
		}
		else
			wait(NULL);
	}

	close(pipeline[0]);
	close(pipeline[1]);
}

void ioRedirect(char *cmd, char *args[])
{
	int child2;
	int fileIn, fileOut, fileErr;
	if (p.io_bits & (IO_errout|IO_errf|IO_outa|IO_out|IO_in))
	{
		//int current_in;
		
		if(p.io_bits & IO_in)
		{
			fileIn = open(p.ioFile[0], O_RDONLY);
			dup2(fileIn, STDIN_FILENO);
			
			//current_in = dup(0);	// keeps current buffer
		}
		if(p.io_bits & (IO_out | IO_outa))
		{
			if (p.io_bits & IO_out)
				fileOut = open(p.ioFile[1], O_WRONLY | O_TRUNC);
			else if (p.io_bits & IO_outa)
				fileOut = open(p.ioFile[1], O_WRONLY | O_APPEND);
			
			dup2(fileOut, STDOUT_FILENO);
			
		}
		if(p.io_bits & (IO_errf | IO_errout))
		{
			if (p.io_bits & IO_errf)		// should append to file
			{	
				fileErr = open(p.ioFile[2], O_WRONLY | O_APPEND);
				dup2(fileErr, STDERR_FILENO);
			}
			else if (p.io_bits & IO_errout)  // should print err to screen
			{
				dup2(STDOUT_FILENO, STDERR_FILENO);
				//current_outerr = dup(2);
			}
			
			
		}
		
		// for (int i = 0; i < 3; i++)
	 	// 	printf("io_files: %s\n", p.ioFile[i]);
	}

	if (child2 = fork() <= 0)
	{
		execv(cmd, args);
	}
	else
	{
		wait(NULL);
	}
		
	close(fileIn);
	close(fileOut);
	close(fileErr);
	// 	if (!(strcmp(p.ioFile[i], NULL) == 0))

}

int cmdRunner(){
	
	int child, child2;
	if (child = fork() <= 0)	//start in child process to avoid pipes crashing
	{
		
		if (cmdIndex > 1)	// number of cmds is more than 1
		{
			//printf("In the pipeline.\n");
			pipeliner(0, 1);
		}
		else if (cmdIndex == 1){
			if (p.cmd[0].aIndex == 1) // no args available besides path
			{
				char *aRep[2] = {strdup(p.cmd[0].args[0]), 0};
				ioRedirect(p.cmd[0].cmd, aRep);
				// if (child2 = fork() <= 0)
				// 	execv(p.cmd[0].cmd, p.cmd[0].args);
				// else
				// 	wait(NULL);
			}
			else
			{

				ioRedirect(p.cmd[0].cmd, p.cmd[0].args);
				// if (child2 = fork() <= 0)
				// 	execv(p.cmd[0].cmd, p.cmd[0].args);
				// else
				// 	wait(NULL);
			}
				
		}
		exit(1);
		_exit(EXIT_FAILURE);	
	}
	else
	{
		//printf("Parent process\n");
		if (p.bg == false)
			wait(NULL);
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
		fprintf(stderr, "ERROR: internal error, PWD is missing\n");
		fprintf(stderr, "Attempting to reinstate PWD (previous PWD will not be preserved)...");
		if (getcwd(cwd, sizeof(cwd)))
		{
			if (runSetenv("PWD", cwd))
			{
				printf("Success!\n");
				printf("Retrying cd command...\n");
				return runCD(arg);
			}
		}

		fprintf(stderr, "Failed!\n");
		fprintf(stderr, "Shell may need restart.\n");
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
			fprintf(stderr, "HOME directory not found.\n");
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
			fprintf(stderr, "'%s':No such file or directory\n", arg);
			return 1;
		}
	}
	else { // arg is absolute path
		if(chdir(arg) == 0){
			strcpy(envTable.word[pwd], arg);
			return 1;
		}
		else {
			fprintf(stderr, "'%s':No such file or directory\n", arg);
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

	int child;
	FILE *fileOut;
	if (child = fork() <= 0)
	{
		openFile(&fileOut);

		if (aliasIndex > 0)
		{
			for (int i = 0; i < aliasIndex; i++)
			{
				fprintf(fileOut,"%s=%s\n", aliasTable.name[i], aliasTable.word[i]);
			}
		}
		fclose(fileOut);
		exit(0);
	}
	else
	{
		wait(NULL);
	}

	cmdIndex = 0;
	resetCmdPipe(&p);
	return 1;
}

int runSetAlias(char *name, char *word) {
	if(strcmp(name, word) == 0){
		// alias a a
		fprintf(stderr, "Error, expansion of \"%s\" would create a loop.\n", name);
		return 1;
	}

	for (int i = 0; i < aliasIndex; i++) {
		if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
			// alias a b
			// alias a b
			fprintf(stderr, "Error, expansion of \"%s\" would create a loop.\n", name);
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
				printf("Error");
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
		printf("Error");
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

const char* getHomeDir(){
   const char* homedir = getpwuid(getuid())->pw_dir;
   return homedir;
}

const char* getCurrDir(){
   const char* currdir = getcwd(cwd, sizeof(cwd));
   return currdir;
}

char* replaceInPath(const char* path, const char* oldChar, const char* newDir)
{
    // count special characters in path
    int dirLength = strlen(newDir);
    int count = 0;
    int i;
    for (i = 0; path[i] != '\0'; ++i) 
    {
        if (strstr(&path[i], oldChar) == &path[i]) 
        {
            count++;
        }
    }

    char* newPath = (char*)malloc(i + count * dirLength);
  
    // compare strings
    int j = 0;
    while (*path) {
        if (strstr(path, oldChar) == path) 
        {
            strcpy(&newPath[j], newDir);
            path++;
            j += dirLength;
        }
        else
        {
            newPath[j++] = *path++;
        }     
    }

    newPath[j] = '\0';
    return newPath;
}

int clearPathTokens()
{
	// printf("Clearing Path: \n");
	for(int i = 0; i <= pathIndex; i++)
	{
		strcpy(currPathTokens[i], "\0");
		pathIndex--;
	}

	return 1;
}

int parsePath(char* path, char* delim)
{
	// printf("Parsing Path: \n");
	// check if path is empty, if not clear it
	if(pathIndex != 0)
	{
		// clear path token array
		// printf("Current Path Index: %d. Path must be cleared first.\n", pathIndex);
		clearPathTokens();
	}

	// remove first char '.' from path
	if(path[0] == '.')
	{
		memmove(path, path+1, strlen(path));
	}

	char* token = strtok(path, delim);

	int i = 0;
	while(token != NULL)
	{
		// printf("Incoming token: %s\n", token);
		if(strcmp(token, "."))
		{

		}
		strcpy(currPathTokens[i], token);
		pathIndex++;
		i++;
		token = strtok(NULL, delim);
	}
	i = 0; // reset i

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
		fprintf(stderr, "Error: var/word length should be <%d.\n", maxCharsEV);
		return -1;
	}

	// search for existing environment variable name
	// if yes, replace existing word and return
	for (int i = 0; i < envIndex; i++) {
		if(strcmp(envTable.var[i], var) == 0) 
		{
			// check for special conventions
			const char* tempWord = word;
			const char* temp = getHomeDir();
			char buf[100];
			strcpy(buf, temp);
			const char* tempHome = strcat(buf, "/");			
			char* tempTilde = replaceInPath(tempWord, "~", tempHome);
			char* newPath = replaceInPath(tempTilde, "//", "/");

			// store path in envTable
			strcpy(envTable.word[i], newPath);

			// check if word is path
			if(word[0] == '.') 
			{
				parsePath(word, ":");
			}
			else
			{
				printf("Error: path must begin with a '.'");
			}
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
			fprintf(stderr,"Error: var size != word size. Internal error.");
			return -1;
		}
	}
	else // should no space be left, do nothing but print error
	{
		char *fullTable = "You have too many environment variables,"
							"consider unbinding some using:\n"
							"\tunsetenv [variable] \n";
		fprintf(stderr, "%s", fullTable);
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
		fprintf(stderr,"ERROR: unsetting HOME could lead to unstability. Reversing action...\n");
		return 0;
	}
	else if (var == "PATH")
	{
		fprintf(stderr,"ERROR: unsetting PATH will break me. Please do not try again.\n");
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

	int child;
	FILE *fileOut;
	if (child = fork() <= 0)
	{
		openFile(&fileOut);
		
		if (envIndex > 0)
		{
			for (int i = 0; i < envIndex; i++)
			{
				fprintf(fileOut, "%s=%s\n", envTable.var[i], envTable.word[i]);
			}
		}
		else
		{
			if (p.io_bits & IO_errf)
			{
				fprintf(fileOut, "You have no environment variables...\n");
				fprintf(fileOut, "To add some, use:\n\tsetenv [variable] [value]\n");
			}
			else
			{
				fprintf(stderr, "You have no environment variables...\n");
				fprintf(stderr, "To add some, use:\n\tsetenv [variable] [value]\n");
			}
		}

		fclose(fileOut);
		exit(0);
	}
	else
	{
		wait(NULL);
	}

	cmdIndex = 0;
	resetCmdPipe(&p);
	return 1;
}

int runEnvXpand(char *var){
	// add to be concatenated
}