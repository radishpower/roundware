import MySQLdb
import string
import logging
from roundwared import settings
from roundwared import gpsmixer

def create_session (udid):
	dbh = get_connection()
	cursor = dbh.cursor()
	cursor.execute ("insert into session (udid) values ('"+udid+"')")
	rowid = cursor.lastrowid
	cursor.close ()
	dbh.close ()
	return rowid

def log_event (eventtypeid, form):
	scalar_columns = [
		"sessionid",
		"clienttime",
		"latitude",
		"longitude",
		"course",
		"haccuracy",
		"speed",
		"message",
	]
	list_columns = [
		"demographicid",
		"genderid",
		"ageid",
		"usertypeid",
		"questionid",
	]

	columns = ['eventtypeid']
	values = [str(eventtypeid)]

	for c in scalar_columns:
		if form.has_key(c):
			columns.append(c)
			values.append("'"+form[c]+"'")

	for c in list_columns:
		if form.has_key(c):
			columns.append(c)
			v = string.replace(form[c],"\t",",")
			values.append("'"+v+"'")
		
	sql = "insert into event (" \
		+ ",".join(columns) \
		+ ") values (" \
		+ ",".join(values) \
		+ ")"

	logging.debug(sql)
	dbh = get_connection()
	cursor = dbh.cursor()
	cursor.execute (sql)
	cursor.close()
	dbh.close()
	return True

def get_demographics (projectname = None):
	dbh = get_connection()
	projectid = get_projectid(dbh, projectname)
	if projectid: projectidsql = " where projectid = " + str(projectid)
	else: projectidsql = " where projectid is null"
	usertypesql = "select * from usertype" + projectidsql
	agesql = "select * from age" + projectidsql
	gendersql = "select * from gender"
	demographicsql = "select * from demographic"
	#TODO: Change this a client to accept usertypeid instead of usertypes
	result = {
		"usertypes" : sql_table_dict(dbh, usertypesql),
		"ages" : sql_table_dict(dbh, agesql),
		"genders" : sql_table_dict(dbh, gendersql),
		"demographics" : sql_table_dict(dbh, demographicsql),
	}
	dbh.close()
	return result

def get_categories (projectname = None):
	dbh = get_connection()
	projectid = get_projectid(dbh, projectname)
	categorysql = "select * from category where activeyn = 'Y'"
	if projectid: categorysql += "and projectid = " + str(projectid)
	else: categorysql += "and projectid is null"
	
	categories = sql_table_dict(dbh, categorysql)
	for category in categories:
		subcategorysql = """
			select
				subcategory.*,
				case when artist.id is null
				then ''
				else concat(artist.firstname, ' ', artist.lastname) end artist_name
			from
				subcategory
				left outer join artist on artist.id = subcategory.artistid
			where
				subcategory.categoryid = """ + str(category["id"]) + """
			order by
				subcategory.ordering
		"""
		questionssql = "select * from question where categoryid = " + str(category["id"])
		category["subcategories"] = sql_table_dict(dbh, subcategorysql)
		category["questions"] = sql_table_dict(dbh, questionssql)
	dbh.close()
	return categories

def get_questions (categoryids, subcategoryids, form):
	#first, get all questions
	dbh = get_connection()
	
	questionsql = """
		select id, text, categoryid, subcategoryid, randordering, listenyn, speakyn, radius, latitude, longitude, @rownum:=@rownum+1 'ordering'
		from question_v, (SELECT @rownum:=9) r
		where question_v.categoryid in (""" + string_helper(categoryids) + """)
		and question_v.subcategoryid in (""" + string_helper(subcategoryids) + """)
		order by question_v.randordering"""
	#return dictionary based on distance: iterate through; if lat/long emtpy or (radius meters) from lat/long, add to dict
	d = sql_table_dict(dbh, questionsql)
	returnCollection = []
	for row in d:
		if (form.has_key('latitude') and form.has_key('longitude') and row.has_key('latitude') and row.has_key('longitude') 
		    and row.has_key('radius') and float(row["latitude"]) != 0 
		    and float(row["longitude"]) != 0 and float(row["radius"]) != 0 ):
			dist = int(gpsmixer.distance_in_meters(float(row["latitude"]), float(row["longitude"]), float(form["latitude"]),float(form["longitude"])))
			if(dist < float(row["radius"])):
				row['listenyn'] = 'N'
				returnCollection.append(row)
		else:
			returnCollection.append(row)
	return returnCollection


def get_projectid (dbh, projectname):
	if projectname:
		return sql_value(dbh, "select id from project where name = '" + projectname + "'")
	else:
		return None

def get_recording_filename (recordingid):
	dbh = get_connection()
	filename = sql_value(dbh, "select filename from recording where id = " + str(recordingid))
	dbh.close()
	return filename

def get_sharing_message_for_categoryid (categoryid):
	dbh = get_connection()
	sharing_message = sql_value(dbh, "SELECT p.sharing_message FROM project p, category c WHERE c.id = " 
	                            + str(categoryid) 
	                            + " AND c.projectid = p.id")
	dbh.close()
	return sharing_message
