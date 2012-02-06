//
//  RWFramework.m
//  RWExample
//
//  Created by Joe Zobkiw on 10/23/11.
//  Copyright (c) 2011 Earsmack Music. All rights reserved.
//

#import "RWFramework.h"
#import "AudioQueue.h"
#import "RWTagViewController.h"
#import "Reachability.h"

// Our singleton
static RWFramework *sharedRWFramework = nil;

#pragma mark Utility

static NSError* make_error(NSString *description, NSInteger code);
static NSError* make_error(NSString *description, NSInteger code) {
	NSMutableDictionary* details = [NSMutableDictionary dictionary];
	[details setValue:description forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:@"org.roundware.RWFramework" code:code userInfo:details];
}

#pragma mark RWFramework

@class AudioQueue;

@interface RWFramework ()
// Private methods
	#pragma mark Private method declarations

// Config
	- (void)offlineConfig;
	- (void)config;
	- (void)configSuccess;
	- (void)configFailure:(NSError*)error;

// Get Tags
	- (void)getTags;
	- (void)getTagsSuccess; 
	- (void)getTagsFailure:(NSError*)error; 

// Request Stream
	- (void)requestStream;
	- (void)requestStreamSuccess:(NSURL*)url; 
	- (void)requestStreamFailure:(NSError*)error;

// Modify Stream
	- (void)modifyStream:(CLLocation *)newLocation;
	- (void)modifyStreamSuccess;
	- (void)modifyStreamFailure:(NSError*)error;

// Heartbeat
	- (void)heartbeatTimerFireMethod:(NSTimer*)theTimer;
	- (void)heartbeat:(CLLocation *)newLocation;
	- (void)heartbeatSuccess;
	- (void)heartbeatFailure:(NSError*)error;

// Record
	- (void)recordTimerMethod:(NSTimer*)theTimer;

// Conversion
	- (void)convertFileAndAddToQueue;

// Queue
	- (NSUInteger)numItemsInQueue;
	- (void)queueTimerFireMethod:(NSTimer*)theTimer;
	- (void)submitFile:(NSString*)filePath latitude:(double)latitude longitude:(double)longitude tags:(NSString*)tags envelopeID:(NSString*)envelopeID date:(NSDate*)date reference:(id)reference;
	- (void)submitFileSuccess:(id)reference;
	- (void)submitFileFailure:(id)reference error:(NSError*)error;
	- (void)createEnvelopeSuccess:(NSString*)envelopeID;
	- (void)createEnvelopeFailure:(NSError*)error;
	- (void)addAssetToEnvelopeSuccess:(NSString*)envelopeID;
	- (void)addAssetToEnvelopeFailure:(NSError*)error;
	
// GPS
	- (void)locationManager:(CLLocationManager *)manager
		didUpdateToLocation:(CLLocation *)newLocation
			   fromLocation:(CLLocation *)oldLocation;
	- (void)locationManager:(CLLocationManager *)manager
		   didFailWithError:(NSError *)error;
	
// Edit Tags
	- (IBAction)doneEditingTags:(id)sender;
	- (void)editTags:(NSString*)type withTitle:(NSString*)title;
	- (IBAction)handleSwipeGestureLeft:(UIGestureRecognizer *)sender;
	- (IBAction)handleSwipeGestureRight:(UIGestureRecognizer *)sender;

// Reachability
	- (void)reachabilityChanged:(NSNotification*)note;

// Logging
	- (void)logEvent:(NSString*)event;
	- (void)logEvent:(NSString*)event withData:(NSString*)data;
	- (void)logEventSuccess;
	- (void)logEventFailure:(NSError*)error;

// Singleton
	- (id)init;
	- (void)dealloc;
	+ (id)allocWithZone:(NSZone *)zone;
	- (id)copyWithZone:(NSZone *)zone;
	- (id)retain;
	- (unsigned)retainCount;
	- (oneway void)release;
	- (id)autorelease;

// Misc
	- (id)getConfigValue:(NSString*)aKey;
	- (id)getConfigValue:(NSString*)aKey inGroup:(NSString*)aGroup;
	- (void)alertOK:(NSString*)title withMessage:(NSString*)message;
	- (NSString*)doubleToStringWithZeroAsEmptyString:(double)d;
	- (NSString *)frameworkDocumentsDirectory;

@end

@implementation RWFramework

// private
@synthesize _systemSupported;
@synthesize _multitaskingSupported;
@synthesize _locationServicesEnabled;

@synthesize _offlineConfiged;
@synthesize _configed;

@synthesize _requestStreamSucceeded;
@synthesize _streamURL;
@synthesize _player;

@synthesize _soundRecorder;
@synthesize _soundPlayer;
@synthesize _recordTimer;
@synthesize _lastRecordedLocation;

@synthesize _recordingQueued;
@synthesize _processingItem;
@synthesize _queueTimer;
@synthesize _bti;

@synthesize _locationManager;
@synthesize _heartbeatTimer;

@synthesize _hostReach;

// public
@synthesize playing;
@synthesize delegate;
@synthesize managedObjectContext;

#pragma mark Start method

- (void)start {
	NSLog(@"RW: sharedRWFramework start");
	
	// Handle any fatal errors that should force the app to quit
	if (!_systemSupported) {
		NSError *error = make_error(@"iOS version not supported", -1);
		[self configFailure:error];
		return;
	}
	
	// Pay attention to reachability
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	_hostReach = [[Reachability reachabilityWithHostName: [self getConfigValue:@"reachability_host_name"]] retain];
	[_hostReach startNotifier];
	
	// Delete any stale files
	NSError *error;
	BOOL b = [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [self getConfigValue:@"recorded_file_name"]] error:&error];
	if (b == NO && ([error code] != 4)) {
		[self alertOK:nil withMessage:[error localizedDescription]];
	}
	b = [[NSFileManager defaultManager] removeItemAtPath:[[self frameworkDocumentsDirectory] stringByAppendingPathComponent: [self getConfigValue:@"converted_file_name"]] error:&error];
	if (b == NO && ([error code] != 4)) {
		[self alertOK:nil withMessage:[error localizedDescription]];
	}
	
	/*
	 [[NSNotificationCenter defaultCenter] addObserver:self
	 selector:@selector(receiveNotification:) 
	 name:@"get_config_success"
	 object:nil];
	 [[NSNotificationCenter defaultCenter] addObserver:self
	 selector:@selector(receiveNotification:) 
	 name:@"get_config_failure"
	 object:nil];
	 */
}

#pragma mark Config methods

/*
 This method (one or the other config or offlineConfig) is called to initialize the framework. This kicks everything else off. 
 */

- (void)offlineConfig {
	
	// This way we can check to only start ourselves once
	if (_offlineConfiged == YES || _configed == YES) { 
		NSLog(@"RW: skipping offlineConfig because we've already offlineConfiged or configed");
		return;
	}
	_offlineConfiged = YES;
	
	NSLog(@"RW: OFFLINE CONFIG");
	
	BOOL speak_enabled = [[self getConfigValue:@"speak_enabled"] boolValue];
	if (speak_enabled) {
		BOOL geo_speak_enabled = [[self getConfigValue:@"geo_speak_enabled"] boolValue];
		
		// Record timer (and for playback of recording)
		if (_recordTimer == nil)
			_recordTimer = [NSTimer scheduledTimerWithTimeInterval:.1
														target:self 
													  selector:@selector(recordTimerMethod:)
													  userInfo:nil
													   repeats:YES];
		
		// Enable buttons as appropriate
		if ([[self delegate] respondsToSelector:@selector(rwReadyToRecord)])
			[[self delegate] rwReadyToRecord];
		
		// Determine if we need GPS services and if so Initialize and possibly start them
		if (geo_speak_enabled) {
			NSLog(@"RW: Initializing GPS... geo_speak_enabled=%i", geo_speak_enabled);
			// Initialize GPS
			_locationManager = [[CLLocationManager alloc] init];
			_locationManager.delegate = self;
			_locationManager.distanceFilter = [[self getConfigValue:@"distance_filter_in_meters"] doubleValue];
			_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		} else NSLog(@"RW: GPS is not being initialized because geo_speak_enabled is false.");
	}
	
	// Config was successful
	if ([[self delegate] respondsToSelector:@selector(rwOfflineConfigSuccess)])
		[[self delegate] rwOfflineConfigSuccess];

}

