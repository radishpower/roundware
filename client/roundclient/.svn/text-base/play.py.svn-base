import gobject
import pygst
pygst.require("0.10")
import gst
import settings
import webservice
import time

INIT_VOLUME = 0.5

class ClientPlay:
	def __init__ (self, on_eos, on_error):
		self.on_eos = on_eos
		self.on_error = on_error
		self.is_playing = False
		self.volume = INIT_VOLUME
		self.pipeline = None
		self.watch_id = None
		self.dspmp3sink = None

	def play (self, request):
		self.stream_url = webservice.invoke("request_stream", [request])
		self.pipeline = gst.Pipeline()
		if settings.config.get("client","device") == "N800":
			self.gnomevfssrc = gst.element_factory_make("gnomevfssrc")
			self.gnomevfssrc.set_property("location", self.stream_url)
                        self.dspmp3sink = gst.element_factory_make("dspmp3sink")
                        self.dspmp3sink.set_property("fvolume", self.volume)
                        self.pipeline.add(self.gnomevfssrc, self.dspmp3sink)
                        gst.element_link_many(self.gnomevfssrc, self.dspmp3sink)
		else:
			playbin = gst.element_factory_make("playbin")
			playbin.set_property("uri", self.stream_url)
			self.pipeline.add(playbin)

		self.bus = self.pipeline.get_bus()
		self.bus.add_signal_watch()
		self.watch_id = self.bus.connect("message", self.get_message)

		self.is_playing = True
		self.pipeline.set_state(gst.STATE_PLAYING)

	def get_message (self, bus, message):
		#print message.src.get_name() + str(message.type)
		if message.type == gst.MESSAGE_ERROR:
			err, debug = message.parse_error()
                        print "Error from " + message.src.get_name() \
				+ ": " + str(err) + " debug: " + debug
			self.stop()
			self.on_error(
				"Sorry, there was a network error. " \
				+ "Please try again in a few seconds.")
		elif message.type == gst.MESSAGE_EOS:
			self.on_eos()

	def stop (self):
		self.is_playing = False
		if self.pipeline:
			if self.watch_id:
				self.pipeline.get_bus().remove_signal_watch()
				self.pipeline.get_bus().disconnect(self.watch_id)
				self.watch_id = None
			self.pipeline.set_state(gst.STATE_NULL)
			self.pipeline = None

	def get_is_playing (self):
		return self.is_playing

	def set_volume (self, volume):
		if self.dspmp3sink:
			self.dspmp3sink.set_property("fvolume", volume)

	def skip_ahead (self):
		if self.pipeline:
			webservice.invoke("skip_ahead", [{ "stream_url" : self.stream_url }])

