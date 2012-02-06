//
//  ScapesAppDelegate.m
//  Scapes
//
//  Created by Joe Zobkiw on 12/3/09.
//  Copyright Earsmack Music 2009. All rights reserved.
//

#import "ScapesAppDelegate.h"
#import "RootViewController.h"
#import "AudioStreamer.h"
#import "SoundEffect.h"
#import "ASIFormDataRequest.h"
#import "JSON.h"

@implementation ScapesAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize sessionID;
@synthesize streamer;
@synthesize streamURL;
@synthesize audioStreamerIsSupposedToBePlaying;
@synthesize requestedStreamURL;
@synthesize networkAvailable;
@synthesize networkTryAgainCount;
@synthesize agreed;
@synthesize audioFormat;
@synthesize maxRecordingTimeSeconds;
@synthesize listenQuestions;
@synthesize speakQuestions;
@synthesize jsonDict;
@synthesize demographicChoices;
@synthesize locationManager;
@synthesize recordedCoordinate;
@synthesize gpsIdleTimer;
@synthesize gpsPingSoundEffect;
@synthesize lastGPSResult;

#pragma mark -
#pragma mark Overridden Getters

//usedEncoding:(NSStringEncoding *)enc error:(NSError **)error
- (UInt32)audioFormat {
	if (audioFormat == 0) {
		NSError* error;
		NSURL* url = [NSURL URLWithString:kAudioFormatURL];
		NSString* s = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error];
		if ([s length] != 0)
			audioFormat = [s intValue];
		else audioFormat = kAudioFormatLinearPCM;
	}
	return audioFormat;
}

- (int)maxRecordingTimeSeconds {
	if (maxRecordingTimeSeconds == 0) {
		NSError* error;
		NSURL* url = [NSURL URLWithString:kMaxRecordingTimeSecondsURL];
		NSString* s = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error];
		if ([s length] != 0)
			maxRecordingTimeSeconds = [s intValue];
		else maxRecordingTimeSeconds = kMaxRecordingTimeSeconds;
	}
	return maxRecordingTimeSeconds;
}

- (NSDictionary*)listenQuestions { // TOFIX
	if (listenQuestions == nil) {
		//	listenQuestions = [[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:kListenQuestionsURL]] retain];
		
		if (jsonDict == nil) {
            NSError* error;
            NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", kEventURL_, kScapesBaseParams, kGetQuestionsOperation]];
            NSString* s = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error];
            jsonDict = [[s JSONValue] retain];
		}
        NSMutableDictionary *md = [[NSMutableDictionary dictionary] retain]; // create an empty dictionary
		NSDictionary *d;
		for (d in jsonDict) {
			if ([[d objectForKey:@"listenyn"] isEqualToString: @"Y"]) {
				[md setObject:[NSString stringWithFormat:@"%@ %@", [d objectForKey:@"ordering"], [d objectForKey:@"text"]]
					   forKey:[d objectForKey:@"id"]];
                /*
                [md setObject:[NSString stringWithFormat:@"%@", [d objectForKey:@"text"]]
					   forKey:[d objectForKey:@"id"]];
                */
			}
		}
		listenQuestions = [[NSDictionary dictionaryWithDictionary:md] retain]; // copy to listen questions
		[md release];
	}
	return listenQuestions;
}

- (void)freeSpeakQuestions {
    if (speakQuestions != nil) {
        [jsonDict release];
        jsonDict = nil;
        [speakQuestions release];
        speakQuestions = nil;
    }
}

