using DBAccess;
using Mysql;
using Types;

int main (string[] argv) {
	Database dbh = db_connect("localhost", "round", "round", "round");
	Request request = Request() {
		categoryid = {10}
	};
	test_get_speakers(dbh, request);
	test_get_recordings(dbh, request);
	test_get_compositions(dbh, request);
	return 0;
}

void test_get_recordings (Database dbh, Request request) {
	Recording[] recordings = get_recordings(dbh, request);
	foreach (Recording r in recordings) {
		stdout.printf("%s,%u\n", r.filename, r.audiolength);
	}
}

void test_get_speakers (Database dbh, Request request) {
	Speaker[] speakers = get_speakers(dbh, request);
	foreach (Speaker s in speakers) {
		stdout.printf("%s,%f,%f\n", s.uri, s.latitude, s.longitude);
	}
}

void test_get_compositions (Database dbh, Request request) {
	Composition[] compositions = get_compositions(dbh, request);
	foreach (Composition c in compositions) {
		stdout.printf("%u\n", c.minduration);
	}
}

