import time
import string
import subprocess
import os
import logging
import json
import traceback
from roundwared import settings
from roundwared import db
from roundwared import convertaudio
from roundwared import discover_audiolength
from roundwared import roundexception
from roundwared import icecast2
from roundwared import gpsmixer
from roundwared import rounddbus

def icecast_mount_point(sessionid, audio_format):
	return '/stream' + str(sessionid) + "." + audio_format.lower()

def request_stream (form):
	logging.debug("request")
	#FIXME: next line is a hack. os.envrion is not available from fastcgi
	db.log_event(10, form)
	hostname_without_port = str(settings.config["external_host_name_without_port"])

	if is_listener_in_range_of_stream(form):
		udid = ""
		if form.has_key('udid'):
			udid = form['udid']
		sessionid = db.create_session(udid)
		command = ['/usr/local/bin/streamscript', '--sessionid', str(sessionid)]

		for p in ['categoryid', 'subcategoryid', 'questionid', 'usertypeid', 'genderid', 'demographicid', 'ageid', 'latitude', 'longitude', 'audioformat']:
			if form.has_key(p) and form[p]:
				command.extend(['--' + p, form[p].replace("\t", ",")])

		if form.has_key('config'):
			command.extend(['--configfile', os.path.join(settings.configdir, form['config'])])

		audio_format = 'MP3'
		if form.has_key('audioformat'):
			audio_format = form['audioformat'].upper()

		apache_safe_daemon_subprocess(command)
		wait_for_stream(sessionid, audio_format)

		#TODO: must return streamurl and sessionid here
		#	do NOT brake scapes.py
		return {
			"SESSIONID" : sessionid,
			"STREAM_URL" : "http://" + hostname_without_port + ":" + \
				str(settings.config["icecast_port"]) + \
				icecast_mount_point(sessionid, audio_format),
		}
	else:
		msg = "This application is designed to be used in specific geographic locations.  Apparently your phone thinks you are not at one of those locations, so you will hear a sample audio stream instead of the real deal.  If you think your phone is incorrect, please restart Scapes and it will probably work.  Thanks for checking it out!"
		if form.has_key('out_of_range_message'):
			msg = form['out_of_range_message']
			
		url = "http://" + hostname_without_port + ":" + \
				str(settings.config["icecast_port"]) + \
				"/outofrange.mp3"
		if form.has_key('categoryid'):
			dburl = db.get_out_of_range_url_for_categoryid(form["categoryid"])
			if(dburl):
				url = dburl
		
		return {
			"SESSIONID" : "-1",		        
			'STREAM_URL' : url ,
			'USER_ERROR_MESSAGE' : msg
		}

def is_listener_in_range_of_stream (form):
	if not form.get('latitude') or not form.get('latitude'):
		return True
	speakers = db.get_speakers(form['categoryid'])
	for speaker in speakers:
		distance = gpsmixer.distance_in_meters(
				float(form['latitude']),
				float(form['longitude']),
				speaker['latitude'],
				speaker['longitude'])
		if not distance > 3 * speaker['maxdistance']:
			return True
	msg = db.get_out_of_range_message_for_categoryid(form['categoryid'])
	if msg:
		form['out_of_range_message'] = msg
	return False

def modify_stream (form):
	db.log_event(12, form)
	request = form_to_request(form)
	arg_hack = json.dumps(request)
	rounddbus.emit_stream_signal(int(form['sessionid']), "modify_stream", arg_hack)
	return True

def move_listener (form):
	db.log_event(1, form)
	request = form_to_request(form)
	arg_hack = json.dumps(request)
	rounddbus.emit_stream_signal(int(form['sessionid']), "move_listener", arg_hack)
	return True

#TODO: Inspect the printed values from stderr and the return value of the script to check for errors.
def apache_safe_daemon_subprocess (command):
	logging.debug(str(command))
	DEVNULL_OUT = open(os.devnull, 'w')
	DEVNULL_IN = open(os.devnull, 'r')
	proc = subprocess.Popen(
		command,
		close_fds = True,
		stdin = DEVNULL_IN,
		stdout = DEVNULL_OUT,
		stderr = DEVNULL_OUT,
	)
	proc.wait()

