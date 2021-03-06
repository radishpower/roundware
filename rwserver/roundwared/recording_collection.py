#MODES: True Shuffle, Random cycle N times

import logging
import random
import threading
from roundwared import gpsmixer
from roundware.rw import models
from roundwared import db


class RecordingCollection:
	######################################################################
	# Public
	######################################################################
	def __init__ (self, stream, request, radius):
		self.radius = radius
		self.stream = stream
		self.request = request
		# these are lists of model.Recording objects ie [rec1,rec2,etc]
		self.all_recordings = []
		self.far_recordings = []
		self.nearby_played_recordings = []
		self.nearby_unplayed_recordings = []
		self.lock = threading.Lock()
		self.update_request(self.request)

	# Updates the request stored in the collection.
	def update_request (self, request):
		logging.debug("update_request")
		self.lock.acquire()
		self.all_recordings = db.get_recordings(request)
		self.far_recordings = self.all_recordings
		self.nearby_played_recordings = []
		self.nearby_unplayed_recordings = []
		self.update_nearby_recordings(request)
		logging.debug("update_request: all_recordings count: " + str(len(self.all_recordings)) 
		              + ", far_recordings count: " + str(len(self.far_recordings))
		              + ", nearby_played_recordings count: " + str(len(self.nearby_played_recordings))
		              + ", nearby_unplayed_recordings count: " + str(len(self.nearby_unplayed_recordings)))
		self.lock.release()

	# Gets a new recording to play.
	def get_recording (self):
		logging.debug("Recording Collection: Getting a recording from the bucket.")
		self.lock.acquire()
		recording = None
		logging.debug("Recording Collection: we have " + str(len(self.nearby_unplayed_recordings) )+  " unplayed recs.")
		if len(self.nearby_unplayed_recordings) > 0:
			index = random.randint(0, len(self.nearby_unplayed_recordings) - 1)
			recording = self.nearby_unplayed_recordings.pop(index)
			logging.debug("RecordingCollection: get_recording: Got " + recording.filename)
			self.nearby_played_recordings.append(recording)
		self.lock.release()
		return recording

	#Updates the collection of recordings according to a new listener position.
	def move_listener (self, listener):
		#logging.debug("move_listener")
		self.lock.acquire()
		self.update_nearby_recordings(listener)
		self.lock.release()

	# A list of string so of the filenames of the recordings. Useful
	# debugging log messages.
	def get_filenames (self):
		return map(
			lambda recording: recording.filename,
			self.nearby_unplayed_recordings)

	# True if the collection has any recordings left to play.
	def has_recording (self):
		return len(self.nearby_unplayed_recordings) > 0

	######################################################################
	# Private
	######################################################################

	def update_nearby_recordings (self, listener):
		new_far_recordings = []
		new_nearby_unplayed_recordings = []
		new_nearby_played_recordings = []

		for r in self.far_recordings:
			if self.is_nearby(listener, r):
				new_nearby_unplayed_recordings.append(r)
			else:
				new_far_recordings.append(r)

		for r in self.nearby_unplayed_recordings:
			if self.is_nearby(listener, r):
				new_nearby_unplayed_recordings.append(r)
			else:
				new_far_recordings.append(r)

		for r in self.nearby_played_recordings:
			if self.is_nearby(listener, r):
				new_nearby_played_recordings.append(r)
			else:
				new_far_recordings.append(r)

		self.far_recordings = new_far_recordings
		self.nearby_unplayed_recordings = new_nearby_unplayed_recordings
		self.nearby_played_recordings = new_nearby_played_recordings

	#True if the listener are recording are close enough to be heard.
	def is_nearby (self, listener, recording):
		if listener.has_key('latitude') \
			and listener['latitude'] \
			and listener['longitude']:

			distance = gpsmixer.distance_in_meters(
				listener['latitude'], listener['longitude'],
				recording.latitude, recording.longitude)

			return distance <= self.radius
		else:
			return True
			
