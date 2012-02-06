//
//  ListenViewController.m
//  Scapes
//
//  Created by Joe Zobkiw on 12/3/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "ListenViewController.h"
#import "ScapesAppDelegate.h"
#import "ListenSub1ViewController.h"
#import "ListenSub2WhoViewController.h"
#import "ListenSub3WhatViewController.h"

@implementation ListenViewController

@synthesize playButton;
@synthesize whoButton;
@synthesize whatButton;
@synthesize currentSubViewController;
@synthesize currentSubViewID;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	self.title = NSLocalizedString(kLISTEN_TITLE, kLISTEN_TITLE);
}

- (void)viewWillAppear:(BOOL)animated {
	
	// Set background image for screen
//	self.view.backgroundColor = [UIColor clearColor];
//	self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"listen_bg.png"]];
	
	// Set playButton accordingly
	[self pressPlayButton: nil];
	
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self updateStream];
	[super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	
	// Display the initial sub view
	[self updateSubView: kListenSub1View];
	
	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[playButton release]; playButton = nil;
	[whoButton release]; whoButton = nil;
	[whatButton release]; whatButton = nil;
	[currentSubViewController release]; currentSubViewController = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Animations

- (void)updateSubView:(int)which {
	
	// If we click the same button of the current subview, then really hide the current subview and show the default one instead
	if (self.currentSubViewID == which)
		which = kListenSub1View;

	// Reset button images to OFF state
	[whoButton setImage:[UIImage imageNamed:@"whogroup-button-off.png"] forState:UIControlStateNormal];
	[whatButton setImage:[UIImage imageNamed:@"whatgroup-button-off.png"] forState:UIControlStateNormal];

	// If there is a current sub view displayed, hide it
	if (currentSubViewController != nil) {

		// Force to back otherwise it will slide down in front of the control area
		[self.view sendSubviewToBack:currentSubViewController.view]; 
		
        // Swap the background image and the list
        [self.view exchangeSubviewAtIndex:1 withSubviewAtIndex:0];

		// Change the frame to be off-screen
		CGRect frame = currentSubViewController.view.frame;
		frame.origin.y = 480;
		currentSubViewController.view.frame = frame;
		
		[self.currentSubViewController viewWillDisappear: YES]; // have to call this explicitely otherwise it will not be called

		// Create the animation to push the view off-screen
		CATransition *animation = [CATransition animation];
		[animation setDelegate:self];
		[animation setDuration: frame.size.height * kAnimationMultiplier];
		[animation setType:kCATransitionPush];
		[animation setSubtype:kCATransitionFromBottom];
		[animation setValue:@"SlideDown" forKey:@"MyAnimationType"];
		[animation setValue:[NSString stringWithFormat:@"%d", which] forKey:@"MyNextSubViewID"]; // pass thru the id of the view we ultimately want to push on-screen
		[[currentSubViewController.view layer] addAnimation:animation forKey:@"TransitionViewOut"];
	 
	} else {
	
		// Track the current subview
		self.currentSubViewID = which;
		
		// Display the new sub view that is being requested
		UIViewController *subViewController = nil;
		CGRect frame;
		
		// Load the proper subview and set the y origin properly for it to slide onto the screen
		switch (which) {
			case kListenSub1View:
				subViewController = [[ListenSub1ViewController alloc] initWithNibName:@"ListenSub1ViewController" bundle:nil];
				frame = subViewController.view.frame;
				frame.origin.y = kListenSub1ViewY;
				break;
			case kListenSub2WhoView:
				subViewController = [[ListenSub2WhoViewController alloc] initWithNibName:@"ListenSub2WhoViewController" bundle:nil];
				frame = subViewController.view.frame;
				frame.origin.y = kListenSub2WhoViewY;
				[whoButton setImage:[UIImage imageNamed:@"whogroup-button-on.png"] forState:UIControlStateNormal];
				
				UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(pressDoneButton:)];          
				[self.navigationItem setRightBarButtonItem:anotherButton animated:YES];
				[anotherButton release];
				
				break;
			case kListenSub3WhatView:
				subViewController = [[ListenSub3WhatViewController alloc] initWithNibName:@"ListenSub3WhatViewController" bundle:nil];
				frame = subViewController.view.frame;
				frame.origin.y = kListenSub3WhatViewY;
				[whatButton setImage:[UIImage imageNamed:@"whatgroup-button-on.png"] forState:UIControlStateNormal];
		
				UIBarButtonItem *anotherButton2 = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(pressDoneButton:)];          
				[self.navigationItem setRightBarButtonItem:anotherButton2 animated:YES];
				[anotherButton2 release];

				break;
			default:
				return;
				break;
		}
		
		subViewController.view.frame = frame;
		self.currentSubViewController = subViewController; // save the subViewController - no need to retain since alloc returns a retained object
		[self.view addSubview: self.currentSubViewController.view];
		[self.view sendSubviewToBack:currentSubViewController.view]; 

        // Swap the background image and the list
        [self.view exchangeSubviewAtIndex:1 withSubviewAtIndex:0];

        [self.currentSubViewController viewWillAppear: YES]; // have to call this explicitely otherwise it will not be called		
		
		// Setup the animation to push the view on-screen
		CATransition *animation = [CATransition animation];
		[animation setDelegate:self];
		[animation setDuration: frame.size.height * kAnimationMultiplier];
		[animation setType:kCATransitionPush];
		[animation setSubtype:kCATransitionFromTop];
		[animation setValue:@"SlideUp" forKey:@"MyAnimationType"];
		[[self.currentSubViewController.view layer] addAnimation:animation forKey:@"TransitionViewIn"];
	}
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSString* animationType = [anim valueForKey:@"MyAnimationType"];
	
    if ([animationType isEqualToString:@"SlideDown"]) {
		
		// The animation has completed, we can now remove the view from the superview
		[self.currentSubViewController viewDidDisappear: YES]; // have to call this explicitely otherwise it will not be called
		[currentSubViewController.view removeFromSuperview];
		[currentSubViewController release]; // removeFromSuperview supposedly calls release so this may be overkill
		currentSubViewController = nil;
		
		// Pass the id of the subview that we actually want displayed
		NSString* nextSubViewID = [anim valueForKey:@"MyNextSubViewID"];
		[self updateSubView:[nextSubViewID intValue]];
		
    } else if ([animationType isEqualToString:@"SlideUp"]) {
		
		[self.currentSubViewController viewDidAppear: YES]; // have to call this explicitely otherwise it will not be called
		
	}
}

