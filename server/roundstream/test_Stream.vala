using Stream;
using Gst;

/*
void test_gnomevfsmp3src (string[] args) {
	Gst.init (ref args);
	Pipeline pipeline = new Pipeline("test");
	Element src = new GnomeVFSMP3Src("http://wbur-sc.streamguys.com:80/", 1);
	Element alsasink = ElementFactory.make("alsasink", "alsasink");
	pipeline.add_many(src, alsasink);
	src.link(alsasink);
	pipeline.set_state (State.PLAYING);
	MainLoop loop = new MainLoop (null, false);
	loop.run ();
}
*/

void test_roundstream (string[] args) {
	Gst.init (ref args);
	Stream.Stream s = new RoundStream.Stream("foo");
	s.start();
	MainLoop loop = new MainLoop (null, false);
	loop.run ();
}

void main (string[] args) {
	test_roundstream(args);
	//test_gnomevfsmp3src(args);
}
