import string
import logging
import datetime
import time
from roundwared import settings
from roundwared import gpsmixer
from roundwared import roundexception
from django.db.models import Q
from roundware.rw.models import Session
from roundware.rw.models import Event
from roundware.rw.models import Project
from roundware.rw.models import Asset
from roundware.rw.models import Tag
from roundware.rw.models import TagCategory
from roundware.rw.models import MasterUI
from roundware.rw.models import UIMapping
import operator

def get_config_tag_json_for_project (project_id):
	p = Project.objects.get(id=project_id)
	m = MasterUI.objects.filter(project=p)
	response=[]
	modes = {}
	for masterui in m:
		if masterui.active:
			mappings = UIMapping.objects.filter(master_ui=masterui, active=True)
			masterD = masterui.toTagDictionary()
			masterOptionsList = []
			
			default = []
			for mapping in mappings:
				if mapping.default:
					default.append(mapping.tag.id)
				masterOptionsList.append(mapping.toTagDictionary())
			
			masterD["options"] = masterOptionsList
			masterD["defaults"] = default
			if not modes.has_key(masterui.ui_mode.name):
				modes[masterui.ui_mode.name] = [masterD,]
			else:
				modes[masterui.ui_mode.name].append(masterD)
	
	return modes

def get_recordings (request):

	logging.debug("get_recordings: got request: " + str(request))
	recs = []
	if request.has_key("project_id") and hasattr(request["project_id"],"__iter__") and len(request["project_id"]) > 0:		
		logging.debug("get_recordings: got project_id: " + str(request["project_id"][0]))
		p = Project.objects.get(id=request["project_id"][0])
	elif request.has_key("project_id") and not hasattr(request["project_id"],"__iter__"):		
		logging.debug("get_recordings: got project_id: " + str(request["project_id"]))
		p = Project.objects.get(id=request["project_id"])

	if request.has_key("session_id") and hasattr(request["session_id"],"__iter__") and len(request["session_id"]) > 0:		
		logging.debug("get_recordings: got session_id: " + str(request["session_id"][0]))
		s = Session.objects.get(id=request["session_id"][0])
		p = s.project
	elif request.has_key("session_id") and not hasattr(request["session_id"],"__iter__") :		
		logging.debug("get_recordings: got session_id: " + str(request["session_id"]))
		s = Session.objects.get(id=request["session_id"])
		p = s.project
	   
	#this first check checks whether tags is a list of numbers.  
	if request.has_key("tags") and hasattr(request["tags"],"__iter__") and len(request["tags"]) > 0:		
		logging.debug("get_recordings: got " + str(len(request["tags"]))  + "tags." )
		#recs = Asset.objects.filter(project=p, submitted=True, tags__in=request["tags"])
		recs = filter_recs_for_tags(p,request["tags"])
	#this second check checks whether tags is a string representation of a list of numbers.  
	elif request.has_key("tags") and not hasattr(request["tags"],"__iter__") :		
		logging.debug("get_recordings: tags supplied: " + request["tags"])
		#recs = Asset.objects.filter(project=p,submitted=True, tags__in=request["tags"].split(","))
		recs = filter_recs_for_tags(p,request["tags"].split(","))
	else:
		logging.debug("get_recordings: no tags supplied")
		recs = Asset.objects.filter(project=p,submitted=True)
		
	logging.debug("db: get_recordings: got " + str(len(recs)) + " recordings from db for project " + str(p.id))
	return recs
#import operator

#search_fields = ('title', 'body', 'summary')
#q_objects = [Q(**{field + '__icontains':q}) for field in search_fields]
#queryset = BlogPost.objects.filter(reduce(operator.or_, q_objects))
	
def filter_recs_for_tags (p,tagids_from_request):
	logging.debug("filter_recs_for_tags enter")
	recs = []
	tags_from_request = Tag.objects.filter(id__in=tagids_from_request)
	
	tags_per_cat_dict = {}
	cats = TagCategory.objects.all()
	for cat in cats:
		tags_per_cat_dict[cat] = Tag.objects.filter(tag_category=cat)
	
	project_recs = Asset.objects.filter(project=p, submitted=True).distinct()
	for rec in project_recs:
		remove = False
		for cat in cats:
			if remove:
				break
			#tags_per_category = Tag.objects.filter(tag_category=cat)
			tags_per_category = tags_per_cat_dict[cat]
			tags_for_this_cat_from_request = filter(lambda x: x in tags_per_category, tags_from_request)			
			tags_for_this_cat_from_rec = filter(lambda x: x in tags_per_category, rec.tags.all())
			# if the asset has any tags from this category, make sure at least one match with exists, else remove
			if len(tags_for_this_cat_from_request) > 0:
				found = False
				if len(tags_for_this_cat_from_rec) > 0 and len(tags_for_this_cat_from_request) > 0:
					for t in tags_for_this_cat_from_request:
						if t in tags_for_this_cat_from_rec:
							found = True
							break
				if not found:
					remove = True
		if not remove:
			recs.append(rec)
			
	
	return recs
def create_session (device_id, proj):
	ret = ""
	s = Session(device_id = device_id, starttime=datetime.datetime.now(), project = proj)
	if(s == None):
		raise roundexception.RoundException("failed to create session for device_id:" + str(device_id));
	else:
		s.save()
	ret = s.id
	return ret
# form args:
#event_type <string>
#session_id <integer>
#[client_time] <string using RFC822 format>
#[latitude] <float?>
#[longitude] <float?>
#[tags] (could possibly be incorporated into the 'data' field?)
#[data]
def log_event (event_type, session_id,form):
	s = Session.objects.get(id=session_id)
	if(s == None):
		raise roundexception.RoundException("failed to access session " + str(session_id));
	client_time = None
	latitude = None
	longitude = None
	tags = None
	data = None
	if form != None:
		if form.has_key("client_time"):
			client_time = form["client_time"]
		if form.has_key("latitude"):
			latitude = form["latitude"]
		if form.has_key("longitude"):
			longitude = form["longitude"]
		if form.has_key("tags"):
			tags = form["tags"]
		if form.has_key("data"):
			data = form["data"]

	e = Event(session = s,
	          event_type = event_type,
	          server_time = datetime.datetime.now(),
	          client_time = client_time, 
	          latitude = latitude, 
	          longitude=longitude, 
	          tags = tags, 
	          data = data)
	e.save()
	          
	return True