- (void)config {
	
	// This way we can check to only start ourselves once
	if (_offlineConfiged == YES || _configed == YES) { 
		NSLog(@"RW: skipping config because we've already configed or offlineConfiged");
		return;
	}
	_configed = YES;
	
	NSLog(@"RW: ONLINE CONFIG");

	// Call get_config passing a device id if we have one
	NSString *device_id = [self getConfigValue:@"device_id" inGroup:@"device"];
	NSURL* requestURL = nil;
	requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&project_id=%@&device_id=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"get_config", [self getConfigValue:@"project_id"], device_id ? device_id : @""]];
	NSLog(@"RW: get_config: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		
		// When the JSON returns we write it out to NSUSerDefaults for easy access, this also makes it stay around between app launches
		//NSLog(@"RW: JSON = %@", [JSON debugDescription]);
		for (NSDictionary *d in JSON) {
			//NSLog(@"RW: d=%@", [d debugDescription]);
			[d enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
				NSLog(@"RW: writing to defaults: %@ = %@", key, object);
				[[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
			}];
		}
		
		// Tell the delegate that this was successful.
		[self configSuccess];
		
		// Load the tags
		[self getTags];
		
		// A future enhancement may be to use notifications instead of delegate method for this (and other) communication - this is here as a placeholder/reminder
		//[[NSNotificationCenter defaultCenter] postNotificationName:@"get_config_success" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
		
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		
		// we had a failure, pass it up the chain to be handled and displayed to the user
		[self configFailure:error];
		
		// A future enhancement may be to use notifications instead of delegate method for this (and other) communication - this is here as a placeholder/reminder
		//[[NSNotificationCenter defaultCenter] postNotificationName:@"get_config_failure" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, @"error", nil]];
	}];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}


// Once config returns successfully we can use the info gathered to set up the framework features
- (void)configSuccess { 
	NSLog(@"RW: configSuccess");
	
	NSString *version = [self getConfigValue:@"version" inGroup:@"server"];
	if ([[self delegate] respondsToSelector:@selector(rwCurrentVersion:)])
		[[self delegate] rwCurrentVersion:version];
	
	BOOL listen_enabled = [[self getConfigValue:@"listen_enabled"] boolValue];
	BOOL geo_listen_enabled = [[self getConfigValue:@"geo_listen_enabled"] boolValue];
	BOOL speak_enabled = [[self getConfigValue:@"speak_enabled"] boolValue];
	BOOL geo_speak_enabled = [[self getConfigValue:@"geo_speak_enabled"] boolValue];
	
	// Determine if we need GPS services and if so Initialize and possibly start them
	if (geo_listen_enabled || geo_speak_enabled) {
		NSLog(@"RW: Initializing GPS... geo_listen_enabled=%i geo_speak_enabled=%i", geo_listen_enabled, geo_speak_enabled);
		// Initialize GPS
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.delegate = self;
		_locationManager.distanceFilter = [[self getConfigValue:@"distance_filter_in_meters"] doubleValue];
		_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		if (geo_listen_enabled) {
			NSLog(@"RW: Starting GPS for geo_listen_enabled...");
			[_locationManager startUpdatingLocation];
		}
	} else NSLog(@"RW: GPS is not being initialized because both geo_listen_enabled and geo_speak_enabled are false.");
	
	// If we allow listening then we should request a stream
	if (listen_enabled) {
		NSLog(@"RW: Requesting stream... listen_enabled=%i", listen_enabled);
		[self requestStream];
		
		// Heartbeat timer
		NSInteger interval = [[self getConfigValue:@"gps_idle_interval_in_seconds"] integerValue];
		NSLog(@"RW: Enabling heartbeat timer... interval=%i listen_enabled=%i", interval, listen_enabled);
		if (_heartbeatTimer == nil)
			_heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:interval 
														   target:self 
														 selector:@selector(heartbeatTimerFireMethod:) 
														 userInfo:nil 
														  repeats:YES];
		
	} else NSLog(@"RW: Stream is not being requested because listen_enabled=%i", listen_enabled);
	
	// We use a timer to help manage UI stuff while recording if enabled
	if (speak_enabled) {
		NSLog(@"RW: Create record timer (for UI stuff)... speak_enabled=%i", speak_enabled);
		
		// Record timer (and for playback of recording)
		if (_recordTimer == nil)
			_recordTimer = [NSTimer scheduledTimerWithTimeInterval:.1
															target:self 
														  selector:@selector(recordTimerMethod:)
														  userInfo:nil
														   repeats:YES];
		// Queue timer (for uploading)
		if (_queueTimer == nil)
			_queueTimer = [NSTimer scheduledTimerWithTimeInterval:7
													   target:self 
													 selector:@selector(queueTimerFireMethod:) 
													 userInfo:nil 
													  repeats:YES];

		
	} else NSLog(@"RW: recordTimer is not being created because speak_enabled=%i", speak_enabled);
	
	// Config was successful
	if ([[self delegate] respondsToSelector:@selector(rwConfigSuccess)])
		[[self delegate] rwConfigSuccess];
	
	// Enable buttons as needed
	if (speak_enabled) {
		if ([[self delegate] respondsToSelector:@selector(rwReadyToRecord)])
			[[self delegate] rwReadyToRecord];
	}
}

- (void)configFailure:(NSError*)error { 
	NSLog(@"RW: configFailure %@", [error localizedDescription]); 
	if ([[self delegate] respondsToSelector:@selector(rwConfigFailure:)])
		[[self delegate] rwConfigFailure:error];
	else
		[self alertOK:nil withMessage:[error localizedDescription]];

	[self logEvent:@"client_error" withData:[NSString stringWithFormat:@"configFailure %@", [error localizedDescription]]];
}

#pragma mark Tags methods

/*
 Get the tags for the project
 */
- (void)getTags {
	if (_configed == NO) { 
		NSLog(@"RW: skipping getTags because we haven't configed yet");
		return;
	}
	
	NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&project_id=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"get_tags", [self getConfigValue:@"project_id"]]];
	NSLog(@"RW: get_tags: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		
		// When the JSON returns we write it out to NSUSerDefaults for easy access, this also makes it stay around between app launches
		NSLog(@"RW: JSON = %@", [JSON debugDescription]);
		
		// Listen Tags
		NSArray *listen = [JSON objectForKey:@"listen"];
		NSLog(@"RW: listen is a %@ %@", [listen class], [listen debugDescription]);
		[[NSUserDefaults standardUserDefaults] setObject:listen forKey:@"tags_listen"];
		
		// If we don't have current settings saved for listen tags then save the defaults as current as individual NSArrays
		[listen enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSDictionary *d = obj;
			NSArray *defaults = [d objectForKey:@"defaults"];
			NSString *code = [d objectForKey:@"code"];
			NSString *defaultsKeyName = [NSString stringWithFormat:@"tags_listen_%@_current", code];
			NSArray *current = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKeyName];
			if (current == nil)
				[[NSUserDefaults standardUserDefaults] setObject:defaults forKey:defaultsKeyName];
		}];
		
		// Speak Tags
		NSArray *speak = [JSON objectForKey:@"speak"];
		NSLog(@"RW: speak is a %@ %@", [speak class], [speak debugDescription]);
		[[NSUserDefaults standardUserDefaults] setObject:speak forKey:@"tags_speak"];
		
		// ...and speak
		[speak enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSDictionary *d = obj;
			NSArray *defaults = [d objectForKey:@"defaults"];
			NSString *code = [d objectForKey:@"code"];
			NSString *defaultsKeyName = [NSString stringWithFormat:@"tags_speak_%@_current", code];
			NSArray *current = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKeyName];
			if (current == nil)
				[[NSUserDefaults standardUserDefaults] setObject:defaults forKey:defaultsKeyName];
		}];
		
		//NSLog(@"RW: %@", [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] debugDescription]);
		
		[self getTagsSuccess];
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		[self getTagsFailure:error];
	}];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}


- (void)getTagsSuccess { 
	if ([[self delegate] respondsToSelector:@selector(rwGetTagsSuccess)])
		[[self delegate] rwGetTagsSuccess];
}

- (void)getTagsFailure:(NSError*)error { 
	NSLog(@"RW: getTagsFailure %@", [error localizedDescription]); 
	if ([[self delegate] respondsToSelector:@selector(rwGetTagsFailure:)])
		[[self delegate] rwGetTagsFailure:error];
	else
		[self alertOK:nil withMessage:[error localizedDescription]];

	[self logEvent:@"client_error" withData:[NSString stringWithFormat:@"getTagsFailure %@", [error localizedDescription]]];
}


