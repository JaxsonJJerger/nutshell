#include "stdbool.h"
#include <limits.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <pwd.h>
#include <stdint.h>
#include <stdio.h>

#define maxCharsEV               100
#define IO_in                    (uint32_t)(1<<0)
#define IO_out                   (uint32_t)(1<<1)
#define IO_outa                  (uint32_t)(1<<2)
#define IO_errf                  (uint32_t)(1<<3)
#define IO_errout                (uint32_t)(1<<4)

struct evTable {
   char var[128][maxCharsEV];
   char word[128][maxCharsEV];
};

struct aTable {
	char name[128][100];
	char word[128][100];
};


struct Command
{
   int aIndex; // ARRAY INDEX + 1
   char* cmd;
   char* in;
   char* out;
   char* args[50];
};

struct Pipeline
{

   unsigned int io_bits : 5;

   bool bg;
   int cmdCounter;   // EQUIVALENT TO CMD ARRAY INDEX
   char* ioFile[3];
   struct Command cmd[50];
};

// struct passwd *pw = getpwuid(getuid());

char cwd[PATH_MAX];

struct evTable envTable; // Environment Variable Table

struct aTable aliasTable;

struct Pipeline p;

char *cmdArgs[100];

char currPathTokens[128][100];

int aliasIndex, envIndex, env_xpand, max_xpand, cmdIndex, pathIndex;

const char *homedir, *currdir;

// int resetCurrPath(char[][]*);

char* subAliases(char* name);
char* strFindEnv(char *str);
char* getENV(char *var);
int runCD(char* arg);
bool ifENV(char *var);

void initCmd(struct Command *c);
void resetCmd(struct Command *c);
void resetCmdPipe(struct Pipeline *p);
int addCmdArg(struct Command *c, char *toInsert);
const char* getHomeDir();
const char* getCurrDir();
char* getCmdPath(char *cmd);
int addCmdArg(struct Command *c, char *toInsert);
