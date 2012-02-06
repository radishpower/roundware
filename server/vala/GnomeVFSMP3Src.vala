using Gst;

namespace GnomeVFSMP3Src {
	class GnomeVFSMP3Src : Gst.Bin {
		public GnomeVFSMP3Src (string uri, double volume_level = 1.0) {
			Element gnomevfssrc = ElementFactory.make("gnomevfssrc", "gnomevfssrc1");
			gnomevfssrc.set("location", uri);
			Element mad = ElementFactory.make("mad", "mad1");
			Element audioconvert = ElementFactory.make("audioconvert", "audioconvert1");
			Element audioresample = ElementFactory.make("audioresample", "audioresample1");
			Element volume = ElementFactory.make("volume", "volume1");
			volume.set("volume", volume_level);
			this.add_many(gnomevfssrc, mad, audioconvert, audioresample, volume);
			gnomevfssrc.link(mad);
			mad.link(audioconvert);
			audioconvert.link(audioresample);
			audioresample.link(volume);
			Pad pad = volume.get_pad("src");
			GhostPad ghost_pad = new GhostPad("src", pad);
			this.add_pad(ghost_pad);
		}
	}
}

