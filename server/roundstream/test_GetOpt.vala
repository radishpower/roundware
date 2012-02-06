using GetOpt;

void main (string[] args) {
	Options o = new Options(args);
	stdout.printf("%d\n", o.get_request().categoryids[0]);
	o.get_request();
	return;
}

