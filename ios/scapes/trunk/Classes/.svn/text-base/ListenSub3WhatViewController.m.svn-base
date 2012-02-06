//
//  ListenSub3WhatViewController
//  Scapes
//
//  Created by Joe Zobkiw on 12/4/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import "ListenSub3WhatViewController.h"
#import "ScapesAppDelegate.h"
#import "QuestionCell.h"

@implementation ListenSub3WhatViewController

@synthesize textLabel;
@synthesize _tableView;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	_tableView.separatorColor = [UIColor darkGrayColor];
	[super viewDidLoad];
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


- (void)dealloc {
	[textLabel release]; textLabel = nil;
	[_tableView release]; _tableView = nil;
    [super dealloc];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kQuestionSections;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSDictionary *listenQuestions = [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] listenQuestions];
    return (section == kQuestionSection && listenQuestions) ? [listenQuestions count] : 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"QuestionCell";
    
    QuestionCell *cell = (QuestionCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"QuestionCell" owner:self options:nil];
		
		for (id currentObject in topLevelObjects){
			if ([currentObject isKindOfClass:[UITableViewCell class]]){
				cell = (QuestionCell *) currentObject;
				break;
			}
		}
    }
    
	NSString *text = nil;
	if (indexPath.section == kQuestionSection) {
		
		// Get key and string for row
		NSDictionary *listenQuestions = [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] listenQuestions];
		//NSArray *keys = [listenQuestions allKeys];
		NSArray *keys = [listenQuestions keysSortedByValueUsingSelector:@selector(compare:)];
		id aKey = [keys objectAtIndex: indexPath.row];
		id anObject = [listenQuestions objectForKey:aKey];
		text = [[NSString stringWithFormat:@"%@", anObject] substringFromIndex:3];
		//text = [NSString stringWithFormat:@"%@", anObject];
		
		// Get the checkmark value for the row
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		NSArray *myPrefs = [prefs objectForKey:kListenQuestionPref];
		NSUInteger i = (myPrefs == nil) ? NSNotFound : [myPrefs indexOfObject: aKey];
		// cell.accessoryType = (i == NSNotFound) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark; // use normal checkmark
		cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:((i == NSNotFound) ? kUncheckedChevron : kCheckedChevron)]]; // use custom checkmark
	}
	
	cell.textLabel.text = text;
	
    return cell;
}

// Override to support row selection in the table view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == kQuestionSection) {
		
		// Get key for row
		NSDictionary *listenQuestions = [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] listenQuestions];
		//NSArray *keys = [listenQuestions allKeys];
		NSArray *keys = [listenQuestions keysSortedByValueUsingSelector:@selector(compare:)];
		id aKey = [keys objectAtIndex: indexPath.row];
		
		// Update preference for key
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		NSMutableArray *myPrefs = [[prefs objectForKey:kListenQuestionPref] mutableCopy];
		if (myPrefs == nil)
			myPrefs = [[NSMutableArray array] retain];
		NSUInteger i = (myPrefs == nil) ? NSNotFound : [myPrefs indexOfObject: aKey];
		if (i == NSNotFound) {
			[myPrefs addObject: aKey];
		} else {
			[myPrefs removeObject: aKey];
		}
		[prefs setObject:myPrefs forKey:kListenQuestionPref];
		[myPrefs release];
		
		// Update table
		[tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
	}
}

@end
