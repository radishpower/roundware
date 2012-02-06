//
//  SpeakViewController.m
//  Ocean Voices
//
//  Created by Joe Zobkiw on 12/3/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import "SpeakViewController.h"
#import "OceanVoicesAppDelegate.h"
#import "SpeakSub1ViewController.h"
#import "SpeakSub2WhoViewController.h"
#import "SpeakSub25TypeViewController.h"
#import "SpeakSub3WhatViewController.h"
#import "SpeakSub4RecordViewController.h"
#import "SpeakSub5SubmitViewController.h"
#import "SpeakThankYouViewController.h"

@implementation SpeakViewController

@synthesize recordButton;
@synthesize playButton;
@synthesize stopButton;
@synthesize submitButton;
@synthesize currentSubViewController;
@synthesize currentSubViewID;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(kSPEAK_TITLE, kSPEAK_TITLE);
}

- (void)viewWillAppear:(BOOL)animated {
	
	// Set background image for screen
	self.view.backgroundColor = [UIColor clearColor];
	self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"speak_bg.png"]];
	
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	
	[self resetWizard]; // This basically cleans everything up and starts fresh
	
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
 	[recordButton release]; recordButton = nil;
 	[playButton release]; playButton = nil;
	[stopButton release]; stopButton = nil;
 	[submitButton release]; submitButton = nil;
	[currentSubViewController release]; currentSubViewController = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Animations

