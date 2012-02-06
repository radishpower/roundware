#!/usr/bin/env python

import urllib2_file
import urllib2
import sys

data = {
	'operation' : 'upload_and_process_file',
	'file':  open(sys.argv[1]),
	'categoryid' : "7",
	'subcategoryid' : "8",
	'questionid' : "23",
	#'ageid' : "30",
	#'genderid' : "2",
	'demographicid' : "1",
	'usertypeid' : "7",
	'submittedyn' : "Y",
	#'config' : 'oceanvoices',
}

f = urllib2.urlopen('http://localhost/cgi-bin/roundware.py', data)
print f.read()
f.close()