/*
 - (void)receiveNotification:(NSNotification *)notification
 {
 if ([[notification name] isEqualToString:@"get_config_success"]) {
 NSLog (@"get_config_success!");
 NSLog(@"RW: %@", [notification userInfo]);
 [self currentVersion];
 [self requestStream];
 if ([[self delegate] respondsToSelector:@selector(configSuccess)])
 [[self delegate] configSuccess];
 
 } else if ([[notification name] isEqualToString:@"get_config_failure"]) {
 NSLog (@"get_config_failure!");
 NSLog(@"RW: %@", [notification userInfo]);
 NSLog(@"RW: configFailure %@", [[[notification userInfo] objectForKey:@"error"] localizedDescription]); 
 if ([[self delegate] respondsToSelector:@selector(configFailure:)])
 [[self delegate] configFailure:[[notification userInfo] objectForKey:@"error"]];
 else
 [self alertOK:nil withMessage:[[[notification userInfo] objectForKey:@"error"] localizedDescription]];
 }
 }
 */

#pragma mark Stream control methods

// Instantiate the singleton player and/or return it
- (AVPlayer*)player {
    if (_player == nil) {
		playing = NO;
        _player = [[AVPlayer playerWithURL:self._streamURL] retain];
        if (_player == nil) {
            NSLog(@"RW: An error occurred trying to allocate the AVPlayer.");
        }
    } 
    return _player;
}

// Play the stream
- (void)play {
	BOOL listen_enabled = [[self getConfigValue:@"listen_enabled"] boolValue];
	if (!listen_enabled) {
		NSLog(@"RW: Playing not allowed listen_enabled=%i", listen_enabled);
		return;
	}

    if ([_player status] == AVPlayerStatusFailed) {
		[_player release];
		_player = nil;
	}
	[[self player] play];
	playing = YES;
	
	[self logEvent:@"start_listen"];
}

// Pause the stream
- (void)pause {
	BOOL listen_enabled = [[self getConfigValue:@"listen_enabled"] boolValue];
	if (!listen_enabled) {
		NSLog(@"RW: Playing not allowed listen_enabled=%i", listen_enabled);
		return;
	}

    if ([_player status] == AVPlayerStatusFailed) {
		[_player release];
		_player = nil;
	}
    [[self player] pause];
	playing = NO;
	
	[self logEvent:@"stop_listen"];
}

// Is the app allowed to play
- (BOOL)canPlay {
	return [[self getConfigValue:@"listen_enabled"] boolValue];
}

/*
 Request a stream URL to be used and store it - TBD - how to handle when this stream expires!
 */
- (void)requestStream {
	if (_configed == NO) { 
		NSLog(@"RW: skipping requestStream because we haven't configed yet");
		return;
	}
	
	NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&session_id=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"request_stream", [self getConfigValue:@"session_id" inGroup:@"session"]]];
	NSLog(@"RW: request_stream: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		_requestStreamSucceeded = YES;
		[self requestStreamSuccess:[NSURL URLWithString:[JSON valueForKeyPath:@"stream_url"]]];
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		NSLog(@"RW: request: %@", [request description]);
		NSLog(@"RW: response: %@", [response description]);
		NSLog(@"RW: error: %@", [error description]);
		NSLog(@"RW: JSON: %@", [JSON description]);
		[self requestStreamFailure:error];
	}];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}

- (void)requestStreamSuccess:(NSURL*)url { 
	NSLog(@"RW: requestStreamSuccess %@", url);
	if (url) {
		[_streamURL release];
		self._streamURL = [url retain];
		if ([[self delegate] respondsToSelector:@selector(rwReadyToPlay)])
			[[self delegate] rwReadyToPlay];
	}
}

- (void)requestStreamFailure:(NSError*)error { 
	NSLog(@"RW: requestStreamFailure %@", [error localizedDescription]); 
	if ([[self delegate] respondsToSelector:@selector(rwUnableToPlay)])
		[[self delegate] rwUnableToPlay:error];
	else
		[self alertOK:nil withMessage:NSLocalizedString(@"CONNECTIVITY_ERROR", nil)];

	//[self alertOK:nil withMessage:[error localizedDescription]]; // TODO Fix server problem with streams not returning properly?

	[self logEvent:@"client_error" withData:[NSString stringWithFormat:@"requestStreamFailure %@", [error localizedDescription]]];
}

/*
 modifyStream is called when location changes and listen_enabled = YES
 */
- (void)modifyStream:(CLLocation *)newLocation {
	if (_configed == NO) { 
		NSLog(@"RW: skipping modifyStream because we haven't configed yet");
		return;
	}
	if (_requestStreamSucceeded == NO) { 
		NSLog(@"RW: skipping modify_stream because request_stream has not yet succeeded");
		return;
	}
	
	// Build the string to be passed to the tags param
	NSArray *listen = [[NSUserDefaults standardUserDefaults] arrayForKey:@"tags_listen"];
	NSMutableArray *ma = [[NSMutableArray array] retain];
	[listen enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSDictionary *d = obj;
		NSString *code = [d objectForKey:@"code"];
		NSString *defaultsKeyName = [NSString stringWithFormat:@"tags_listen_%@_current", code];
		NSArray *current = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKeyName];
		if (current != nil)
			[ma addObjectsFromArray:current];
	}];
	NSString *tags = [[ma componentsJoinedByString:@","] retain];
	[ma release];
	
	NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&session_id=%@&latitude=%@&longitude=%@&tags=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"modify_stream", [self getConfigValue:@"session_id" inGroup:@"session"], [self doubleToStringWithZeroAsEmptyString: newLocation.coordinate.latitude], [self doubleToStringWithZeroAsEmptyString:newLocation.coordinate.longitude ], tags]];
	[tags release];
	NSLog(@"RW: modify_stream: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		[self modifyStreamSuccess];
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		[self modifyStreamFailure:error];
	}];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}

- (void)modifyStreamSuccess {
	NSLog(@"RW: modifyStreamSuccess");
	if ([[self delegate] respondsToSelector:@selector(rwModifyStreamSuccess)])
		[[self delegate] rwModifyStreamSuccess];
}

- (void)modifyStreamFailure:(NSError*)error {
	NSLog(@"RW: modifyStreamFailure %@", [error localizedDescription]); 
	if ([[self delegate] respondsToSelector:@selector(rwModifyStreamFailure:)])
		[[self delegate] rwModifyStreamFailure:error];

	[self logEvent:@"client_error" withData:[NSString stringWithFormat:@"modifyStreamFailure %@", [error localizedDescription]]];
}

#pragma mark AVAudioPlayerDelegate methods

/* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
	if ([[self delegate] respondsToSelector:@selector(rwUpdateUI:)])
		[[self delegate] rwUpdateUI:0];
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
	[self alertOK:nil withMessage:[error localizedDescription]];
	if ([[self delegate] respondsToSelector:@selector(rwUpdateUI:)])
		[[self delegate] rwUpdateUI:0];
	
	[self logEvent:@"client_error" withData:[NSString stringWithFormat:@"audioPlayerDecodeErrorDidOccur %@", [error localizedDescription]]];
}

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {}

/* audioPlayerEndInterruption:withFlags: is called when the audio session interruption has ended and this player had been interrupted while playing. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags NS_AVAILABLE_IOS(4_0) {}

/* audioPlayerEndInterruption: is called when the preferred method, audioPlayerEndInterruption:withFlags:, is not implemented. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player {}



#pragma mark Heartbeat methods

/*
 heartbeat timer is called either when gps location hasn't changed in a certain amount of time or each time it's triggered if geo_listen_enabled is NO
 */
- (void)heartbeatTimerFireMethod:(NSTimer*)theTimer {
	BOOL geo_listen_enabled = [[self getConfigValue:@"geo_listen_enabled"] boolValue];
	if (geo_listen_enabled) {
		NSInteger interval = [[self getConfigValue:@"gps_idle_interval_in_seconds"] integerValue];
		NSTimeInterval diff = [_locationManager.location.timestamp timeIntervalSinceNow];
		if (diff < -interval)
			[self heartbeat:_locationManager.location];
	} else {
		[self heartbeat:nil];
	}
}

