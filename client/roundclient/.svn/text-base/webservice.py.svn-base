import simplejson
import settings
import MultipartPostHandler
import urllib2

def invoke (operation, args = []):
	get_string = "http://" + settings.config.get("server", "host") + \
		":" + settings.config.get("server", "port") + \
		settings.config.get("server", "get_string") + \
		"&operation=" + operation
	post_args = combine_dicts(args)
	obj = simplejson.loads(http_post(get_string, post_args))
	if type(obj) == dict and obj.has_key("ERROR_MESSAGE"):
		raise Exception(obj["ERROR_MESSAGE"] + " traceback =" + obj["TRACEBACK"])
	else:
		return obj

#TODO: Error handling.
def http_post (get_string, post_args):
	opener = urllib2.build_opener(MultipartPostHandler.MultipartPostHandler)
	urllib2.install_opener(opener)
	req = urllib2.Request(get_string, post_args)
	return urllib2.urlopen(req).read().strip()

#def http_get (getstring):
#	conn = httplib.HTTPConnection(settings.config.get("server","host"), settings.config.get("server", "port"))
#	print "http://"+settings.config.get("server","host")+":"+settings.config.get("server", "port")+getstring
#	conn.request("GET", getstring)
#	r = conn.getresponse()
#	if r.status == 200 and r.reason == "OK":
#		data = r.read()
#		conn.close()
#		return data
#	else:
#		conn.close()
#		return '{ "ERROR_MESSAGE" : "Error connection to server: status=' + \
#			r.status + ' reason=' + r.reason + '"}'

def combine_dicts (list_of_dict):
	total = {}
	for d in list_of_dict:
		for k in d.keys():
			if d[k] != None:
				total[k] = to_postable_value(d[k])
	return total

def to_postable_value (value):
	if type(value) == list:
		return ",".join(map(to_postable_value, value))
	elif type(value) == int :
		return str(value)
	elif type(value) == str or type(value) == file or type(value) == unicode:
		return value
	else:
		raise Exception("to_postable_value: Invalid parameter type: " + str(type(value))) 
