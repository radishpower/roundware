//
//  RWFrameworkBase.m
//  RWExample
//
//  Created by Joe Zobkiw on 10/31/11.
//  Copyright (c) 2011 Earsmack Music. All rights reserved.
//

#import "RWFrameworkBase.h"

// Our singleton
static RWFrameworkBase *sharedRWFrameworkBase = nil;

#pragma mark Utility

static NSError* make_error(NSString *description, NSInteger code);
static NSError* make_error(NSString *description, NSInteger code) {
	NSMutableDictionary* details = [NSMutableDictionary dictionary];
	[details setValue:description forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:@"org.roundware.RWFrameworkBase" code:code userInfo:details];
}

#pragma mark RWFrameworkBase

@implementation RWFrameworkBase

@synthesize delegate;
@synthesize started;
@synthesize requestStreamSucceeded;

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
			NSLog(@"RWB: O %@.%@ = %@", aGroup, aKey, v);
			return v;
		}
	}
	
	// No overide so pull from our own RWFramework.plist instead
	NSString *path = [[NSBundle mainBundle] pathForResource: @"RWFramework" ofType:@"plist"];
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
	id def_obj = [d objectForKey:aKey];
	NSLog(@"RWB: D %@.%@ = %@", aGroup, aKey, def_obj);
	return def_obj;
}

/*
This method is called to initialize the base framework. This kicks everything else off. 
*/

- (void)start {
	
	// This way we can check to only start ourselves once
	if (started == YES) { 
		NSLog(@"RWB: skipping start because we've already started");
		return;
	}
	started = YES;
	
	// Call get_config passing a device id if we have one
	NSString *device_id = [self getConfigValue:@"device_id" inGroup:@"device"];
	NSURL* requestURL = nil;
	requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&project_id=%@&device_id=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"get_config", [self getConfigValue:@"project_id"], device_id ? device_id : @""]];
	NSLog(@"RWB: get_config: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		
		// When the JSON returns we write it out to NSUSerDefaults for easy access, this also makes it stay around between app launches
		//NSLog(@"RWB: JSON = %@", [JSON debugDescription]);
		for (NSDictionary *d in JSON) {
			//NSLog(@"RWB: d=%@", [d debugDescription]);
			[d enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
				NSLog(@"RWB: writing to defaults: %@ = %@", key, object);
				[[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
			}];
		}
		
		// Tell the delegate that this was successful.
		[[self delegate] configSuccess];
		
		// Load the tags
		[self getTags];
		
		// A future enhancement may be to use notifications instead of delegate method for this (and other) communication - this is here as a placeholder/reminder
		//[[NSNotificationCenter defaultCenter] postNotificationName:@"get_config_success" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
		
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		
		// we had a failure, pass it up the chain to be handled and displayed to the user
		[[self delegate] configFailure:error];
		
		// A future enhancement may be to use notifications instead of delegate method for this (and other) communication - this is here as a placeholder/reminder
		//[[NSNotificationCenter defaultCenter] postNotificationName:@"get_config_failure" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, @"error", nil]];
	}];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}

/*
 Get the tags for the project
 */
- (void)getTags {
	if (started == NO) { 
		NSLog(@"RWB: skipping getTags because we haven't started yet");
		return;
	}
	
	NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&project_id=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"get_tags", [self getConfigValue:@"project_id"]]];
	NSLog(@"RWB: get_tags: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		
		// When the JSON returns we write it out to NSUSerDefaults for easy access, this also makes it stay around between app launches
		NSLog(@"RWB: JSON = %@", [JSON debugDescription]);
		
		NSArray *listen = [JSON objectForKey:@"listen"];
		NSLog(@"RWB: listen is a %@ %@", [listen class], [listen debugDescription]);
		[[NSUserDefaults standardUserDefaults] setObject:listen forKey:@"tags_listen"];
		
		NSArray *speak = [JSON objectForKey:@"speak"];
		NSLog(@"RWB: speak is a %@ %@", [speak class], [speak debugDescription]);
		[[NSUserDefaults standardUserDefaults] setObject:speak forKey:@"tags_speak"];
		
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
		
		//NSLog(@"RWB: %@", [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] debugDescription]);
		
		[[self delegate] getTagsSuccess];
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		[[self delegate] getTagsFailure:error];
	}];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}

/*
Request a stream URL to be used and store it - TBD - how to handle when this stream expires!
*/
- (void)requestStream {
	if (started == NO) { 
		NSLog(@"RWB: skipping requestStream because we haven't started yet");
		return;
	}

	NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&session_id=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"request_stream", [self getConfigValue:@"session_id" inGroup:@"session"]]];
	NSLog(@"RWB: request_stream: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		requestStreamSucceeded = YES;
		[[self delegate] requestStreamSuccess:[NSURL URLWithString:[JSON valueForKeyPath:@"stream_url"]]];
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		NSLog(@"RWB: request: %@", [request description]);
		NSLog(@"RWB: response: %@", [response description]);
		NSLog(@"RWB: error: %@", [error description]);
		NSLog(@"RWB: JSON: %@", [JSON description]);
		[[self delegate] requestStreamFailure:error];
	}];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}

