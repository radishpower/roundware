//
//  SpeakThankYouViewController.h
//  Ocean Voices
//
//  Created by Joe Zobkiw on 12/28/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MKMapView;

@interface SpeakThankYouViewController : UIViewController <MKMapViewDelegate> {
	IBOutlet MKMapView *googleMapView;
}

@property (nonatomic,retain) IBOutlet MKMapView *googleMapView;

- (IBAction)pressDoneButton:(id)sender;

@end
