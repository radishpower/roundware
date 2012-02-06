//
//  SpeakSub5SubmitViewController.m
//  Scapes
//
//  Created by Joe Zobkiw on 12/28/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import "SpeakSub5SubmitViewController.h"
#import "SpeakViewController.h"
#import "ScapesAppDelegate.h"
#import "SpeakThankYouViewController.h"
#import "JSON.h"
#import "SHK.h"

@implementation SpeakSub5SubmitViewController

@synthesize textLabel;
@synthesize progressView;
@synthesize speakViewController;
@synthesize timer;
@synthesize lastRecordingID;
@synthesize progressTimer;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    timer = nil;
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	
    [self enterRecording];
	[super viewDidAppear:animated];
}

#pragma mark ENTER

- (void)enterRecording {
 	// Prefs
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	// Setup controls
	[progressView setProgress:0];
	[speakViewController.navigationItem setHidesBackButton:YES animated:YES];
    
    // Enter
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kEventURL__]];
	
	// Question
	NSArray *speakQuestionPrefs = [prefs objectForKey:kSpeakQuestionPref];
	NSString *keyStr = [speakQuestionPrefs objectAtIndex:0];
	[request setPostValue:keyStr forKey:@"questionid"];
	
	// Gender
	NSArray *speakGenderPrefs = [prefs objectForKey:kSpeakGenderAgePref];
	NSString *keyStr2 = [speakGenderPrefs objectAtIndex:0];
	[request setPostValue:keyStr2 forKey:@"demographicid"];
	
	// File
	//[request setFile:[NSTemporaryDirectory() stringByAppendingPathComponent: katRecordedFileName] forKey:@"file"];
	
	[request setPostValue:kConfig forKey:@"config"];
	[request setPostValue:kCategoryID forKey:@"categoryid"];
	[request setPostValue:kSubcategoryID forKey:@"subcategoryid"];
	[request setPostValue:[NSString stringWithFormat:@"%@", kScapesMuseumVisitor] forKey:@"usertypeid"];
    
	//[request setPostValue:[NSString stringWithFormat:@"%d", kEVENT_START_UPLOAD] forKey:@"operationid"];
	[request setPostValue:[NSString stringWithFormat:@"enter_recording"] forKey:@"operation"]; // changed from operationid
	[request setPostValue:@"Y" forKey:@"submittedyn"];
    
	[request setPostValue:[NSString stringWithFormat:@"%@", [UIDevice currentDevice].uniqueIdentifier] forKey:@"udid"];
	[request setPostValue:[NSString stringWithFormat:@"%@", [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] sessionID]] forKey:@"sessionid"];
	//[request setPostValue:[NSString stringWithFormat:@"12345", [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] sessionID]] forKey:@"sessionid"];
	[request setPostValue:[NSString stringWithFormat:@"%d", time(NULL)] forKey:@"clienttime"]; // 2009-10-19 08:36:07
	
	CLLocationManager *locationManager = [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] locationManager];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.coordinate.latitude] forKey:@"latitude"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.coordinate.longitude] forKey:@"longitude"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.course] forKey:@"course"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.horizontalAccuracy] forKey:@"haccuracy"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.speed] forKey:@"speed"];
    
	//[request setUploadProgressDelegate:progressView];
	[request setDelegate:self];
    [request setDidFinishSelector:@selector(requestFinished_enterRecording:)];
    [request setDidFailSelector:@selector(requestFailed_enterRecording:)];
	[request startAsynchronous];
    
}