/*
 heartbeat is called via NSTimer and keeps things alive
 */
- (void)heartbeat:(CLLocation *)newLocation {
	if (_configed == NO) { 
		NSLog(@"RW: skipping heartbeat because we haven't configed yet");
		return;
	}
	
	NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&session_id=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"heartbeat", [self getConfigValue:@"session_id" inGroup:@"session"]]];
	NSLog(@"RW: heartbeat: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		[self heartbeatSuccess];
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		[self heartbeatFailure:error];
	}];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}

- (void)heartbeatSuccess {
	NSLog(@"RW: heartbeatSuccess");
	if ([[self delegate] respondsToSelector:@selector(rwHeartbeatSuccess)])
		[[self delegate] rwHeartbeatSuccess];
}

- (void)heartbeatFailure:(NSError*)error {
	NSLog(@"RW: heartbeatFailure %@", [error localizedDescription]); 
	if ([[self delegate] respondsToSelector:@selector(rwHeartbeatFailure:)])
		[[self delegate] rwHeartbeatFailure:error];

	[self logEvent:@"client_error" withData:[NSString stringWithFormat:@"heartbeatFailure %@", [error localizedDescription]]];
}


#pragma mark Recording control methods

static NSInteger max_recording_length; // local static copy to provide faster access to this configuration option

// Start recording
- (void)startRecording {
	
	// Are we allowed to record?
	BOOL speak_enabled = [[self getConfigValue:@"speak_enabled"] boolValue];
	if (!speak_enabled) {
		NSLog(@"RW: Recording not allowed speak_enabled=%i", speak_enabled);
		return;
	}
	
	// Start updating location if required
	BOOL geo_speak_enabled = [[self getConfigValue:@"geo_speak_enabled"] boolValue];
	if (geo_speak_enabled) {
		NSLog(@"RW: Updating location for speaking...");
		[_locationManager startUpdatingLocation];
	}
	
	// Start fresh each time
	[_soundRecorder release];
	_soundRecorder = nil;
	
	// Create soundFileURL
    NSString *soundFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent: [self getConfigValue:@"recorded_file_name"]];
    NSURL *soundFileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];

	// Create AVAudioRecorder
	NSDictionary *recordSettings =
		[[NSDictionary alloc] initWithObjectsAndKeys:
		 [NSNumber numberWithFloat: 22050.0], AVSampleRateKey,
		 [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
		 [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
		 [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
		 nil];
	AVAudioRecorder *newRecorder = [[AVAudioRecorder alloc] initWithURL: soundFileURL settings: recordSettings error: nil];
    [soundFileURL release];
	[recordSettings release];
	self._soundRecorder = newRecorder;
	[newRecorder release];
	self._soundRecorder.delegate = self;
	
	// Prepare and record
	[_soundRecorder prepareToRecord];
	[_soundRecorder recordForDuration:(NSTimeInterval)[[self getConfigValue:@"max_recording_length"] integerValue]];

	// Reset flag
	_recordingQueued = NO;
	
	[self logEvent:@"start_record"];
}

// Stop recording
- (void)stopRecording {
	if ([_soundRecorder isRecording]) {
		[_soundRecorder stop];
		// audioRecorderDidFinishRecording will be called by default when this happens
	}
}

// Playback the recording
- (void)playbackRecording {
	if ([_soundPlayer isPlaying])
		[_soundPlayer stop];
	[_soundPlayer release];
	_soundPlayer = nil;

	if ([self hasRecording]) {

		NSString *soundFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent: [self getConfigValue:@"recorded_file_name"]];
		NSURL *soundFileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
		AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: soundFileURL error: nil];
		[soundFileURL release];
		self._soundPlayer = newPlayer;
		[newPlayer release];

		[_soundPlayer setDelegate: self];
		[_soundPlayer prepareToPlay];
		[_soundPlayer play];

	} else [self alertOK:nil withMessage:NSLocalizedString(@"MUST_RECORD_BEFORE_PLAYBACK_ERROR", nil)];
}

// Stop playback of the recording
- (void)stopPlayback {
	if ([_soundPlayer isPlaying]) {
		[_soundPlayer stop];
		if ([[self delegate] respondsToSelector:@selector(rwUpdateUI:)])
			[[self delegate] rwUpdateUI:0];
	}
}

// Are we currently recording?
- (BOOL)isRecording {
	return [_soundRecorder isRecording];
}

// Did we record something?
- (BOOL)hasRecording {
	return [[NSFileManager defaultManager] fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [self getConfigValue:@"recorded_file_name"]] isDirectory:NO];
}

// Are we playing back the current recording?
- (BOOL)isPlayingBack {
	return [_soundPlayer isPlaying];
}

// Is recording allowed?
- (BOOL)canRecord {
	return [[self getConfigValue:@"speak_enabled"] boolValue];
}

// Update the UI while recording or playing back (for progress meter)
- (void)recordTimerMethod:(NSTimer*)theTimer
{
	if ([self isRecording] || [self isPlayingBack]) {
		if (max_recording_length == 0) {
			max_recording_length = [[self getConfigValue:@"max_recording_length"] integerValue];
		}
		float percentage = [self isRecording] ? 
		([_soundRecorder currentTime]/max_recording_length) : 
		([_soundPlayer currentTime]/max_recording_length);
		if ([[self delegate] respondsToSelector:@selector(rwUpdateUI:)])
			[[self delegate] rwUpdateUI:percentage];
	}
}

#pragma mark AVAudioRecorderDelegate methods

/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
	
	// Stop updating location if required
	BOOL geo_listen_enabled = [[self getConfigValue:@"geo_listen_enabled"] boolValue];
	BOOL geo_speak_enabled = [[self getConfigValue:@"geo_speak_enabled"] boolValue];
	if (geo_speak_enabled) {
		// Get most recent location for submission
		self._lastRecordedLocation = [_locationManager location];
		
		// Stop location updates if required
		if (!geo_listen_enabled || [self offline]) {
			NSLog(@"RW: Stopping location updating for speaking...");
			[_locationManager stopUpdatingLocation];
		}
	}
	
	if ([[self delegate] respondsToSelector:@selector(rwUpdateUI:)]) {
		[[self delegate] rwUpdateUI:0];
	}
	
	[self logEvent:@"stop_record"];
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
	[self alertOK:nil withMessage:[error localizedDescription]];
	if ([[self delegate] respondsToSelector:@selector(rwUpdateUI:)]) {
		[[self delegate] rwUpdateUI:0];
	}
	
	[self logEvent:@"client_error" withData:[NSString stringWithFormat:@"audioRecorderEncodeErrorDidOccur %@", [error localizedDescription]]];
}

/* audioRecorderBeginInterruption: is called when the audio session has been interrupted while the recorder was recording. The recorder will have been paused. */
- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {}

