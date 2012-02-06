//
//  OceanVoicesAppDelegate.m
//  Ocean Voices
//
//  Created by Joe Zobkiw on 12/3/09.
//  Copyright Earsmack Music 2009. All rights reserved.
//

#import "OceanVoicesAppDelegate.h"
#import "RootViewController.h"
#import "AudioStreamer.h"
#import "SoundEffect.h"
#import "ASIFormDataRequest.h"
#import "JSON.h"

@implementation OceanVoicesAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize sessionID;
@synthesize streamer;
@synthesize streamURL;
@synthesize audioStreamerIsSupposedToBePlaying;
@synthesize requestedStreamURL;
@synthesize networkAvailable;
@synthesize listenQuestions;
@synthesize speakQuestions;
@synthesize demographicChoices;
@synthesize usertypeChoices;
@synthesize locationManager;
@synthesize recordedCoordinate;
@synthesize gpsIdleTimer;
@synthesize gpsPingSoundEffect;
@synthesize lastGPSResult;

#pragma mark -
#pragma mark Overridden Getters

- (NSDictionary*)listenQuestions {
	if (listenQuestions == nil)
		listenQuestions = [[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:kListenQuestionsURL]] retain];
	return listenQuestions;
}

- (NSDictionary*)speakQuestions {
	if (speakQuestions == nil)
		speakQuestions = [[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:kSpeakQuestionsURL]] retain];
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

- (NSDictionary*)usertypeChoices {
	if (usertypeChoices == nil)
		usertypeChoices = [[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:kUserTypesURL]] retain];
	return usertypeChoices;
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
    self.audioStreamerIsSupposedToBePlaying = NO;
	self.requestedStreamURL = NO;
	self.lastGPSResult = YES;
	
	// Session
	sessionID = [[NSString alloc] initWithFormat:@"%d", time(NULL)];

	// Default preferences
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSDictionary *appPrefs = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSArray arrayWithObjects: nil], kSpeakUserTypePref,
							  [NSArray arrayWithObjects: nil], kSpeakGenderAgePref,
							  [NSArray arrayWithObjects: nil], kSpeakQuestionPref,
							  [NSArray arrayWithArray: [self.demographicChoices allKeys]], kListenGenderAgePref,
							  [NSArray arrayWithArray: [self.usertypeChoices allKeys]], kListenUserTypePref,
							  [NSArray arrayWithArray: [self.listenQuestions allKeys]], kListenQuestionPref,
							  [NSNumber numberWithBool: NO], kHalseyModeGPSPingPref,
							  nil];
	[prefs registerDefaults:appPrefs];
	[prefs setObject:[NSArray arrayWithArray: [self.demographicChoices allKeys]] forKey:kListenGenderAgePref]; // reset to all on
	[prefs setObject:[NSArray arrayWithArray: [self.usertypeChoices allKeys]] forKey:kListenUserTypePref]; // reset to all on
	[prefs setObject:[NSArray arrayWithArray: [self.listenQuestions allKeys]] forKey:kListenQuestionPref]; // reset to all on
	[prefs synchronize];
	
	// Setup GPS
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self; // send loc updates to myself
	locationManager.distanceFilter = 1;
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
	[demographicChoices release]; demographicChoices = nil;
	[usertypeChoices release]; usertypeChoices = nil;
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
		[self submitEvent:kEVENT_GPS_FIX];
	#else
		if ((float)self.locationManager.location.coordinate.latitude != (float)-0.000000) {
			// Our first event
			if (self.requestedStreamURL == NO) {
				self.requestedStreamURL = YES;
				[self submitEvent:kEVENT_START_SESSION]; // Send this here so we know we have a GPS coordinate
			}
			
			// Send updated locations to server
			[self submitEvent:kEVENT_GPS_FIX];
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
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Error" message:@"An error occurred trying to obtain your location. This could be due to low GPS signal strength. Ocean Voices requires location information to function properly. Please restart Ocean Voices and allow location." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try Again", @"Cancel", nil];
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

