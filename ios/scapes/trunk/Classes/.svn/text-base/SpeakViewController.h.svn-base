//
//  SpeakViewController.h
//  Scapes
//
//  Created by Joe Zobkiw on 12/3/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SpeakViewController : UIViewController {
	IBOutlet UIButton *recordButton;
	IBOutlet UIButton *playButton;
	IBOutlet UIButton *stopButton;
	IBOutlet UIButton *submitButton;
	UIViewController *currentSubViewController;
	
	int currentSubViewID;
}

@property (nonatomic,retain) IBOutlet UIButton *recordButton;
@property (nonatomic,retain) IBOutlet UIButton *playButton;
@property (nonatomic,retain) IBOutlet UIButton *stopButton;
@property (nonatomic,retain) IBOutlet UIButton *submitButton;
@property (nonatomic,retain) UIViewController *currentSubViewController;

@property int currentSubViewID;

#define kButtonStateDefault		kButtonStateRecordable
#define kButtonStateRecordable	1
#define kButtonStateRecording	2
#define kButtonStatePlayable	3
#define kButtonStatePlaying		4
#define kButtonStateWho			5
#define kButtonStateWhat		6
#define kButtonStateRecord		7
#define kButtonStateUploading	8

- (void)updateButtonStates:(int)state;
- (void)submitRecording;
- (void)displayThankYou;
- (void)resetWizard;

- (void)updateStream;
- (IBAction)pressDoneButton:(id)sender;
- (IBAction)pressRecordButton:(id)sender;
- (IBAction)pressPlayButton:(id)sender;
- (IBAction)pressSubmitButton:(id)sender;

- (void)updateSubView:(int)which;

#define kControlAreaHeight		114
#define kMiddleHeight			206
#define kHudHeight				104
#define kUploadProgressHeight	40
#define kSlopHeight				20

#define kSpeakSub1View				1
#define kSpeakSub2WhoView			2
#define kSpeakSub3WhatView			3
#define kSpeakSub4RecordView		4
#define kSpeakSub5SubmitView		5

#define kSpeakSub1ViewY			(480-kControlAreaHeight-kHudHeight-kSlopHeight)		// 242
#define kSpeakSub2WhoViewY		(480-kControlAreaHeight-kMiddleHeight-kHudHeight-kSlopHeight)	// 36
#define kSpeakSub3WhatViewY		(480-kControlAreaHeight-kMiddleHeight-kHudHeight-kSlopHeight)	// 36
#define kSpeakSub4RecordViewY	(480-kControlAreaHeight-kMiddleHeight-kHudHeight-kSlopHeight)	// 36
#define kSpeakSub5SubmitViewY	(480-kControlAreaHeight-kUploadProgressHeight-kHudHeight-kSlopHeight) // 202

@end