- (NSDictionary*)speakQuestions {
	if (speakQuestions == nil) {
		//	speakQuestions = [[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:kSpeakQuestionsURL]] retain];
		
		if (jsonDict == nil) {
            NSError* error;
            NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@&latitude=%@&longitude=%@", kEventURL_, kScapesBaseParams, kGetQuestionsOperation, [NSString stringWithFormat:@"%f", locationManager.location.coordinate.latitude], [NSString stringWithFormat:@"%f",locationManager.location.coordinate.longitude]]];
            NSString* s = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error];
            jsonDict = [[s JSONValue] retain];
        }
		NSMutableDictionary *md = [[NSMutableDictionary dictionary] retain];
        // create an empty dictionary
		NSDictionary *d;
		for (d in jsonDict) {
			if ([[d objectForKey:@"speakyn"] isEqualToString: @"Y"]) {
				[md setObject:[NSString stringWithFormat:@"%@ %@", [d objectForKey:@"ordering"], [d objectForKey:@"text"]]
					   forKey:[d objectForKey:@"id"]];
				/*
                 [md setObject:[NSString stringWithFormat:@"%@", [d objectForKey:@"text"]]
                 forKey:[d objectForKey:@"id"]];
                 */
			}
		}
		speakQuestions = [[NSDictionary dictionaryWithDictionary:md] retain]; // copy to speak questions
		[md release];
	}
	return speakQuestions;
}


- (NSDictionary*)demographicChoices {
	if (demographicChoices == nil) {
		demographicChoices = [NSDictionary dictionaryWithObjectsAndKeys:
							  @"Woman", kWomanTag,
							  @"Man", kManTag,
							  @"Girl", kGirlTag,
							  @"Boy", kBoyTag,
							  nil];
		[demographicChoices retain];
	}
	return demographicChoices;
}

- (SoundEffect*)gpsPingSoundEffect {
	if (gpsPingSoundEffect == nil) {
		NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"reset.caf"];
		gpsPingSoundEffect = [[SoundEffect alloc] initWithContentsOfFile:path];
	}
	return gpsPingSoundEffect;
}

#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
	// Assume no network until we verify it
	self.networkAvailable = NO;
    self.networkTryAgainCount = 0;
	self.agreed = NO;
	self.audioFormat = 0;
	self.maxRecordingTimeSeconds = 0;
    self.audioStreamerIsSupposedToBePlaying = NO;
	self.requestedStreamURL = NO;
	self.lastGPSResult = YES;
	
	// Session
	// sessionID = [[NSString alloc] initWithFormat:@""]; // Now starts as empty string, filled in by request_stream
	self.sessionID = nil;
	self.streamURL = nil;
	
	// Default preferences
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSDictionary *appPrefs = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSArray arrayWithObjects: nil], kSpeakGenderAgePref,
							  [NSArray arrayWithObjects: nil], kSpeakQuestionPref,
							  [NSArray arrayWithArray: [self.demographicChoices allKeys]], kListenGenderAgePref,
							  [NSArray arrayWithArray: [self.listenQuestions allKeys]], kListenQuestionPref,
							  [NSNumber numberWithBool: NO], kHalseyModeGPSPingPref,
							  nil];
	[prefs registerDefaults:appPrefs];
	[prefs setObject:[NSArray arrayWithArray: [self.demographicChoices allKeys]] forKey:kListenGenderAgePref]; // reset to all on
	[prefs setObject:[NSArray arrayWithArray: [self.listenQuestions allKeys]] forKey:kListenQuestionPref]; // reset to all on
	[prefs synchronize];
	
	// Setup GPS
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self; // send loc updates to myself
	locationManager.distanceFilter = 100; //change from 1 for location-based listening to higher value to reduce gps usage
    [locationManager startUpdatingLocation];
	gpsIdleTimer = [NSTimer scheduledTimerWithTimeInterval:kGPSIdleTimerInterval 
							target:self 
							selector:@selector(gpsIdleTimerFireMethod:) 
							userInfo:nil 
							repeats:YES];

	// MOVED TO AFTER FIRST GPS_FIX
	// Our first event
	// [self submitEvent:kEVENT_START_SESSION];

	// Setup Audio Session
	AVAudioSession *session = [AVAudioSession sharedInstance];
	session.delegate = self;
	NSError *setCategoryError = nil;
	[session setCategory:AVAudioSessionCategoryPlayAndRecord error:&setCategoryError];
	UInt32 doChangeDefaultRoute = 1;
	AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);
	NSError *activationError = nil;
	[session setActive:YES error:&activationError];

	// Setup Window
	[window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	[self submitEvent:kEVENT_STOP_SESSION];
	// Save data if appropriate
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[sessionID release]; sessionID = nil;
	[streamer stop]; [streamer release]; streamer = nil;
	[streamURL release]; streamURL = nil;
	[listenQuestions release]; listenQuestions = nil;
	[speakQuestions release]; speakQuestions = nil;
    [jsonDict release]; jsonDict = nil;
	[demographicChoices release]; demographicChoices = nil;
	[locationManager release]; locationManager = nil;
	[gpsIdleTimer release]; gpsIdleTimer = nil;
	[gpsPingSoundEffect release]; gpsPingSoundEffect = nil;
	[navigationController release];
	[window release];
	[super dealloc];
}