#pragma mark -
#pragma mark Actions

- (void)updateUserInterface:(NSNumber*)begin {
	if ([begin boolValue] == YES) {
		if (([(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] isAudioStreamerPlaying]))
			[(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] toggleAudioStreamer];
	}
	[self pressPlayButton:nil];
}

- (void)updateStream {
	if (self.navigationItem.rightBarButtonItem) {
		[self.navigationItem setRightBarButtonItem:nil animated:YES];
		([(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] submitEvent:kEVENT_MODIFY_STREAM]);
	}
}

- (IBAction)pressDoneButton:(id)sender {
	[self updateStream];
	[self updateSubView: kListenSub1View];
}

- (IBAction)pressWhoButton:(id)sender {
	[self updateStream];
	[self updateSubView: kListenSub2WhoView];
}

- (IBAction)pressWhatButton:(id)sender {
	[self updateStream];
	[self updateSubView: kListenSub3WhatView];
}

- (IBAction)pressRecordButton:(id)sender {
	UIViewController *rootViewController = [[self.navigationController viewControllers] objectAtIndex:0];
	if ([rootViewController respondsToSelector:@selector(setFastForwardFlag)])
		[rootViewController performSelector:@selector(setFastForwardFlag)];
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)pressVolumeButton:(id)sender {
	MPVolumeSettingsAlertShow();
}

- (IBAction)pressPlayButton:(id)sender {
	BOOL isAudioStreamerPlaying = ([(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] isAudioStreamerPlaying]);
	
	if (sender != nil) { // an actual button push as opposed to use just priming the button image
		[(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] toggleAudioStreamer];
		isAudioStreamerPlaying = !isAudioStreamerPlaying; // swap the value in anticipation of the state change
	}
	
	[playButton setImage:[UIImage imageNamed:(isAudioStreamerPlaying ? @"PAUSE-button.png" : @"PLAY-button.png")] forState:UIControlStateNormal]; 
}


@end
