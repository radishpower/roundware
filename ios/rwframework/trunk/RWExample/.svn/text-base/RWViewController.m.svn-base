//
//  RWViewController.m
//  RWExample
//
//  Created by Joe Zobkiw on 10/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RWViewController.h"
#import "MapAnnotation.h"

@implementation RWViewController

@synthesize heartButton;
@synthesize playButton;
@synthesize recordButton;
@synthesize playbackButton;
@synthesize submitButton;
@synthesize infoButton;
@synthesize listenTagButton;
@synthesize speakTagButton;
@synthesize progressView;
@synthesize textView;
@synthesize myMapView;
@synthesize aiView;

#pragma mark RWFrameworkDelegate methods

- (void)rwUpdateStatus:(NSString*)message {
	[textView setText:[[textView text] stringByAppendingString:[NSString stringWithFormat:@"%@\n", message]]];
	[textView scrollRangeToVisible:NSMakeRange([textView.text length], 0)];
}

- (void)rwReadyToPlay {
	// Buttons are disabled by default
	[playButton setEnabled:YES];
	[listenTagButton setEnabled:YES];
}

- (void)rwReadyToRecord {
	// Buttons are disabled by default
	[recordButton setEnabled:YES];
	[speakTagButton setEnabled:YES];
}

- (void)rwCurrentVersion:(NSString*)version {
	[self rwUpdateStatus:[NSString stringWithFormat:@"roundware server version %@", version]];
}

- (void)rwHeartbeatSuccess {
	// Create the keyframe animation object
	CAKeyframeAnimation *scaleAnimation = 
	[CAKeyframeAnimation animationWithKeyPath:@"transform"];
	
	// Set the animation's delegate to self so that we can add callbacks if we want
	scaleAnimation.delegate = self;
	
	// Create the transform; we'll scale x and y by 1.5, leaving z alone 
	// since this is a 2D animation.
	CATransform3D transform = CATransform3DMakeScale(1.5, 1.5, 1); // Scale in x and y
	
	// Add the keyframes.  Note we have to start and end with CATransformIdentity, 
	// so that the label starts from and returns to its non-transformed state.
	[scaleAnimation setValues:[NSArray arrayWithObjects:
							   [NSValue valueWithCATransform3D:CATransform3DIdentity],
							   [NSValue valueWithCATransform3D:transform],
							   [NSValue valueWithCATransform3D:CATransform3DIdentity],
							   nil]];
	
	// set the duration of the animation
	[scaleAnimation setDuration: .5];
	
	// animate your label layer = rock and roll!
	[[heartButton.titleLabel layer] addAnimation:scaleAnimation forKey:@"scaleText"];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	NSLog(@"New Location: %@", [newLocation description]);
	MKCoordinateRegion region;
	region.center.latitude = newLocation.coordinate.latitude;
	region.center.longitude = newLocation.coordinate.longitude;
	region.span.latitudeDelta = 0.002; //0.0035
	region.span.longitudeDelta = 0.002; //0.0035
	[myMapView setRegion:region animated:YES];

	// Remove annotations
	[myMapView removeAnnotations:myMapView.annotations];
	
	// Add current annotation
	MapAnnotation *mapAnnotation = [MapAnnotation alloc];
	[mapAnnotation setCoordinate:newLocation.coordinate];
	[myMapView addAnnotation:mapAnnotation];
	[mapAnnotation release];

}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	NSLog(@"Location Error: %@", [error description]);
}

- (void)rwUpdateUI:(float)progress {
    RWFramework *sharedRWFramework = [RWFramework sharedRWFramework];
	
	if (progress == 0.0) { // avoid excessive button manipulation
		// Listen
		if ([sharedRWFramework canPlay]) {
			if ([sharedRWFramework isPlaying]) {
				[playButton setImage:[UIImage imageNamed:@"rw_pause.png"] forState:UIControlStateNormal];
			} else {
				[playButton setImage:[UIImage imageNamed:@"rw_play.png"] forState:UIControlStateNormal];
			}
		}
		
		// Speak
		if ([sharedRWFramework canRecord]) {
			[recordButton setEnabled:![sharedRWFramework isPlayingBack]];
			if ([sharedRWFramework isRecording]) {
				[recordButton setImage:[UIImage imageNamed:@"rw_stop.png"] forState:UIControlStateNormal];
			} else {
				[recordButton setImage:[UIImage imageNamed:@"rw_record.png"] forState:UIControlStateNormal];
			}
			if ([sharedRWFramework hasRecording]) {
				[playbackButton setEnabled:![sharedRWFramework isRecording]];
				[submitButton setEnabled:![sharedRWFramework isRecording] && ![sharedRWFramework isPlayingBack]];
			} else {
				[playbackButton setEnabled:NO];
				[submitButton setEnabled:NO];
			}
			if ([sharedRWFramework isPlayingBack]) {
				[playbackButton setImage:[UIImage imageNamed:@"rw_stop.png"] forState:UIControlStateNormal];
			} else {
				[playbackButton setImage:[UIImage imageNamed:@"rw_play.png"] forState:UIControlStateNormal];
			}
		}
	}
	
	// Progress in the event we are doing something that has a progress associated with it
	if ([progressView progress] != progress) {
        [progressView setProgress:progress];
	}

}

