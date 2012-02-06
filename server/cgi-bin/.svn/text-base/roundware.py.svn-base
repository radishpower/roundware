#!/usr/bin/env python

import cgi, cgitb 
from roundwared import server
import json

print "Content-type: text/plain"
print
# The following like is what should be here. However the OceanVoices client
# is still expecting a different protocol and thus the hack at the end of this
# file is in place to accomodate it.
#print server.webservice_main(server.form_to_dict(cgi.FieldStorage()))

# BEGIN HACK
val = server.catch_errors(server.form_to_dict(cgi.FieldStorage()))
if val.has_key('STREAM_URL'):
	print '"'+val['STREAM_URL']+'"';
else:
	print json.dumps(val, sort_keys=True, indent=4)
# END HACK

