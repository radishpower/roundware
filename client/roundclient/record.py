import gobject
import pygst
pygst.require("0.10")
import gst
import settings
import gui_helper
import time
import webservice

class ClientRecord:
	def __init__ (self, level_meter, count_down_label, on_done, on_eos, on_error):
		self.level_meter = level_meter
		self.count_down_label = count_down_label
		self.on_done = on_done
		self.on_eos = on_eos
		self.on_error = on_error

		self.record_pipeline = None
		self.play_pipeline = None
		self.record_watch_id = None
		self.play_watch_id = None
		self.count_down_id = None

	def prepare_for_recording (self):
		self.time_left = settings.config.getint("client","max_recording_length")
		self.set_count_down_label(self.time_left)

	def record (self, user, request):
		self.filename = "/media/mmc2/round_recorded_file.wav" #TODO
		self.user = user
		self.request = request
		self.record_pipeline = gst.Pipeline()
		dsppcmsrc = gst.element_factory_make("dsppcmsrc")
		self.level = gst.element_factory_make("level")
		self.level.set_property("interval", 100)
		self.level.set_property("message", True)
		capsfilter = gst.element_factory_make("capsfilter")
		outcaps = gst.Caps ("audio/x-raw-int,channels=1,rate=8000,width=16,depth=16")
		capsfilter.props.caps = outcaps
		wavenc = gst.element_factory_make("wavenc")
		filesink = gst.element_factory_make("filesink")
		filesink.set_property ("location", self.filename)
		self.record_pipeline.add (dsppcmsrc, self.level, capsfilter, wavenc, filesink)
		gst.element_link_many(dsppcmsrc, self.level, capsfilter, wavenc, filesink)
		self.record_pipeline.set_state(gst.STATE_PLAYING)

		self.bus = self.record_pipeline.get_bus()
		self.bus.add_signal_watch()
		self.record_watch_id = self.bus.connect("message", self.get_message_record)
		self.count_down_id = gobject.timeout_add(1000, self.count_down)

	def count_down (self):
		self.time_left -= 1
		if self.time_left == 0:
			self.stop_recording()
			self.on_done()
			return False
		else:
			self.set_count_down_label(self.time_left)
			return True

	def set_count_down_label (self, seconds):
		self.count_down_label.set_markup(
			"<span weight=\"bold\">"+gui_helper.markup(50,str(seconds))+"</span>")

	def stop_recording (self):
		self.update_level_meter(-100.0)
		if self.record_pipeline:
			if self.record_watch_id:
				self.record_pipeline.get_bus().remove_signal_watch()
				self.record_pipeline.get_bus().disconnect(self.record_watch_id)
				self.record_watch_id = None
			self.record_pipeline.set_state(gst.STATE_NULL)
			self.record_pipeline = None
		if self.count_down_id:
			gobject.source_remove(self.count_down_id)
			self.count_down_id = None

	def stop_playback (self):
		if self.play_pipeline:
			if self.play_watch_id:
				self.play_pipeline.get_bus().remove_signal_watch()
				self.play_pipeline.get_bus().disconnect(self.play_watch_id)
				self.play_watch_id = None
			self.play_pipeline.set_state(gst.STATE_NULL)
			self.play_pipeline = None

	def update_level_meter (self, level):
		if self.level_meter: self.level_meter.set_fraction(1 + level/100.0)

	def play(self):
		self.play_pipeline = gst.Pipeline()
		filesrc = gst.element_factory_make("filesrc")
		filesrc.set_property ("location", self.filename)
		wavparse = gst.element_factory_make("wavparse")
		audioconvert = gst.element_factory_make("audioconvert")
		sink = gst.element_factory_make("dsppcmsink")
		self.play_pipeline.add(filesrc, wavparse, audioconvert, sink)
		filesrc.link(wavparse)
		audioconvert.link(sink)
		def on_pad (comp, pad):
			convpad = audioconvert.get_compatible_pad(pad, pad.get_caps())
			pad.link(convpad)
		wavparse.connect("pad-added", on_pad)
		self.play_pipeline.set_state(gst.STATE_PLAYING)

		self.bus = self.play_pipeline.get_bus()
		self.bus.add_signal_watch()
		self.watch_id = self.bus.connect("message", self.get_message_play)

	def submit (self):
		#t = threading.Thread(group=None, target=func, args=...)
		#t.start()
		#introduce and on_upload_complete function

		params = {
			'file' : open(self.filename, 'rb'),
			'submittedyn' : 'Y',
		}
		webservice.invoke("upload_and_process_file", [params, self.user, self.request])

	def get_message_record (self, bus, message):
		#print message.src.get_name() + str(message.type)
		if message.type == gst.MESSAGE_ERROR:
			err, debug = message.parse_error()
			self.on_error("Error from " +
				message.src.get_name() +
				": " + str(err) +
				" debug: " + debug)
		elif message.type == gst.MESSAGE_ELEMENT \
			and message.src == self.level:

			struc = message.structure
			self.update_level_meter(struc["peak"][0])

	def get_message_play (self, bus, message):
		#print message.src.get_name() + str(message.type)
		if message.type == gst.MESSAGE_ERROR:
			err, debug = message.parse_error()
			self.on_error("Error from " + message.src.get_name() + ": " + str(err) + " debug: " + debug)
		elif message.type == gst.MESSAGE_EOS:
			self.on_eos()

