import settings
import urllib2
import sys
import os
import string
import webservice

LOCAL_VERSION = 1.2
LOCAL_DEB_FILE = "/media/mmc2/RoundClient-1.0.linux-armv5tel.deb"
SERVER_DEB_FILE = "/roundware/RoundClient-1.0.linux-armv5tel.deb"

def check_and_update ():
	server_version = get_current_version_from_server()
	if server_version > LOCAL_VERSION:
		print "Updating new version..."
		deb_file = download_from_server()
		print "Saving..."
		write_to_local_file(deb_file)
		print "Installing package..."
		status = os.system("sudo dpkg -i %s" % (LOCAL_DEB_FILE))
		if status == 0:
			print "Success. New version installed"
		else:
			print "Failure. New version not installed"
	else:
		print "Current version already installed."

def get_current_version_from_server ():
	return webservice.invoke("current_version")

def download_from_server():
	src = "http://" + settings.config.get("server","host") + SERVER_DEB_FILE
	opener1 = urllib2.build_opener()
	page1 = opener1.open(src)
	return page1.read()

def write_to_local_file (deb_file):
	fout = open(LOCAL_DEB_FILE, "wb")
	fout.write(deb_file)
	fout.close()

if __name__ == "__main__":
	check_and_update()
