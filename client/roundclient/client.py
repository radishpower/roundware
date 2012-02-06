#!/usr/bin/python

import gobject
import pygtk
import gtk
import gtk.glade
import os, os.path
import time
import play
import record
import settings
import hildon
import gui_helper
import webservice

MODE_LISTEN = "MODE_LISTEN"
MODE_SPEAK = "MODE_SPEAK"

MAX_VOLUME = 1
MIN_VOLUME = 0
VOLUME_STEP = 0.10

DISCLAIMER_PAGE = 1
START_PAGE = 5
SPLASH_PAGE = 2

QUESTIONS_PAGE = 3
RECORD_PAGE = 6
LISTEN_PAGE = 5
PVM_ARTWORK_PAGE = 4
ARTWORK_PAGE = 1
DEMOGRAPHICS_PAGE = 2

GLADE_FILE = 'client.glade'
SHARE_DIR = '/usr/share/roundclient'
IMAGE_DIR = os.path.join(SHARE_DIR, "images")

BTN_PLAY = os.path.join(SHARE_DIR, "pp_play.png")
BTN_RECORD = os.path.join(SHARE_DIR, "pp_record.png")
BTN_STOP = os.path.join(SHARE_DIR, "pp_stop.png")

LIST_PADDING = 10

HILDON_HARDKEY_UP         = gtk.keysyms.Up
HILDON_HARDKEY_LEFT       = gtk.keysyms.Left
HILDON_HARDKEY_RIGHT      = gtk.keysyms.Right
HILDON_HARDKEY_DOWN       = gtk.keysyms.Down
HILDON_HARDKEY_SELECT     = gtk.keysyms.Return
HILDON_HARDKEY_HOME       = gtk.keysyms.F5
HILDON_HARDKEY_ESC        = gtk.keysyms.Escape
HILDON_HARDKEY_FULLSCREEN = gtk.keysyms.F6
HILDON_HARDKEY_INCREASE   = gtk.keysyms.F7
HILDON_HARDKEY_DECREASE   = gtk.keysyms.F8
HILDON_HARDKEY_MENU       = gtk.keysyms.F10

PROJECT = "PAUSEPLAY"
categories = webservice.invoke("get_categories", [{ "project_name" : PROJECT }])
demographics = webservice.invoke("get_demographics", [{ "project_name" : PROJECT }])

