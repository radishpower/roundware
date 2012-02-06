import gobject
import pygst
pygst.require("0.10")
import gst
import gtk
import os

IMAGE_DIR = "/usr/share/roundclient/images"

def fill_button_list (eventbox, text, items, callback):
	label = RoundLabel(text)
	#assert(len(items) > 0)
	eventbox.foreach(lambda child: eventbox.remove(child))
	table = gtk.Table(len(items) + 1, 1, True)
	eventbox.add(table)
	table.attach(label, 0, 1, 0, 1, gtk.EXPAND, 0, 0, 0)
	i = 1
	def add_button (row_num, item):
		def make_callback (item):
			return lambda button, event: callback(item)
		button = RoundButton(item["imagefile"], make_callback(item))
		table.attach(button, 0, 1, row_num, row_num+1,
				gtk.EXPAND, gtk.EXPAND, 0, 10)
	for item in items:
		add_button(i, item)
		i += 1
	table.show_all()

def background(eventbox, filename, invalidate_window = None):
	eventbox.set_app_paintable(True)
	def realize (widget):
		buf = gtk.gdk.pixbuf_new_from_file(
			os.path.join(IMAGE_DIR, filename))
		pixmap, mask = buf.render_pixmap_and_mask()
		widget.window.set_back_pixmap(pixmap, False)
	if invalidate_window:
#		realize(eventbox)
#		(x, y, w, h, bd) = invalidate_window.window.get_geometry()
#		invalidate_window.window.invalidate_rect((x,y,w,h), True)
		eventbox.set_app_paintable(True)
		buf = gtk.gdk.pixbuf_new_from_file(
				os.path.join(IMAGE_DIR, filename))
		pixmap, mask = buf.render_pixmap_and_mask()
		eventbox.window.set_back_pixmap(pixmap, False)
		(x, y, w, h, bd) = invalidate_window.window.get_geometry()
		invalidate_window.window.invalidate_rect((x,y,w,h), True)
	else:
		eventbox.connect("realize", realize)

class RoundButton (gtk.EventBox):
	def __init__ (self, image_filename, callback):
		gtk.EventBox.__init__(self)
		self.image_filename = os.path.join(IMAGE_DIR, image_filename)
		self.callback = callback

		self.set_visible_window(False)
		self.image = gtk.Image()
		self.image.set_from_file(self.image_filename)
		self.add(self.image)
		self.connect("button_release_event", self.release)

	def release (self, button, event):
		self.callback(button, event)

class RoundToggleButton (gtk.EventBox):
	def __init__ (self, off_state_image, off_state_callback, on_state_image, on_state_callback):
		gtk.EventBox.__init__(self)
		self.set_visible_window(False)
		self.off_state_image = os.path.join(IMAGE_DIR, off_state_image)
		self.on_state_image = os.path.join(IMAGE_DIR, on_state_image)
		self.off_state_callback = off_state_callback
		self.on_state_callback = on_state_callback
		self.in_off_state = True
		self.image = gtk.Image()
		self.image.set_from_file(self.off_state_image)
		self.add(self.image)
		self.connect("button_release_event", self.release)

	def release (self, button, event):
		self.toggle(True)

	def toggle (self, execute_callback = True):
		if self.in_off_state:
			self.in_off_state = False
			self.image.set_from_file(self.on_state_image)
			if execute_callback: self.off_state_callback()
		else:
			self.in_off_state = True
			self.image.set_from_file(self.off_state_image)
			if execute_callback: self.on_state_callback()

	def toggle_to (self, to_off_state, execute_callback = True):
		if not self.in_off_state == to_off_state:
			self.toggle(execute_callback)

class RoundPlayButton (RoundToggleButton):
	def __init__ (self, play_image, pause_image, filename, on_play):
		RoundToggleButton.__init__(self, play_image, self.play, pause_image, self.pause)
		self.filename = "file:///media/mmc2/"+filename
		self.pipeline = None
		self.on_play = on_play
		self.is_playing = False

	def play (self):
		print "RoundPlayButton.play()"
		self.on_play(self)
		if not self.pipeline:
			self.pipeline = gst.Pipeline()
			gnomevfssrc = gst.element_factory_make("gnomevfssrc")
			gnomevfssrc.set_property("location", self.filename)
			dspmp3sink = gst.element_factory_make("dspmp3sink")
			self.pipeline.add(gnomevfssrc, dspmp3sink)
			gnomevfssrc.link(dspmp3sink)

			self.bus = self.pipeline.get_bus()
			self.bus.add_signal_watch()
			self.watch_id = self.bus.connect("message", self.get_message)
		self.pipeline.set_state(gst.STATE_PLAYING)
		self.is_playing = True

	def get_message (self, bus, message):
		print message.src.get_name() + str(message.type)
		if message.type == gst.MESSAGE_ERROR:
			err, debug = message.parse_error()
			print "Error from " + message.src.get_name() \
				+ ": " + str(err) + " debug: " + debug
			self.cleanup()
			self.on_error(
				"Sorry, there was a network error. " \
				+ "Please try again in a few seconds.")
		elif message.type == gst.MESSAGE_EOS:
			self.cleanup()

	def cleanup (self):
		print "RoundPlayButton.cleanup()"
		self.toggle_to(True, False)
		if self.pipeline:
			if self.watch_id:
				self.pipeline.get_bus().remove_signal_watch()
				self.pipeline.get_bus().disconnect(self.watch_id)
				self.watch_id = None
			self.pipeline.set_state(gst.STATE_NULL)
			self.pipeline = None

	def pause (self):
		self.cleanup()
		return
		print "RoundPlayButton.pause()"
		if self.is_playing:
			self.is_playing = False
			self.toggle_to(True, False)
			if self.pipeline:
				self.pipeline.set_state(gst.STATE_PAUSED)

class RoundLabel (gtk.Label):
	def __init__ (self, text, size = 22, justify = gtk.JUSTIFY_CENTER):
		gtk.Label.__init__(self)
		self.set_markup(markup(size, text))
		self.set_justify(justify)
		self.set_line_wrap(True)

def markup (fontsize, text):
	return "<span font_family=\"arial\" font_desc =\""+str(fontsize)+"\">"+text+"</span>"

def hide_cursor(window):
	pixmap = gtk.gdk.Pixmap(None, 1, 1, 1)
	color = gtk.gdk.Color()
	cursor = gtk.gdk.Cursor(pixmap, pixmap, color, color, 0, 0)
	window.window.set_cursor(cursor)	

