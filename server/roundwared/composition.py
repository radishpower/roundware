#TODO: Figure out how to get the main pipeline to send EOS
#	when all compositions are finished (only happens
#	when repeat is off)
#TODO: Reimplement panning using a gst.Controller
#TODO: Remove stero_pan from public interface

import gobject
gobject.threads_init()
import pygst
pygst.require("0.10")
import gst
import random
#import logging
import sys
import os
from roundwared import roundfilesrc
from roundwared import settings

STATE_PLAYING = 0
STATE_DEAD_AIR = 1
STATE_WAITING = 2

class Composition:
	######################################################################
	# PUBLIC
	######################################################################
	def __init__ (self, parent, pipeline, adder, comp_settings, recordings):
		self.parent = parent
		self.pipeline = pipeline
		self.adder = adder
		self.comp_settings = comp_settings
		self.recordings = recordings
		self.current_pan_pos = 0
		self.target_pan_pos = 0
		self.state = STATE_WAITING
		self.roundfilesrc = None
		self.current_recording = None

	def wait_and_play (self):
		def callback ():
			self.add_file()
			return False
		deadair = random.randint(
			self.comp_settings["mindeadair"],
			self.comp_settings["maxdeadair"]) / gst.MSECOND
		gobject.timeout_add(deadair, callback)

	def stereo_pan (self):
		if self.current_pan_pos == self.target_pan_pos \
			or self.pan_steps_left == 0:
			self.set_new_pan_target()
			self.set_new_pan_duration()
		else:
			pan_distance = \
				self.target_pan_pos - self.current_pan_pos
			amount_to_pan_now = pan_distance / self.pan_steps_left
			self.current_pan_pos += amount_to_pan_now
			self.pan_steps_left -= 1
			if self.roundfilesrc:
				self.roundfilesrc.pan_to(self.current_pan_pos)

	def move_listener (self, posn):
		if self.recordings.has_recording():
			if self.state == STATE_WAITING:
				self.add_file()
#FIXME: This code is responsible for swapping the playing file if there is
#	a closer one to play and we've walked out of range of another.
#	Problem is it sounds bad without the ability to fade it out.
#	Uncomment this when fading works.
#			elif self.state == STATE_PLAYING:
#				if not self.recordings.is_nearby(
#						listener,
#						self.currently_playing_recording):
#					#FIXME: This should fade out.
#					self.clean_up()
#					self.add_file()

	######################################################################
	# PRIVATE
	######################################################################

	def add_file (self):
		self.current_recording = self.recordings.get_recording()
		if not self.current_recording:
			self.state = STATE_WAITING
			return

		duration = min(
			self.current_recording["audiolength"],
			random.randint(
				#FIXME: I don't allow less than a second to
				# play currently. Mostly because playing zero
				# is an error. Revisit this.
				max(self.comp_settings["minduration"],
					gst.SECOND),
				max(self.comp_settings["maxduration"],
					gst.SECOND)))

		start = random.randint(
			0,
			self.current_recording["audiolength"] - duration)

		fadein = random.randint(
			self.comp_settings["minfadeintime"],
			self.comp_settings["maxfadeintime"])
		fadeout = random.randint(
			self.comp_settings["minfadeouttime"],
			self.comp_settings["maxfadeouttime"])

		#FIXME: Instead of doing this divide by two, instead,
		# decrease them by the same percentage. Remember it's
		# possible that fade_in != fade_out.
		if fadein + fadeout > duration:
			fadein = duration / 2
			fadeout = duration / 2

		volume = self.current_recording["volume"] * (
			self.comp_settings["minvolume"] + \
			random.random() * \
			(self.comp_settings["maxvolume"] - \
				self.comp_settings["minvolume"]))

		self.roundfilesrc = roundfilesrc.RoundFileSrc(
			"file://" + os.path.join(settings.config["audio_dir"],
					self.current_recording["filename"]),
			start, duration, fadein, fadeout, volume)
		self.pipeline.add(self.roundfilesrc)
		self.srcpad = self.roundfilesrc.get_pad('src')
		self.addersinkpad = self.adder.get_request_pad('sink%d')
		self.srcpad.link(self.addersinkpad)
		self.addersinkpad.add_event_probe(self.event_probe)
		(ret, cur, pen) = self.pipeline.get_state()
		self.roundfilesrc.set_state(cur)
		self.state = STATE_PLAYING

	def event_probe (self, pad, event):
		if event.type == gst.EVENT_EOS:
			gobject.idle_add(self.clean_up_wait_and_play)
		elif event.type == gst.EVENT_NEWSEGMENT:
			gobject.idle_add(self.roundfilesrc.seek_to_start)
		return True

	def clean_up_wait_and_play (self):
		self.clean_up()
		self.wait_and_play()

	def clean_up (self):
		if self.roundfilesrc:
			self.roundfilesrc.set_state(gst.STATE_NULL)
			self.pipeline.remove(self.roundfilesrc)
			self.adder.release_request_pad(self.addersinkpad)
			self.state = STATE_DEAD_AIR
			self.current_recording = None
			self.roundfilesrc = None
		return False

	def set_new_pan_target(self):
		pan_step_size = (self.comp_settings["maxpanpos"] - \
			self.comp_settings["minpanpos"]) / \
			settings.config["num_pan_steps"]
		target_pan_step = random.randint(
			0,
			settings.config["num_pan_steps"])
		self.target_pan_pos = -1 + target_pan_step * pan_step_size

	def set_new_pan_duration(self):
		duration_in_gst_units = \
			random.randint(
				self.comp_settings["minpanduration"],
				self.comp_settings["maxpanduration"])
		duration_in_miliseconds = duration_in_gst_units / gst.MSECOND
		self.pan_steps_left = duration_in_miliseconds / \
			settings.config["stereo_pan_interval"]

	def skip_ahead (self):
		self.clean_up_wait_and_play()