- (void)rwUpdateApplicationIconBadgeNumber:(NSUInteger)count {
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
}

- (void)rwUpdateActivity:(BOOL)uploading {
	if ([aiView isAnimating] && (uploading == NO)) {
		[aiView stopAnimating];
	} else if (![aiView isAnimating] && (uploading == YES)) {
		[aiView startAnimating];
	}
}

- (void)rwSharingMessage:(NSString*)message url:(NSString*)url {
	NSLog(@"Application received sharing msg (%@) and url (%@)", message, url);
	[self rwUpdateStatus:[NSString stringWithFormat:@"Sharing Msg: %@", message]];
}

#pragma mark MKMapViewDelegate method

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id)annotation{
    static NSString *customAnnotationIdentifier=@"CustomAnnotationIdentifier";
	
    if ([annotation isKindOfClass:[MapAnnotation class]]) {
        //Try to get an unused annotation, similar to uitableviewcells
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:customAnnotationIdentifier];
        //If one isn't available, create a new one
        if(!annotationView){
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:customAnnotationIdentifier];
            // Here's where the magic happens
            annotationView.image = [UIImage imageNamed:@"rw_map_dot.png"];
        }
        return annotationView;
    }
    return nil;
}

#pragma mark IBActions

- (IBAction)play:(id)sender {
    RWFramework *sharedRWFramework = [RWFramework sharedRWFramework];
	if ([sharedRWFramework isPlaying]) {
		[sharedRWFramework pause];
	} else {
		[sharedRWFramework play];
	}
	[self rwUpdateUI:0];
}

- (IBAction)record:(id)sender {
    RWFramework *sharedRWFramework = [RWFramework sharedRWFramework];
	if ([sharedRWFramework isRecording]) {
		[sharedRWFramework stopRecording];
	} else {
		[sharedRWFramework startRecording];
	}
	[self rwUpdateUI:0];
}

- (IBAction)playback:(id)sender {
    RWFramework *sharedRWFramework = [RWFramework sharedRWFramework];
	if ([sharedRWFramework isPlayingBack]) {
		[sharedRWFramework stopPlayback];
	} else {
		[sharedRWFramework playbackRecording];
	}
	[self rwUpdateUI:0];
}

- (IBAction)submit:(id)sender {
    RWFramework *sharedRWFramework = [RWFramework sharedRWFramework];
	[sharedRWFramework submit];
	[self rwUpdateUI:0];
}

- (IBAction)info:(id)sender {
	RWFramework *sharedRWFramework = [RWFramework sharedRWFramework];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:[sharedRWFramework info] delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
}

- (IBAction)listenTag:(id)sender {
	RWFramework *sharedRWFramework = [RWFramework sharedRWFramework];
	[sharedRWFramework editListenTags];
}

- (IBAction)speakTag:(id)sender {
	RWFramework *sharedRWFramework = [RWFramework sharedRWFramework];
	[sharedRWFramework editSpeakTags];
}

#pragma mark

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	// When our view loads we kick everything off
	RWFramework *sharedRWFramework = [RWFramework sharedRWFramework];
	[sharedRWFramework setDelegate: self];
	[sharedRWFramework start];

	[myMapView setDelegate:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	[playButton release]; playButton = nil;
    [recordButton release]; recordButton = nil;
    [playbackButton release]; playbackButton = nil;
    [submitButton release]; submitButton = nil;
    [speakTagButton release]; speakTagButton = nil;
    [listenTagButton release]; listenTagButton = nil;
    [infoButton release]; infoButton = nil;
    [progressView release]; progressView = nil;
    [textView release]; textView = nil;
    [myMapView release]; myMapView = nil;
	[aiView release]; aiView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	[self rwUpdateUI:0]; // Get our buttons in order
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
    [playButton release];
    [recordButton release];
    [playbackButton release];
	[listenTagButton release];
	[speakTagButton release];
    [submitButton release];
    [progressView release];
    [textView release];
	[myMapView release];
    [super dealloc];
}

@end
