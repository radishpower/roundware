//
//  SpeakSub3WhatViewController.h
//  Scapes
//
//  Created by Joe Zobkiw on 12/23/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SpeakViewController;

@interface SpeakSub3WhatViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
	IBOutlet UILabel *textLabel;
	IBOutlet UITableView *_tableView;
	SpeakViewController *speakViewController;
}

@property (nonatomic,retain) IBOutlet UILabel *textLabel;
@property (nonatomic,retain) IBOutlet UITableView *_tableView;
@property (nonatomic,retain) SpeakViewController *speakViewController;

@end
