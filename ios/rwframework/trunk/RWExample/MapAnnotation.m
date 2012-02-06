//
//  MapAnnotation.m
//  Scapes
//
//  Created by Joe Zobkiw on 12/28/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import "MapAnnotation.h"

@implementation MapAnnotation
@synthesize coordinate;

- (NSString *)subtitle {
	return [NSString stringWithFormat:@"%f, %f", coordinate.latitude, coordinate.longitude];
}

- (NSString *)title {
	return @"Your Location";
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
	coordinate = newCoordinate;
}

@end
