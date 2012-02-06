//
//  SpeakThankYouViewController.h
//  Scapes
//
//  Created by Joe Zobkiw on 12/28/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
@class SpeakViewController;

@class MKMapView;

@interface SpeakThankYouViewController : UIViewController <MKMapViewDelegate> {
	IBOutlet MKMapView *googleMapView;
	SpeakViewController *speakViewController;
}

@property (nonatomic,retain) IBOutlet MKMapView *googleMapView;
@property (nonatomic,retain) SpeakViewController *speakViewController;

- (IBAction)pressDoneButton:(id)sender;

@end
