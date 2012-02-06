//
//  RootViewController.m
//  Ocean Voices
//
//  Created by Joe Zobkiw on 12/3/09.
//  Copyright Earsmack Music 2009. All rights reserved.
//

#import "RootViewController.h"
#import "ListenViewController.h"
#import "SpeakViewController.h"
#import "OceanVoicesAppDelegate.h"
#import "HalseyModeViewController.h"

@implementation RootViewController

@synthesize listenButton;
@synthesize speakButton;
@synthesize activityIndicatorView;
@synthesize fastForwardToSpeak;

// A callback from the ListenViewController
- (void)setFastForwardFlag {
	self.fastForwardToSpeak = YES;
}

-(void)networkAvailable: (NSNotification*)notification {
	[listenButton setEnabled:YES];
	[speakButton setEnabled:YES];
	[activityIndicatorView stopAnimating];
}

 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	// Display gray translucent navigationBar in navigationController
	[self navigationController].navigationBar.barStyle = UIBarStyleBlack;
	[self navigationController].navigationBar.translucent = YES;

	self.title = NSLocalizedString(kHOME_TITLE, kHOME_TITLE);

	self.fastForwardToSpeak = NO;
	
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	
	if (([(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] networkAvailable]) == NO) {
		[listenButton setEnabled:NO];
		[speakButton setEnabled:NO];
		[activityIndicatorView startAnimating];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(networkAvailable:) name: @"networkAvailable" object:nil];
	}
	
	// Hide the navigationController on the home screen
	[[self navigationController] setNavigationBarHidden:YES animated:animated];

	// Set background image for home screen (clouds)
	self.view.backgroundColor = [UIColor clearColor];
	self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Default_no_logo.png"]];
	
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	// If we are coming back from the Listen:Record button we want to auto-push the SpeakViewController
	if (self.fastForwardToSpeak == YES) {
		self.fastForwardToSpeak = NO;
		[self viewWillDisappear: animated]; // we need to call this manually otherwise it will not get called at this stage
		[self speak:nil];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	
	// Show the navigationController on other screens
	[[self navigationController] setNavigationBarHidden:NO animated:animated];
	
	[super viewWillDisappear:animated];
}

- (void)dealloc {
	[listenButton release]; listenButton = nil;
	[speakButton release]; speakButton = nil;
	[activityIndicatorView release]; activityIndicatorView = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Actions

- (IBAction)listen:(id)sender
{
	if ([(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] networkAvailable]) {
		// Start the stream
		[(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] startAudioStreamer];
		
		ListenViewController *viewController = [[ListenViewController alloc] initWithNibName:@"ListenViewController" bundle:nil];
		[self.navigationController pushViewController:viewController animated:YES];
		[viewController release];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Network" message:@"There is no network connection. Please wait a moment and try again. If this persists you can quit Ocean Voices and launch it again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

- (IBAction)speak:(id)sender
{
	if ([(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] networkAvailable]) {
		// Stop the stream
		[(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] stopAudioStreamer];

		SpeakViewController *viewController = [[SpeakViewController alloc] initWithNibName:@"SpeakViewController" bundle:nil];
		[self.navigationController pushViewController:viewController animated:YES];
		[viewController release];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Network" message:@"There is no network connection. Please wait a moment and try again. If this persists you can quit Ocean Voices and launch it again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

#pragma mark About, etc.

- (IBAction)info:(id)sender
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"About Ocean Voices" message:kABOUT_OCEANVOICES delegate:self cancelButtonTitle:nil otherButtonTitles:@"Website", @"Done", nil];
	[alert show];
	[alert release];
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (([alertView title] == @"About Ocean Voices") && (buttonIndex == 0)) // Website button
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kOCEANVOICES_WEBSITE]];
}

- (IBAction)halseymode:(id)sender
{
	HalseyModeViewController *anotherViewController = [[HalseyModeViewController alloc] initWithNibName:@"HalseyModeViewController" bundle:nil];
	[self.navigationController pushViewController:anotherViewController animated:YES];
	[anotherViewController release];
}

@end