- (void)requestFinished_enterRecording:(ASIHTTPRequest *)request {
    
    NSDictionary *jsonDictionary = [[request responseString] JSONValue];
    //	NSLog(@"%@", jsonDictionary);
    lastRecordingID = [[NSString stringWithFormat:@"%@", [jsonDictionary objectForKey:@"RESULT"]] retain];
	NSString *recordingID = [NSString stringWithFormat:@"%@", [jsonDictionary objectForKey:@"RESULT"]];
	NSLog(@"recordingID: %@", recordingID);
	NSString *sharingMessage = [NSString stringWithFormat:@"%@", [jsonDictionary objectForKey:@"SHARING_MESSAGE"]]; 
	NSLog(@"sharingMessage: %@ (local)", sharingMessage);
    
    // Set the sharing message here so it can be picked up in the ThankYou view
    [[speakViewController sharingMessage] release];
    [speakViewController setSharingMessage:[NSString stringWithFormat:@"%@", [jsonDictionary objectForKey:@"SHARING_MESSAGE"]]];
   	NSLog(@"sharingMessage: %@ (speakViewController)", [speakViewController sharingMessage]);
 
    /*
    // ShareKit
    // Create the item to share (in this example, a url)
    //  NSURL *url = [NSURL URLWithString:kSCAPES_WEBSITE];
    //  SHKItem *item = [SHKItem URL:url title:sharingMessage];
    SHKItem *item = [SHKItem text:sharingMessage];
    
    // Get the ShareKit action sheet
    SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    
    // Display the action sheet
    //[actionSheet showFromToolbar:navigationController.toolbar];
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
    */
    
    // Convert the file
    [self convertFile];

    // Begin the upload process
    //[self uploadFile:recordingID];
    
    //[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];
}

- (void)requestFailed_enterRecording:(ASIHTTPRequest *)request {
	
	// Display error
	NSError *error = [request error];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload failed - please submit again." message:[NSString stringWithFormat:@"%@ (%d)", [error localizedDescription], [error code]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	[alert release];
	
	// Reset controls
	[progressView setProgress:0];
	textLabel.text = @"Upload failed!";
	
	[(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] stopAudioStreamer];
	[speakViewController.navigationItem setHidesBackButton:NO animated:YES];
	[speakViewController updateSubView:kSpeakSub4RecordView];
}

#pragma mark CONVERT

static AVAssetExportSession *exportSession;

- (void)convertFile {
    
    NSURL *assetURL = nil;
    AVURLAsset *audioAsset = nil;
    NSDictionary *options = nil;
    NSString *outputPath = nil;
    NSURL *outputURL = nil;
    
    textLabel.text = @"Optimizing recording for upload...";
    
    if (exportSession != nil) {
        if ([exportSession progress] < 1.0) 
            NSLog(@"Export in progress will be cancelled!");
        [exportSession cancelExport];
        [exportSession release];
        exportSession = nil;
    }
    if (progressTimer != nil) {
        [progressTimer release];
        progressTimer = nil;
    }
    
    options = [[NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithBool:YES], @"AVURLAssetPreferPreciseDurationAndTimingKey", 
                nil] retain];
    
    assetURL = [[NSURL alloc] initFileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent: katRecordedFileName]]; // OK
    if (assetURL == nil) { NSLog(@"Couldn't create NSURL"); goto fail; }
    audioAsset = [[AVURLAsset URLAssetWithURL:assetURL options:options] retain];
    if (audioAsset == nil) { NSLog(@"Couldn't create AVURLAsset"); goto fail; }
    // if ([((AVURLAsset*)audioAsset) isExportable] == NO) { NSLog(@"This audio is not exportable"); goto fail; }
    
    exportSession = [[AVAssetExportSession exportSessionWithAsset:audioAsset presetName:AVAssetExportPresetMediumQuality /*AVAssetExportPresetAppleM4A*/] retain];
    if (exportSession == nil) { NSLog(@"Couldn't create AVAssetExportSession"); goto fail; }
    
    outputPath = [[NSTemporaryDirectory() stringByAppendingString: katConvertedFileName] retain];
    NSError *error;
    
    if (([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) && ([[NSFileManager defaultManager] removeItemAtPath:outputPath error:&error] == NO)) {
        NSLog(@"Couldn't delete previous output file: %@", [error localizedDescription]);
        goto fail;
        // This is a fatal error - can not convert, probably shouldn't upload - not sure the best way to handle it - but it should NEVER happen!
    }
    NSLog(@"Converting to: %@", outputPath);
    outputURL = [[NSURL alloc] initFileURLWithPath: outputPath];
    
    // configure export session output with all our parameters
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie /* AVFileTypeAppleM4A */ ; 
    
    // Setup a timer
    progressTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 
                                                      target:self 
                                                    selector:@selector(progressTimerFireMethod:) 
                                                    userInfo:nil 
                                                     repeats:YES] retain];
    NSLog(@"--- BEGINNING EXPORT ---");
    
    // perform the export
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (AVAssetExportSessionStatusCompleted == exportSession.status) {
            NSLog(@"AVAssetExportSessionStatusCompleted --- EXPORT SUCCESS");
        } else if (AVAssetExportSessionStatusFailed == exportSession.status) {
            // a failure may happen because of an event out of your control
            // for example, an interruption like a phone call coming in
            // make sure and handle this case appropriately
            NSLog(@"AVAssetExportSessionStatusFailed: %@ --- EXPORT FAIL", [exportSession.error localizedDescription]);
        } else {
            NSLog(@"Export Session Status: %d --- EXPORT UNKNOWN (FAIL)", exportSession.status);
        }
        
        if (progressTimer != nil) {
            [progressTimer invalidate];
            [progressTimer release];
            progressTimer = nil;
        }
        
        // Kick off the upload no matter what happens - it will handle uploaded converted or unconverted file
        textLabel.text = @"Uploading recording...";
        [progressView setProgress:0];
        [self uploadFile:lastRecordingID];
        
    }];
    
    goto exit;
