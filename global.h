#include "stdbool.h"
#include <limits.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <pwd.h>

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
   int aIndex; // ARRAY INDEX + 1
   char* cmd;
   char* in;
   char* out;
   char* args[50];
};

struct Pipeline
{
   bool bg;
   int cmdCounter;   // EQUIVALENT TO CMD ARRAY INDEX
   struct Command cmd[50];
};

// struct passwd *pw = getpwuid(getuid());

char cwd[PATH_MAX];

struct evTable envTable; // Environment Variable Table

struct aTable aliasTable;

struct Pipeline p;

char *cmdArgs[100];

char *currPathTokens[100];

int aliasIndex, envIndex, env_xpand, max_xpand, cmdIndex, pathIndex;

const char *homedir;

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
