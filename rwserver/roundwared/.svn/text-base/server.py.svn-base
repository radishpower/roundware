import time
import string
import subprocess
import os
import logging
import json
import traceback
import uuid
from roundwared import settings
from roundwared import db
from roundwared import convertaudio
from roundwared import discover_audiolength
from roundwared import roundexception
from roundwared import icecast2
from roundwared import gpsmixer
from roundwared import rounddbus
from roundware.rw import models



#2.0 Protocol
def get_config(request):
	form = request.GET
	try:
		hostname_without_port = str(settings.config["external_host_name_without_port"])
	except KeyError:
		raise roundexception.RoundException("Roundware configuration file is missing 'external_host_name_without_port' key. ")
	#check params
	if not form.has_key('project_id'):
		raise roundexception.RoundException("a project_id is required for this operation")
	project = models.Project.objects.get(id=form.get('project_id'))

	if not form.has_key('device_id') or (form.has_key('device_id') and form['device_id']==""):
		device_id = str(uuid.uuid4())
	else:
		device_id = form.get('device_id')
		
		
	session_id = db.create_session(device_id,project)
	
	sharing_url = str.format("http://{0}/roundware/?operation=view_envelope&envelopeid=[id]", hostname_without_port)
	
	response = [ 
	        { "device":{"device_id":device_id}},
	        { "session":{"session_id":session_id}},
	        { "project":{
	                "project_id":project.id, 
	                "project_name":project.name,
	                "audio_format":project.audio_format,
	                "max_recording_length":project.max_recording_length,
	                "sharing_message":project.sharing_message,
	                "sharing_url":sharing_url,
	                "listen_questions_dynamic":project.listen_questions_dynamic,
	                "speak_questions_dynamic":project.speak_questions_dynamic,
	                }},
	        { "server":{	                
	                "version": "2.0"}}
	]	
	db.log_event('start_session',session_id,None)
	return response

def get_tags_for_project(request):
	form = request.GET
	if not form.has_key('project_id'):
		raise roundexception.RoundException("a project_id is required for this operation")
	project = models.Project.objects.get(id=form.get('project_id'))

	return db.get_config_tag_json_for_project(project.id)
	

def log_event (request):
	
	form = request.GET
	if not form.has_key('session_id'):
		raise roundexception.RoundException("a session_id is required for this operation")
	if not form.has_key('event_type'):
		raise roundexception.RoundException("an event_type is required for this operation")
	db.log_event(form.get('event_type'),form.get('session_id'), form)
	
	return {"success":True}

#create_envelope
#args: (operation, session_id, [tags])
#example: http://localhost/roundware/?operation=create_envelope&sessionid=1&tags=1,2
#returns envelope_id, sharing_messsage
#example:
#{"envelope_id": 2}
def create_envelope(request):
	form = request.GET
	if not form.has_key('session_id'):
		raise roundexception.RoundException("a session_id is required for this operation")
	s = models.Session.objects.get(id=form.get('session_id'))
	
	#todo - tags
	
	env = models.Envelope(session = s)
	env.save()
	
	return {"envelope_id":env.id}
	
#add_asset_to_envelope (POST method)
#args (operation, envelope_id, file, latitude, longitude, [tagids])
#example: http://localhost/roundware/?operation=add_asset_to_envelope
#returns success bool
#{"success": true}
def add_asset_to_envelope(request):

	envelope_id = get_parameter_from_request(request, 'envelope_id', True)
	latitude = get_parameter_from_request(request, 'latitude', False)
	longitude = get_parameter_from_request(request, 'longitude', False)
	if latitude == None:
		latitude = 0.0
	if longitude == None:
		longitude = 0.0
	
	tagset = []
	tags = get_parameter_from_request(request, 'tags', False)
	if tags != None:
		ids = tags.split(',')
		tagset = models.Tag.objects.filter(id__in=ids)

	envelope = models.Envelope.objects.get(id=envelope_id)
	session = envelope.session
	submitted = get_parameter_from_request(request, 'submitted', False)
	if submitted == None:
		submitted=session.project.auto_submit 
	
	db.log_event("start_upload", session.id,request.GET)
	
	fileitem = request.FILES.get('file')
	if fileitem.name:
		logging.debug("Processing " + fileitem.name)
		(filename_prefix, filename_extension) = \
			os.path.splitext(fileitem.name)
		fn = time.strftime("%Y%m%d-%H%M%S") + filename_extension
		fileout = open(os.path.join(settings.config["upload_dir"], fn), 'wb')
		fileout.write(fileitem.file.read())
		fileout.close()
		newfilename = convertaudio.convert_uploaded_file(fn)
		if newfilename:
			asset = models.Asset(latitude=latitude,longitude=longitude,
			                      filename=newfilename, session=session, submitted=submitted, volume=1.0)
			asset.project = session.project
			asset.save()
			for t in tagset:
				asset.tags.add(t)
			
			discover_audiolength.discover_and_set_audiolength(asset, newfilename)
			asset.save()
			envelope.assets.add(asset)
			envelope.save()
		else:
			raise RoundException("File not converted successfully: " + newfilename)		
	else:
		raise RoundException("No file in request")
	rounddbus.emit_stream_signal(0, "refresh_recordings", "")
	return {"success":True}

def get_parameter_from_request(request,name, required):
	ret = None
	if request.POST.has_key(name):
		ret = request.POST.get(name)
	elif request.GET.has_key(name):
		ret = request.GET.get(name)
	else:
		if required:
			raise roundexception.RoundException(name + " is required for this operation")
	return ret