class RoundClient:
	def main (self):
		gtk.main()

	def delete_event(self, widget, event, data=None):
		return False

	def destroy(self, widget, data=None):
		gtk.main_quit()

	def __init__ (self):
		# Glade
		self.wTree = gtk.glade.XML(os.path.join(SHARE_DIR, GLADE_FILE), "round")
		self.wTree.signal_autoconnect({
			"on_demonext_clicked" : self.on_demonext_clicked,
			"on_demo_clicked" : self.on_demo_clicked,
#			"on_setup_okay_clicked" : self.on_setup_okay_clicked,
			"on_disclaimer_okay_clicked" : self.on_disclaimer_okay_clicked,
			"on_disclaimer_decline_clicked" : self.on_disclaimer_decline_clicked,
			"on_listen_clicked" : self.on_listen_clicked,
			"on_speak_clicked" : self.on_speak_clicked,
			"on_start_over_clicked" : self.on_start_over_clicked,
			"on_resume_clicked" : self.on_resume_clicked,
			"on_back_to_category_clicked" : self.on_back_to_category_clicked,
			"on_back_to_artwork_clicked" : self.on_back_to_artwork_clicked,
			"on_category_clicked" : self.on_category_clicked,
			"on_demographics_okay_clicked" : self.on_demographics_okay_clicked,
			"on_listen_skip_clicked" : self.on_listen_skip_clicked,
			"on_done_recording_submit_clicked" : self.on_done_recording_submit_clicked,
			"on_done_recording_rerecord_clicked" : self.on_done_recording_rerecord_clicked,
			"on_submitted_record_another_clicked" : self.on_submitted_record_another_clicked,
			"on_listen_record_clicked" : self.on_listen_record_clicked,
			"on_start_start_clicked" : self.on_start_start_clicked,
			#"on_round_delete_event" : self.delete_event,
			#"on_round_destroy_event" : self.destroy,
			#"on_round_keypress_event" : self.on_keypress_event,
			"on_pvm_artwork_clicked" : self.on_pvm_artwork_clicked,
		})

		self.init_gui_members()

		#Temporary fix for not having custom widgets.
                self.recordbtn = \
                        gui_helper.RoundToggleButton("pp_record.png", self.record, "pp_stop.png", self.stop_recording)
                self.wTree.get_widget("table7").remove(self.wTree.get_widget("eventbox19"))
                self.wTree.get_widget("table7").attach(self.recordbtn, 0, 3, 2, 3, gtk.EXPAND, gtk.EXPAND, 0, 0)
                self.recordbtn.show_all()

		self.playbtn = \
			gui_helper.RoundToggleButton("pp_play.png", self.play, "pp_stop.png", self.stop)
                self.wTree.get_widget("table6").remove(self.wTree.get_widget("listen_play_eventbox"))
                self.wTree.get_widget("table6").attach(self.playbtn, 0, 1, 3, 4, gtk.FILL, gtk.FILL, 15, 0)
		self.playbtn.show_all()

		self.playbackbtn = \
			gui_helper.RoundToggleButton("pp_play.png", self.playback, "pp_stop.png", self.stop_playback)
                self.wTree.get_widget("table8").remove(self.wTree.get_widget("eventbox20"))
                self.wTree.get_widget("table8").attach(self.playbackbtn, 0, 1, 1, 2, 0, gtk.EXPAND, 10, 35)
		self.playbackbtn.show_all()

		self.playellimanbtn = self.setup_pvm_play_button("elliman.mp3", "playelliman_eventbox", 4)
		self.playjetsetbtn = self.setup_pvm_play_button("jetset.mp3", "playjetset_eventbox", 7)
		self.playohlssonbtn = self.setup_pvm_play_button("ohlsson.mp3", "playohlsson_eventbox", 10)

		# Connections
		self.window.connect("destroy", self.destroy)
		self.window.connect("delete_event", self.delete_event)
		self.window.connect("key_press_event", self.on_keypress_event)
		self.window.connect("window-state-event", self.on_window_state_change)
		self.window_is_fullscreen = False # Not in full screen mode initially.

		#self.hide_cursor()
		self.window.show_all()

		# use max and min when you bother to look up floating point division
		self.volume = 0.5
		#self.volume = (MAX_VOLUME - MIN_VOLUME) / 2

		# members for streams
		self.client_play = play.ClientPlay(self.on_play_eos, self.on_play_error)
		self.client_record = record.ClientRecord(
			self.wTree.get_widget("level_meter"),
			self.wTree.get_widget("count_down_label"),
			self.on_record_done,
			self.on_record_eos,
			self.banner)

		# I don't know why these buttons aren't invisible by default
		self.resume_btn.hide()
		self.back_to_category_btn.hide()
		self.back_to_artwork_btn.hide()

		# It's a lot easier to deal with the notebook in glade if the
		# tabs are shown so I hide them hear instead
		if self.super_notebook: self.super_notebook.set_show_tabs(False)
		self.main_notebook.set_show_tabs(False)
		self.sub_notebook.set_show_tabs(False)

		self.init_backgrounds()

		# For the secret code
		self.current_konomi_pos = 0

		self.window.fullscreen()

		self.main_notebook.set_current_page(DISCLAIMER_PAGE)

	def setup_pvm_play_button (self, mp3_filename, eventbox, row):
		togglebtn = \
			gui_helper.RoundPlayButton("pp_play.png", "pp_stop.png", mp3_filename, self.stop_pvm_audio)
                self.wTree.get_widget("pvm_artwork_table").remove(self.wTree.get_widget(eventbox))
                self.wTree.get_widget("pvm_artwork_table").attach(togglebtn, 0, 1, row, row+1, gtk.EXPAND, gtk.EXPAND, 0, 0)
		togglebtn.show_all()
		return togglebtn

	def stop_pvm_audio (self, exceptbtn = None):
		print "stop_pvm_audio()"
		if exceptbtn:
			print "with exceptbtn"
			# If exceptbtn is passed, that means one of the others was clicked and thus
			# we are not leaving the page and we should only pause the other two
			if not (exceptbtn == self.playellimanbtn):
				self.playellimanbtn.pause()
			if not (exceptbtn == self.playjetsetbtn):
				self.playjetsetbtn.pause()
			if not (exceptbtn == self.playohlssonbtn):
				self.playohlssonbtn.pause()
		else:
			print "without exceptbtn"
			#otherwise we should clean them all up.
			self.playellimanbtn.cleanup()
			self.playjetsetbtn.cleanup()
			self.playohlssonbtn.cleanup()

	def init_gui_members (self):
		self.window = self.wTree.get_widget("round")
		self.super_notebook = self.wTree.get_widget("super_notebook")
		self.main_notebook = self.wTree.get_widget("main_notebook")
		self.sub_notebook = self.wTree.get_widget("sub_notebook")
		self.resume_btn = self.wTree.get_widget("resume_eventbox")
		self.back_to_category_btn = self.wTree.get_widget("back_to_category_eventbox")
		self.back_to_artwork_btn = self.wTree.get_widget("back_to_artwork_eventbox")
		self.sidebar = self.wTree.get_widget("sidebar_eventbox")
		self.level_meter = self.wTree.get_widget("level_meter")
		self.listen_selections_label = self.wTree.get_widget("listen_selections_label")
		self.speak_selections_label = self.wTree.get_widget("speak_selections_label")

	def init_backgrounds (self):
		self.backGround(self.wTree.get_widget("start_eventbox"), "pp_splash.png")
		self.backGround(self.wTree.get_widget("startpage_eventbox"), "pp_start.png")
		for eb in [
			"categorybg_eventbox",
			"artwork_eventbox",
			"demographicsbg_eventbox",
			"question_eventbox",
			"listenbg_eventbox",
			"startrecordingbg_eventbox",
			"donerecordingbg_eventbox",
			"submittedrecordingbg_eventbox"
		]: self.backGround(self.wTree.get_widget(eb), "pp_background.png")

	def on_window_state_change(self, widget, event, *args):
		if event.new_window_state & gtk.gdk.WINDOW_STATE_FULLSCREEN:
			self.window_is_fullscreen = True
		else:
			self.window_is_fullscreen = False

	def on_keypress_event (self, widget, event):
		if event.keyval == HILDON_HARDKEY_MENU:
			widget.stop_emission("key-press-event")
		elif event.keyval == HILDON_HARDKEY_INCREASE:
			self.volume = min(self.volume + VOLUME_STEP, MAX_VOLUME)
			if self.client_play: self.client_play.set_volume(self.volume)
		elif event.keyval == HILDON_HARDKEY_DECREASE:
			self.volume = max(self.volume - VOLUME_STEP, MIN_VOLUME)
			if self.client_play: self.client_play.set_volume(self.volume)
		elif event.keyval == HILDON_HARDKEY_FULLSCREEN:
			if self.window_is_fullscreen:
				#FIXME: Take this line out. It's annoying
				# for development but it's needed for production
				if self.main_notebook.get_current_page() == DISCLAIMER_PAGE:
				#if True:
					self.window.unfullscreen()
			else:
				self.window.fullscreen()
			
		keyname = gtk.gdk.keyval_name(event.keyval)
		self.konomi(keyname)

	def on_demonext_clicked (self, widget, event):
		self.super_notebook.next_page()
 
	def on_demo_clicked (self, widget, event):
		self.super_notebook.set_current_page(0)

	def konomi (self, keyname):
		code = ["Up", "Up", "Down", "Down"]
		if keyname == code[self.current_konomi_pos]:
			self.current_konomi_pos += 1
		else:
			self.current_konomi_pos = 0

		if self.current_konomi_pos == len(code):
			self.current_konomi_pos = 0
			self.main_notebook.set_current_page(DISCLAIMER_PAGE)

	def backGround(self, eventbox, filename):
		eventbox.set_app_paintable(True)
		def realize (widget):
			buf = gtk.gdk.pixbuf_new_from_file(
				os.path.join(IMAGE_DIR, filename))
			pixmap, mask = buf.render_pixmap_and_mask()
			widget.window.set_back_pixmap(pixmap, False)
		eventbox.connect("realize", realize)

	def backGroundNow(self, eventbox, filename):
		eventbox.set_app_paintable(True)
		buf = gtk.gdk.pixbuf_new_from_file(
				os.path.join(IMAGE_DIR, filename))
		pixmap, mask = buf.render_pixmap_and_mask()
		eventbox.window.set_back_pixmap(pixmap, False)
		(x, y, w, h, bd) = eventbox.window.get_geometry()
		eventbox.window.invalidate_rect((x,y,w,h), True)

	def paint_button (self, button, filename):
		image_file = os.path.join(IMAGE_DIR, filename)
		image = gtk.Image()
		image.set_from_file(image_file)
		button.set_image(image)

	def paint_eventbox (self, eventbox, filename):
		image_file = os.path.join(IMAGE_DIR, filename)
		image = gtk.Image()
		image.set_from_file(image_file)
		eventbox.foreach(lambda child: eventbox.remove(child))
		eventbox.add(image)
		image.show()

