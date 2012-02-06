//
//  SpeakThankYouViewController.m
//  Ocean Voices
//
//  Created by Joe Zobkiw on 12/28/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import "SpeakThankYouViewController.h"
#import "SpeakViewController.h"
#import "OceanVoicesAppDelegate.h"
#import "MapAnnotation.h"

@implementation SpeakThankYouViewController

@synthesize googleMapView;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Zoom the map to the current user location
	CLLocationManager *locationManager = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] locationManager];
	MKCoordinateRegion region;
	region.center.latitude = locationManager.location.coordinate.latitude;
	region.center.longitude = locationManager.location.coordinate.longitude;
	region.span.latitudeDelta = 0.0200; //0.0035;
	region.span.longitudeDelta = 0.0200; //0.0035;
	[googleMapView setRegion:region animated:YES];
	googleMapView.showsUserLocation = NO; // This finds the current location, possibly add annotations instead?
	googleMapView.delegate = self;

	// Display saved location (when recording ended) to show on map
	CLLocationCoordinate2D recordedCoordinate = ([(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] recordedCoordinate]);
	MapAnnotation *mapAnnotation = [[MapAnnotation alloc] initWithCoordinate:recordedCoordinate];
	[googleMapView addAnnotation:mapAnnotation];
	[mapAnnotation release];
	
	self.title = NSLocalizedString(kTHANKYOU_TITLE, kTHANKYOU_TITLE);
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

- (void)viewWillAppear:(BOOL)animated {
	
	// Set background image for screen
	self.view.backgroundColor = [UIColor clearColor];
	self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"home_bg.png"]];
	
	[self.navigationItem setHidesBackButton:YES animated:NO];

	UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(pressDoneButton:)];          
	[self.navigationItem setRightBarButtonItem:anotherButton animated:YES];
	[anotherButton release];
	
    [super viewWillAppear:animated];
}

- (void)dealloc {
	[googleMapView release]; googleMapView = nil;
    [super dealloc];
}


// HRB code for popup to comment on the app in the app store
- (IBAction)pressDoneButton:(id)sender {
	//UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ocean Voices Message" message:kPOST_RECORD_POPUP_TEXT delegate:self cancelButtonTitle:nil otherButtonTitles:@"Yes, please!", @"Not now", nil];
	//[alert show];
	//[alert release];
	[self.navigationController popToRootViewControllerAnimated:YES];
}

// 
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (([alertView title] == @"Ocean Voices Message") && (buttonIndex == 0)) // Website button
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kOCEANVOICES_ITUNESURL]];
	else {
		[self.navigationController popToRootViewControllerAnimated:YES];
	}

}

@end
