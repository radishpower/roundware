//
//  ScapesAppDelegate.h
//  Scapes
//
//  Created by Joe Zobkiw on 12/3/09.
//  Copyright Earsmack Music 2009. All rights reserved.
//

@class SoundEffect;
@class AudioStreamer;
@class ASIHTTPRequest;

@interface ScapesAppDelegate : NSObject <UIApplicationDelegate, CLLocationManagerDelegate, AVAudioSessionDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;

	// Session
	NSString *sessionID;

	// Audio
	AudioStreamer *streamer;
	NSString *streamURL;
	BOOL audioStreamerIsSupposedToBePlaying;
	BOOL requestedStreamURL;
	UInt32 audioFormat;
	int maxRecordingTimeSeconds;
	
	// Network
	BOOL networkAvailable;
    int networkTryAgainCount;

	// Flags
	BOOL agreed;
	
	// Questions
	NSDictionary *listenQuestions;
	NSDictionary *speakQuestions;
	NSDictionary *jsonDict;
    
	// Demographics
	NSDictionary *demographicChoices;

	// GPS
	CLLocationManager *locationManager;
	CLLocationCoordinate2D recordedCoordinate;
	NSTimer *gpsIdleTimer;
	BOOL lastGPSResult;
	
	// Debug
	SoundEffect *gpsPingSoundEffect;
	
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@property (nonatomic, retain) NSString *sessionID;
@property (nonatomic, retain) AudioStreamer *streamer;
@property (nonatomic, retain) NSString *streamURL;
@property (nonatomic) BOOL audioStreamerIsSupposedToBePlaying;
@property (nonatomic) BOOL requestedStreamURL;
@property (nonatomic) BOOL networkAvailable;
@property (nonatomic) int networkTryAgainCount;
@property (nonatomic) BOOL agreed;
@property (nonatomic) UInt32 audioFormat;
@property (nonatomic) int maxRecordingTimeSeconds;
@property (nonatomic, retain) NSDictionary *listenQuestions;
@property (nonatomic, retain) NSDictionary *speakQuestions;
@property (nonatomic, retain) NSDictionary *jsonDict;
@property (nonatomic, retain) NSDictionary *demographicChoices;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic) CLLocationCoordinate2D recordedCoordinate;
@property (nonatomic, retain) NSTimer *gpsIdleTimer;
@property (nonatomic) BOOL lastGPSResult;
@property (nonatomic, retain) SoundEffect *gpsPingSoundEffect;

- (void)playGPSPingSoundEffect;

- (void)gpsIdleTimerFireMethod:(NSTimer*)theTimer;

- (void)startAudioStreamer;
- (void)stopAudioStreamer;
- (void)toggleAudioStreamer;
- (BOOL)isAudioStreamerPlaying;
- (void)streamerError;

- (NSString*)convertEventTypeToString:(NSInteger)eventID;
- (void)submitEvent:(NSInteger)eventID;
- (void)rememberRecordedCoordinate;

- (void)requestFinished_startsession:(ASIHTTPRequest *)request;
- (void)requestFailed_startsession:(ASIHTTPRequest *)request;
- (void)requestFinished:(ASIHTTPRequest *)request;

- (void)requestFinished_gps:(ASIHTTPRequest *)request;

@end