#pragma mark -
#pragma mark GPS delegate methods

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
//	NSLog(@"%f", self.locationManager.location.coordinate.latitude);
	
	#if TARGET_IPHONE_SIMULATOR
		if (self.requestedStreamURL == NO) {
			self.requestedStreamURL = YES;
			[self submitEvent:kEVENT_START_SESSION]; // Send this here so we know we have a GPS coordinate
		}
		// Send updated locations to server
		//[self submitEvent:kEVENT_GPS_FIX]; //comment out for non-location-based listening like OV or SFMS
	#else
		if ((float)self.locationManager.location.coordinate.latitude != (float)-0.000000) {
			// Our first event
			if (self.requestedStreamURL == NO) {
				self.requestedStreamURL = YES;
				[self submitEvent:kEVENT_START_SESSION]; // Send this here so we know we have a GPS coordinate
			}
			
			// Send updated locations to server
			//[self submitEvent:kEVENT_GPS_FIX]; //comment out for non-location-based listening like OV or SFMS
		}
	#endif
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	BOOL value = [prefs boolForKey:kHalseyModeGPSPingPref];
	if (value == YES) [self playGPSPingSoundEffect];
	
	//NSLog(@"Location: %@", [newLocation description]);
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	// Immediately stop updating location, user has a chance to re-enable via alert
	[locationManager stopUpdatingLocation];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Error" message:@"An error occurred trying to obtain your location. This could be due to low GPS signal strength. Stories from Main Street requires location information to function properly. Please restart Stories from Main Street and allow location." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try Again", @"Cancel", nil];
	[alert show];
	[alert release];

	//NSLog(@"Error: %@", [error description]);
}

#pragma mark -
#pragma mark GPS_IDLE Timer methods

- (void)gpsIdleTimerFireMethod:(NSTimer*)theTimer {
	
	if (self.requestedStreamURL == NO) {
		self.requestedStreamURL = YES;
		[self submitEvent:kEVENT_START_SESSION]; // Eventually we have to send this
	}
	
	NSTimeInterval diff = [locationManager.location.timestamp timeIntervalSinceNow];
	if (diff < -kGPSIdleTimerInterval)
		[self submitEvent:kEVENT_GPS_IDLE];
}

/*
NSTimer
locationManager.location.timestamp timeIntervalSinceNow
*/

#pragma mark -
#pragma mark Alert methods

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (([alertView title] == @"Location Error") && (buttonIndex == 0)) // Try Again
		[locationManager startUpdatingLocation];
	if (([alertView title] == @"Network Error") && (buttonIndex == 0)) // Try Again
		[self submitEvent:kEVENT_START_SESSION];
}

#pragma mark -
#pragma mark AVAudioSession delegate methods

- (void) beginInterruption {
	if ([[navigationController topViewController] respondsToSelector:@selector(updateUserInterface:)]) {
		[[navigationController topViewController] performSelector:@selector(updateUserInterface:) withObject:[NSNumber numberWithBool:YES]];
	}
}