/* audioRecorderEndInterruption:withFlags: is called when the audio session interruption has ended and this recorder had been interrupted while recording. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags NS_AVAILABLE_IOS(4_0) {}

/* audioRecorderEndInterruption: is called when the preferred method, audioRecorderEndInterruption:withFlags:, is not implemented. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder {}

#pragma mark Submission/Conversion methods

// Submit the most recent recording (convert, add to queue, upload)
- (void)submit {
	if ([self hasRecording] && _recordingQueued == NO) {
		_recordingQueued = YES;
		
		[self convertFileAndAddToQueue];
		
		// Copy the recorded file into the queue directory, possibly update some data regarding the upload (tags, etc.) and then the queuing mechanism will take over uploading the file at the next possible time.
		
		//[self alertOK:nil withMessage:@"Your recording has been queued and will be submitted soon."];
	} else if (_recordingQueued == YES) {
		[self alertOK:nil withMessage:NSLocalizedString(@"RECORDING_ALREADY_QUEUED_ERROR", nil)];
	} else if (![self hasRecording]) {
		[self alertOK:nil withMessage:NSLocalizedString(@"RECORDING_REQUIRED_BEFORE_QUEUED_ERROR", nil)];
	}
}

- (void)convertFileAndAddToQueue {
    
    AVURLAsset *audioAsset = nil;
    NSDictionary *options = nil;
    NSString *outputPath = nil;
    NSURL *outputURL = nil;
	AVAssetExportSession *exportSession = nil;
	
    options = [[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithBool:YES], @"AVURLAssetPreferPreciseDurationAndTimingKey", 
				nil] retain];
    
    NSString *soundFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent: [self getConfigValue:@"recorded_file_name"]];
    NSURL *soundFileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	audioAsset = [[AVURLAsset URLAssetWithURL:soundFileURL options:options] retain];
	[soundFileURL release];
    if (audioAsset == nil) { NSLog(@"RW: Couldn't create AVURLAsset"); goto fail; }
    if ([((AVURLAsset*)audioAsset) isExportable] == NO) { NSLog(@"RW: This audio is not exportable"); goto fail; }
	
    exportSession = [[AVAssetExportSession alloc] initWithAsset:audioAsset presetName:AVAssetExportPresetMediumQuality];
    if (exportSession == nil) { NSLog(@"RW: Couldn't create AVAssetExportSession"); goto fail; }
    
	NSString *uniqueFileName = [NSString stringWithFormat:@"%f_%@", [NSDate timeIntervalSinceReferenceDate], [self getConfigValue:@"converted_file_name"]];
	outputPath = [[[self frameworkDocumentsDirectory] stringByAppendingPathComponent: uniqueFileName] retain];
    
	NSError *error;
    if (([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) && ([[NSFileManager defaultManager] removeItemAtPath:outputPath error:&error] == NO)) {
        NSLog(@"RW: Couldn't delete previous output file: %@", [error localizedDescription]);
        goto fail;
        // This is a fatal error - can not convert, probably shouldn't upload - not sure the best way to handle it - but it should NEVER happen!
    }
    NSLog(@"RW: Converting to: %@", outputPath);
    outputURL = [[NSURL alloc] initFileURLWithPath: outputPath];
    
    // configure export session output with all our parameters
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie /* AVFileTypeAppleM4A */ ; 
    
    NSLog(@"RW: --- BEGINNING AUDIO EXPORT ---");
	if ([[self delegate] respondsToSelector:@selector(rwUpdateStatus:)])
		[[self delegate] rwUpdateStatus:[NSString stringWithFormat:NSLocalizedString(@"PREPARING_AND_QUEUING", nil)]];
	
	// Put these here so they can be easily accessed in the success block below
	CGFloat latitude = self._lastRecordedLocation.coordinate.latitude;
	CGFloat longitude = self._lastRecordedLocation.coordinate.longitude;
	
	// Build the string to be passed to the tags param
	NSArray *speak = [[NSUserDefaults standardUserDefaults] arrayForKey:@"tags_speak"];
	NSMutableArray *ma = [[NSMutableArray array] retain];
	[speak enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSDictionary *d = obj;
		NSString *code = [d objectForKey:@"code"];
		NSString *defaultsKeyName = [NSString stringWithFormat:@"tags_speak_%@_current", code];
		NSArray *current = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKeyName];
		if (current != nil)
			[ma addObjectsFromArray:current];
	}];
	NSString *tags = [[ma componentsJoinedByString:@","] retain];
	[ma release];
	
    // perform the export
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
		 if (AVAssetExportSessionStatusCompleted == exportSession.status) {
			NSLog(@"RW: AVAssetExportSessionStatusCompleted --- AUDIO EXPORT SUCCESS");
			
			// Create the envelope for this audio file
			if (_configed == YES && [self online]) { 
				NSLog(@"RW: Requesting an envelope id...");

				// create envelope
				NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&session_id=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"create_envelope", [self getConfigValue:@"session_id" inGroup:@"session"]]];
				NSLog(@"RW: create_envelope: %@", [requestURL debugDescription]);
				NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
				
				AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
					
					NSString *envelope_id = [NSString stringWithFormat:@"%@", [JSON valueForKeyPath:@"envelope_id"]];
					NSLog(@"RW: envelope_id=%@", envelope_id);
					
					if ((envelope_id == nil) || [envelope_id isEqualToString:@""]) {
						//[self performSelectorOnMainThread:@selector(createEnvelopeFailure:) withObject:nil waitUntilDone:NO];
						[self createEnvelopeFailure:nil];
					} else {
						//[self performSelectorOnMainThread:@selector(createEnvelopeSuccess:) withObject:envelope_id waitUntilDone:NO];
						[self createEnvelopeSuccess:envelope_id];
					}
					
					// Save the audio file to the queue for later uploading
					AudioQueue *aq = (AudioQueue *)[NSEntityDescription insertNewObjectForEntityForName:@"AudioQueue" inManagedObjectContext:managedObjectContext];
					[aq setCreationDate:[NSDate date]];
					[aq setFilePath:outputPath];
					[aq setLatitude:[NSNumber numberWithFloat:latitude]];
					[aq setLongitude:[NSNumber numberWithFloat:longitude]];
					[aq setTags:tags];
					if ((envelope_id == nil) || [envelope_id isEqualToString:@""])
						[aq setEnvelopeID:@""];
					else
						[aq setEnvelopeID:envelope_id];
					
					NSError *error = nil;
					if (![managedObjectContext save:&error]) {
						NSLog(@"RW: An error occurred trying to save the audio to the queue. %@", [error localizedDescription]);
					} else {
						NSLog(@"RW: Audio saved to queue");
						// Show the number yet to be processed at all
						if ([[self delegate] respondsToSelector:@selector(rwUpdateApplicationIconBadgeNumber:)]) {
							[[self delegate] rwUpdateApplicationIconBadgeNumber:[self numItemsInQueue]];
						}
					}
					
				} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
					[self createEnvelopeFailure:error];
				}];
				
				NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
				[queue addOperation:operation];
				
			} else {
				NSLog(@"RW: Using an empty envelope id because we haven't configed yet - will be requested when uploading.");
				
				// Save the audio file to the queue for later uploading
				AudioQueue *aq = (AudioQueue *)[NSEntityDescription insertNewObjectForEntityForName:@"AudioQueue" inManagedObjectContext:managedObjectContext];
				[aq setCreationDate:[NSDate date]];
				[aq setFilePath:outputPath];
				[aq setLatitude:[NSNumber numberWithFloat:latitude]];
				[aq setLongitude:[NSNumber numberWithFloat:longitude]];
				[aq setTags:tags];
				[aq setEnvelopeID:@""];
				
				NSError *error = nil;
				if (![managedObjectContext save:&error]) {
					NSLog(@"RW: An error occurred trying to save the audio to the queue. %@", [error localizedDescription]);
				} else {
					NSLog(@"RW: Audio saved to queue");
					// Show the number yet to be processed at all
					if ([[self delegate] respondsToSelector:@selector(rwUpdateApplicationIconBadgeNumber:)]) {
						[[self delegate] rwUpdateApplicationIconBadgeNumber:[self numItemsInQueue]];
					}
				}
				
			}
		
        } else if (AVAssetExportSessionStatusFailed == exportSession.status) {
            // a failure may happen because of an event out of your control for example, an interruption like a phone call coming in
            // make sure and handle this case appropriately
            NSLog(@"RW: AVAssetExportSessionStatusFailed: %@ --- AUDIO EXPORT FAIL", [exportSession.error localizedDescription]);
			[self alertOK:nil withMessage:[exportSession.error localizedDescription]];
        } else {
            NSLog(@"RW: Export Session Status: %d --- AUDIO EXPORT UNKNOWN (FAIL)", exportSession.status);
			[self alertOK:nil withMessage:[exportSession.error localizedDescription]];
		}
    }];
    
	[tags release];
    goto exit;
fail:
    NSLog(@"RW: AUDIO EXPORT FAIL");
    [self alertOK:nil withMessage:NSLocalizedString(@"AUDIO_COULD_NOT_BE_CONVERTED_ERROR", nil)];
	// If can't convert...upload anyway?
exit:
    NSLog(@"RW: AUDIO EXPORT EXIT");
	[exportSession release];
    [outputPath release];
    [options release];
    [outputURL release];
    [audioAsset release]; 
	
}

#pragma mark Queue methods

- (NSUInteger)numItemsInQueue {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"AudioQueue" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor release];
	
	NSError *error = nil;
	NSUInteger count = [managedObjectContext countForFetchRequest:request error:&error];    
	return count;
}

