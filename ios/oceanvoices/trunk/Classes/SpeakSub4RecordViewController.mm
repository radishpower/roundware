//
//  SpeakSub4RecordViewController.mm
//  Ocean Voices
//
//  Created by Joe Zobkiw on 12/23/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import <CoreAudio/CoreAudioTypes.h>
#import "SpeakViewController.h"
#import "SpeakSub4RecordViewController.h"
#import "OceanVoicesAppDelegate.h"
#include "CALevelMeter.h"

@implementation SpeakSub4RecordViewController

@synthesize textLabel;
@synthesize countdownLabel;
@synthesize instructionLabel;
@synthesize levelMeter;
@synthesize repeatingTimer;
@synthesize audioLevelTimer;
@synthesize soundRecorder;
@synthesize soundPlayer;
@synthesize soundFileURL;
@synthesize recording;
@synthesize playing;
@synthesize speakViewController;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	// Create soundFileURL
    NSString *tempDir = NSTemporaryDirectory();
    NSString *soundFilePath = [tempDir stringByAppendingString: katRecordedFileName];
    NSURL *newURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    self.soundFileURL = newURL;
    [newURL release];
		
	// Create a new sound recorder
	NSDictionary *recordSettings =
		[[NSDictionary alloc] initWithObjectsAndKeys:
		 [NSNumber numberWithFloat: 22050.0], AVSampleRateKey,
		 [NSNumber numberWithInt: kAudioFormatLinearPCM /* kAudioFormatMPEG4AAC /*very small*/ /*kAudioFormatAppleLossless pretty small*//*kAudioFormatLinearPCM large*/], AVFormatIDKey,
		 [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
		 [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
		 nil];
	AVAudioRecorder *newRecorder = [[AVAudioRecorder alloc] initWithURL: self.soundFileURL settings: recordSettings error: nil];
	[recordSettings release];
	self.soundRecorder = newRecorder;
	[newRecorder release];
	self.soundRecorder.delegate = self;

	// Initialize our state variables
	recording = NO;
    playing = NO;
	
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	
	// Display the chosen question the user is to speak about
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSArray *speakQuestionPrefs = [prefs objectForKey:kSpeakQuestionPref];
	NSString *keyStr = [speakQuestionPrefs objectAtIndex:0];
	NSDictionary *speakQuestions = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] speakQuestions];
	self.textLabel.text = [[speakQuestions objectForKey:keyStr] substringFromIndex:3];

	UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(pressResetButton:)];          
	[[speakViewController navigationItem] setRightBarButtonItem:anotherButton animated:YES];
	[anotherButton release];

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self.navigationItem setRightBarButtonItem:nil animated:YES];
    [super viewWillDisappear:animated];
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
	[textLabel release]; textLabel = nil;
	[countdownLabel release]; countdownLabel = nil;
	[instructionLabel release]; instructionLabel = nil;
	[levelMeter release]; levelMeter = nil;
	[repeatingTimer invalidate]; repeatingTimer = nil;
	[audioLevelTimer invalidate]; audioLevelTimer = nil;
	[soundFileURL release]; soundFileURL = nil;
	[soundRecorder release]; soundRecorder = nil;
	[soundPlayer release]; soundPlayer = nil;
	
	[super dealloc];
}

#pragma mark Action Methods

- (IBAction)pressResetButton:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm Reset" message:@"Resetting will delete any current recording and restart the recording process. Are you sure you want to continue?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", @"Cancel", nil];
	[alert show];
	[alert release];
}


// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (([alertView title] == @"Confirm Reset") && (buttonIndex == 0)) { // Confirm
		[speakViewController resetWizard];
	} else if (([alertView title] == @"Confirm Record") && (buttonIndex == 0)) { // Confirm
		[self record];
	}
}

#pragma mark Timer Methods

- (void)timerFireMethod:(NSTimer*)theTimer
{
	int currentTime = kMaxRecordingTimeSeconds - [[self soundRecorder] currentTime] + 1; // + 1 so we can be more accurate in our display
	[self updateCountdownLabel:currentTime];
}

- (void)updateCountdownLabel:(int)count {
	if (count >= 60) {
		int secs = count % 60;
		int min = count / 60;
		self.countdownLabel.text = [NSString stringWithFormat:@"%d:%02d", min, secs];
	} else if (count >= 0) {
		self.countdownLabel.text = [NSString stringWithFormat:@":%02d", count];
	}
}

