using Mysql;

void main (string[] args) {
	Mysql.library_init (args);
	Mysql.Database db = new Database();
	stdout.printf("here\n");
	if (!db.real_connect ("localhost", "round", "round", "recon")) {
		message (db.error ());
		return;
	}
	db.query("select id, name from category");
	Mysql.Result r = db.store_result();
	uint num_rows = r.num_rows();
	unowned string[]? row;
	while ((row = r.fetch_row()) != null) {
		stdout.printf("%s,%s\n",row[0],row[1]);
	}
	while((row = r.fetch_row()) != null);
}

