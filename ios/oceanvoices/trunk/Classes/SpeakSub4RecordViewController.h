//
//  SpeakSub4RecordViewController.h
//  Ocean Voices
//
//  Created by Joe Zobkiw on 12/23/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CALevelMeter;
@class SpeakViewController;

@interface SpeakSub4RecordViewController : UIViewController <AVAudioSessionDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate> {
	IBOutlet UILabel *textLabel;
	IBOutlet UILabel *countdownLabel;
	IBOutlet UIImageView *instructionLabel;
	IBOutlet CALevelMeter *levelMeter;
	
	NSTimer *repeatingTimer;
	NSTimer *audioLevelTimer;
	AVAudioRecorder *soundRecorder;
	AVAudioPlayer *soundPlayer;
	NSURL	*soundFileURL;
	BOOL	recording;
	BOOL	playing;

	SpeakViewController *speakViewController;
}

@property (nonatomic,retain) IBOutlet UILabel *textLabel;
@property (nonatomic,retain) IBOutlet UILabel *countdownLabel;
@property (nonatomic,retain) IBOutlet UIImageView *instructionLabel;
@property (nonatomic,retain) IBOutlet CALevelMeter *levelMeter;

@property (assign) NSTimer *repeatingTimer;
@property (assign) NSTimer *audioLevelTimer;
@property (nonatomic,retain) AVAudioRecorder *soundRecorder;
@property (nonatomic,retain) AVAudioPlayer *soundPlayer;
@property (nonatomic,retain) NSURL	*soundFileURL;
@property BOOL recording;
@property BOOL playing;

@property (nonatomic,retain) SpeakViewController *speakViewController;

- (void)record;
- (BOOL)recorded;
- (void)updateCountdownLabel:(int)count;
- (IBAction)pressRecordButton:(id)sender;
- (IBAction)pressPlayButton:(id)sender;
- (IBAction)pressSubmitButton:(id)sender;

@end