- (void)queueTimerFireMethod:(NSTimer*)theTimer {
	NSLog(@"RW: queueTimerFireMethod");
	
	// We only process one item at a time in the queue
	if (_processingItem == YES) {
		NSLog(@"RW: Currently processing queue item, returning...");
		return;
	}
	
	_processingItem = YES;
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"AudioQueue" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor release];
	
	//[request setFetchLimit:1]; // We get all results so we can let the app know what to set the application badge number to

	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		NSLog(@"RW: executeFetchRequest error %@", [error localizedDescription]);
	}

	if ([mutableFetchResults count] > 0) {
		if ([[self delegate] respondsToSelector:@selector(rwUpdateStatus:)])
			[[self delegate] rwUpdateStatus:[NSString stringWithFormat:NSLocalizedString(@"SUBMITTING", nil)]];
		
		AudioQueue *aq = [mutableFetchResults objectAtIndex:0];
		NSLog(@"RW: Submitting %@...", [[aq filePath] lastPathComponent]);
		
		_bti = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			NSLog(@"RW: Task completed");
			_bti = UIBackgroundTaskInvalid;
		}];
		[self submitFile:aq.filePath latitude:[aq.latitude doubleValue] longitude:[aq.longitude doubleValue] tags:aq.tags envelopeID:aq.envelopeID date:aq.creationDate reference:aq];
		
		/*
		 when submission is complete it will call back to completion method that says file was submitted succesfully, passing the AudioQueue
		 reference back to that call. At that point the completion method can delete the file and delete the object from the managed context.
		 This allows us to not have to store the AudioQueue around in a global as we instead pass it back and forth
		 */

	} else _processingItem = NO;
	
	[mutableFetchResults release];
	[request release];

}

/*
 submitFile is called by the queue timer to begin the process of uploading a single file at a time.
 */
- (void)submitFile:(NSString*)filePath latitude:(double)latitude longitude:(double)longitude tags:(NSString*)tags envelopeID:(NSString*)envelopeID date:(NSDate*)date reference:(id)reference {
	if (_configed == NO) { 
		NSLog(@"RW: skipping submitFile because we haven't configed yet");
		return;
	}
	
	if ([[self delegate] respondsToSelector:@selector(rwUpdateActivity:)])
		[[self delegate] rwUpdateActivity:YES];
	
	// Convert our date to RFC822 format: Mon, 15 Aug 05 15:52:01 +0000
	// see http://www.alexcurylo.com/blog/2009/01/29/nsdateformatter-formatting/ for details
	/*
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"ccc, dd MMM yy HH:mm:ss Z"]; 
	NSString *clientTimeString = [[dateFormatter stringFromDate:date] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	[dateFormatter release];
	 */
	NSString *clientTimeString = [[[NSDate date] description] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];

	if ((envelopeID == nil) || [envelopeID isEqualToString:@""]) {
		NSLog(@"RW: Creating an envelope id because we must have been offline when the file was submitted.");

		// create envelope if needed
		NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&session_id=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"create_envelope", [self getConfigValue:@"session_id" inGroup:@"session"]]];
		NSLog(@"RW: create_envelope: %@", [requestURL debugDescription]);
		NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
		
		AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
			
			NSString *envelope_id = [NSString stringWithFormat:@"%@", [JSON valueForKeyPath:@"envelope_id"]];
			NSLog(@"RW: envelope_id=%@", envelope_id);
			
			[self createEnvelopeSuccess:envelope_id];
			
			if ((envelope_id == nil) || [envelope_id isEqualToString:@""]) {
				[self submitFileFailure:reference error:nil];
			} else {
				
				// add_asset_to_envelope
				NSURL* requestURL2 = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&envelope_id=%@&latitude=%@&longitude=%@&tags=%@&client_time=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"add_asset_to_envelope", envelope_id, [self doubleToStringWithZeroAsEmptyString:latitude], [self doubleToStringWithZeroAsEmptyString:longitude], tags, clientTimeString]];
				NSLog(@"RW: add_asset_to_envelope: %@", [requestURL2 debugDescription]);
				AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:requestURL2];
				NSMutableURLRequest *request2 = [httpClient multipartFormRequestWithMethod:@"POST" path:@"" parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
					NSError *error = nil;
					BOOL appended = [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath isDirectory:NO] name:@"file" /*[filePath lastPathComponent]*/ error:&error];
					NSLog(@"RW: file appended %i %@", appended, [error localizedDescription]);
				}];
				
				AFJSONRequestOperation *operation2 = [AFJSONRequestOperation JSONRequestOperationWithRequest:request2 success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
					[self addAssetToEnvelopeSuccess:envelope_id];
					[self submitFileSuccess:reference];
				} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
					[self addAssetToEnvelopeFailure:error];
					[self submitFileFailure:reference error:error];
				}];
				
				[operation2 setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
					NSLog(@"RW: Sent %d of %d bytes", totalBytesWritten, totalBytesExpectedToWrite);
				}];
				
				NSOperationQueue *queue2 = [[[NSOperationQueue alloc] init] autorelease];
				[queue2 addOperation:operation2];
			}
			
		} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
			[self createEnvelopeFailure:error];
			[self submitFileFailure:reference error:error];
		}];
		
		NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
		[queue addOperation:operation];
		
	} else { // we have an envelope id...use it

		NSLog(@"RW: Using envelope id: %@", envelopeID);

		// add_asset_to_envelope
		NSURL* requestURL2 = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&envelope_id=%@&latitude=%@&longitude=%@&tags=%@&client_time=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"add_asset_to_envelope", envelopeID, [self doubleToStringWithZeroAsEmptyString:latitude], [self doubleToStringWithZeroAsEmptyString:longitude], tags, clientTimeString]];
		NSLog(@"RW: add_asset_to_envelope: %@", [requestURL2 debugDescription]);
		AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:requestURL2];
		NSMutableURLRequest *request2 = [httpClient multipartFormRequestWithMethod:@"POST" path:@"" parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
			NSError *error = nil;
			BOOL appended = [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath isDirectory:NO] name:@"file" /*[filePath lastPathComponent]*/ error:&error];
			NSLog(@"RW: file appended %i %@", appended, [error localizedDescription]);
		}];
		
		AFJSONRequestOperation *operation2 = [AFJSONRequestOperation JSONRequestOperationWithRequest:request2 success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
			[self addAssetToEnvelopeSuccess:envelopeID];
			[self submitFileSuccess:reference];
		} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
			[self addAssetToEnvelopeFailure:error];
			[self submitFileFailure:reference error:error];
		}];
		
		[operation2 setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
			NSLog(@"RW: Sent %d of %d bytes", totalBytesWritten, totalBytesExpectedToWrite);
		}];
		
		NSOperationQueue *queue2 = [[[NSOperationQueue alloc] init] autorelease];
		[queue2 addOperation:operation2];

	}
	
}

- (void)submitFileSuccess:(id)reference {
	NSLog(@"RW: submitFileSuccess %@", reference);
	if (reference) {
		NSError *error = nil;
		AudioQueue *aq = reference;
		NSString *filePath = [[aq filePath] retain];
		
		// Once processed, delete the record
		[managedObjectContext deleteObject:aq];
        error = nil;
        if (![managedObjectContext save:&error]) {
            NSLog(@"RW: error deleting object from persistent store %@", [error localizedDescription]);
        }

		// Once processed, delete the file
		if ([[NSFileManager defaultManager] removeItemAtPath:filePath error:&error] == NO) {
			NSLog(@"RW: error deleting file %@ %@", [filePath lastPathComponent], [error localizedDescription]);
		}
		
		[filePath release];

		// release the object // no need to do this it seems (aka: crashes!)
		//[aq release];
	}
	
	[[UIApplication sharedApplication] endBackgroundTask:_bti];
	
	if ([[self delegate] respondsToSelector:@selector(rwUpdateActivity:)])
		[[self delegate] rwUpdateActivity:NO];
	if ([[self delegate] respondsToSelector:@selector(rwUpdateStatus:)])
		[[self delegate] rwUpdateStatus:[NSString stringWithFormat:NSLocalizedString(@"AUDIO_SUBMISSION_SUCCESSFUL", nil)]];
	if ([[self delegate] respondsToSelector:@selector(rwUpdateApplicationIconBadgeNumber:)])
		[[self delegate] rwUpdateApplicationIconBadgeNumber:[self numItemsInQueue]];
	
	self._processingItem = NO;
	
	[self logEvent:@"stop_upload" withData:@"true"];

}

