//
//  RWFrameworkBase.h
//  RWExample
//
//  Created by Joe Zobkiw on 10/31/11.
//  Copyright (c) 2011 Earsmack Music. All rights reserved.
//
/*
	"Communicate & Cache"
	RWFrameworkBase handles direct communication to the server implementing the server API as defined

 "Server Comms"
 RWFrameworkBaseDelegate allows detailed notifications to the delegate about the status of specific calls throughout the framework and communicates directly with the server.
 First pass focuses on
 - editable what needs to be editable (plist)
 - accessible what needs to be accessible (protocols, public variables)
 - defaults are what makes roundware work best and most optimized
 Phase II can include
 - more detailed access to nitty-gritty
 */

#import "AFNetworking.h"
#import "JSONKit.h"

#pragma mark RWFrameworkBaseDelegate

@protocol RWFrameworkBaseDelegate
@optional
@required
	- (void)configSuccess;
	- (void)configFailure:(NSError*)error;
	- (void)getTagsSuccess;
	- (void)getTagsFailure:(NSError*)error;
	- (void)requestStreamSuccess:(NSURL*)url;
	- (void)requestStreamFailure:(NSError*)error;
	- (void)modifyStreamSuccess;
	- (void)modifyStreamFailure:(NSError*)error;
	- (void)heartbeatSuccess;
	- (void)heartbeatFailure:(NSError*)error;
	- (void)createEnvelopeSuccess:(NSString*)envelopeID;
	- (void)createEnvelopeFailure:(NSError*)error;
	- (void)addAssetToEnvelopeSuccess:(NSString*)envelopeID;
	- (void)addAssetToEnvelopeFailure:(NSError*)error;
	- (void)submitFileSuccess:(id)reference;
	- (void)submitFileFailure:(id)reference error:(NSError*)error;
@end

#pragma mark RWFrameworkBase

@interface RWFrameworkBase : NSObject {
@private
	id			<RWFrameworkBaseDelegate> delegate;
	BOOL		requestStreamSucceeded;
@public
	BOOL		started;
}

@property (retain)				id			delegate;
@property (nonatomic, assign)	BOOL		started;
@property (nonatomic, assign)	BOOL		requestStreamSucceeded;

+ (id)sharedRWFrameworkBase;

- (id)getConfigValue:(NSString*)aKey;
- (id)getConfigValue:(NSString*)aKey inGroup:(NSString*)aGroup;

- (void)start;
- (void)getTags;
- (void)requestStream;
- (void)modifyStream:(CLLocation *)newLocation;
- (void)heartbeat:(CLLocation *)newLocation;
- (void)submitFile:(NSString*)filePath latitude:(double)latitude longitude:(double)longitude tags:(NSString*)tags reference:(id)reference;

@end
