using Gst;

namespace Composition {
	class Composition : Gst.Bin {
		CompositionSettings settings;
		Recording[] recordings;
		Element adder;
		int current_pan_position = 0;
		int target_pan_position = 0;
		bool can_stereo_pan = false;

		public Composition (CompositionSettings settings, Recording[] recordings) {
			this.settings = settings;
			this.recordings = recordings;
		}

		public void wait_and_play () {
			uint deadair = Random.int_range(this.settings.min_dead_air, this.settings.max_dead_air);
			Timeout.add(deadair, () => {
				this.add_file();
				return false;
			});
		}

		private void add_file () {
			if (this.recordings.length == 0) {
				//send parent eos if repeat recordings is not in effect
				this.set_currently_not_playing_or_pending();
				return;
			}

			Recording recording = this.get_random_recording();
			int duration = min(
				recording.audiolength,
				Random.int_range(this.settings.min_duration, this.settings.max_duration));
			int start = Random.int_range(0, recording.audiolength - duration);
			int fadein = Random.int_range(this.settings.min_fadein, this.settings.max_fadein);
			int fadeout = Random.int_range(this.settings.min_fadeout, this.settings.max_fadeout);
			//FIXME: Instead of doing this divide by two, instead, decrease them by
			//the same percentage. Remember it's possible that fade_in != fade_out.
			if (fadein + fadeout > duration) {
				fadein = duration / 2;
				fadeout = duration / 2;
			}
			int volume = recording.volume * (
				this.settings.min_volume +
				Random.next_double() * (this.settings.max_volume - this.settings.min_volume))
			GnomeVFSMP3FileSrc.GnomeVFSMP3FileSrc src =
				new GnomeVFSMP3FileSrc.GnomeVFSMP3FileSrc (
					"file://" + AUDIO_DIR + "/" + recording.filename,
					volume, duration, fadein, fadeout)
			this.add(src)
			Gst.Pad srcpad = src.get_pad("src");
			Gst.Pad addersinkpad = this.adder.get_request_pad("sink%d");
			srcpad.link(addersinkpad);
			addersinkpad.add_event_probe(this.event_probe);
		}

		//TODO: This function should check if repeat is on, if it's not,
		//	remove the chosen file from the array.
		private Recording get_random_recording () {
			int index = Random.int_range (0, this.recordings.length);
			return this.recording[index];
		}

		private bool event_probe (Gst.Pad pad, Gst.Event event) {
			if (event.type == Gst.EVENT_EOS) {
				GObject.idle_add(this.clean_up);
			} else if (event.type == Gst.EVENT_NEWSEGMENT) {
				GObject.idle_add(this.roundfilesrc.seek_to_start);
			}
			return true;
		}

		private void clean_up () {
			if (this.currently_playing) {
				this.set_currently_pending_playing();
				this.roundfilesrc.set_state(Gst.STATE_NULL);
				this.remove(this.roundfilesrc);
				this.adder.release_request_pad(this.addersinkpad);
				this.wait_and_play();
			}
			return false;
		}
	}
}

