//
//  RWTagViewController.h
//  RWExample
//
//  Created by Joe Zobkiw on 12/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RWTagViewController : UITableViewController {
	NSDictionary *_tag;
	NSString *_currentKeyName;
}

@property (nonatomic, retain, setter=setTag:) NSDictionary *_tag;	    
@property (nonatomic, retain, setter=setCurrentKeyName:) NSString *_currentKeyName;	    

@end