def get_out_of_range_message_for_categoryid (categoryid):
	dbh = get_connection()
	msg = sql_value(dbh, "SELECT p.out_of_range_message FROM project p, category c WHERE c.id = " 
	                            + str(categoryid) 
	                            + " AND c.projectid = p.id")
	dbh.close()
	return msg
def get_out_of_range_message_for_categoryid (categoryid):
	dbh = get_connection()
	msg = sql_value(dbh, "SELECT p.out_of_range_message FROM project p, category c WHERE c.id = " 
	                            + str(categoryid) 
	                            + " AND c.projectid = p.id")
	dbh.close()
	return msg

def get_out_of_range_url_for_categoryid (categoryid):
	dbh = get_connection()
	url = sql_value(dbh, "SELECT p.out_of_range_url FROM project p, category c WHERE c.id = " 
	                            + str(categoryid) 
	                            + " AND c.projectid = p.id")
	dbh.close()
	return url

def store_recording (user, request, filename):
	conn = get_connection()
	cursor = conn.cursor()
	columns = ["filename"]
	values = ["'"+filename+"'"]
	for key in user.keys():
		if key == 'demographicid':
			columns.append('ageid')
			values.append("(select ageid from demographic where id = " + str(user[key]) + ")")
			columns.append('genderid')
			values.append("(select genderid from demographic where id = " + str(user[key]) + ")")
		elif user[key]:
			columns.append(key)
			if type(user[key]) is str:
				values.append("'"+user[key]+"'")
			else:
				values.append(str(user[key]))
	for key in request.keys():
		if request[key]:
			columns.append(key)
			values.append(str(request[key]))
	cursor.execute ("insert into recording (" + ",".join(columns) + ") values (" + ",".join(values) + ")")
	id = cursor.lastrowid
	cursor.close ()
	conn.close ()
	return id

def update_recording (user, request, filename):
	conn = get_connection()
	cursor = conn.cursor()
	columns = ["filename"]
	values = ["'"+filename+"'"]
	for key in user.keys():
		if key == 'demographicid':
			columns.append('ageid')
			values.append("(select ageid from demographic where id = " + str(user[key]) + ")")
			columns.append('genderid')
			values.append("(select genderid from demographic where id = " + str(user[key]) + ")")
		elif user[key]:
			columns.append(key)
			if type(user[key]) is str:
				values.append("'"+user[key]+"'")
			else:
				values.append(str(user[key]))
	for key in request.keys():
		if request[key]:
			columns.append(key)
			values.append(str(request[key]))
#	cursor.execute ("insert into recording (" + ",".join(columns) + ") values (" + ",".join(values) + ")")
# add update call here
	id = cursor.lastrowid
	cursor.close ()
	conn.close ()
	return id

def update_audiolength (filename, audiolength):
	conn = get_connection()
	cursor = conn.cursor()
	cursor.execute("update recording set audiolength = " \
		+ str(audiolength) + " where filename = '" + filename + "'")
	cursor.close ()
	conn.close ()

def submit_recording(recordingid, submityn):
	conn = get_connection()
	cursor = conn.cursor()
	cursor.execute ("update recording set submittedyn = '" + submityn + "' where id = " + str(recordingid))
	cursor.close()
	conn.close()

def update_recording_filename(recordingid, filename):
	conn = get_connection()
	cursor = conn.cursor()
	cursor.execute ("update recording set filename = '" + filename + "' where id = " + str(recordingid))
	cursor.close()
	conn.close()
	
	
def get_recordings (request):
	dbh = get_connection()

	# the incoming question should always be a 'global' question recordings
	# query for incoming question, as well as ALL loc-based question recordings, sifting the results for ones in proximity of listener
	sql = "select * from recording where submittedyn = 'Y' and audiolength is not null"
	sql_locbased = "select * from recording r, question_v q where r.submittedyn = 'Y' and r.audiolength is not null"
	for p in ['categoryid', 'subcategoryid', 'usertypeid', 'genderid', 'ageid']:
		if len(request[p]) > 0:
			sql += " and " + p + " in (" + string_helper(request[p]) + ")"
			sql_locbased += " and r." + p + " in (" + string_helper(request[p]) + ")"
	if len(request['questionid']) > 0:
		sql += " and questionid in (" + string_helper(request['questionid']) + ")"
		
	sql_locbased += " and q.id = r.questionid and q.latitude != 0 and q.longitude != 0 and q.radius != 0"
		
	if len(request['demographicid']) > 0:
		sql += """ and exists (
			select 1
			from demographic
			where demographic.ageid = recording.ageid
			and demographic.genderid = recording.genderid
			and demographic.id in ("""+ string_helper(request['demographicid'])+"))"
		sql_locbased += """ and exists (
			select 1
			from demographic
			where demographic.ageid = r.ageid
			and demographic.genderid = r.genderid
			and demographic.id in ("""+ string_helper(request['demographicid'])+"))"
		
	logging.debug("and now request is...")
	logging.debug(request)
	logging.debug("query 1: "+ sql)
	logging.debug("query 2: " + sql_locbased)
	
	#now we have the full list of recordings for the supplied questions.  
	# We'll do a second query for all recordings with loc-based question ids, 
	# then check each recording to see if it's within range
	
	files = sql_table_dict(dbh, sql)
	files_locbased = sql_table_dict(dbh, sql_locbased)
	for row in files_locbased:
		if (request.has_key('latitude') and request.has_key('longitude') and row.has_key('latitude') and row.has_key('longitude') 
		    and row.has_key('radius') and float(row["latitude"]) != 0 
		    and float(row["longitude"]) != 0 and float(row["radius"]) != 0 ):
			dist = int(gpsmixer.distance_in_meters(float(row["latitude"]), float(row["longitude"]), float(request["latitude"]),float(request["longitude"])))
			if(dist < float(row["radius"])):
				files.append(row)
	dbh.close()
	return files

