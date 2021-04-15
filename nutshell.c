// nutshell main file
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "global.h"


void initCmd(struct Command *c)
{
    c->aIndex = 0;
}

void resetCmd(struct Command *c)
{
    for (int i=0; i < c->aIndex; i++)
        c->args[i] = NULL;
    c->aIndex = 0;
    c->cmd = NULL;
    c->in = NULL;
    c->out = NULL;
}

void resetCmdPipe(struct Pipeline *p)
{
    for (int i=0; i < p->cmdCounter; i++)
        resetCmd(&p->cmd[i]);
    p->bg = 0;
    p->cmdCounter = 0;
}

char *getcwd(char *buf, size_t size);
int yyparse();

int main()
{
    aliasIndex = 0;
    envIndex = 0;
    env_xpand = 0;
    max_xpand = 1;
    cmdIndex = 0;
    p.cmdCounter = 0;
    p.bg = false;


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
        printf("[%s]>> ", getENV("PROMPT"));
        yyparse(); // yylex() routine to obtain a token from the input
        // check for tokens passed to yyparse()
    }

   return 0;
}
