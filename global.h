#include "stdbool.h"
#include <limits.h>

#define maxCharsEV            100

struct evTable {
   char var[128][maxCharsEV];
   char word[128][maxCharsEV];
};

struct aTable {
	char name[128][100];
	char word[128][100];
};

char cwd[PATH_MAX];

struct evTable envTable; // Environment Variable Table

struct aTable aliasTable;

int aliasIndex, envIndex, env_xpand, max_xpand;

char* subAliases(char* name);
void strFindEnv(char *str, char **outstr);
bool ifENV(char *var, char **dupWord);