NSError *activationError = nil;
- (void) endInterruption {
	[[AVAudioSession sharedInstance] setActive:YES error:&activationError];
	if ([[navigationController topViewController] respondsToSelector:@selector(updateUserInterface:)]) {
		[[navigationController topViewController] performSelector:@selector(updateUserInterface:) withObject:[NSNumber numberWithBool:NO]];
	}
}


#pragma mark -
#pragma mark Audio streamer

- (void)startAudioStreamer {
	if (streamer == nil) {
		// Setup Streamer
		NSString *escapedValue = [(NSString *)CFURLCreateStringByAddingPercentEscapes(nil, (CFStringRef)streamURL, NULL, NULL, kCFStringEncodingUTF8) autorelease];
		NSURL *url = [NSURL URLWithString: escapedValue];
		streamer = [[AudioStreamer alloc] initWithURL:url];
		//[streamer setDelegate:self];
		//[streamer setDidErrorSelector:@selector(streamerError)];
	}
	if ([self isAudioStreamerPlaying] == NO) {
		[streamer start];
		self.audioStreamerIsSupposedToBePlaying = YES;
		[self submitEvent:kEVENT_START_STREAM];
	}
}

- (void)stopAudioStreamer {
	if ([self isAudioStreamerPlaying] == YES) {
		[streamer stop];
		[streamer release];
		streamer = nil;
		self.audioStreamerIsSupposedToBePlaying = NO;
		[self submitEvent:kEVENT_STOP_STREAM];
	}
}

- (void)toggleAudioStreamer {
	if ([self isAudioStreamerPlaying])
		[self stopAudioStreamer];
	else
		[self startAudioStreamer];
}

- (BOOL)isAudioStreamerPlaying {
	return [streamer isPlaying] || [streamer isWaiting] || self.audioStreamerIsSupposedToBePlaying;
}

- (void)streamerError {
	[self stopAudioStreamer];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Stream Error" message:@"An error occurred trying to play the audio stream. If this error persists, please try quitting the app and launching it again." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try Again", @"Cancel", nil];
	[alert show];
	[alert release];
}

#pragma mark -
#pragma mark Callback methods

- (void)rememberRecordedCoordinate {
	recordedCoordinate = locationManager.location.coordinate;
}

#pragma mark -
#pragma mark Event methods

- (NSString*)convertEventTypeToString:(NSInteger)eventID {
	NSString *s = nil;
	switch (eventID) {
        case kEVENT_MODIFY_STREAM:
			s = [NSString stringWithFormat:@"modify_stream"];
            break;
		case kEVENT_START_SESSION:
			s = [NSString stringWithFormat:@"request_stream"];
			break;
		case kEVENT_GPS_FIX:
			s = [NSString stringWithFormat:@"move_listener"];
			break;
		case kEVENT_GPS_IDLE:
			s = [NSString stringWithFormat:@"heartbeat"];
			break;
		case kEVENT_START_STREAM:
		case kEVENT_STOP_STREAM:
		case kEVENT_START_RECORD:
		case kEVENT_STOP_RECORD:
		case kEVENT_START_UPLOAD:
		case kEVENT_STOP_SESSION:
		case kEVENT_STOP_UPLOAD_SUCCESS:
		case kEVENT_STOP_UPLOAD_FAIL:
			s = [NSString stringWithFormat:@"log_event"];
			break;
		default:
			break;
	}
	return s;
}