#pragma mark Submit Methods

- (IBAction)pressSubmitButton:(id)sender {
	
	// make sure a file exists for playing
	if ([self recorded] == NO) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please make a recording first." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
		return;
	}

	// Tell our parent it's ok to submit the current recording
	[speakViewController submitRecording];
}

#pragma mark Record Methods

- (IBAction)pressRecordButton:(id)sender {
	
	// Fade counter/instructions
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	[instructionLabel setAlpha:(recording?1.0:0.0)];
	[countdownLabel setAlpha:(recording?0.0:1.0)];
	[self updateCountdownLabel: kMaxRecordingTimeSeconds];
	[UIView commitAnimations];

	if (recording) {
		[speakViewController updateButtonStates:kButtonStateRecordable];
		[levelMeter setPlayer:nil];
		[soundRecorder stop];
		recording = NO;
		
		[repeatingTimer invalidate];
		repeatingTimer = nil;
		
		// Save current location to show on map
		([(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] rememberRecordedCoordinate]);
		([(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] submitEvent:kEVENT_STOP_RECORD]);

	} else {
		
		if ([self recorded] == YES) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm Record" message:@"You already have a recording that you have yet to submit. Continuing will delete that recording. Are you sure you want to continue?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", @"Cancel", nil];
			[alert show];
			[alert release];
		} else {
			[self record];
		}
		
	}
}

- (void)record {
	[soundRecorder prepareToRecord];
	[levelMeter setPlayer:soundRecorder];
	[soundRecorder recordForDuration:(NSTimeInterval)kMaxRecordingTimeSeconds];
	[speakViewController updateButtonStates:kButtonStateRecording];
	recording = YES;
	
	if (self.repeatingTimer == nil) {
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0/2
														  target:self selector:@selector(timerFireMethod:)
														userInfo:nil repeats:YES];
		self.repeatingTimer = timer;
	}
	
	([(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] submitEvent:kEVENT_START_RECORD]);
}

- (BOOL)recorded {
	return ([[NSFileManager defaultManager] fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent: katRecordedFileName]]);
}

#pragma mark AVAudioRecorder Interruptions

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder
{
	if (soundRecorder && recording) {
		[self pressRecordButton: nil];
	}
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder
{
	if (soundRecorder && recording) {
		[self pressRecordButton: nil];
	}

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Audio Recorder Interrupted" message:@"Please begin your recording again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	[alert release];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
	if (soundRecorder && recording) {
		[self pressRecordButton: nil];
	}

	if (flag == NO) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Audio Recorder Error" message:@"The recording did not finish successfully. Please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
	if (soundRecorder && recording) {
		[self pressRecordButton: nil];
	}

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Audio Recorder Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	[alert release];
}

#pragma mark Play Methods

- (IBAction)pressPlayButton:(id)sender {
	if (playing) {
		[speakViewController updateButtonStates:kButtonStatePlayable];
		[levelMeter setPlayer:nil];
		[soundPlayer stop];
		[soundPlayer release];
		soundPlayer = nil;
		playing = NO;
	} else {
		
		// make sure a file exists for playing
		if ([self recorded] == NO) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please make a recording first." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
			[alert release];
			return;
		}
		
		[speakViewController updateButtonStates:kButtonStatePlaying];

		if (self.soundPlayer == nil) {
			AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: soundFileURL error: nil];
			self.soundPlayer = newPlayer;
			[newPlayer release];
		}
		
		[levelMeter setPlayer:soundPlayer];
		[soundPlayer prepareToPlay];
		[soundPlayer play];
		[soundPlayer setDelegate: self];
		playing = YES;
	}
}

#pragma mark AVAudioPlayer Interruptions

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
	if (soundPlayer && playing) {
		[self pressPlayButton: nil];
	}
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
	if (soundPlayer && playing) {
		[self pressPlayButton: nil];
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Audio Player Interrupted" message:@"Please begin your playback again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	[alert release];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	if (soundPlayer && playing) {
		[self pressPlayButton: nil];
	}

	if (flag == NO) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Audio Player Error" message:@"The playback did not finish successfully. Please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{	
	if (soundPlayer && playing) {
		[self pressPlayButton: nil];
	}

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Audio Player Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	[alert release];
}



@end