- (void)submitEvent:(NSInteger)eventID {
	// id, operationid, udid, sessionid, servertime, clienttime, latitude, longitude, course, haccuracy, speed
	
	NSLog(@"%f,%f", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude);
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kEventURL]];
	
	[request setPostValue:@"Add" forKey:@"action"];
	[request setPostValue:[NSString stringWithFormat:@"%d", eventID] forKey:@"operationid"];
	[request setPostValue:[NSString stringWithFormat:@"%@", [UIDevice currentDevice].uniqueIdentifier] forKey:@"udid"];
	[request setPostValue:[NSString stringWithFormat:@"%@", sessionID] forKey:@"sessionid"];
	[request setPostValue:[NSString stringWithFormat:@"%d", time(NULL)] forKey:@"clienttime"]; // 2009-10-19 08:36:07
	[request setPostValue:[NSString stringWithFormat:@"%d", locationManager.locationServicesEnabled] forKey:@"locationServicesEnabled"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.coordinate.latitude] forKey:@"latitude"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.coordinate.longitude] forKey:@"longitude"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.course] forKey:@"course"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.horizontalAccuracy] forKey:@"haccuracy"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.speed] forKey:@"speed"];
	[request setPostValue:[NSString stringWithFormat:@"%@", streamURL] forKey:@"streamURL"];
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSMutableString *result = [[NSMutableString alloc] init];
	for (NSObject * obj in [prefs stringArrayForKey:kListenGenderAgePref]) {	// , delimit array properly
		if ([result length])
			[result appendString:@","];
		[result appendString:[obj description]];
	}
	[request setPostValue:result forKey:kListenGenderAgePref];
	[result release];
	
	NSMutableString *result2 = [[NSMutableString alloc] init];
	for (NSObject * obj in [prefs stringArrayForKey:kListenQuestionPref]) {		// , delimit array properly
		if ([result2 length])
			[result2 appendString:@","];
		[result2 appendString:[obj description]];
	}
	[request setPostValue:result2 forKey:kListenQuestionPref];
	[result2 release];
	
	NSMutableString *result3 = [[NSMutableString alloc] init];
	for (NSObject * obj in [prefs stringArrayForKey:kListenUserTypePref]) {	// , delimit array properly
		if ([result3 length])
			[result3 appendString:@","];
		[result3 appendString:[obj description]];
	}
	[request setPostValue:result3 forKey:kListenUserTypePref];
	[result3 release];

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
	
	lastGPSResult = [[jsonDictionary objectForKey:@"RESULT"] boolValue];
	if (lastGPSResult == NO) {
		[locationManager stopUpdatingLocation];
		[gpsIdleTimer invalidate];
	}

	NSString *errorMessage = [[jsonDictionary objectForKey:@"ERROR_MESSAGE"] retain];
	if ([errorMessage length]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ocean Voices Message" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
	[errorMessage release];
}

- (void)requestFinished_startsession:(ASIHTTPRequest *)request
{
	if (streamURL != nil)
		[streamURL release];
	NSDictionary *jsonDictionary = [[request responseString] JSONValue];
	streamURL = [[jsonDictionary objectForKey:@"RESULT"] retain];
	if ([streamURL hasPrefix:@"http://"]) {
		[self requestFinished:request];
		self.networkAvailable = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"networkAvailable" object:nil];
	} else {
		[self requestFailed_startsession: request];
	}
}

- (void)requestFailed_startsession:(ASIHTTPRequest *)request
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Oops! A network error has occurred. If a network connection can not be established Ocean Voices will not be able to function properly." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try Again", @"Cancel", nil];
	[alert show];
	[alert release];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	NSDictionary *jsonDictionary = [[request responseString] JSONValue];
	NSString *errorMessage = [[jsonDictionary objectForKey:@"ERROR_MESSAGE"] retain];
	if ([errorMessage length]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ocean Voices Message" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
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

