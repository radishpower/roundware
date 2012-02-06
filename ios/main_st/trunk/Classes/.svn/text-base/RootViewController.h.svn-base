//
//  RootViewController.h
//  Scapes
//
//  Created by Joe Zobkiw on 12/3/09.
//  Copyright Earsmack Music 2009. All rights reserved.
//

@interface RootViewController : UIViewController <UIAlertViewDelegate> {
	IBOutlet UIButton *listenButton;
	IBOutlet UIButton *speakButton;
	IBOutlet UIActivityIndicatorView *activityIndicatorView;
	BOOL fastForwardToSpeak;
}

@property (nonatomic,retain) IBOutlet UIButton *listenButton;
@property (nonatomic,retain) IBOutlet UIButton *speakButton;
@property (nonatomic,retain) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) BOOL fastForwardToSpeak;

- (void)setFastForwardFlag;
- (IBAction)listen:(id)sender;
- (IBAction)speak:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)halseymode:(id)sender;

@end
