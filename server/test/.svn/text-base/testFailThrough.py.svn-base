import gobject
gobject.threads_init()
import pygst
pygst.require("0.10")
import gst
from httplib import HTTP
from urlparse import urlparse

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

class GnomeVFSMP3Src (gst.Bin):
	def __init__ (self, p, uri, uri2, vol = 1.0):
		gst.Bin.__init__(self)
		self.uri2 = uri2

#		bus = p.get_bus()
#		bus.add_signal_watch()
#		bus.connect("message", self.get_message)

		self.gnomevfssrc = gst.element_factory_make("gnomevfssrc")
		if checkURL(uri):
			self.gnomevfssrc.set_property("location", uri)
		else:
			self.gnomevfssrc.set_property("location", uri2)
			
		mad = gst.element_factory_make("mad")
		audioconvert = gst.element_factory_make("audioconvert")
		audioresample = gst.element_factory_make("audioresample")
		self.current_vol = vol
		self.target_vol = vol
		self.volume = gst.element_factory_make("volume")
		self.volume.set_property("volume", self.current_vol)
		self.add(self.gnomevfssrc, mad, audioconvert,
			audioresample, self.volume)
		gst.element_link_many(self.gnomevfssrc, mad,
			audioconvert, audioresample, self.volume)
		pad = self.volume.get_pad("src")
		ghostpad = gst.GhostPad("src", pad)
		self.add_pad(ghostpad)

	def get_message (self, bus, message):
		if message.src == self.gnomevfssrc \
			and message.type == gst.MESSAGE_ERROR:

			err, debug = message.parse_error()
			print err
			if err == "Resource not found.":
				self.set_state(gst.STATE_PAUSED)
				self.gnomevfssrc.set_property(
					"location",
					self.uri2)
				self.set_state(gst.STATE_PLAYING)

 
def checkURL(url):
	p = urlparse(url)
	h = HTTP(p[1])
	h.putrequest('HEAD', p[2])
	h.endheaders()
	print h.getreply()
	if h.getreply()[0] == 200: return 1
	else: return 0

class Stream:
	def __init__ (self):
		self.main_loop = gobject.MainLoop()
		self.pipeline = gst.Pipeline()
		src = GnomeVFSMP3Src(
			self.pipeline,
			"http://aevidence2.dyndns.org:8000/scapes1.mp3",
			"http://aevidence2.dyndns.org:8000/scapes1.mp3")
		blanksrc = BlankAudioSrc(4)
		self.adder = gst.element_factory_make("adder")
		alsasink = gst.element_factory_make("alsasink")
		self.pipeline.add(self.adder, alsasink)
		self.adder.link(alsasink)
		self.add_source_to_adder(blanksrc)
		self.add_source_to_adder(src)

	def play(self):
		self.pipeline.set_state(gst.STATE_PLAYING)
		self.main_loop.run()

	def add_source_to_adder (self, src_element):
		self.pipeline.add(src_element)
		srcpad = src_element.get_pad('src')
		addersinkpad = self.adder.get_request_pad('sink%d')
		srcpad.link(addersinkpad)

s = Stream()
s.play()

