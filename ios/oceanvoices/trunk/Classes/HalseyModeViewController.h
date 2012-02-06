//
//  HalseyModeViewController.h
//  ScapesApp
//
//  Created by Joe Zobkiw on 10/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

@interface HalseyModeViewController : UIViewController {
	IBOutlet UISwitch *gpsPingSwitch;
}

@property (nonatomic,retain) IBOutlet UISwitch *gpsPingSwitch;

- (IBAction)toggleGPSPingSwitch:(id)sender;


@end
