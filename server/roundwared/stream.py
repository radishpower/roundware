import gobject
gobject.threads_init()
import pygst
pygst.require("0.10")
import gst
import logging
import time
from roundwared import settings
from roundwared import db
from roundwared import composition
from roundwared import icecast2
from roundwared import server
from roundwared import gpsmixer
from roundwared import recording_collection

class RoundStream:
	######################################################################
	# PUBLIC
	######################################################################
	def __init__ (self, sessionid, audio_format, request):
		logging.debug("begin stream")
		self.sessionid = sessionid
		self.request = request
		self.listener = request
		self.audio_format = audio_format
		self.last_listener_count = 1
		self.gps_mixer = None
		self.main_loop = gobject.MainLoop()
		self.icecast_admin = icecast2.Admin(
			"localhost:8000", "admin", "roundice")
		self.heartbeat()
		self.recordings = \
			recording_collection.RecordingCollection(self, request)

	def start (self):
		logging.info("Serving stream" + str(self.sessionid))

		self.pipeline = gst.Pipeline()
		self.adder = gst.element_factory_make("adder")
		sink = RoundStreamSink(self.sessionid, self.audio_format)
		self.pipeline.add(self.adder, sink)
		self.adder.link(sink)

		logging.info("Going to play: " \
			+ ",".join(self.recordings.get_filenames()) \
			+ " Total of " \
			+ str(len(self.recordings.get_filenames()))
			+ " files.")

		self.add_music_source()
		self.add_voice_compositions()
		self.add_message_wacher()

		self.pipeline.set_state(gst.STATE_PLAYING)
		gobject.timeout_add(
			settings.config["stereo_pan_interval"],
			self.stereo_pan)
		self.main_loop.run()

	def skip_ahead (self):
		logging.debug("Skip ahead")
		for comp in self.compositions:
			comp.skip_ahead()

	# Sets the activity timestamp to right now.
	# The timestamp is used to detect
	# when the client last sent any message.
	def heartbeat (self):
		self.activity_timestamp = time.time()
		#logging.debug("update time="+str(self.activity_timestamp))

	def modify_stream (self, request):
		self.heartbeat()
		self.request = request
		self.listener = request
		self.refresh_recordings()
		logging.info("Going to play: " \
			+ ",".join(self.recordings.get_filenames()) \
			+ " Total of " \
			+ str(len(self.recordings.get_filenames()))
			+ " files.")
		return True

	# Force the recording collection to get new recordings from the DB
	def refresh_recordings (self):
		self.recordings.update_request(self.request)
		for comp in self.compositions:
			comp.move_listener(self.listener)

	def move_listener (self, listener):
		self.heartbeat()
		self.listener = listener
		#logging.debug("move_listener("
		#	+ str(listener['latitude']) + ","
		#	+ str(listener['longitude']) + ")")
		if self.gps_mixer:
			self.gps_mixer.move_listener(listener)
		self.recordings.move_listener(listener)
		#logging.info("Going to play: " \
		#	+ ",".join(self.recordings.get_filenames()) \
		#	+ " Total of " \
		#	+ str(len(self.recordings.get_filenames()))
		#	+ " files.")
		for comp in self.compositions:
			comp.move_listener(listener)

	######################################################################
	# PRIVATE
	######################################################################
	def add_message_wacher (self):
		self.bus = self.pipeline.get_bus()
		self.bus.add_signal_watch()
		self.watch_id = self.bus.connect("message", self.get_message)

	def add_source_to_adder (self, src_element):
		self.pipeline.add(src_element)
		srcpad = src_element.get_pad('src')
		addersinkpad = self.adder.get_request_pad('sink%d')
		srcpad.link(addersinkpad)

	def add_music_source (self):
		speakers = db.get_speakers(self.request["categoryid"])
		#FIXME: We might need to unconditionally add blankaudio.
		# what happens if the only speaker is out of range? I think
		# it'll be fine but test this.
		if len(speakers) > 0:
			self.gps_mixer = gpsmixer.GPSMixer(
				{'latitude' : self.request['latitude'],
				'longitude' : self.request['longitude']},
				speakers)
			self.add_source_to_adder(self.gps_mixer)
		else:
			self.add_source_to_adder(BlankAudioSrc())

	def add_voice_compositions(self):
		self.compositions = \
			map (lambda comp_settings:
				composition.Composition(
					self,
					self.pipeline,
					self.adder,
					comp_settings,
					self.recordings),
				db.get_composition_settings(
					self.request["categoryid"]))

	def get_message (self, bus, message):
		#logging.debug(message.src.get_name() + str(message.type))
		if message.type == gst.MESSAGE_ERROR:
			err, debug = message.parse_error()
			if err.message == "Could not read from resource.":
				logging.warning("Error reading file: " \
					+ message.src.get_property("location"))
			else:
				logging.error("Error on " + str(self.sessionid) \
					+ " from " + message.src.get_name() + \
					": " + str(err) + " debug: " + debug)
				self.cleanup()
		elif message.type == gst.MESSAGE_STATE_CHANGED:
			prev, new, pending = message.parse_state_changed()
			if message.src == self.pipeline \
				and new == gst.STATE_PLAYING:
				logging.debug("Announcing " + str(self.sessionid) \
						+ " is playing")
				gobject.timeout_add(
					settings.config["ping_interval"],
					self.ping)
				for comp in self.compositions:
					comp.wait_and_play()

	def cleanup(self):
		db.log_event(15, {'sessionid':str(self.sessionid)})
		logging.debug("Cleaning up" + str(self.sessionid))
		if self.pipeline:
			if self.watch_id:
				self.pipeline.get_bus().remove_signal_watch()
				self.pipeline.get_bus().disconnect(self.watch_id)
				self.watch_id = None
			self.pipeline.set_state(gst.STATE_NULL)
		self.main_loop.quit()

	def stereo_pan (self):
		for comp in self.compositions:
			comp.stereo_pan()
		return True

	def ping (self):
		is_stream_active = \
			self.is_anyone_listening() \
			or self.is_activity_timestamp_recent()

		if is_stream_active:
			return True
		else:
			self.cleanup()
			return False
	
	def is_anyone_listening (self):
		listeners = self.icecast_admin.get_client_count(
			server.icecast_mount_point(
				self.sessionid, self.audio_format))
		#logging.debug("Number of listeners: " + str(listeners))
		if self.last_listener_count == 0 and listeners == 0:
			#logging.info("Detected noone listening.")
			return False
		else:
			self.last_listener_count = listeners
			return True

	def is_activity_timestamp_recent (self):
		#logging.debug("check now=" + str(time.time()) \
		#	+ " time=" + str(self.activity_timestamp) \
		#	+ " diff=" + str(time.time() - self.activity_timestamp))
		return time.time() - self.activity_timestamp < settings.config["heartbeat_timeout"]

