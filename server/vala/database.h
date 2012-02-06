#ifndef DATABASE_H
#define DATABASE_H

typedef struct {
	int id;
	char *name;
	//char imagefile[50];
	//char bcfile[30];
	char *musicuri;
	float musicvolume;
	//char activeyn;
	//int projectid;
} Category;

typedef struct {
	int id;
	char activeyn;
	int categoryid;
	double latitude, longitude;
	int mindistance, maxdistance;
	float minvolume, maxvolume;
	char *uri;
} Speaker;

typedef struct {
	int id;
	char *filename;
	unsigned int audiolength;
	float volume;
	double latitude, longitude;
} Recording;

typedef struct {
	int id;
	float minvolume, maxvolume;
	unsigned int minduration, maxduration;
	unsigned int mindeadair, maxdeadair;
	unsigned int minfadeintime, maxfadeintime;
	unsigned int minfadeouttime, maxfadeouttime;
	float minpanpos, maxpanpos;
	unsigned int minpanduration, maxpanduration;
	char repeatrecordings;
} Composition;

MYSQL* getDatabaseHandle(const char *host, const char *user, const char *password, const char *database);
Category* getCategories (MYSQL *dbh, int *count);
Speaker* getSpeakers (MYSQL *dbh, int *count);
Recording* getRecordings (MYSQL *dbh, int *count);
Composition* getCompositions (MYSQL *dbh, int *count);

#endif