# String -> None
# Loops until the give stream is present and ready to be listened to.
def wait_for_stream (sessionid, audio_format):
	logging.debug("waiting "+str(sessionid)+audio_format)
	admin = icecast2.Admin("localhost:8000", "admin", "roundice")
	retries_left = 1000
	while not admin.stream_exists(icecast_mount_point(sessionid, audio_format)):
		if retries_left > 0:
			retries_left -= 1
		else:
			raise roundexception.RoundException("Stream timedout on creation")
		time.sleep(0.1)

def number_of_recordings (form):
	logging.debug("number_of_recordings")
	request = form_to_request(form)
	return db.number_of_recordings(request)

def skip_ahead (form):
	rounddbus.emit_stream_signal(int(form['sessionid']), "skip_ahead", "")
	return True #FIXME: return false if it failed. don't always return true

def heartbeat (form):
	db.log_event(2, form)
	rounddbus.emit_stream_signal(int(form['sessionid']), "heartbeat", "")
	return True #FIXME: return false if it failed. don't always return true

def current_version (form):
	return 1.2

def get_categories (form):
	return db.get_categories(form['project_name'])

def get_demographics (form):
	return db.get_demographics(form['project_name'])

def submit_recording (form):
	submityn = 'Y'
	if form.has_key('submityn'):
		submityn = form['submityn']
	return db.submit_recording(form['recordingid'], submityn)

#TODO: Come up with a more robust method of raising exceptions when the web services
#	are passed invalid or missing arguments.
def process_recorded_file (form):
	user = form_to_user(form)
	request = form_to_recording_request(form)
	filename = form['filename']
	if not filename:
		raise roundexception.RoundException("process_recorded_file requires a filename")
	submityn = form['submittedyn']
	retval = process_recorded_file_helper (user, request, filename, submityn)
	refresh_recordings()
	return retval

def upload_and_process_file (form):
	logging.debug("upload_and_process_file")
	db.log_event(7, form)
	user = form_to_user(form)
	request = form_to_recording_request(form)
	submityn = form['submittedyn']
	fileitem = form['file']
	if fileitem.filename:
		logging.debug("Processing " + fileitem.filename)
		(filename_prefix, filename_extension) = \
			os.path.splitext(fileitem.filename)
		fn = time.strftime("%Y%m%d-%H%M%S") + filename_extension
		fileout = open(os.path.join(settings.config["upload_dir"], fn), 'wb')
		fileout.write(fileitem.file.read())
		fileout.close()
		retval = process_recorded_file_helper (user, request, fn, submityn)
		refresh_recordings()
		return retval
	else:
		raise RoundException("Uploaded file has no filename")

def upload_recording (form):
	logging.debug("upload_recording")
	db.log_event(7, form)
	
	user = form_to_user(form)
	request = form_to_recording_request(form)
	fileitem = form['file']
	id_to_update = form['recordingid']
	
	if id_to_update != None:
		if fileitem.filename:
			logging.debug("Processing " + fileitem.filename)
			(filename_prefix, filename_extension) = \
				os.path.splitext(fileitem.filename)
			fn = time.strftime("%Y%m%d-%H%M%S") + filename_extension
			fileout = open(os.path.join(settings.config["upload_dir"], fn), 'wb')
			fileout.write(fileitem.file.read())
			fileout.close()
			retval = update_recorded_file_helper (user, request, fn, id_to_update)
			refresh_recordings()
			return retval
		else:
			raise RoundException("Uploaded file has no filename")	
	else:
		raise RoundException("No recordingid provided for update")	


def enter_recording (form):
	response = {}
	logging.debug("enter_recording")
	db.log_event(7, form)
	user = form_to_user(form)
	request = form_to_recording_request(form)
	recordingid = db.store_recording(user, request, '')	
	response['RESULT'] = recordingid
	
	msg = db.get_sharing_message_for_categoryid(form['categoryid'])
	msg = msg + str(recordingid)
	response['SHARING_MESSAGE'] = msg
	return response
	
def refresh_recordings ():
	#NOTE: The zero is a hack. No ID is required.
	rounddbus.emit_stream_signal(0, "refresh_recordings", "")

