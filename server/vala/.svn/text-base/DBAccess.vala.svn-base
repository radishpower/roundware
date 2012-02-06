using Mysql;
using Types;

namespace DBAccess {
	Database db_connect (string host, string user, string password, string database) {
		string[] args = {};
		library_init (args);
		Database dbh = new Database();
		if (!dbh.real_connect (host, user, password, database)) {
			//TODO: raise exception
			message (dbh.error ());
		}
		return dbh;
	}

	//Category[] get_categories (Database dbh) { };

	Speaker[] get_speakers (Database dbh, Request request) {
		string sql_str = "select uri, latitude, longitude, mindistance, maxdistance, minvolume, maxvolume from speaker where activeyn = 'Y' and categoryid = "+request.categoryid[0].to_string();
		dbh.query(sql_str);
		Result r = dbh.store_result();
		uint num_rows = r.num_rows();
		Speaker[] results = new Speaker[num_rows];
		for (int i = 0; i < num_rows; i++) {
			unowned string[]? row = r.fetch_row();
			results[i] = Speaker () {
				uri = row[0],
				latitude = row[1].to_double(),
				longitude = row[2].to_double(),
				mindistance = row[3].to_int(),
				maxdistance = row[4].to_int(),
				minvolume = (float)row[5].to_double(),
				maxvolume = (float)row[6].to_double()
			};
		}
		return results;
	}

	//TODO: Check for errors returned from the database.
	Recording[] get_recordings (Database dbh, Request request) {
		string sql_str = "select filename, audiolength, volume, latitude, longitude from recording where submittedyn = 'Y' and audiolength is not null and " + request_to_where_clause(request);
		dbh.query(sql_str);
		Result r = dbh.store_result();
		uint num_rows = r.num_rows();
		Recording[] results = new Recording[num_rows];
		for (int i = 0; i < num_rows; i++) {
			unowned string[]? row = r.fetch_row();
			results[i] = Recording () {
				filename = row[0],
				audiolength = row[1].to_int(),
				volume = (float)row[2].to_double(),
				latitude = row[3].to_double(),
				longitude = row[4].to_double()
			};
		}

		return results;
	}

	Composition[] get_compositions (Database dbh, Request request) {
		string sql_str = "select minvolume, maxvolume, minduration, maxduration, mindeadair, maxdeadair, minfadeintime, maxfadeintime, minfadeouttime, maxfadeouttime, minpanpos, maxpanpos, minpanduration, maxpanduration, repeatrecordings from composition where categoryid = " + request.categoryid[0].to_string();
		dbh.query(sql_str);
		Result r = dbh.store_result();
		uint num_rows = r.num_rows();
		Composition[] results = new Composition[num_rows];
		for (int i = 0; i < num_rows; i++) {
			unowned string[]? row = r.fetch_row();
			results[i] = Composition () {
				minvolume = (float)row[0].to_double(),
				maxvolume = (float)row[1].to_double(),
				minduration = row[2].to_int(),
				maxduration = row[3].to_int(),
				mindeadair = row[4].to_int(),
				maxdeadair = row[5].to_int(),
				minfadeintime = row[6].to_int(),
				maxfadeintime = row[7].to_int(),
				minfadeouttime = row[8].to_int(),
				maxfadeouttime = row[9].to_int(),
				minpanpos = (float)row[10].to_double(),
				maxpanpos = (float)row[11].to_double(),//
				minpanduration = row[12].to_int(),
				maxpanduration = row[13].to_int(),
				repeatrecordings = 'Y'//(row[14] == "Y" ? 'Y' : 'N')
			};
		}
		return results;
	}

	string sql_bind_list (int[] ids) {
		string list = ids[0].to_string();
		for (int i = 1; i < ids.length; i++) {
			list += ","+ids[i].to_string();
		}
		return list;
	}

	string request_to_where_clause (Request request) {
		string sql_str = "(";
		bool used_clause = false;
		if (request.categoryid.length > 0) {
			if (used_clause) { sql_str += " and "; } else { used_clause = true; }
			sql_str += "categoryid in (" + sql_bind_list(request.categoryid) + ")";
		}
		if (request.subcategoryid.length > 0) {
			if (used_clause) { sql_str += " and "; } else { used_clause = true; }
			sql_str += "subcategoryid in (" + sql_bind_list(request.subcategoryid) + ")";
		}
		if (request.questionid.length > 0) {
			if (used_clause) { sql_str += " and "; } else { used_clause = true; }
			sql_str += "questionid in (" + sql_bind_list(request.questionid) + ")";
		}
		if (request.ageid.length > 0) {
			if (used_clause) { sql_str += " and "; } else { used_clause = true; }
			sql_str += "ageid in (" + sql_bind_list(request.ageid) + ")";
		}
		if (request.genderid.length > 0) {
			if (used_clause) { sql_str += " and "; } else { used_clause = true; }
			sql_str += "genderid in (" + sql_bind_list(request.genderid) + ")";
		}
		if (request.usertypeid.length > 0) {
			if (used_clause) { sql_str += " and "; } else { used_clause = true; }
			sql_str += "usertypeid in (" + sql_bind_list(request.usertypeid) + ")";
		}
		if (!used_clause) {
			sql_str += "1=1";
		}

		sql_str += ")";
		return sql_str;
	}
}


