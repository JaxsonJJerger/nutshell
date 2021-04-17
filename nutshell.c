// nutshell main file
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "global.h"
#include <sys/types.h>
#include <pwd.h>

void initCmd(struct Command *c)
{
    c->aIndex = 0;
}

void resetCmd(struct Command *c)
{
    //for (int i=0; i < c->aIndex; i++)
    memset(&c->args, 0, sizeof(c->args));
    memset(&c->aIndex, 0, sizeof(c->aIndex));
    memset(&c->cmd, 0, sizeof(c->cmd));
    memset(&c->in, 0, sizeof(c->in));
    memset(&c->out, 0, sizeof(c->out));

}

void resetCmdPipe(struct Pipeline *p)
{
    for (int i=0; i <= p->cmdCounter; i++)
        resetCmd(&p->cmd[i]);
    p->bg = false;
    memset(&p->ioFile, 0, sizeof(p->ioFile));
    p->io_bits &= 0;
    memset(&p->cmdCounter, 0, sizeof(p->cmdCounter));
}

char *getcwd(char *buf, size_t size);
int yyparse();

/* struct passwd *pw = getpwuid(getuid());
const char *homedir;
char* HOME = "";
char* PATH = "usr/bin";*/

int main()
{
    aliasIndex = 0;
    envIndex = 0;
    env_xpand = 0;
    max_xpand = 1;
    cmdIndex = 0;
    p.cmdCounter = 0;
    p.bg = false;
    p.io_bits &= 0;


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
        fprintf(stdout,"[%s]>> ", getENV("PROMPT"));
        fflush(stdout);
        yyparse(); // yylex() routine to obtain a token from the input
        // check for tokens passed to yyparse()
    }

   return 0;
}