- (void)submitEvent:(NSInteger)eventID {
	// id, operationid, udid, sessionid, servertime, clienttime, latitude, longitude, course, haccuracy, speed
	
	//NSLog(@"%f,%f", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude);
	
	// Convert number event types to text event types - THANKS ALOT!
	NSString *sNewEventID = [self convertEventTypeToString:eventID];
	if (sNewEventID == nil) {
		NSLog(@"skipped event: old_event_id:%d", eventID);
		return;
	} else NSLog(@"sent event: new_event_id:%@ old_event_id:%d", sNewEventID, eventID);
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kEventURL__]];
	
	[request setPostValue:kConfig forKey:@"config"];
	[request setPostValue:kCategoryID forKey:@"categoryid"];
	[request setPostValue:kSubcategoryID forKey:@"subcategoryid"];
	[request setPostValue:[NSString stringWithFormat:@"%@", kScapesMuseumVisitor] forKey:@"usertypeid"];

	[request setPostValue:[NSString stringWithFormat:@"%@", sNewEventID] forKey:@"operation"]; // changed from operationid
	[request setPostValue:[NSString stringWithFormat:@"%@", [UIDevice currentDevice].uniqueIdentifier] forKey:@"udid"];
	if ([self sessionID] != nil)
		[request setPostValue:[NSString stringWithFormat:@"%@", [self sessionID]] forKey:@"sessionid"];
	//[request setPostValue:[NSString stringWithFormat:@"12345", [self sessionID]] forKey:@"sessionid"];
	
    if ([sNewEventID isEqualToString:@"log_event"]) {
		if ((eventID == kEVENT_STOP_UPLOAD_SUCCESS) || (eventID == kEVENT_STOP_UPLOAD_FAIL)) {
			[request setPostValue:[NSString stringWithFormat:@"%d", 14] forKey:@"eventtypeid"];
			if (eventID == kEVENT_STOP_UPLOAD_FAIL) {
				[request setPostValue:[NSString stringWithFormat:@"ERROR: File Upload Failed"] forKey:@"message"];
			}
		} else {
			[request setPostValue:[NSString stringWithFormat:@"%d", eventID] forKey:@"eventtypeid"];
		}
	}
	
	[request setPostValue:[NSString stringWithFormat:@"%d", time(NULL)] forKey:@"clienttime"]; // 2009-10-19 08:36:07
//	[request setPostValue:[NSString stringWithFormat:@"%d", locationManager.locationServicesEnabled] forKey:@"locationServicesEnabled"];
//	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.coordinate.latitude] forKey:@"latitude"]; // remove for global listening, not location-based listening
//	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.coordinate.longitude] forKey:@"longitude"]; // remove for global listening, not location-based listening
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.course] forKey:@"course"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.horizontalAccuracy] forKey:@"haccuracy"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.speed] forKey:@"speed"];
//	[request setPostValue:[NSString stringWithFormat:@"%@", streamURL] forKey:@"stream_url"];
	
	/* 
	 ageid, genderid
	 - also, ageid and genderid will need to be determined from demographicid; in other words,
	 if 'Man' is selected as the speaker, ageid will be 17 (adult) and genderid will be 2 (male)
	 - adult=17, child=16, man=2, woman=1
	 
	*/
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
//  NSLog(@"userDefaults dump: %@", [prefs dictionaryRepresentation]);
    
    NSMutableString *result = [[NSMutableString alloc] init];
//	for (NSObject * obj in [prefs stringArrayForKey:kListenGenderAgePref]) {	// , delimit array properly
    for (NSObject * obj in [[prefs dictionaryRepresentation] objectForKey:kListenGenderAgePref]) {	// , delimit array properly
		if ([result length])
			[result appendString:@"\t"];
		[result appendString:[obj description]];
	}
	//[request setPostValue:result forKey:kListenGenderAgePref];
	[request setPostValue:result forKey:@"demographicid"];
	//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://scapesaudio.dyndns.org/test.php?%@=%@", kListenGenderAgePref, result]]];
	[result release];
    
	NSMutableString *result2 = [[NSMutableString alloc] init];
//	for (NSObject * obj2 in [prefs2 stringArrayForKey:kListenQuestionPref]) {		// , delimit array properly kListenQuestionPref
    for (NSObject * obj in [[prefs dictionaryRepresentation] objectForKey:kListenQuestionPref]) {		// , delimit array properly kListenQuestionPref
		if ([result2 length])
			[result2 appendString:@"\t"];
		[result2 appendString:[obj description]];
	}
