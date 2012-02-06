//
//  SpeakSub5SubmitViewController.h
//  Scapes
//
//  Created by Joe Zobkiw on 12/28/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ASIFormDataRequest.h"
@class SpeakViewController;
@class AVAssetExportSession;

@interface SpeakSub5SubmitViewController : UIViewController {
	IBOutlet UILabel *textLabel;
	IBOutlet UIProgressView *progressView;
    
	SpeakViewController *speakViewController;
	
	NSTimer *timer; // retry
    NSString *lastRecordingID;
    NSTimer *progressTimer; // conversion
    
    NSString *submittedyn;
    // AVAssetExportSession *exportSession;
}

@property (nonatomic,retain) IBOutlet UILabel *textLabel;
@property (nonatomic,retain) IBOutlet UIProgressView *progressView;
@property (nonatomic,retain) NSTimer *timer;
@property (nonatomic,retain) NSString *lastRecordingID;
@property (nonatomic,retain) NSTimer *progressTimer;
@property (nonatomic,retain) NSString *submittedyn;

@property (nonatomic,retain) SpeakViewController *speakViewController;

- (void)enterRecording;
- (void)convertFile;
- (void)progressTimerFireMethod:(NSTimer*)theTimer;

- (void)uploadFile:(NSString *)recordingID;
- (void)timerFireMethod:(NSTimer*)theTimer;
- (void)requestFinished_enterRecording:(ASIHTTPRequest *)request;
- (void)requestFailed_uploadFile:(ASIHTTPRequest *)request;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end