def process_recorded_file_helper (user, request, filename, submityn):
	newfilename = convertaudio.convert_uploaded_file(filename)
	#TODO: For now it's easiest to call these three functions because they already
	#exist, but in the long term, it'll be more efficient to just create one row in the
	#database instead of creating, and updating it twice like I'm doing here.
	if newfilename:
		recordingid = db.store_recording(user, request, newfilename)
		discover_audiolength.discover_and_set_audiolength(recordingid, newfilename)
		if submityn == 'Y':
			db.submit_recording(recordingid, submityn)
		return recordingid
	else:
		raise RoundException("File not converted successfully: " + newfilename)
def update_recorded_file_helper (user, request, filename, recordingid):
	response = {}
	newfilename = convertaudio.convert_uploaded_file(filename)
	#TODO: For now it's easiest to call these three functions because they already
	#exist, but in the long term, it'll be more efficient to just create one row in the
	#database instead of creating, and updating it twice like I'm doing here.
	submityn = 'Y'
	if request.has_key('submityn'):
		submityn = request['submityn']
	if newfilename:
		db.update_recording_filename(recordingid, newfilename)
		discover_audiolength.discover_and_set_audiolength(recordingid, newfilename)
		db.submit_recording(recordingid, submityn)
		return recordingid
	else:
		raise RoundException("File not converted successfully: " + newfilename)

def form_to_user (form):
	user = {}
	userkeys = ['usertypeid', 'ageid', 'demographicid', 'genderid', 'firstname', 'lastname', 'email', 'geonameid', 'latitude', 'longitude', 'comment', 'email']
	for key in userkeys:
		if form.has_key(key):
			user[key] = form[key]
	return user

def form_to_request (form):
	request = {}
	for p in ['categoryid', 'subcategoryid', 'questionid', 'projectid', 'usertypeid', 'genderid', 'demographicid', 'ageid']:
		if form.has_key(p) and form[p]:
			request[p] = map(int, form[p].split("\t"))
		else:
			request[p] = []

	for p in ['latitude', 'longitude']:
		if form.has_key(p) and form[p]:
			request[p] = float(form[p])
		else:
			request[p] = False
	return request

def form_to_recording_request (form):
	request = {}
	#FIXME: This needs lat/lon I think. Be very careful to cast the unicode to a float!
	for p in ['categoryid', 'subcategoryid', 'questionid', 'projectid']:
		if form.has_key(p) and form[p]:
			request[p] = int(form[p])
		else:
			request[p] = False
	return request

#TODO: Have a table of the allowed arguments, the types of those arguments, and the default values.
#	Make this do some checking and also autoconvert the args.
def form_to_dict (form):
	dform = {}
	for k in form.keys():
		#For some reason on python2.6.4 the file is turned into a str
		#if I use getvalue. Not in 2.6.5 I think
		if k == "file":
			dform[k] = form[k]
		else:
			dform[k] = form.getvalue(k)
	return dform

def typed_form_to_dict (form):
	def arrayOfInt (s):
		return map(int, s.rsplit(","))

	valid_fields = [
		["sessionid", int],
		["udid", int],
		["stream_url", str],
		["categoryid", arrayOfInt],
		["subcategoryid", arrayOfInt],
		["questionid", arrayOfInt],
		["usertypeid", arrayOfInt],
		["ageid", arrayOfInt],
		["genderid", arrayOfInt],
		["demographicid", arrayOfInt],
		["latitude", float],
		["longitude", float],
		["cource", str],
		["haccuracy", str],
		["speed", str],
		["clienttime", str],
		["operation", str]
		["config", str]
	]

	dform = {}
	for f in valid_fields:
		key = f[0]
		convert = f[1]
		if form.has_key(key):
			str_value = form.getvalue(key)
			dform[key] = convert(str_value)
		elif len(f) == 3:
			dform[key] = f[2]
	return dform

def get_questions (form):
	categoryid = map(int, form["categoryid"].split(","))
	subcategoryid = map(int, form["subcategoryid"].split(","))	
	return db.get_questions(categoryid, subcategoryid,form)

def log_event (form):
	if form.has_key('eventtypeid'):
		eventtypeid = int(form['eventtypeid'])
		return db.log_event(eventtypeid, form)
	else:
		raise roundexception.RoundException("An eventtypeid is required for the log_event operation")

