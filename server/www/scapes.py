#!/usr/bin/python

import fcgi
import cgi, cgitb
import json
import traceback
import string
import re
from roundwared import server
from roundwared import db

cgitb.enable()

def create_roundware_arguments(form):
	dform = server.form_to_dict(form)
	convert_listen_versions(dform)
	convert_comma_to_tab(dform)
	find_session_id(dform)
	dform['operation'] = get_operation(dform)
	dform['config'] = "scapes"
	dform['projectid'] = "4"
	dform['categoryid'] = "8"
	dform['subcategoryid'] = "9"
	return dform

def convert_listen_versions (form):
	if form.has_key('listen_genderage'): form['demographicid'] = form['listen_genderage']
	if form.has_key('listen_question'): form['questionid'] = form['listen_question'].replace(",","\t")

def convert_comma_to_tab (dform):
	keys = [
		'categoryid',
		'subcategoryid',
		'questionid',
		'usertypeid',
		'genderid',
		'demographicid',
		'ageid',
	]
	for key in keys:
		if dform.has_key(key):
			dform[key] = string.replace(dform[key],",","\t")

def find_session_id(dform):
	if dform.has_key('stream_url'):
		m = re.search('stream([0-9]+)', dform['stream_url'])
		if m is None:
			pass
		else:
			dform['sessionid'] = m.group(1) # converted to int later

def get_operation (form):
	operationid = int(form['operationid'])
	if operationid == 1: return 'move_listener'
	elif operationid == 2: return 'heartbeat'
	elif operationid == 7: return 'process_recorded_file'
	elif operationid == 10: return 'request_stream'
	elif operationid == 12: return 'modify_stream'
	else: return ''

def app(environ, start_response):
	try:
		start_response('200 OK', [('Content-Type', 'text/html')])
		form = cgi.FieldStorage(environ['wsgi.input'], environ=environ)
		dform = create_roundware_arguments(form)
		if not dform.has_key('operation') or dform['operation'] == '':
			result = True
		elif dform['operation'] == "move_listener" and dform['stream_url'] == '(null)':
			result = True
		else:
			result = server.catch_errors(dform)

		try: db.insert_event(form)
		except: pass

		if type(result) == type({}):
			if result.has_key('STREAM_URL'):
				result['RESULT'] = result['STREAM_URL']
			return json.dumps(result, sort_keys=True, indent=4)
		else:
			return json.dumps({ "RESULT" : result }, sort_keys=True, indent=4)
	except:
		return json.dumps({
			"ERROR_MESSAGE" : "An uncaught exception was raised. See traceback for details.",
			"TRACEBACK" : traceback.format_exc(),
		})

fcgi.WSGIServer(app, bindAddress = '/tmp/fcgi2.sock').run()

