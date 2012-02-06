#!/usr/bin/python

import fcgi
import cgi, cgitb
from roundwared import server

def app(environ, start_response):
	start_response('200 OK', [('Content-Type', 'text/html')])
	form = cgi.FieldStorage(environ['wsgi.input'], environ=environ)
	return server.webservice_main(server.form_to_dict(form))

fcgi.WSGIServer(app, bindAddress = '/tmp/fcgi.sock').run()

