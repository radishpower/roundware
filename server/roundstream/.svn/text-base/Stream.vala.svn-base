//TODO: Logging.
//TODO: Settings.
//TODO: Database.
//TODO: Stereo pan interval
//TODO: Icecast ping.
//TODO: GPS Mixer
//TODO: Handle EOS on non-repeating compositions
//TODO: Skip ahead
//TODO: modify stream

using GLib;
using Gst;
using GnomeVFSMP3Src;

namespace Stream {

	//const string STREAM_CAPS = "audio/x-raw-int,rate=44100,channels=2,width=16,depth=16,signed=(boolean)true";
	const string ICE_USER = "source";
	const string ICE_PASSWORD = "roundice";
	const double MASTER_VOLUME = 1;
	const string MUSIC_URI = "http://wbur-sc.streamguys.com:80/";
	const double MUSIC_VOLUME = 1.0;

	class Stream : GLib.Object {

		private string stream_name;
		//private string request;
		private Pipeline pipeline;
		private Element adder;
		private Bus bus;

		public Stream (string stream_name) {
			this.stream_name = stream_name;
			//this.request = request;
			//this.recordings = db.get_recordings(this.request);
		}

		public void start () {
			this.pipeline = new Pipeline("pipeline0");
			this.adder = ElementFactory.make("adder", "adder0");
			Element sink = new RoundSink(ServerUtils.icecast_mount_point(this.stream_name));
			this.pipeline.add_many(this.adder, sink);
			this.adder.link(sink);
			this.add_background_source();
			this.add_voice_compositions();
			this.add_bus_watcher();
			this.pipeline.set_state(State.PLAYING);
		}

		private void add_background_source () {
			if (MUSIC_URI == "") {
				this.add_source(new BlankAudioSrc());
			} else {
				this.add_source(new GnomeVFSMP3Src.GnomeVFSMP3Src(MUSIC_URI, MUSIC_VOLUME));
			}
		}

		private void add_voice_compositions () {
		}

		private void add_bus_watcher () {
			this.bus = this.pipeline.get_bus();
			this.bus.add_watch(this.get_message);
		}

		private void add_source (Element src) {
			this.pipeline.add(src);
			Pad srcpad = src.get_pad("src");
			Pad addersinkpad = this.adder.get_request_pad("sink%d");
			srcpad.link(addersinkpad);
		}

		private bool get_message (Gst.Bus bus, Gst.Message message) {
			stdout.printf("%s", message.src.get_name());
			switch (message.type) {
				case Gst.MessageType.ELEMENT:
					string structure_name = message.structure.get_name();
					stdout.printf("Message from %s", structure_name);
					break;
				case Gst.MessageType.WARNING:
					warning ("%s", message.structure.to_string ());
					break;
				case Gst.MessageType.ERROR:
					critical ("%s", message.structure.to_string());
					break;
				default:
					break;
			}

			return true;
		}
	}

	class RoundSink : Gst.Bin {
		public RoundSink (string mount_point) {
			//TODO: There's no capsfilter. Is it needed? Why is it commented out? I think it wasn't working.
			//Element capsfilter = ElementFactory.make("capsfilter", "capsfilter0");
			//Caps c = new Caps.empty();
			//c.from_string(STREAM_CAPS);
			//capsfilter.set("caps", c);
			Element volume = ElementFactory.make("volume", "volume0");
			volume.set("volume", MASTER_VOLUME);
			Element lame = ElementFactory.make("lame", "lame0");
			Element shout2send = ElementFactory.make("shout2send", "shout2send0");
			shout2send.set("username", ICE_USER);
			shout2send.set("password", ICE_PASSWORD);
			shout2send.set("mount", mount_point);
			this.add_many(/*capsfilter,*/ volume, lame, shout2send);
			//capsfilter.link(volume);
			volume.link(lame);
			lame.link(shout2send);
			Pad pad = /*capsfilter*/volume.get_pad("sink");
			GhostPad ghost_pad = new GhostPad("sink", pad);
			this.add_pad(ghost_pad);
		}
	}

	class BlankAudioSrc : Gst.Bin {
		public BlankAudioSrc (int wave = 4) {
			Element audiotestsrc = ElementFactory.make("audiotestsrc", "audiotestsrc0");
			audiotestsrc.set("wave", wave); //4 is silence
			Element audioconvert = ElementFactory.make("audioconvert", "audioconvert0");
			this.add_many(audiotestsrc, audioconvert);
			audiotestsrc.link(audioconvert);
			Pad pad = audioconvert.get_pad("src");
			GhostPad ghost_pad = new GhostPad("src", pad);
			this.add_pad(ghost_pad);
		}
	}
}

