//
//  RWFramework.h
//  RWExample
//
//  Created by Joe Zobkiw on 10/23/11.
//  Copyright (c) 2011 Earsmack Music. All rights reserved.
//
/*
	RWFramework is the interface to Roundware functionality
*/

#import <CoreLocation/CoreLocation.h>
#import "AFNetworking.h"
#import "JSONKit.h"

#define MIN_SYSTEM_VERSION  (4.0)

#pragma mark RWFrameworkDelegate

/*
 RWFrameworkDelegate allows simple notifications to the delegate about the general status of the framework
*/
@protocol RWFrameworkDelegate
@required
	// none required but your app will be pretty boring without a few implemented :-)

@optional
	// INITIALIZATION & OVERALL STATUS ------------------------------------------------------------------
	// Sent when configuration has been successful
	- (void)rwConfigSuccess;

	// Sent when OFFLINE configuration has been successful
	- (void)rwOfflineConfigSuccess;

	// Sent when configuration has failed with details of the failure
	- (void)rwConfigFailure:(NSError*)error;

	// Sent when OFFLINE configuration has failed with details of the failure
	- (void)rwOfflineConfigFailure:(NSError*)error;

	// Sent when get_tags has been successful
	- (void)rwGetTagsSuccess;

	// Sent when get_tags has failed with details of the failure
	- (void)rwGetTagsFailure:(NSError*)error;

	// Sent when modify_stream has been successful
	- (void)rwModifyStreamSuccess;

	// Sent when modify_stream has failed with details of the failure
	- (void)rwModifyStreamFailure:(NSError*)error;

	// Sent when create_envelope has been successful
	- (void)rwCreateEnvelopeSuccess:(NSString*)envelopeID;

	// Sent when create_envelope has failed with details of the failure
	- (void)rwCreateEnvelopeFailure:(NSError*)error;

	// Sent when add_asset_to_envelope has been successful
	- (void)rwAddAssetToEnvelopeSuccess:(NSString*)envelopeID;

	// Sent when add_asset_to_envelope has failed with details of the failure
	- (void)rwAddAssetToEnvelopeFailure:(NSError*)error;
	
	// Sent when an envelope has been created and a sharing URL can be formed
	- (void)rwSharingMessage:(NSString*)message url:(NSString*)url;

	// LISTEN ------------------------------------------------------------------
	// Sent when a stream has been acquired and can be played. Clients should enable their Play buttons
	- (void)rwReadyToPlay; // requestStreamSuccess in framework

	// Sent when a stream could not be required and therefore can not be played. Clients should disable their Play buttons
	- (void)rwUnableToPlay:(NSError*)error; // requestStreamFailure in framework

	// Sent to the server when the GPS has not updated in at least 15 seconds
	- (void)rwHeartbeatSuccess;

	// Sent in the case that sending the heartbeat failed
	- (void)rwHeartbeatFailure:(NSError*)error;

	// RECORD ------------------------------------------------------------------
	// Sent when the framework determines that recording is possibly (via config)
	- (void)rwReadyToRecord;

	// Returns the current version of the server API
	- (void)rwCurrentVersion:(NSString*)version;
	
	// UI/STATUS ------------------------------------------------------------------
	// Called when something occurs that may require a user interface update. progressPercentage pertains to recording when isRecording is YES or playback when isPlayingBack is YES otherwise it is set to 0.
	- (void)rwUpdateUI:(float)progress;

	// The number of items in the queue waiting to be uploaded
	- (void)rwUpdateApplicationIconBadgeNumber:(NSUInteger)count;

	// A user-readable message that can be passed on as status information
	- (void)rwUpdateStatus:(NSString*)message;
	
	// Sent when network activity changes state (ie: we are uploading a file)
	- (void)rwUpdateActivity:(BOOL)uploading;

	// LOCATION ------------------------------------------------------------------
	// Standard CLLocationManagerDelegate methods passed through to client
	- (void)locationManager:(CLLocationManager *)manager
		didUpdateToLocation:(CLLocation *)newLocation
			   fromLocation:(CLLocation *)oldLocation;

	- (void)locationManager:(CLLocationManager *)manager
		   didFailWithError:(NSError *)error;

	// LOGGING ------------------------------------------------------------------
	// Sent to the server when an event is logged
	- (void)rwLogEventSuccess;

	// Sent in the case that sending the logevent failed
	- (void)rwLogEventFailure:(NSError*)error;

