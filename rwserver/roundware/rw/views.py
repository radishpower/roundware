from django.http import HttpResponse
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
from roundwared import server

#Used for the visualization engine
from django.template import RequestContext, loader
from rw.models import Asset
from django.http import HttpResponse

def main (request):
	return HttpResponse(json.dumps(catch_errors(request), sort_keys=True, indent=4), mimetype='application/json')


def visualview (request):
  latest_entry_list = Asset.objects.all().order_by('session')
  t = loader.get_template('Project/index.html')
  c = RequestContext(request, {
      'latest_entry_list': latest_entry_list,
  })
  return HttpResponse(t.render(c))

def catch_errors (request):
	try:
		config_file = "rw"
		if request.GET.has_key('config'):
			config_file = request.GET['config']
		settings.initialize_config(os.path.join('/etc/roundware/',config_file))

		logging.basicConfig(
			filename=settings.config["log_file"],
			filemode="a",
			level=logging.DEBUG,
			format='%(asctime)s %(filename)s:%(lineno)d %(levelname)s %(message)s',
			)

		if request.GET.has_key('operation'):
			function = operation_to_function(request.GET['operation'])
		elif request.POST.has_key('operation'):
			function = operation_to_function(request.POST['operation'])
		return function(request)
	except roundexception.RoundException as e:
		logging.error(str(e) + traceback.format_exc())
		return { "error_message" : str(e) }
	except:
		logging.error(
			"An uncaught exception was raised. See traceback for details." + \
			traceback.format_exc())
		return {
			"error_message" : "An uncaught exception was raised. See traceback for details.",
			"traceback" : traceback.format_exc(),
		}


def operation_to_function (operation):
	if not operation:
		raise roundexception.RoundException("Operation is required")
	operations = {
		"request_stream" : server.request_stream,
		"heartbeat" : server.heartbeat,
		"current_version" : server.current_version,
		"log_event" : server.log_event,
		"create_envelope" : server.create_envelope,
	        "add_asset_to_envelope" : server.add_asset_to_envelope,
	        "get_config" : server.get_config,
	        "get_tags" : server.get_tags_for_project,
	        "modify_stream" : server.modify_stream
	}
	key = string.lower(operation)
	if operations.has_key(key):
		return operations[key]
	else:
		raise roundexception.RoundException("Invalid operation, " + operation)