- (void)updateSubView:(int)which {
	
	// If we click the same button of the current subview, then really hide the current subview and show the default one instead
	if (self.currentSubViewID == which) { // TODO: VERIFY REALLY ONLY THIS HAPPENS IF WE CLICK WHO/WHAT AGAIN
		which = kSpeakSub4RecordView;
	}
	
	// If preferences aren't set, force the user to set them before doing anything else
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSArray *speakGenderAgePrefs = [prefs objectForKey:kSpeakGenderAgePref];
	if ([speakGenderAgePrefs count] == 0) {
		which = kSpeakSub2WhoView;
	} else {
		NSArray *speakTypePrefs = [prefs objectForKey:kSpeakUserTypePref];
		if ([speakTypePrefs count] == 0) {
			which = kSpeakSub25TypeView;
		} else {
			NSArray *speakQuestionPrefs = [prefs objectForKey:kSpeakQuestionPref];
			if ([speakQuestionPrefs count] == 0) {
				which = kSpeakSub3WhatView;
			}
		}
	}
	
	// Reset button images to OFF state
	//[whoButton setImage:[UIImage imageNamed:@"whosingle-button-off.png"] forState:UIControlStateNormal];
	//[whatButton setImage:[UIImage imageNamed:@"whatsingle-button-off.png"] forState:UIControlStateNormal];
	
	// If there is a current sub view displayed, hide it
	if (currentSubViewController != nil) {
		
		// Force to back otherwise it will slide down in front of the control area
		[self.view sendSubviewToBack:currentSubViewController.view]; 
		
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
			
			case kSpeakSub1View:
				subViewController = [[SpeakSub1ViewController alloc] initWithNibName:@"SpeakSub1ViewController" bundle:nil];
				frame = subViewController.view.frame;
				frame.origin.y = kSpeakSub1ViewY;
				break;
				
			case kSpeakSub2WhoView:
				subViewController = [[SpeakSub2WhoViewController alloc] initWithNibName:@"SpeakSub2WhoViewController" bundle:nil];
				((SpeakSub2WhoViewController*)subViewController).speakViewController = self;
				frame = subViewController.view.frame;
				frame.origin.y = kSpeakSub2WhoViewY;
				
				/*
				 UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(pressDoneButton:)];          
				 [self.navigationItem setRightBarButtonItem:anotherButton animated:YES];
				 [anotherButton release];
				 */
				
				[self updateButtonStates:kButtonStateWho];
				break;

			case kSpeakSub25TypeView:
				subViewController = [[SpeakSub25TypeViewController alloc] initWithNibName:@"SpeakSub25TypeViewController" bundle:nil];
				((SpeakSub2WhoViewController*)subViewController).speakViewController = self;
				frame = subViewController.view.frame;
				frame.origin.y = kSpeakSub25TypeViewY;
				
				/*
				 UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(pressDoneButton:)];          
				 [self.navigationItem setRightBarButtonItem:anotherButton animated:YES];
				 [anotherButton release];
				 */
				
				[self updateButtonStates:kButtonStateType];
				break;
				
			case kSpeakSub3WhatView:
				subViewController = [[SpeakSub3WhatViewController alloc] initWithNibName:@"SpeakSub3WhatViewController" bundle:nil];
				((SpeakSub3WhatViewController*)subViewController).speakViewController = self;
				frame = subViewController.view.frame;
				frame.origin.y = kSpeakSub3WhatViewY;
				
				/*
				UIBarButtonItem *anotherButton2 = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(pressDoneButton:)];          
				[self.navigationItem setRightBarButtonItem:anotherButton2 animated:YES];
				[anotherButton2 release];
				*/
				
				[self updateButtonStates:kButtonStateWhat];
				break;
				
			case kSpeakSub4RecordView:
				subViewController = [[SpeakSub4RecordViewController alloc] initWithNibName:@"SpeakSub4RecordViewController" bundle:nil];
				((SpeakSub4RecordViewController*)subViewController).speakViewController = self;
				frame = subViewController.view.frame;
				frame.origin.y = kSpeakSub4RecordViewY;
				
				[self updateButtonStates:kButtonStateRecordable];
				break;
			
			case kSpeakSub5SubmitView:
				subViewController = [[SpeakSub5SubmitViewController alloc] initWithNibName:@"SpeakSub5SubmitViewController" bundle:nil];
				((SpeakSub5SubmitViewController*)subViewController).speakViewController = self;
				frame = subViewController.view.frame;
				frame.origin.y = kSpeakSub5SubmitViewY;
				
				[self updateButtonStates:kButtonStateUploading];
				break;
				
			default:
				return;
				break;
		}
		
		subViewController.view.frame = frame;
		self.currentSubViewController = subViewController; // save the subViewController - no need to retain since alloc returns a retained object
		[self.view addSubview: self.currentSubViewController.view];
		[self.view sendSubviewToBack:currentSubViewController.view]; 
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
#pragma mark Callbacks

- (void)updateButtonStates:(int)state {
	switch(state) {
		case kButtonStateRecordable:
			[recordButton setImage:[UIImage imageNamed:@"RECORD-button.png"] forState:UIControlStateNormal];
			[recordButton setEnabled: YES];
			[playButton setEnabled: YES];
			[submitButton setEnabled: YES];
			break;
		case kButtonStateRecording:
			[recordButton setImage:[UIImage imageNamed:@"STOP-button.png"] forState:UIControlStateNormal];
			[recordButton setEnabled: YES];
			[playButton setEnabled: NO];
			[submitButton setEnabled: NO];
			break;
		case kButtonStatePlayable:
			[recordButton setImage:[UIImage imageNamed:@"RECORD-button.png"] forState:UIControlStateNormal];
			[recordButton setEnabled: YES];
			[playButton setHidden:NO];
			[stopButton setHidden:YES];
			[submitButton setEnabled: YES];
			break;
		case kButtonStatePlaying:
			[recordButton setImage:[UIImage imageNamed:@"RECORD-button.png"] forState:UIControlStateNormal];
			[recordButton setEnabled: NO];
			[playButton setHidden:YES];
			[stopButton setHidden:NO];
			[submitButton setEnabled: NO];
			break;
		case kButtonStateRecord:
			[recordButton setEnabled: YES];
			[playButton setEnabled: YES];
			[submitButton setEnabled: YES];
			break;
		case kButtonStateWho:
		case kButtonStateType:
		case kButtonStateWhat:
			[recordButton setEnabled: NO];
			[playButton setEnabled: NO];
			[submitButton setEnabled: NO];
			break;
		case kButtonStateUploading:
			[recordButton setEnabled: NO];
			[playButton setEnabled: NO];
			[submitButton setEnabled: NO];
			break;
		default:
			break;
	}
}

- (void)submitRecording {
	[self updateStream];
	[self updateSubView: kSpeakSub5SubmitView];
}

- (void)displayThankYou {
	// Push success screen
	SpeakThankYouViewController *anotherViewController = [[SpeakThankYouViewController alloc] initWithNibName:@"SpeakThankYouViewController" bundle:nil];
	[self.navigationController pushViewController:anotherViewController animated:YES];
	[anotherViewController release];
	
	[self updateSubView: kSpeakSub1View];
}

- (void)resetWizard {
	// Remove previously recorded file so we can have a fresh start
	[[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent: katRecordedFileName] error:NULL];
	
	// Clear speak preferences
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs removeObjectForKey:kSpeakQuestionPref];
	[prefs removeObjectForKey:kSpeakGenderAgePref];
	[prefs removeObjectForKey:kSpeakUserTypePref];

	// Display the initial sub view
	[self updateSubView: kSpeakSub4RecordView];
}

#pragma mark -
#pragma mark Actions

- (void)updateStream { // On the Record side we don't have a stream to update - but we still use the same mechanism to handle Done button dismissal
	if (self.navigationItem.rightBarButtonItem) {
		[self.navigationItem setRightBarButtonItem:nil animated:YES];
	}
}

- (IBAction)pressDoneButton:(id)sender {
	[self updateStream];
	[self updateSubView: kSpeakSub4RecordView];
}

- (IBAction)pressRecordButton:(id)sender {
	if ([currentSubViewController respondsToSelector:@selector(pressRecordButton:)]) {
		[currentSubViewController performSelector:@selector(pressRecordButton:) withObject:sender];
	}
}

- (IBAction)pressPlayButton:(id)sender {
	if ([currentSubViewController respondsToSelector:@selector(pressPlayButton:)]) {
		[currentSubViewController performSelector:@selector(pressPlayButton:) withObject:sender];
	}
}

- (IBAction)pressSubmitButton:(id)sender {
	if ([currentSubViewController respondsToSelector:@selector(pressSubmitButton:)]) {
		[currentSubViewController performSelector:@selector(pressSubmitButton:) withObject:sender];
	}
}


@end