def request_stream (request):
	request_form = request.GET
	logging.debug("request")
	#FIXME: next line is a hack. os.envrion is not available from fastcgi
	try:
		hostname_without_port = str(settings.config["external_host_name_without_port"])
	except KeyError:
		raise roundexception.RoundException("Roundware configuration file is missing 'external_host_name_without_port' key. ")
	
	if not request_form.get('session_id'):
		raise roundexception.RoundException("Must supply session_id.")
	session = models.Session.objects.get(id=request_form.get('session_id'))
	project = session.project
	
	if is_listener_in_range_of_stream(request_form, project):
		command = ['/usr/local/bin/streamscript', '--session_id', str(session.id), '--project_id', str(project.id)]
		for p in ['latitude', 'longitude', 'audio_format']:
			if request_form.has_key(p) and request_form[p]:
				command.extend(['--' + p, request_form[p].replace("\t", ",")])
		if request_form.has_key('config'):
			command.extend(['--configfile', os.path.join(settings.configdir, request_form['config'])])
		else:
			command.extend(['--configfile', os.path.join(settings.configdir, 'rw')])
		
		audio_format = project.audio_format.upper()
		apache_safe_daemon_subprocess(command)
		wait_for_stream(session.id, audio_format)

		return {
			"stream_url" : "http://" + hostname_without_port + ":" + \
				str(settings.config["icecast_port"]) + \
				icecast_mount_point(session.id, audio_format),
		}
	else:
		if project.out_of_range_message:
			msg = project.out_of_range_message
		else:
			msg = "This application is designed to be used in specific geographic locations.  Apparently your phone thinks you are not at one of those locations, so you will hear a sample audio stream instead of the real deal.  If you think your phone is incorrect, please restart Scapes and it will probably work.  Thanks for checking it out!"
		
		if project.out_of_range_url:
			url = project.out_of_range_url
		else:
			url = "http://" + hostname_without_port + ":" + \
				        str(settings.config["icecast_port"]) + \
				        "/outofrange.mp3"
		
		return {
			'stream_url' : url ,
			'user_error_message' : msg
		}

def modify_stream (request):
	success = False
	msg = ""
	form = request.GET
	request = form_to_request(form)
	arg_hack = json.dumps(request)
	db.log_event("modify_stream", int(form['session_id']),form)
	if form.has_key('session_id'):
		session = models.Session.objects.get(id=form['session_id'])
		project = session.project
		audio_format = project.audio_format.upper()
		if stream_exists(int(form['session_id']), audio_format):
			rounddbus.emit_stream_signal(int(form['session_id']), "modify_stream", arg_hack)
			success = True
		else:
			msg = "no stream available for session: " + form['session_id']
	else:
		msg = "a session_id is required for this operation"
		
		
	if success:
		return {"success":success}
	else:
		return {"success":success,"user_error_message":msg}

def move_listener (request):
	form = request.GET
	request = form_to_request(form)
	arg_hack = json.dumps(request)
	rounddbus.emit_stream_signal(int(form['session_id']), "move_listener", arg_hack)
	return {"success":True}

def heartbeat (request):
	form = request.GET
	rounddbus.emit_stream_signal(int(form['session_id']), "heartbeat", "")
	db.log_event("heartbeat", int(form['session_id']),form)
	return {"success":True}

def current_version (request):
	return {"version" :"2.0"}
#END 2.0 Protocol

#2.0 Helper methods

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

# Loops until the give stream is present and ready to be listened to.
def wait_for_stream (sessionid, audio_format):
	logging.debug("waiting "+str(sessionid)+audio_format)
	admin = icecast2.Admin(settings.config["icecast_host"]+":"+str(settings.config["icecast_port"]), 
	                       settings.config["icecast_username"], 
	                       settings.config["icecast_password"])
	retries_left = 1000
	while not admin.stream_exists(icecast_mount_point(sessionid, audio_format)):
		if retries_left > 0:
			retries_left -= 1
		else:
			raise roundexception.RoundException("Stream timedout on creation")
		time.sleep(0.1)

def stream_exists(sessionid, audio_format):
	logging.debug("checking for existence of "+str(sessionid)+audio_format)
	admin = icecast2.Admin(settings.config["icecast_host"]+":"+str(settings.config["icecast_port"]), 
	                       settings.config["icecast_username"], 
	                       settings.config["icecast_password"])
	return admin.stream_exists(icecast_mount_point(sessionid, audio_format))

def is_listener_in_range_of_stream (form, proj):
	if not form.get('latitude') or not form.get('latitude'):
		return True
	speakers = models.Speaker.objects.filter(project=proj)
	
	for speaker in speakers:
		distance = gpsmixer.distance_in_meters(
				float(form['latitude']),
				float(form['longitude']),
				speaker.latitude,
				speaker.longitude)
		if not distance > 3 * speaker.maxdistance:
			return True
	return False
#END 2.0 Helper methods



def form_to_request (form):
	request = {}
	for p in ['project_id', 'session_id']:
		if form.has_key(p) and form[p]:
			request[p] = map(int, form[p].split("\t"))
		else:
			request[p] = []
	for p in ['tags']:
		if form.has_key(p) and form[p]:
			request[p] = map(int, form[p].split(","))
		else:
			request[p] = []

	for p in ['latitude', 'longitude']:
		if form.has_key(p) and form[p]:
			request[p] = float(form[p])
		else:
			request[p] = False
	return request


def icecast_mount_point(sessionid, audio_format):
	return '/stream' + str(sessionid) + "." + audio_format.lower()
