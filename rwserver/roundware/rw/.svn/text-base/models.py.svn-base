from django.db import models
from django.contrib import admin

import datetime

class BigIntegerField(models.IntegerField):
    empty_strings_allowed=False
    def get_internal_type(self):
        return "BigIntegerField"	
    def db_type(self):
        return 'bigint' # Note this won't work with Oracle.

class ProjectAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'latitude','longitude')
    ordering = ['id']

class Project(models.Model):
    name = models.CharField(max_length=50)
    latitude = models.FloatField()
    longitude = models.FloatField()
    pub_date = models.DateTimeField('date published')
    audio_format = models.CharField(max_length=50)
    auto_submit = models.BooleanField()
    max_recording_length = models.IntegerField()
    listen_questions_dynamic =  models.BooleanField()
    speak_questions_dynamic = models.BooleanField()
    sharing_message = models.TextField()
    out_of_range_message = models.TextField()
    out_of_range_url = models.CharField(max_length=512)
    recording_radius = models.IntegerField(null=True)
    def __unicode__(self):
            return self.name


class SessionAdmin(admin.ModelAdmin):
    list_display = ('id', 'device_id', 'starttime')
    ordering = ['id']
class Session(models.Model):
    device_id = models.CharField(max_length=36, null=True, blank=True)
    starttime = models.DateTimeField()
    stoptime = models.DateTimeField(null=True, blank=True)
    project = models.ForeignKey(Project)
    ordering = ['id']

    def __unicode__(self):
        return str(self.id)
    
class UIModeAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'data')
    ordering = ['id']
class UIMode(models.Model):
    name = models.CharField(max_length=50)
    data = models.TextField(null=True, blank=True)
    def __unicode__(self):
            return str(self.id) + ":" + self.name
    
class TagCategoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'data')
    ordering = ['id']
class TagCategory(models.Model):
    name = models.CharField(max_length=50)
    data = models.TextField(null=True, blank=True)
    def __unicode__(self):
            return str(self.id) + ":" + self.name
        
class SelectionMethodAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'data')
    ordering = ['id']
class SelectionMethod(models.Model):
    name = models.CharField(max_length=50)
    data = models.TextField(null=True, blank=True)
    def __unicode__(self):
            return str(self.id) + ":" + self.name

class TagAdmin(admin.ModelAdmin):
    list_display = ('id', 'tag_category', 'value')
    ordering = ['id']
class Tag(models.Model):
    tag_category = models.ForeignKey(TagCategory)
    value = models.TextField()
    data = models.TextField(null=True, blank=True)

    def __unicode__(self):
            return self.tag_category.name + " : " + self.value
        
        
    
#MasterUIs describe screens containing choices limited to one mode (Speak, Listen), 
#  and one tag category.
class MasterUIAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'ui_mode','tag_category','select','active','index','project')
    ordering = ['id']
class MasterUI(models.Model):
    name = models.CharField(max_length=50)
    ui_mode = models.ForeignKey(UIMode)
    tag_category = models.ForeignKey(TagCategory)
    select = models.ForeignKey(SelectionMethod)
    active = models.BooleanField(default=True)
    index = models.IntegerField()
    project = models.ForeignKey(Project)
    def toTagDictionary(self):
        return {'name':self.name,'code':self.tag_category.name,'select':self.select.name,'order':self.index}
    def __unicode__(self):
            return str(self.id) + ":" + self.ui_mode.name + ":" + self.name
#UI Mappings describe the ordering and selectability of tags for a given MasterUI.  

class UIMappingAdmin(admin.ModelAdmin):
    list_display = ('id', 'master_ui','index','tag','default','active')
    ordering = ['id']
class UIMapping(models.Model):
    #type = models.CharField(max_length=50)
    #code = models.CharField(max_length=50)
    master_ui = models.ForeignKey(MasterUI)
    index = models.IntegerField()
    tag = models.ForeignKey(Tag)
    default = models.BooleanField(default=False)
    active = models.BooleanField(default=False)
    def toTagDictionary(self):
        return {'tag_id':self.tag.id,'order':self.index,'value':self.tag.value}
    def __unicode__(self):
            return str(self.id) + ":" + self.master_ui.name + ":" + self.tag.tag_category.name


class AudiotrackAdmin(admin.ModelAdmin):
    list_display = ('id', 'project')
    ordering = ['id']
class Audiotrack(models.Model):
    project = models.ForeignKey(Project)
    minvolume = models.FloatField()
    maxvolume = models.FloatField()
    minduration = models.FloatField()
    maxduration = models.FloatField()
    mindeadair = models.FloatField()
    maxdeadair = models.FloatField()
    minfadeintime = models.FloatField()
    maxfadeintime = models.FloatField()
    minfadeouttime = models.FloatField()
    maxfadeouttime = models.FloatField()
    minpanpos = models.FloatField()
    maxpanpos = models.FloatField()
    minpanduration = models.FloatField()
    maxpanduration = models.FloatField()
    repeatrecordings = models.BooleanField()
    def __unicode__(self):
            return "Track " + str(self.id)

class EventType(models.Model):
    name = models.CharField(max_length=50)
    ordering = ['id']

class EventAdmin(admin.ModelAdmin):
    list_display = ('id','session','event_type','data','server_time','client_time')
    ordering = ['id']
    
class Event(models.Model):
    server_time = models.DateTimeField()
    client_time = models.CharField(max_length=50,null=True, blank=True)
    session = models.ForeignKey(Session)

    event_type = models.CharField(max_length=50)
    data = models.TextField(null=True, blank=True)
    latitude = models.CharField(max_length=50,null=True, blank=True)
    longitude = models.CharField(max_length=50,null=True, blank=True)
    tags = models.TextField(null=True, blank=True)
    
    operationid = models.IntegerField(null=True, blank=True)
    udid = models.CharField(max_length=50,null=True, blank=True)
    


class AssetAdmin(admin.ModelAdmin):
    list_display = ('id','session','created','audiolength')
    ordering = ['id']
    
class Asset(models.Model):
    session = models.ForeignKey(Session,null=True, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    filename = models.CharField(max_length=256,null=True, blank=True)
    volume = models.FloatField(null=True, blank=True)
    
    submitted = models.BooleanField(default=True)
    project = models.ForeignKey(Project, null=True, blank=True)
    
    created = models.DateTimeField(default=datetime.datetime.now)
    audiolength = models.BigIntegerField(null=True, blank=True)
    tags = models.ManyToManyField(Tag, null=True, blank=True)
   
    def __unicode__(self):
            return str(self.id) + ": " + str(self.latitude) + "/" + str(self.longitude)

class EnvelopeAdmin(admin.ModelAdmin):
    list_display = ('id','session')
    ordering = ['id']
    
class Envelope(models.Model):
    session = models.ForeignKey(Session)
    assets = models.ManyToManyField(Asset)
    def __unicode__(self):
            return str(self.id) + ": Session id: " + str(self.session.id)
    
class SpeakerAdmin(admin.ModelAdmin):
    list_display = ('id','code','project','latitude', 'longitude','uri')
    ordering = ['id']
class Speaker(models.Model):
    project = models.ForeignKey(Project)
    activeyn = models.BooleanField()
    code = models.CharField(max_length=10)
    latitude = models.FloatField()
    longitude = models.FloatField()
    maxdistance = models.IntegerField()
    mindistance = models.IntegerField()
    maxvolume = models.FloatField()
    minvolume = models.FloatField()
    uri = models.URLField()
    backupuri = models.URLField()
    def __unicode__(self):
            return str(self.id) + ": " + str(self.latitude) + "/" + str(self.longitude) + " : " + self.uri
    