fail:
    NSLog(@"FAIL");
    
    if (progressTimer != nil) {
        [progressTimer invalidate];
        [progressTimer release];
        progressTimer = nil;
    }

    // If we can't convert - just upload as is.
    textLabel.text = @"Uploading recording...";
    [progressView setProgress:0];
    [self uploadFile:lastRecordingID];
    
exit:
    NSLog(@"EXIT");
    [outputPath release];
    [options release];
    [assetURL release];
    [outputURL release];
    [audioAsset release];    
}

- (void)progressTimerFireMethod:(NSTimer*)theTimer {
    //  NSLog(@"progressTimerFireMethod");
	[progressView setProgress:(exportSession != nil ? [exportSession progress] : 0.0)];
}

#pragma mark UPLOAD

- (void)uploadFile:(NSString *)recordingID {
	// Prefs
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	// Setup controls
	[progressView setProgress:0];
	[speakViewController.navigationItem setHidesBackButton:YES animated:YES];
	
	// Upload
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kEventURL__]];
	
    // Recording ID from enter_recording
	[request setPostValue:recordingID forKey:@"recordingid"];
    
	// Question
	NSArray *speakQuestionPrefs = [prefs objectForKey:kSpeakQuestionPref];
	NSString *keyStr = [speakQuestionPrefs objectAtIndex:0];
	[request setPostValue:keyStr forKey:@"questionid"];
	
	// Gender
	NSArray *speakGenderPrefs = [prefs objectForKey:kSpeakGenderAgePref];
	NSString *keyStr2 = [speakGenderPrefs objectAtIndex:0];
	[request setPostValue:keyStr2 forKey:@"demographicid"];
	
	// File
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent: katConvertedFileName]]) {
        [request setFile:[NSTemporaryDirectory() stringByAppendingPathComponent: katConvertedFileName] forKey:@"file"];
        [request setPostValue:@"YES" forKey:@"converted"];
	} else if ([[NSFileManager defaultManager] fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent: katRecordedFileName]]) {
        [request setFile:[NSTemporaryDirectory() stringByAppendingPathComponent: katRecordedFileName] forKey:@"file"];
        [request setPostValue:@"NO" forKey:@"converted"];
    }
	
	[request setPostValue:kConfig forKey:@"config"];
	[request setPostValue:kCategoryID forKey:@"categoryid"];
	[request setPostValue:kSubcategoryID forKey:@"subcategoryid"];
	[request setPostValue:[NSString stringWithFormat:@"%@", kScapesMuseumVisitor] forKey:@"usertypeid"];
    
	//[request setPostValue:[NSString stringWithFormat:@"%d", kEVENT_START_UPLOAD] forKey:@"operationid"];
	[request setPostValue:[NSString stringWithFormat:@"upload_recording"] forKey:@"operation"]; // changed from operationid
	[request setPostValue:@"Y" forKey:@"submittedyn"];
    
	[request setPostValue:[NSString stringWithFormat:@"%@", [UIDevice currentDevice].uniqueIdentifier] forKey:@"udid"];
	[request setPostValue:[NSString stringWithFormat:@"%@", [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] sessionID]] forKey:@"sessionid"];
	//[request setPostValue:[NSString stringWithFormat:@"12345", [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] sessionID]] forKey:@"sessionid"];
	[request setPostValue:[NSString stringWithFormat:@"%d", time(NULL)] forKey:@"clienttime"]; // 2009-10-19 08:36:07
	
	CLLocationManager *locationManager = [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] locationManager];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.coordinate.latitude] forKey:@"latitude"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.coordinate.longitude] forKey:@"longitude"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.course] forKey:@"course"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.horizontalAccuracy] forKey:@"haccuracy"];
	[request setPostValue:[NSString stringWithFormat:@"%f", locationManager.location.speed] forKey:@"speed"];
    
	[request setUploadProgressDelegate:progressView];
	[request setDelegate:self];
    [request setDidFinishSelector:@selector(requestFinished_uploadFile:)];
    [request setDidFailSelector:@selector(requestFailed_uploadFile:)];
	[request startAsynchronous];
	
    //	[(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] submitEvent: kEVENT_START_UPLOAD];
    
}