def number_of_recordings (request):
	return len(get_recordings(request))

def sql_list(strs):
	def stringify (str):
		return "\"" + str + "\""
	return "(" + string.join(map(stringify, strs),",") + ")"

def get_music_settings (categoryid):
	conn = get_connection()
	cursor = conn.cursor(MySQLdb.cursors.DictCursor)
	cursor.execute ("select * from category where id = " + str(categoryid))
	row = cursor.fetchone()
	cursor.close()
	conn.close()
	return row

def get_speakers (categoryids):
	conn = get_connection()
	cursor = conn.cursor (MySQLdb.cursors.DictCursor)
	sql = "select * from speaker where categoryid in (" \
		+ string_helper(categoryids) \
		+ ") and ifnull(activeyn, 'N') = 'Y'"
	logging.debug(sql)
	cursor.execute (sql)
	rows = cursor.fetchall()
	cursor.close()
	return rows

def get_composition_settings (categoryids):
	conn = get_connection()
	cursor = conn.cursor (MySQLdb.cursors.DictCursor)
	cursor.execute ("select * from composition where categoryid in ("
		+ string_helper(categoryids) + ")")
	rows = cursor.fetchall()
	cursor.close()
	return rows

def insert_event (form):
	def quotify (s):
		if s: return "'" + s + "'"
		else: return "null"
	def sqlify (v):
		if v: return v
		else: return "null"

	columns = [
		'operationid',
		'udid',
		'sessionid',
		'servertime',
		'clienttime',
		'latitude',
		'longitude',
		'demographicid',
		'questionid',
		'course',
		'haccuracy',
		'speed',
	]

	values = [
		sqlify(form.getvalue('operationid')),
		quotify(form.getvalue('udid')),
		quotify(form.getvalue('sessionid')),
		'now()',
		quotify(form.getvalue('clienttime')),
		quotify(form.getvalue('latitude')),
		quotify(form.getvalue('longitude')),
		quotify(form.getvalue('demographicid')),
		quotify(form.getvalue('questionid')),
		quotify(form.getvalue('course')),
		quotify(form.getvalue('haccuracy')),
		quotify(form.getvalue('speed')),
	]

	q = "insert into event (" + ",".join(columns) + ") values (" \
		+ ",".join(values) + ")"
	conn = get_connection()
	cursor = conn.cursor()
	cursor.execute(q)
	id = cursor.lastrowid
	cursor.close()
	conn.close()
	return id


def get_connection ():
	return MySQLdb.connect (
		host = "localhost",
		user = settings.config["dbuser"],
		passwd = settings.config["dbpasswd"],
		db = settings.config["dbname"])

#FIXME: Abstract with sql_dict
def sql_values (dbh, sql):
	cursor = dbh.cursor()
	cursor.execute(sql)
	row = cursor.fetchone()
	cursor.close()
	return row

def sql_value (dbh, sql):
	row = sql_values(dbh, sql)
	if row:
		return row[0]
	else:
		return None

#FIXME: Abstract with sql_table_dict
def sql_table_values (dbh, sql):
	cursor = dbh.cursor()
	cursor.execute(sql)
	rows = []
	while (True):
		row = cursor.fetchone()
		if row == None: break
		rows.append(row)
	cursor.close()
	return rows

def sql_column_value (dbh, sql):
	data = sql_table_values(dbh, sql)
	if data:
		return map(lambda row: row[0], data)
	else:
		return None

#FIXME: Abstract with sql_values
def sql_dict (dbh, sql):
	conn = get_connection()
	cursor = conn.cursor(MySQLdb.cursors.DictCursor)
	cursor.execute (sql)
	row = cursor.fetchone()
	cursor.close()
	conn.close()
	return row

#FIXME: Abstract with sql_table_values
def sql_table_dict (dbh, sql):
	cursor = dbh.cursor(MySQLdb.cursors.DictCursor)
	cursor.execute(sql)
	rows = []
	while (True):
		row = cursor.fetchone()
		if row == None: break
		rows.append(row)
	cursor.close()
	return rows

def string_helper(s):
	if(isinstance(s,basestring)):
		return str(s) 
	else:
		return ",".join(map(str,s))
