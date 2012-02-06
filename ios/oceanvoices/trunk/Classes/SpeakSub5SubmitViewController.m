//
//  SpeakSub5SubmitViewController.m
//  Ocean Voices
//
//  Created by Joe Zobkiw on 12/28/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import "SpeakSub5SubmitViewController.h"
#import "SpeakViewController.h"
#import "OceanVoicesAppDelegate.h"
#import "ASIFormDataRequest.h"
#import "SpeakThankYouViewController.h"
#import "JSON.h"

@implementation SpeakSub5SubmitViewController

@synthesize textLabel;
@synthesize progressView;
@synthesize speakViewController;
@synthesize timer;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	
	// Prefs
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	// Setup controls
	[progressView setProgress:0];
	[speakViewController.navigationItem setHidesBackButton:YES animated:YES];
	
	// Upload
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kUploadURL]];
	
	// Question
	NSArray *speakQuestionPrefs = [prefs objectForKey:kSpeakQuestionPref];
	NSString *keyStr = [speakQuestionPrefs objectAtIndex:0];
	[request setPostValue:keyStr forKey:@"questionid"];
	
	// Gender
	NSArray *speakGenderPrefs = [prefs objectForKey:kSpeakGenderAgePref];
	NSString *keyStr2 = [speakGenderPrefs objectAtIndex:0];
	[request setPostValue:keyStr2 forKey:@"demographicid"];
	
	// UserType
	NSArray *speakUserTypePrefs = [prefs objectForKey:kSpeakUserTypePref];
	NSString *keyStr3 = [speakUserTypePrefs objectAtIndex:0];
	[request setPostValue:keyStr3 forKey:@"usertypeid"];
	
	// File
	[request setFile:[NSTemporaryDirectory() stringByAppendingPathComponent: katRecordedFileName] forKey:@"file"];
	
	[request setPostValue:@"Submit" forKey:@"action"];
	[request setPostValue:[NSString stringWithFormat:@"%d", kEVENT_START_UPLOAD] forKey:@"operationid"];
	[request setPostValue:[NSString stringWithFormat:@"%@", [UIDevice currentDevice].uniqueIdentifier] forKey:@"udid"];
	[request setPostValue:[NSString stringWithFormat:@"%@", [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] sessionID]] forKey:@"sessionid"];
	[request setPostValue:[NSString stringWithFormat:@"%d", time(NULL)] forKey:@"clienttime"]; // 2009-10-19 08:36:07
	
	CLLocationManager *locationManager = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] locationManager];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.coordinate.latitude] forKey:@"latitude"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.coordinate.longitude] forKey:@"longitude"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.course] forKey:@"course"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.horizontalAccuracy] forKey:@"haccuracy"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.speed] forKey:@"speed"];
	
	[request setUploadProgressDelegate:progressView];
	[request setDelegate:self];
	[request startAsynchronous];
	
//	[(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] submitEvent: kEVENT_START_UPLOAD];

	// Restart the music
	timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];

	[super viewDidAppear:animated];
}

- (void)timerFireMethod:(NSTimer*)theTimer {
	[(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] startAudioStreamer];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	[(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] submitEvent: kEVENT_STOP_UPLOAD_SUCCESS];
	
	// Best attempt to remove previous recording
	[[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent: katRecordedFileName] error:NULL];
	
	// Reset controls
	[progressView setProgress:0];
	textLabel.text = @"Upload succeeded!";

	[speakViewController displayThankYou];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	[(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] submitEvent: kEVENT_STOP_UPLOAD_FAIL];
	
	// Display error
	NSError *error = [request error];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload failed - please submit again." message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	[alert release];
	
	// Reset controls
	[progressView setProgress:0];
	textLabel.text = @"Upload failed!";
	
	[(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] stopAudioStreamer];
	[speakViewController.navigationItem setHidesBackButton:NO animated:YES];
	[speakViewController updateSubView:kSpeakSub4RecordView];
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
	[progressView release]; progressView = nil;
	[timer invalidate]; [timer release]; timer = nil;
    [super dealloc];
}


@end
