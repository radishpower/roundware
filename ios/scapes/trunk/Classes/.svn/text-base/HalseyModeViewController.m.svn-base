//
//  HalseyModeViewController.m
//  ScapesApp
//
//  Created by Joe Zobkiw on 10/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "HalseyModeViewController.h"
#import "ScapesAppDelegate.h"

@implementation HalseyModeViewController

@synthesize gpsPingSwitch;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Halsey Mode", @"Halsey Mode");
}

- (void)viewWillAppear:(BOOL)animated {
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	BOOL value = [prefs boolForKey:kHalseyModeGPSPingPref];
	gpsPingSwitch.on = value;
	
    [super viewWillAppear:animated];
}

- (void)viewDidUnload {
	[gpsPingSwitch release]; gpsPingSwitch = nil;
	[super viewDidUnload];
}

- (void)dealloc {
	[gpsPingSwitch release]; gpsPingSwitch = nil;
    [super dealloc];
}

- (IBAction)toggleGPSPingSwitch:(id)sender
{
	if ([gpsPingSwitch isOn]) 
		[(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] playGPSPingSoundEffect];
	 
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs setBool:[gpsPingSwitch isOn] forKey:kHalseyModeGPSPingPref];
}

@end
