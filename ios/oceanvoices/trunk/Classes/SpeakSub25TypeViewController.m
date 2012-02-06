//
//  SpeakSub25TypeViewController.m
//  Ocean Voices
//
//  Created by Joe Zobkiw on 12/23/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import "SpeakSub25TypeViewController.h"
#import "SpeakViewController.h"
#import "OceanVoicesAppDelegate.h"
#import "DemoCell.h"


@implementation SpeakSub25TypeViewController

@synthesize textLabel;
@synthesize _tableView;
@synthesize speakViewController;

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
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSDictionary *usertypeChoices = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] usertypeChoices];
    return (section == 0 && usertypeChoices) ? [usertypeChoices count] : 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"DemoCell";
    
    DemoCell *cell = (DemoCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"DemoCell" owner:self options:nil];
		
		for (id currentObject in topLevelObjects){
			if ([currentObject isKindOfClass:[UITableViewCell class]]){
				cell = (DemoCell *) currentObject;
				cell.selectionStyle = UITableViewCellSelectionStyleGray;
				break;
			}
		}
    }
    
	NSString *text = nil;
	if (indexPath.section == 0) {
		
		// Get key and string for row
		NSDictionary *usertypeChoices = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] usertypeChoices];
		//NSArray *keys = [demographicChoices allKeys];
		NSArray *keys = [usertypeChoices keysSortedByValueUsingSelector:@selector(compare:)];
		id aKey = [keys objectAtIndex: indexPath.row];
		id anObject = [usertypeChoices objectForKey:aKey];
		text = [[NSString stringWithFormat:@"%@", anObject] substringFromIndex:3];

		// Get the checkmark value for the row
		//NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		//NSArray *myPrefs = [prefs objectForKey:kSpeakGenderAgePref];
		//NSUInteger i = (myPrefs == nil) ? NSNotFound : [myPrefs indexOfObject: aKey];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		//cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:((i == NSNotFound) ? kUncheckedChevron : kCheckedChevron)]]; // use custom checkmark
	}
	
	cell.textLabel.text = text;
	
    return cell;
}

// Override to support row selection in the table view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == 0) {
		
		// Get key for row
		NSDictionary *usertypeChoices = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] usertypeChoices];
		//NSArray *keys = [demographicChoices allKeys];
		NSArray *keys = [usertypeChoices keysSortedByValueUsingSelector:@selector(compare:)];
		id aKey = [keys objectAtIndex: indexPath.row];
		
		// Update preference for key
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		NSMutableArray *myPrefs = [[prefs objectForKey:kSpeakUserTypePref] mutableCopy];
		if (myPrefs == nil)
			myPrefs = [[NSMutableArray array] retain];
		NSUInteger i = (myPrefs == nil) ? NSNotFound : [myPrefs indexOfObject: aKey];
		if (i == NSNotFound) {
			[myPrefs removeAllObjects]; // only allow one choice at a time
			[myPrefs addObject: aKey];
		} else {
			[myPrefs removeObject: aKey];
		}
		[prefs setObject:myPrefs forKey:kSpeakUserTypePref];
		[myPrefs release];
		
		// Update table
		//[tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
		
		[speakViewController pressDoneButton:nil];
	}
}

@end
