#include <stdio.h>
#include <stdlib.h>
#include <mysql/mysql.h>
#include "database.h"

MYSQL* getDatabaseHandle(const char *host, const char *user, const char *password, const char *database) {
	MYSQL *dbh = mysql_init (NULL);
	if (!mysql_real_connect(dbh, host, user, password, database, 0, NULL, 0)) {
		return NULL;
	}
	return dbh;
}

Category* getCategories (MYSQL* dbh, int *count) {
	mysql_query(dbh, "select id, name, musicuri, ifnull(musicvolume,1.0) from category where activeyn = 'Y'");
	MYSQL_RES *result = mysql_store_result(dbh);
	unsigned int numRows = mysql_num_rows(result);
	*count = numRows;
	Category *categories = malloc(numRows * sizeof(Category*));
	for (int i = 0; i < numRows; i++) {
		char **row = mysql_fetch_row(result);
		Category category = {
			atoi(row[0]), //id
			row[1], //name
			row[2], //musicuri
			strtof(row[3], NULL) //musicvolume
		};
		categories[i] = category;
	}
	return categories;
}

Speaker* getSpeakers (MYSQL *dbh, Request request, int *count) {
}

Recording* getRecordings (MYSQL *dbh, Request request, int *count) {
	
}

Composition* getCompositions (MYSQL *dbh, int *count) {
}

int main (int argc, char** argv) {
	mysql_library_init (argc, argv, NULL);
	MYSQL *dbh = getDatabaseHandle("localhost", "round", "round", "round");
	int numCategories;
	Category *categories = getCategories(dbh, &numCategories);
	for (int i = 0; i < numCategories; i++) {
		printf("%d, %s, %s, %f\n",
			categories[i].id, categories[i].name, categories[i].musicuri, categories[i].musicvolume);
	}
	return 0;
}