/*
heartbeat is called via NSTimer and keeps things alive
*/
- (void)heartbeat:(CLLocation *)newLocation {
	if (started == NO) { 
		NSLog(@"RWB: skipping heartbeat because we haven't started yet");
		return;
	}
	
	NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&session_id=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"heartbeat", [self getConfigValue:@"session_id" inGroup:@"session"]]];
	NSLog(@"RWB: heartbeat: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		[[self delegate] heartbeatSuccess];
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		[[self delegate] heartbeatFailure:error];
	}];
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}

/*
modifyStream is called when location changes and listen_enabled = YES
*/
- (void)modifyStream:(CLLocation *)newLocation {
	if (started == NO) { 
		NSLog(@"RWB: skipping modifyStream because we haven't started yet");
		return;
	}
	if (requestStreamSucceeded == NO) { 
		NSLog(@"RWB: skipping modify_stream because request_stream has not yet succeeded");
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
	
	NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&session_id=%@&latitude=%f&longitude=%f&tags=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"modify_stream", [self getConfigValue:@"session_id" inGroup:@"session"], newLocation.coordinate.latitude, newLocation.coordinate.longitude, tags]];
	[tags release];
	NSLog(@"RWB: modify_stream: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		[[self delegate] modifyStreamSuccess];
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		[[self delegate] modifyStreamFailure:error];
	}];

	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}

/*
submitFile is called by the queue timer to begin the process of uploading a single file at a time.
*/
- (void)submitFile:(NSString*)filePath latitude:(double)latitude longitude:(double)longitude tags:(NSString*)tags reference:(id)reference {
	if (started == NO) { 
		NSLog(@"RWB: skipping submitFile because we haven't started yet");
		return;
	}
	
	// create envelope
	NSURL* requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&session_id=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"create_envelope", [self getConfigValue:@"session_id" inGroup:@"session"]]];
	NSLog(@"RWB: create_envelope: %@", [requestURL debugDescription]);
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
		
		NSString *envelope_id = [NSString stringWithFormat:@"%@", [JSON valueForKeyPath:@"envelope_id"]];
		NSLog(@"RWB: envelope_id=%@", envelope_id);

		[[self delegate] createEnvelopeSuccess:envelope_id];

		if ([envelope_id isEqualToString:@""]) {
			[[self delegate] submitFileFailure:reference error:nil];
		} else {
			
			// add_asset_to_envelope
			NSURL* requestURL2 = [NSURL URLWithString:[NSString stringWithFormat:@"%@&operation=%@&envelope_id=%@&latitude=%@&longitude=%@&tags=%@", [[NSURL URLWithString: [NSString stringWithFormat:@"%@", [self getConfigValue:@"base_url"]]] absoluteString], @"add_asset_to_envelope", envelope_id, [NSNumber numberWithDouble:latitude], [NSNumber numberWithDouble:longitude], tags]];
			NSLog(@"RWB: add_asset_to_envelope: %@", [requestURL2 debugDescription]);
			AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:requestURL2];
			NSMutableURLRequest *request2 = [httpClient multipartFormRequestWithMethod:@"POST" path:@"" parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
				NSError *error = nil;
				BOOL appended = [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath isDirectory:NO] name:@"file" /*[filePath lastPathComponent]*/ error:&error];
				NSLog(@"RWB: file appended %i %@", appended, [error localizedDescription]);
			}];

			AFJSONRequestOperation *operation2 = [AFJSONRequestOperation JSONRequestOperationWithRequest:request2 success:^(NSURLRequest *request, NSURLResponse *response, id JSON) {
				[[self delegate] addAssetToEnvelopeSuccess:envelope_id];
				[[self delegate] submitFileSuccess:reference];
			} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
				[[self delegate] addAssetToEnvelopeFailure:error];
				[[self delegate] submitFileFailure:reference error:error];
			}];
			
			[operation2 setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
				NSLog(@"RWB: Sent %d of %d bytes", totalBytesWritten, totalBytesExpectedToWrite);
			}];
			
			NSOperationQueue *queue2 = [[[NSOperationQueue alloc] init] autorelease];
			[queue2 addOperation:operation2];
		}
		
	} failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON) {
		[[self delegate] createEnvelopeFailure:error];
		[[self delegate] submitFileFailure:reference error:error];
	}];

	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}

#pragma mark Singleton methods

+ (id)sharedRWFrameworkBase {
    @synchronized(self) { // Make this allocation thread safe so we don't end up with dual-singletons!
        if (sharedRWFrameworkBase == nil)
            sharedRWFrameworkBase = [[super allocWithZone:NULL] init];
    }
    return sharedRWFrameworkBase;
}

- (id)init {
    if (self = [super init]) {
		requestStreamSucceeded = NO;
		started = NO;
    }
    return self;
}

- (void)dealloc {
    // This is never called as the singleton is around for the entire application life but it's good measure to keep it in case we ever move away from being a singleton.
    
    [super dealloc];
}

// Do not generate a new instance, just return the one we have
+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedRWFrameworkBase] retain];
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

@end