@end

@class Reachability;

@interface RWFramework : NSObject <CLLocationManagerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate> {

    @private
		// status
		BOOL _systemSupported;
		BOOL _multitaskingSupported;
		BOOL _locationServicesEnabled;

		// config
		BOOL _offlineConfiged;
		BOOL _configed;

		// play
		BOOL	_requestStreamSucceeded;
		NSURL	*_streamURL;
		AVPlayer *_player;
	
		// record
		AVAudioRecorder *_soundRecorder;
		AVAudioPlayer	*_soundPlayer;
		NSTimer			*_recordTimer;
		CLLocation		*_lastRecordedLocation;
	
		// queue
		BOOL			_recordingQueued;
		BOOL			_processingItem;
		NSTimer			*_queueTimer;
		UIBackgroundTaskIdentifier _bti;
	
		// GPS
		CLLocationManager *_locationManager;
		NSTimer *_heartbeatTimer;
  
		// Reachability
		Reachability* _hostReach;

   @public
		BOOL playing;
		id	<RWFrameworkDelegate> delegate;
		NSManagedObjectContext *managedObjectContext;	    

}

// private
@property (nonatomic, assign) BOOL _systemSupported;
@property (nonatomic, assign) BOOL _multitaskingSupported;
@property (nonatomic, assign) BOOL _locationServicesEnabled;

@property (nonatomic, assign) BOOL _offlineConfiged;
@property (nonatomic, assign) BOOL _configed;

@property (nonatomic, assign) BOOL _requestStreamSucceeded;
@property (nonatomic, retain) NSURL	*_streamURL;
@property (nonatomic, retain) AVPlayer *_player;

@property (nonatomic,retain) AVAudioRecorder *_soundRecorder;
@property (nonatomic,retain) AVAudioPlayer *_soundPlayer;
@property (assign) NSTimer *_recordTimer;
@property (nonatomic, retain) CLLocation *_lastRecordedLocation;

@property (nonatomic, assign) BOOL _recordingQueued;
@property (nonatomic, assign) BOOL _processingItem;
@property (assign) NSTimer *_queueTimer;
@property (assign) UIBackgroundTaskIdentifier _bti;

@property (nonatomic, retain) CLLocationManager *_locationManager;
@property (assign) NSTimer *_heartbeatTimer;

@property (nonatomic, retain) Reachability* _hostReach;

// public
@property (readonly, getter=isPlaying) BOOL playing;
@property (retain) id delegate;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;	    

#pragma mark Start method

- (void)start;

#pragma mark Stream control methods

- (AVPlayer*)player;
- (void)play;
- (void)pause;
- (BOOL)canPlay;

#pragma mark Recording control methods

- (void)startRecording;
- (void)stopRecording;
- (void)playbackRecording;
- (void)stopPlayback;
- (BOOL)isRecording;
- (BOOL)hasRecording;
- (BOOL)isPlayingBack;
- (BOOL)canRecord;

#pragma mark Submission methods

- (void)submit;

#pragma mark Edit Tags methods

- (void)editListenTags;
- (void)editSpeakTags;

#pragma mark Reachability

- (BOOL)offline;
- (BOOL)online;
- (BOOL)connectedAtLeastOnce;

#pragma mark Singleton methods

+ (id)sharedRWFramework;

#pragma mark Misc

- (NSString *)info;


@end