- (void)submitFileFailure:(id)reference error:(NSError*)error { 
	NSLog(@"RW: submitFileFailure %@", [error localizedDescription]); 
	/*
	if (reference) {
		[reference release]; // release the object but don't delete stuff as we need to try again
	}
	*/
	
	[[UIApplication sharedApplication] endBackgroundTask:_bti];

	//[self alertOK:nil withMessage:[error localizedDescription]]; // suppress errors here, jsut silently try again

	if ([[self delegate] respondsToSelector:@selector(rwUpdateActivity:)])
		[[self delegate] rwUpdateActivity:NO];
	if ([[self delegate] respondsToSelector:@selector(rwUpdateStatus:)])
		[[self delegate] rwUpdateStatus:[NSString stringWithFormat:NSLocalizedString(@"AUDIO_SUBMISSION_ERROR", nil)]];

	self._processingItem = NO;

	[self logEvent:@"stop_upload" withData:@"false"];
	[self logEvent:@"client_error" withData:[NSString stringWithFormat:@"submitFileFailure %@", [error localizedDescription]]];
}


- (void)createEnvelopeSuccess:(NSString*)envelopeID {
	NSLog(@"RW: createEnvelopeSuccess");
	if ([[self delegate] respondsToSelector:@selector(rwCreateEnvelopeSuccess:)])
		[[self delegate] rwCreateEnvelopeSuccess:envelopeID];
	
	// Give the app an opportunity to share this envelope via Twitter/Facebook/etc
	if ([[self delegate] respondsToSelector:@selector(rwSharingMessage:url:)]) {
		NSString *sharing_message = [self getConfigValue:@"sharing_message"];
		NSString *sharing_url = [self getConfigValue:@"sharing_url"];
		[[self delegate] rwSharingMessage:sharing_message url:[sharing_url stringByReplacingOccurrencesOfString:@"[id]" withString:envelopeID]];
	}
}

- (void)createEnvelopeFailure:(NSError*)error {
	NSLog(@"RW: createEnvelopeFailure %@", [error localizedDescription]); 
	if ([[self delegate] respondsToSelector:@selector(rwCreateEnvelopeFailure:)])
		[[self delegate] rwCreateEnvelopeFailure:error];
	
	[self logEvent:@"client_error" withData:[NSString stringWithFormat:@"createEnvelopeFailure %@", [error localizedDescription]]];
}

- (void)addAssetToEnvelopeSuccess:(NSString*)envelopeID {
	NSLog(@"RW: addAssetToEnvelopeSuccess");
	if ([[self delegate] respondsToSelector:@selector(rwAddAssetToEnvelopeSuccess:)])
		[[self delegate] rwAddAssetToEnvelopeSuccess:envelopeID];
}

- (void)addAssetToEnvelopeFailure:(NSError*)error {
	NSLog(@"RW: addAssetToEnvelopeFailure %@", [error localizedDescription]); 
	if ([[self delegate] respondsToSelector:@selector(rwAddAssetToEnvelopeFailure:)])
		[[self delegate] rwAddAssetToEnvelopeFailure:error];

	[self logEvent:@"client_error" withData:[NSString stringWithFormat:@"addAssetToEnvelopeFailure %@", [error localizedDescription]]];
}



#pragma mark GPS methods

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	NSLog(@"RW: New Location: %@", [newLocation description]);
	
	// If listen is enabled we can modify stream when we get a new location
	BOOL listen_enabled = [[self getConfigValue:@"listen_enabled"] boolValue];
	if (listen_enabled) {
		[self modifyStream:newLocation];
	}
	
	// Send it to you delegate
	if ([[self delegate] respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)])
		[[self delegate] locationManager:manager didUpdateToLocation:newLocation fromLocation:oldLocation];
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	NSLog(@"RW: Location Error: %@", [error description]);

	// Send it to you delegate
	if ([[self delegate] respondsToSelector:@selector(locationManager:didFailWithError:)])
		[[self delegate] locationManager:manager didFailWithError:error];
}

#pragma mark Edit Tags methods

static NSInteger lastModalTagEditor = 0;

- (IBAction)doneEditingTags:(id)sender {
	[((UIViewController *)delegate) dismissModalViewControllerAnimated:YES];
	
	if (lastModalTagEditor == 1) { // LISTEN TAGS send modify_stream
		NSLog(@"RW: done editing listen tags");
		
		// If listen is enabled we can modify stream when we get a new location
		BOOL listen_enabled = [[self getConfigValue:@"listen_enabled"] boolValue];
		if (listen_enabled) {
			[self modifyStream:_locationManager.location];
		}
		
	} else if (lastModalTagEditor == 2) { // SPEAK TAGS do nothing
		NSLog(@"RW: done editing speak tags");
	}
	
}

- (void)editListenTags {
	lastModalTagEditor = 1;
	[self editTags:@"tags_listen" withTitle:NSLocalizedString(@"LISTEN_TAGS_TITLE", nil)];
}

- (void)editSpeakTags {
	lastModalTagEditor = 2;
	[self editTags:@"tags_speak" withTitle:NSLocalizedString(@"SPEAK_TAGS_TITLE", nil)];	
}

- (void)editTags:(NSString*)type withTitle:(NSString*)title {

	// Load the tag array for this particular mode/type
	NSArray *tags = [[NSUserDefaults standardUserDefaults] objectForKey:type];
	if ((tags == nil) || ([tags count] == 0)) {
		[self alertOK:NSLocalizedString(@"NO_TAGS_ERROR", nil) withMessage:NSLocalizedString(@"NO_TAGS_DETAILS_ERROR", nil)];
		[self logEvent:@"client_error" withData:@"User tried to edit tags before having any tags to edit. App has never been online."];
		return;
	}
	
	// Tab controller
	UITabBarController* tabBarController = [[UITabBarController alloc] init];
	tabBarController.navigationItem.title = title;
	
	// Add gesture recognizer to allow swiping left and right through tabs
	UISwipeGestureRecognizer *swipeGestureLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGestureLeft:)];
	[swipeGestureLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [tabBarController.view addGestureRecognizer:swipeGestureLeft];
    [swipeGestureLeft release];
	
    UISwipeGestureRecognizer *swipeGestureRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGestureRight:)];
	[swipeGestureRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [tabBarController.view addGestureRecognizer:swipeGestureRight];
    [swipeGestureRight release];

	// Array of controllers
	NSMutableArray *controllers = [[NSMutableArray arrayWithCapacity:[tags count]] retain];
	
	// Enumerate tags
	[tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSDictionary *tag = obj;
		
		// Table View controller
		RWTagViewController *tagvc = [[RWTagViewController alloc] initWithStyle:UITableViewStylePlain];
		tagvc.title = [tag objectForKey:@"name"];
		tagvc.tabBarItem.image = [UIImage imageNamed:@"rw_tag.png"];
		tagvc.view.backgroundColor = [UIColor whiteColor];
		[tagvc setTag:tag];
		
		// Figure out the name of the current stored settings ie: listen_age_current and pass it to the view controller so it can handle interaction and management
		NSString *code = [tag objectForKey:@"code"];
		NSString *defaultsKeyName = [NSString stringWithFormat:@"%@_%@_current", type, code];
		[tagvc setCurrentKeyName:defaultsKeyName];
		
		// Add to array
		[controllers addObject:tagvc];
		[tagvc release];
	}];
	
	// Assign them to the tab controller
	tabBarController.viewControllers = controllers;
	[controllers release];
	
	// Nav controller for Done button
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:tabBarController];
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneEditingTags:)];          
	tabBarController.navigationItem.rightBarButtonItem = doneButton;
	[doneButton release];
	
	// Display modally
	[((UIViewController *)delegate) presentModalViewController:navigationController animated:YES];
	
	// Cleanup
	[tabBarController release];
	[navigationController release];
}

- (IBAction)handleSwipeGestureLeft:(UIGestureRecognizer *)sender {
	UILayoutContainerView* view = (UILayoutContainerView*)[sender view];
	UITabBarController* tabBarController = (UITabBarController*)[view delegate];
	NSUInteger count = [[tabBarController viewControllers] count];
	NSUInteger current = [tabBarController selectedIndex];
	if (current+1 < count)
		tabBarController.selectedIndex++;
}

- (IBAction)handleSwipeGestureRight:(UIGestureRecognizer *)sender {
	UILayoutContainerView* view = (UILayoutContainerView*)[sender view];
	UITabBarController* tabBarController = (UITabBarController*)[view delegate];
	NSUInteger current = [tabBarController selectedIndex];
	if (current > 0)
		tabBarController.selectedIndex--;
}

#pragma mark Reachability methods