#	def on_setup_okay_clicked (self, widget, event):
#		self.user_usertypeid = self.wTree.get_widget("user_type").get_active() + 1
#		self.user_genderid = self.wTree.get_widget("user_gender").get_active() + 1
#		self.user_ageid = self.wTree.get_widget("user_age").get_active() + 1
#		if self.user_usertypeid and self.user_genderid and self.user_ageid:
#			self.main_notebook.next_page()
#		else:
#			self.banner("All infomation must be filled out to continue")

	def on_disclaimer_okay_clicked (self, widget, event):
		self.main_notebook.set_current_page(SPLASH_PAGE)

	def on_start_start_clicked (self, widget, event):
		self.main_notebook.set_current_page(SPLASH_PAGE)

	def on_disclaimer_decline_clicked (self, widget, event):
		self.main_notebook.set_current_page(4)

	def on_listen_clicked (self, widget, event):
		self.mode = MODE_LISTEN
		self.show_rest_ui()
		self.backGroundNow(self.sidebar, "pp_sidebar_listen.png")

	def on_speak_clicked (self, widget, event):
		self.mode = MODE_SPEAK
		self.show_rest_ui()
		self.backGroundNow(self.sidebar, "pp_sidebar_speak.png")

	def show_rest_ui (self):
		self.back_to_category_btn.hide()
		self.back_to_artwork_btn.hide()
		self.resume_btn.hide()
		self.sub_notebook.set_current_page(0)
		self.main_notebook.next_page()

	def on_start_over_clicked (self, widget, event):
		print "on_start_over()"
		self.mode = None
		self.turn_off_stream()
		self.main_notebook.set_current_page(2)

	def on_resume_clicked (self, widget, event):
		self.mode = MODE_LISTEN
		self.resume_btn.hide()
		self.goto_listen_page()
		self.backGroundNow(self.sidebar, "pp_sidebar_listen.png")
		self.playbtn.toggle(True)

	def on_back_to_category_clicked (self, widget, event):
		widget.hide()
		self.resume_btn.hide()
		self.turn_off_stream()
		self.back_to_artwork_btn.hide()
		self.sub_notebook.set_current_page(0)

	def on_back_to_artwork_clicked (self, widget, event):
		widget.hide()
		self.resume_btn.hide()
		self.turn_off_stream()
		if self.current_category["id"] == 11 and self.mode == MODE_LISTEN:
			self.sub_notebook.set_current_page(PVM_ARTWORK_PAGE)
		else:
			self.sub_notebook.set_current_page(ARTWORK_PAGE)

	def on_category_clicked (self, widget, event):
		nametoid = {
			#"category1_btn" : 10,
			"category2_btn" : 10,
			"category3_btn" : 11,
			"category4_btn" : 4,
		}
		self.current_category = self.get_category_data(nametoid[widget.get_name()])
		artlist = self.current_category["subcategories"]
		self.back_to_category_btn.show()
		self.paint_eventbox(
			self.back_to_category_btn,
			self.current_category["bcfile"])
		if self.current_category["id"] == 11 and self.mode == MODE_LISTEN:
			self.sub_notebook.set_current_page(PVM_ARTWORK_PAGE)
		else:
			self.sub_notebook.set_current_page(ARTWORK_PAGE)
		if len(artlist) > 0:
			self.initialize_artwork_page(artlist)
		else:
			self.current_artwork = None
			self.back_to_artwork_btn.hide()
			self.goto_page_after_artwork()

	def goto_listen_page (self):
		self.listen_selections_label.set_markup(
			self.listen_selections_text(
				self.current_category,
				self.current_artwork,
				self.wTree.get_widget("visitors_checkbutton").get_active(),
				self.wTree.get_widget("artists_checkbutton").get_active(),
				self.wTree.get_widget("curators_checkbutton").get_active(),
				self.wTree.get_widget("educators_checkbutton").get_active(),
				))
		self.report_number_of_voices(webservice.invoke("number_of_recordings", [self.get_request()]))
		self.sub_notebook.set_current_page(LISTEN_PAGE)

	def turn_off_stream (self):
		print "turn_off_stream()"
		if self.client_play.is_playing:
			self.client_play.stop()
			self.playbtn.toggle(False)
		if self.client_record:
			self.client_record.stop_recording()
			self.client_record.stop_playback()
			self.recordbtn.toggle(False)
		self.stop_pvm_audio()

	def goto_page_after_artwork(self):
		if self.mode == MODE_LISTEN:
			self.sub_notebook.set_current_page(DEMOGRAPHICS_PAGE)
		elif self.mode == MODE_SPEAK:
			self.sub_notebook.set_current_page(QUESTIONS_PAGE)
			self.initialize_question_page()

	def buildScrolledList (self, parent, first, items, callback):
		length = len(items)
		if length > 0:
			table = gtk.Table(length+1, 1, True)
			table.attach(first, 0, 1, 0, 1, gtk.EXPAND, 0, 0, 0)
			i = 1
			for item in items:
				button = gtk.EventBox()
				button.set_visible_window(False)
				button.connect("button-press-event", callback(item))
				btn_image = gtk.Image()
				if item.has_key("imagefile"):
					btn_image.set_from_file(
						os.path.join(IMAGE_DIR, item["imagefile"]))
				button.add(btn_image)
				table.attach(button, 0, 1, i, i+1, gtk.EXPAND, gtk.EXPAND, 0, LIST_PADDING)
				i += 1
			parent.foreach(lambda c: parent.remove(c))
			parent.add(table)
			parent.show_all()

	def initialize_artwork_page(self, artlist):
		def on_artwork_clicked (item):
			def callback (widget, event):
				self.prepare_artwork_page_and_go(item)
			return callback

		label = gtk.Label()
		label.set_markup(gui_helper.markup(22, "Please select a topic"))
		self.buildScrolledList(
			self.wTree.get_widget("artwork_eventbox"),
			label,
			artlist,
			on_artwork_clicked)

	def prepare_artwork_page_and_go(self,item):
		self.current_artwork = item
		if item.has_key("bcfile"):
			self.paint_eventbox(
				self.back_to_artwork_btn,
				item["bcfile"])
		self.back_to_artwork_btn.show()
		self.goto_page_after_artwork()


	def initialize_question_page (self):
		def on_question_clicked (item):
			def callback (widget, event):
				self.current_question = item
				self.goto_record_page()
			return callback
		label = gtk.Label()
		label.set_markup(gui_helper.markup(22, "Please select a question"))
		questions = []
		for question in self.current_category["questions"]:
			if not self.current_artwork or (question["subcategoryid"] == self.current_artwork["id"]):
				questions.append(question)
		self.buildScrolledList(
			self.wTree.get_widget("question_eventbox"),
			label,
			questions,
			on_question_clicked)

	def on_demographics_okay_clicked(self, widget, event):
