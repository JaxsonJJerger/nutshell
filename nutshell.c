// nutshell main file
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "global.h"


char *getcwd(char *buf, size_t size);
int yyparse();

int main()
{
    aliasIndex = 0;
    envIndex = 0;

    getcwd(cwd, sizeof(cwd));

    strcpy(envTable.var[envIndex], "PWD");
    strcpy(envTable.word[envIndex], cwd);
    envIndex++;
    strcpy(envTable.var[envIndex], "HOME");
    strcpy(envTable.word[envIndex], cwd);
    envIndex++;
    strcpy(envTable.var[envIndex], "PROMPT");
    strcpy(envTable.word[envIndex], "nutshell");
    envIndex++;
    strcpy(envTable.var[envIndex], "PATH");
    strcpy(envTable.word[envIndex], ".:/bin");
    envIndex++;

    system("clear");
    while(1)
    {
        printf("[%s]>> ", envTable.word[2]);
        yyparse(); // yylex() routine to obtain a token from the input
        // check for tokens passed to yyparse()
    }

   return 0;
}