- (void)requestFinished_uploadFile:(ASIHTTPRequest *)request
{
	
   // [self requestFailed_uploadFile: request]; // TESTING123
   // return;
    
    
    [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] submitEvent: kEVENT_STOP_UPLOAD_SUCCESS];
	
	// Best attempt to remove previous recording
	[[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent: katRecordedFileName] error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent: katConvertedFileName] error:NULL];

	// Reset controls
	[progressView setProgress:0];
	textLabel.text = @"Upload succeeded!";
    
	[speakViewController displayThankYou];
}

- (void)timerFireMethod:(NSTimer*)theTimer {
    textLabel.text = @"Trying upload again..."; // DEBUG
    [self uploadFile:lastRecordingID];
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (([alertView title] == @"Upload Error") && (buttonIndex == 0)) { // Try Again
        textLabel.text = @"Trying upload again...";
        [self uploadFile:lastRecordingID];
    }
	if (([alertView title] == @"Upload Error") && (buttonIndex == 1)) { // Cancel
        [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] submitEvent: kEVENT_STOP_UPLOAD_FAIL];
        
        // Reset controls
        [progressView setProgress:0];
        textLabel.text = @"Upload failed!";
        
        [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] stopAudioStreamer];
        [speakViewController.navigationItem setHidesBackButton:NO animated:YES];
        //[speakViewController updateSubView:kSpeakSub4RecordView];
        [speakViewController.navigationController popToRootViewControllerAnimated:YES];

    }
}

- (void)requestFailed_uploadFile:(ASIHTTPRequest *)request
{
    // Try one more time if things failed
    if (timer == nil) {
        // Try again in 3 seconds if we got here and have yet to try again
        timer = [[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO] retain];
        return;
    } else {
        // This will make the timer invalid so we'll try twice (silenty) before alerting the user again if they choose to try again
        [timer invalidate]; 
        [timer release]; 
        timer = nil; 
    
        // Alert the user that it failed (twice) and let them choose to try again or cancel
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Error" message:@"Upload failed due to network error!\nPlease try uploading again or cancel.\nNote: Canceling will delete your current recording." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try Again", @"Cancel", nil];
        [alert show];
        [alert release];
    }
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
	[timer release]; timer = nil;
    [progressTimer release]; progressTimer = nil;
    [lastRecordingID release]; lastRecordingID = nil;
    [super dealloc];
}

@end
