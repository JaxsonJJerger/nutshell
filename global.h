#include "stdbool.h"
#include <limits.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#define maxCharsEV            100

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
   int aIndex;
   char* cmd;
   char* in;
   char* out;
   char* args[20];
};

struct Pipeline
{
   bool bg;
   int cmdCounter;
   struct Command cmd[20];
};

char cwd[PATH_MAX];

struct evTable envTable; // Environment Variable Table

struct aTable aliasTable;

struct Pipeline p;

char *cmdArgs[100];

int aliasIndex, envIndex, env_xpand, max_xpand, cmdIndex;

char* subAliases(char* name);
char* strFindEnv(char *str);
bool ifENV(char *var);
char* getENV(char *var);

void initCmd(struct Command *c);
void resetCmd(struct Command *c);
void resetCmdPipe(struct Pipeline *p);