#!/usr/bin/env python

import cgi, cgitb

cgitb.enable() #Turn on debugging for evelopment.

form = cgi.FieldStorage()

def i (name, type, value=""):
	if type == 'hidden':
		return name+'<input name="'+name+'" type="'+type+'" value="'+value+'"/>'
	else:
		return '<input name="'+name+'" type="'+type+'" value="'+value+'"/>'

def s (name, options):
	return '<select name="'+name+'">'+ "\n".join(map(lambda o: '<option value="'+o+'">'+o+'</option>', options)) \
		+ '</select>'

def di (name, type, value=""):
	return "<dt>"+name+"</dt><dd>"+i(name,type,value)+"</dd>"

def ds (name, options):
	return "<dt>"+name+"</dt><dd>"+s(name, options)+"</dd>"

print "Content-type: text/html"
print
print '<html><head><title>Control Roundware Stream</title></head><body>'
print '<form method="GET" action="/cgi-bin/roundware.py"><dl>'
print di('stream_url', 'hidden', form.getvalue('stream_url'))
print ds('operation', ["modify_stream", "move_listener", "skip_ahead", "heartbeat"])
print di('latitude', 'text')
print di('longitude', 'text')
print '</dl><div><input type="submit"/></div></form></body></html>'

