#TODO: Find all of the places that reference device and split
#	them out into meaningful things like display_tutorial
#	which is used in the kiosk glade file and
#	use_dspmp3sink which only exists on the Nokias.

import ConfigParser
import os
import StringIO

config = ConfigParser.ConfigParser()
config.readfp(StringIO.StringIO("""
[server]
host = localhost
port = 80
get_string = /cgi-bin/roundware.py?config=pauseplay
[client]
device = N800
max_recording_length = 30
alsadevice = hw:0
"""))

#use hildon
#is there a cursor that needs to be hidden
#how to draw background
#how to show banners

#use client.glade or kiosk.glade
#which page to start on

#can make recordings

#sink device

filename = os.path.expanduser('~/.roundclientrc')
config.read(['/etc/roundclient', filename])
file = open(filename, "w")
config.write(file)
file.close()

