from roundwared import server
from roundwared import db

def test (actual, expected):
	if actual != expected:
		print "FAILED"
		
		
def testrecording():
	server.enter_recording({'categoryid':'9','subcategoryid':'9'})
	return
#47.67304230&longitude=-122.36764526&
def test105():
	server.request_stream({'categoryid':'10','subcategoryid':'9','latitude':'47.67304230','longitude':'-122.36764526'})
	return
def test95():
	server.request_stream({'categoryid':'10','subcategoryid':'9','latitude':'20','longitude':'-20'})
	return
def test12():
	r1 = server.get_questions({'categoryid':'8','subcategoryid':'12','latitude':'20','longitude':'-20'})
	r2 = server.get_questions({'categoryid':'8','subcategoryid':'12','latitude':'20','longitude':'20'})
	r3 = server.get_questions({'categoryid':'8','subcategoryid':'12'})
	r1 = db.get_recordings({'categoryid':'8','subcategoryid':'12','latitude':'20','longitude':'-20','demographicid':'1','usertypeid':'17','genderid':'1','ageid':'17','questionid':'36'})
	return
#test(server.stream_url_to_name("http://scapesaudio.dyndns.org:8000/stream127960004754.mp3"),
#	"stream127960004754")
#test(server.stream_url_to_name("http://scapesaudio.dyndns.org:8000/lobby.mp3"),
#	"lobby")
test12()