import httplib

url1 = "http://localhost/cgi-bin/roundware.py?config=scapes&stream_url=stream0.mp3&operation=modify_stream"
#real	2m21.220s
#user	0m0.096s
#sys	0m0.056s

url2 = "http://localhost/roundware/roundware.py?config=scapes&stream_url=stream0.mp3&operation=modify_stream"
#real	0m0.890s
#user	0m0.108s
#sys	0m0.088s


for i in range(0,100):
	h = httplib.HTTPConnection('localhost', 80, timeout=10)
	h.request("GET", url2)
	r = h.getresponse()
	str = r.read()
	print i