// Called by Reachability whenever status changes
- (void)reachabilityChanged:(NSNotification*)note {
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	NSArray *sa = [NSArray arrayWithObjects:NSLocalizedString(@"NETWORK_NOT_REACHABLE", nil), NSLocalizedString(@"NETWORK_REACHABLE_VIA_WIFI", nil), NSLocalizedString(@"NETWORK_REACHABLE_VIA_WWAN", nil), nil];
	NetworkStatus netStatus = [_hostReach currentReachabilityStatus];
	
	// if we are online we can kick things off, if we have yet to kick things off
	if ((netStatus != NotReachable) && (self._configed == NO)) {
		[self config];
	} else if ((netStatus == NotReachable) && (self._offlineConfiged == NO)) {
		[self offlineConfig];
	}
	
	// Let the app know the reachability status
	if ([[self delegate] respondsToSelector:@selector(rwUpdateStatus:)])
		[[self delegate] rwUpdateStatus:[NSString stringWithFormat:[sa objectAtIndex:netStatus]]];
}

// Returns YES if no network reachability, NO otherwise
- (BOOL)offline {
	NetworkStatus netStatus = [_hostReach currentReachabilityStatus];
	return (netStatus == NotReachable);
}

// Returns YES if network reachability, NO otherwise
- (BOOL)online {
	NetworkStatus netStatus = [_hostReach currentReachabilityStatus];
	return (netStatus != NotReachable);
}

// Returns YES if we have a device_id which means we connected to the server at least once
- (BOOL)connectedAtLeastOnce {
	NSString *device_id = [self getConfigValue:@"device_id" inGroup:@"device"];
	return ((device_id != nil) && (![device_id isEqualToString:@""]));
}

#pragma mark Logging methods
// see http://www.roundware.org/trac/wiki/DataAnalysis

- (void)logEvent:(NSString*)event {
	[self logEvent:event withData:@""];
}

- (void)logEvent:(NSString*)event withData:(NSString*)data {
	if (_configed == NO || [self offline]) { 
		NSLog(@"RW: skipping logEvent because we haven't configed yet or are offline");
		return;
	}
	
	//NSLog(@"DEFAULT TIME: %@", [NSDate date]);
	
	// Convert our date to RFC822 format: Mon, 15 Aug 05 15:52:01 +0000
	// see http://www.alexcurylo.com/blog/2009/01/29/nsdateformatter-formatting/ for details
	/*
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"ccc, dd MMM yy HH:mm:ss Z"];
	NSString *clientTimeString = [[dateFormatter stringFromDate:[NSDate date]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	[dateFormatter release];
	*/
	
	NSString *clientTimeString = [[[NSDate date] description] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];

	NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&session_id=%@&event_type=%@&data=%@&latitude=%@&longitude=%@&client_time=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"log_event", [self getConfigValue:@"session_id" inGroup:@"session"], event, [data stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [self doubleToStringWithZeroAsEmptyString:self._lastRecordedLocation.coordinate.latitude], [self doubleToStringWithZeroAsEmptyString:self._lastRecordedLocation.coordinate.longitude], clientTimeString]];
	NSLog(@"RW: log_event: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		[self logEventSuccess];
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		[self logEventFailure:error];
	}];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}

- (void)logEventSuccess {
	NSLog(@"RW: logEventSuccess");
	if ([[self delegate] respondsToSelector:@selector(rwLogEventSuccess)])
		[[self delegate] rwLogEventSuccess];
}

- (void)logEventFailure:(NSError*)error {
	NSLog(@"RW: logEventFailure %@", [error localizedDescription]); 
	if ([[self delegate] respondsToSelector:@selector(rwLogEventFailure:)])
		[[self delegate] rwLogEventFailure:error];
	
	// we do NOT log logEvent failures! Can you say endless loop?!?!
}


#pragma mark Singleton methods

+ (id)sharedRWFramework {
    @synchronized(self) { // Make this allocation thread safe so we don't end up with dual-singletons!
        if (sharedRWFramework == nil)
            sharedRWFramework = [[super allocWithZone:NULL] init];
    }
    return sharedRWFramework;
}

- (id)init {
    if (self = [super init]) {
        // Is 4.0 or later? (must have)
        _systemSupported = [[[UIDevice currentDevice] systemVersion] floatValue] >= MIN_SYSTEM_VERSION;
		NSLog(@"RW: _systemSupported = %i", _systemSupported);
      
        // Is multitasking supported? (we need this for background tasks, playing audio, uploading, etc.)
        _multitaskingSupported = [[UIDevice currentDevice] isMultitaskingSupported];
  		NSLog(@"RW: isMultitaskingSupported = %i", _multitaskingSupported);
      
        // Location services enabled on the device (if we use them anyway it will prompt user to enable them globally)
        _locationServicesEnabled = [CLLocationManager locationServicesEnabled];
		NSLog(@"RW: locationServicesEnabled = %i", _locationServicesEnabled);
		
		// Initialized
		_recordingQueued = NO;
		_processingItem = NO;
		_bti = UIBackgroundTaskInvalid;
		
		// AVPlayer
		_player = nil;
		playing = NO;
		
    }
    return self;
}

- (void)dealloc {
    // This is never called as the singleton is around for the entire application life but it's good measure to keep it in case we ever move away from being a singleton.
	
    [super dealloc];
}

// Do not generate a new instance, just return the one we have
+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedRWFramework] retain];
}

// Do not generate multiple copies of the singleton
- (id)copyWithZone:(NSZone *)zone {
    return self;
}

// We don't retain because we only ever have one copy that survives forever
- (id)retain {
    return self;
}

// Retain count is invalid so we return a number that denotes an object that cannot be released
- (unsigned)retainCount {
    return NSUIntegerMax; 
}

// We don't release because we only ever have one copy that survives forever
- (oneway void)release {
    // never release
}

// Do nothing but return ourselves
- (id)autorelease {
    return self;
}


#pragma Misc
/*
 Configuration values are stored locally in RWFramework.plist. However, the get_config call to the server also returns a
 list of configuration parameters that may be unique and/or may overide values in our local plist. These configuration 
 parameters are stored in a hierarchical NSDictionary (via JSON) by group name (project, session, device) - project being
 the default. When the app needs to get the value of a configuration variable it first looks for an overide. If one is not
 found then it gets our own copy of it.
 */
- (id)getConfigValue:(NSString*)aKey { // by default look in "project" container for overides
	return [self getConfigValue:aKey inGroup:@"project"];
}

- (id)getConfigValue:(NSString*)aKey inGroup:(NSString*)aGroup {
	
	// First look for overides from the server
	id g = [[NSUserDefaults standardUserDefaults] objectForKey:aGroup];
	if (g) {
		id v = [g valueForKey:aKey];
		if (v) {
			NSLog(@"RW: O %@.%@ = %@", aGroup, aKey, v);
			return v;
		}
	}
	
	// No overide so pull from our own RWFramework.plist instead
	NSString *path = [[NSBundle mainBundle] pathForResource: @"RWFramework" ofType:@"plist"];
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
	id def_obj = [d objectForKey:aKey];
	NSLog(@"RW: D %@.%@ = %@", aGroup, aKey, def_obj);
	return def_obj;
}

/**
 Returns the path to the framework's documents directory.
 */
- (NSString *)frameworkDocumentsDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

/* Return some informative information */
- (NSString *)info {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"AudioQueue" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor release];
	
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		NSLog(@"RW: executeFetchRequest error %@", [error localizedDescription]);
	}
	
	NSString *s = [NSString stringWithFormat:@"Network is %@\n%d in queue\n", [self offline] ? @"offline" : @"online", [mutableFetchResults count]];
	for (AudioQueue *aq in mutableFetchResults) {
		s = [s stringByAppendingFormat:@"%@\n", [[aq filePath] lastPathComponent]];
	}
	[mutableFetchResults release];
	[request release];
	
	return s;
}

- (void)alertOK:(NSString*)title withMessage:(NSString*)message {
	if (!title) 
		title = [NSString stringWithFormat:NSLocalizedString(@"ROUNDWARE_ALERT", nil)];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK_BUTTON", nil), nil];
	[alert show];
	[alert release];
}

- (NSString*)doubleToStringWithZeroAsEmptyString:(double)d {
	if (d == 0.) return @"";
	return [[NSNumber numberWithDouble:d] stringValue];
}


@end