//	[request setPostValue:result2 forKey:kListenQuestionPref];
	[request setPostValue:result2 forKey:@"questionid"]; // TOFIX
	[result2 release];
    
	[request setDelegate:self];
	if (eventID == kEVENT_START_SESSION) {
		[request setDidFinishSelector:@selector(requestFinished_startsession:)];
		[request setDidFailSelector:@selector(requestFailed_startsession:)];
	} else if ((eventID == kEVENT_GPS_FIX) || (eventID == kEVENT_GPS_IDLE)) {
		[request setDidFinishSelector:@selector(requestFinished_gps:)];
	}

	[request startAsynchronous];
}

- (void)requestFinished_gps:(ASIHTTPRequest *)request
{
	NSDictionary *jsonDictionary = [[request responseString] JSONValue];
//	NSLog(@"%@", jsonDictionary);
/*
    lastGPSResult = [[jsonDictionary objectForKey:@"RESULT"] boolValue];
    if (lastGPSResult == NO) {
		[locationManager stopUpdatingLocation];
		[gpsIdleTimer invalidate];
	}
*/
    
	NSString *errorMessage = [[jsonDictionary objectForKey:@"USER_ERROR_MESSAGE"] retain];
	if ([errorMessage length]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Stories from Main Street Message" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
	[errorMessage release];
}

- (void)requestFinished_startsession:(ASIHTTPRequest *)request
{
	// TODO: Fill in sessionID here as well
	// SESSIONID, STREAM_URL
	if (streamURL != nil) {
		[streamURL release];
		streamURL = nil;
	}
	if (sessionID != nil) {
		[sessionID release];
		sessionID = nil;
	}
	NSDictionary *jsonDictionary = [[request responseString] JSONValue];
//	NSLog(@"%@", jsonDictionary);
	[self setStreamURL: [NSString stringWithFormat:@"%@", [jsonDictionary objectForKey:@"STREAM_URL"]]];
	NSLog(@"Stream URL: %@", streamURL);
	// [[jsonDictionary objectForKey:@"STREAM_URL"] retain];
	[self setSessionID: [NSString stringWithFormat:@"%@", [jsonDictionary objectForKey:@"SESSIONID"]]]; 
	NSLog(@"Session ID: %@", sessionID);
	// [[jsonDictionary objectForKey:@"SESSIONID"] retain]];
	if ([streamURL hasPrefix:@"http://"]) {
		self.networkAvailable = YES;
		[self requestFinished:request];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"networkAvailable" object:nil];
	} else {
		[self requestFailed_startsession: request];
	}
}

- (void)requestFailed_startsession:(ASIHTTPRequest *)request
{
	if (self.networkTryAgainCount == 0) {   // Since trying again usually solves the problem here we do just that.
        NSLog(@"Trying again after network error %d", self.networkTryAgainCount);
        self.networkTryAgainCount++;
        [self submitEvent:kEVENT_START_SESSION];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Oops! A network error has occurred. If a network connection can not be established Stories from Main Street will not be able to function properly." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try Again", @"Cancel", nil];
        [alert show];
        [alert release];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	NSDictionary *jsonDictionary = [[request responseString] JSONValue];
	NSString *errorMessage = [[jsonDictionary objectForKey:@"USER_ERROR_MESSAGE"] retain];
	if ([errorMessage length]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Stories from Main Street Message" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
	[errorMessage release];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	// Display error
	// PUNT on errors of this type? The user can do nothing about them anyway
	/*
	NSError *error = [request error];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Event Message Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	[alert release];
	*/
}

#pragma mark -
#pragma mark Misc

- (void)playGPSPingSoundEffect
{
	[self.gpsPingSoundEffect play];
}

@end