# If there is no music this is needed to keep the stream not in
# and EOS state while there is dead air.
class BlankAudioSrc (gst.Bin):
	def __init__ (self, wave = 4):
		gst.Bin.__init__(self)
		audiotestsrc = gst.element_factory_make("audiotestsrc")
		audiotestsrc.set_property("wave", wave) #4 is silence
		audioconvert = gst.element_factory_make("audioconvert")
		self.add(audiotestsrc, audioconvert)
		audiotestsrc.link(audioconvert)
		pad = audioconvert.get_pad("src")
		ghost_pad = gst.GhostPad("src", pad)
		self.add_pad(ghost_pad)

class RoundStreamSink (gst.Bin):
	def __init__ (self, sessionid, audio_format):
		gst.Bin.__init__(self)

		capsfilter = gst.element_factory_make("capsfilter")
		volume = gst.element_factory_make("volume")
		volume.set_property("volume", settings.config["master_volume"])
		shout2send = gst.element_factory_make("shout2send")
		shout2send.set_property("username", "source")
		shout2send.set_property("password", "roundice")
		shout2send.set_property("mount",
			server.icecast_mount_point(sessionid, audio_format))

		self.add(capsfilter, volume, shout2send)
		capsfilter.link(volume)

		if audio_format.upper() == "MP3":
			capsfilter.set_property(
				"caps",
				gst.caps_from_string(
					"audio/x-raw-int,rate=44100,channels=2,width=16,depth=16,signed=(boolean)true"))
			lame = gst.element_factory_make("lame")
			self.add(lame)
			gst.element_link_many(volume, lame, shout2send)
		elif audio_format.upper() == "OGG":
			capsfilter.set_property(
				"caps",
				gst.caps_from_string(
					"audio/x-raw-float,rate=44100,channels=2,width=32"))
			vorbisenc = gst.element_factory_make("vorbisenc")
			oggmux = gst.element_factory_make("oggmux")
			self.add(vorbisenc, oggmux)
			gst.element_link_many(
				volume, vorbisenc, oggmux, shout2send)
		else:
			raise "Invalid format"

		pad = capsfilter.get_pad("sink")
		ghostpad = gst.GhostPad("sink", pad)
		self.add_pad(ghostpad)

