//
//  ListenViewController.h
//  Ocean Voices
//
//  Created by Joe Zobkiw on 12/3/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MPMoviePlayerController.h>

@interface ListenViewController : UIViewController {
	IBOutlet UIButton *playButton;
	IBOutlet UIButton *whoButton;
	IBOutlet UIButton *whatButton;
	UIViewController *currentSubViewController;
	MPMoviePlayerController *moviePlayer;
	NSTimer	*timer;
	int currentSubViewID;
}

@property (nonatomic,retain) IBOutlet UIButton *playButton;
@property (nonatomic,retain) IBOutlet UIButton *whoButton;
@property (nonatomic,retain) IBOutlet UIButton *whatButton;
@property (nonatomic,retain) UIViewController *currentSubViewController;
@property (nonatomic,retain) MPMoviePlayerController *moviePlayer;
@property (nonatomic,retain) NSTimer *timer;

@property int currentSubViewID;

- (void)updateUserInterface:(NSNumber*)begin;

- (void)updateStream;
- (IBAction)pressDoneButton:(id)sender;
- (IBAction)pressPlayButton:(id)sender;
- (IBAction)pressWhoButton:(id)sender;
- (IBAction)pressWhatButton:(id)sender;
- (IBAction)pressRecordButton:(id)sender;
- (IBAction)pressVolumeButton:(id)sender;
- (IBAction)pressVideoButton:(id)sender;

- (void)updateSubView:(int)which;

#define kControlAreaHeight	114
#define kMiddleHeight		206
#define kHudHeight			104
#define kSlopHeight			20

#define kListenSub1View			1
#define kListenSub2WhoView		2
#define kListenSub3WhatView		3

#define kListenSub1ViewY		(480-kControlAreaHeight-kHudHeight-kSlopHeight)		// 242
#define kListenSub2WhoViewY		(480-kControlAreaHeight-kMiddleHeight-kHudHeight-kSlopHeight)	// 36
#define kListenSub3WhatViewY	(480-kControlAreaHeight-kMiddleHeight-kHudHeight-kSlopHeight)	// 36

@end
