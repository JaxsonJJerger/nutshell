#include "stdbool.h"
#include <limits.h>

struct evTable {
   char var[128][100];
   char word[128][100];
};

struct aTable {
	char name[128][100];
	char word[128][100];
};

char cwd[PATH_MAX];

struct evTable envTable; // Environment Variable Table

struct aTable aliasTable;

int aliasIndex, envIndex;

char* subAliases(char* name);