// nutshell main file
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "global.h"
#include <sys/types.h>
#include <pwd.h>

char *getcwd(char *buf, size_t size);
int yyparse();

/* struct passwd *pw = getpwuid(getuid());
const char *homedir;
char* HOME = "";
char* PATH = "usr/bin";*/

int main()
{
    aliasIndex = 0;
    varIndex = 0;

    getcwd(cwd, sizeof(cwd));

    strcpy(varTable.var[varIndex], "PWD");
    strcpy(varTable.word[varIndex], cwd);
    varIndex++;
    strcpy(varTable.var[varIndex], "HOME");
    strcpy(varTable.word[varIndex], cwd);
    varIndex++;
    strcpy(varTable.var[varIndex], "PROMPT");
    strcpy(varTable.word[varIndex], "nutshell");
    varIndex++;
    strcpy(varTable.var[varIndex], "PATH");
    strcpy(varTable.word[varIndex], ".:/bin");
    varIndex++;

    system("clear");
    while(1)
    {
        printf("[%s]>> ", varTable.word[2]);
        yyparse(); // yylex() routine to obtain a token from the input
        // check for tokens passed to yyparse()
    }

   return 0;
}