#		self.demographics_usertypeid = \
#			self.wTree.get_widget("demographics_type").get_active()
#		self.demographics_genderid = \
#			self.wTree.get_widget("demographics_gender").get_active()
#		self.demographics_ageid = \
#			self.wTree.get_widget("demographics_age").get_active()
		self.goto_listen_page()

	def on_play_eos (self):
		self.playbtn.toggle(False)

	def on_play_error (self, message, justbanner=False):
		if not justbanner: self.on_play_eos()
		self.banner(message)

	def get_request (self):
		artworkid = None
		if self.current_artwork:
			artworkid = self.current_artwork["id"]
		return {
			"categoryid" : self.current_category["id"],
			"subcategoryid" : artworkid,
			"questionid" : None,
			"usertypeid" : self.get_demographics_selections(),
			"ageid" : [],
			"genderid" : [],
		}

	def report_number_of_voices(self, number):
		if number == 1: word = "recording matches"
		else: word = "recordings match"
		self.wTree.get_widget("number_of_voices_label").set_markup(
			gui_helper.markup(16, "<b>" + str(number) + "</b> " + word + \
			" your current selections."))

	def update_level_meter (self, level):
		self.level_meter.set_fraction(1 + level/100.0)

	def get_demographics_selections(self):
		#FIXME: These IDs are hardcoded and that's not good.
		ids = []
		if self.wTree.get_widget("visitors_checkbutton").get_active():
			ids.append(1)
		if self.wTree.get_widget("curators_checkbutton").get_active():
			ids.append(2)
		if self.wTree.get_widget("artists_checkbutton").get_active():
			ids.append(3)
		if self.wTree.get_widget("educators_checkbutton").get_active():
			ids.append(4)
		return ids

	def play (self):
		self.client_play.play(self.get_request())

	def stop (self):
		self.client_play.stop()

	def record (self):
		self.client_record.record(self.get_user_data(), self.get_request())

	def stop_recording (self):
		self.client_record.stop_recording()
		self.wTree.get_widget("sub_notebook").next_page()

	def on_record_done (self):
		#FIXME: Shouldn't this toggle the record button back to displaying "record"
		# rather than continuing to display "stop"? Test this.
		self.wTree.get_widget("sub_notebook").next_page()

	def on_record_eos (self):
		self.playbackbtn.toggle_to(True)

	def playback (self):
		self.client_record.play()

	def stop_playback (self):
		self.client_record.stop_playback()

	def on_done_recording_submit_clicked (self, widget, event):
		self.playbackbtn.toggle_to(True)
		self.client_record.submit()
		self.sub_notebook.next_page()

	def on_done_recording_rerecord_clicked (self, widget, event):
		self.playbackbtn.toggle_to(True)
		self.goto_record_page()

	def on_submitted_record_another_clicked (self, widget, event):
		self.goto_record_page()

	def on_listen_record_clicked (self, widget, event):
		self.turn_off_stream()
		self.resume_btn.show()
		self.mode = MODE_SPEAK
		self.goto_page_after_artwork()
		self.initialize_question_page(self.current_artwork["id"])
		self.backGroundNow(self.sidebar, "pp_sidebar_speak.png")

	def goto_record_page (self):
		self.recordbtn.toggle_to(True, False)
		self.client_record.prepare_for_recording()
		self.wTree.get_widget("sub_notebook").set_current_page(RECORD_PAGE)
		self.wTree.get_widget("speak_selections_label").set_markup(
			gui_helper.markup(16, "<b>" + self.current_question["text"] + "</b>"))

	def on_listen_skip_clicked (self, widget, event):
		self.client_play.skip_ahead()

	def banner (self, text):
		hildon.hildon_banner_show_information (self.window, None, text)

	def get_user_data (self):
		return {
			"usertypeid" : 1,
			"ageid" : None,
			"genderid" : None,
		}

	def get_category_data (self, categoryid):
		return self.find_id_in_dict_list(categories, categoryid)

	def find_id_in_dict_list (self, list, id):
		for elem in list:
			if elem["id"] == id:
				return elem
		return False	

	def listen_selections_text (self, category, artwork, visitors, artists, curators, educators):
		contributors = []
		if visitors: contributors.append("Visitors")
		if artists: contributors.append("Artists")
		if curators: contributors.append("Curators")
		if educators: contributors.append("Educators/Experts")
		if len(contributors) == 4: contributors = ["All contributors"]
		if len(contributors) == 0: contributors = ["No contributors"]
		
		str = ",".join(contributors) + " talking about "
		if artwork: str += "<b>" + artwork["artist_name"] + ":</b> <i>" + artwork["name"] + "</i>"
		else: str += "<b>" + category["name"] + "</b>"

		return gui_helper.markup(16, str)

	def on_pvm_artwork_clicked (self, widget, event):
		self.stop_pvm_audio()
		if widget == self.wTree.get_widget("pvm_eventbox"):
			return self.prepare_artwork_page_and_go(self.find_id_in_dict_list(self.current_category["subcategories"], 46))
		elif widget == self.wTree.get_widget("elliman_eventbox"):
			return self.prepare_artwork_page_and_go(self.find_id_in_dict_list(self.current_category["subcategories"], 47))
		elif widget == self.wTree.get_widget("jetset_eventbox"):
			return self.prepare_artwork_page_and_go(self.find_id_in_dict_list(self.current_category["subcategories"], 48))
		elif widget == self.wTree.get_widget("ohlsson_eventbox"):
			return self.prepare_artwork_page_and_go(self.find_id_in_dict_list(self.current_category["subcategories"], 49))
		else:
			print "Unknown widget"

client = RoundClient()
client.main()
