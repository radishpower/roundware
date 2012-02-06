#!/usr/bin/env python

import cgi, cgitb 
import logging
import os
from roundwared import server
from roundwared import settings

cgitb.enable() #Turn on debugging for evelopment.

form = cgi.FieldStorage() 

logging.basicConfig(
	filename=settings.config["log_file"],
	filemode="a",
	level=logging.DEBUG,
	format='%(asctime)s %(filename)s:%(lineno)d %(levelname)s %(message)s',
)

if form.getvalue('config'):
	settings.initialize_config(
		os.path.join(
			'/etc/roundware/',
			form.getvalue('config')))

dict_form = server.form_to_dict(form)
result = server.request_stream(dict_form)
url = result['STREAM_URL']
num_rec = server.number_of_recordings(dict_form)

print "Content-type: text/html"
print
print "<html><head><title>Roundware - Listen</title></head><body>"
print "<p>" + str(num_rec) + " recordings match your selection."
print "<p>You can use the <a href=\""+url+"\">MP3 url</a> or the "
print "<a href=\""+url+".m3u\">M3U url</a>."
print "<p>You can <a href=\"/cgi-bin/control.py?stream_url="+url+"\">control</a> your stream too.</p>"
print "</body></html>"

