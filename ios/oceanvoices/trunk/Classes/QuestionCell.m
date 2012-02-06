//
//  QuestionCell.m
//  ScapesApp
//
//  Created by Joe Zobkiw on 9/29/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import "QuestionCell.h"


@implementation QuestionCell

@synthesize textLabel;

- (void)dealloc {
	[textLabel release]; textLabel = nil;
    [super dealloc];
}


@end
