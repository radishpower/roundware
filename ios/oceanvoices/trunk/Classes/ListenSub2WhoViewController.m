//
//  ListenSub2WhoViewController
//  Ocean Voices
//
//  Created by Joe Zobkiw on 12/4/09.
//  Copyright 2009 Earsmack Music. All rights reserved.
//

#import "ListenSub2WhoViewController.h"
#import "OceanVoicesAppDelegate.h"
#import "DemoCell.h"

@implementation ListenSub2WhoViewController

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
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == kDemoSection0) {
		NSDictionary *demographicChoices = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] demographicChoices];
		return (demographicChoices) ? [demographicChoices count] : 0;
	} else if (section == kDemoSection1) {
		NSDictionary *usertypeChoices = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] usertypeChoices];
		return (usertypeChoices) ? [usertypeChoices count] : 0;
	}
	return 0;
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
				break;
			}
		}
    }
    
	NSString *text = nil;
	if (indexPath.section == kDemoSection0) {
		
		// Get key and string for row
		NSDictionary *demographicChoices = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] demographicChoices];
		//NSArray *keys = [demographicChoices allKeys];
		NSArray *keys = [demographicChoices keysSortedByValueUsingSelector:@selector(compare:)];
		id aKey = [keys objectAtIndex: indexPath.row];
		id anObject = [demographicChoices objectForKey:aKey];
		text = [NSString stringWithFormat:@"%@", anObject];
		
		// Get the checkmark value for the row
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		NSArray *myPrefs = [prefs objectForKey:kListenGenderAgePref];
		NSUInteger i = (myPrefs == nil) ? NSNotFound : [myPrefs indexOfObject: aKey];
		// cell.accessoryType = (i == NSNotFound) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark; // use normal checkmark
		cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:((i == NSNotFound) ? kUncheckedChevron : kCheckedChevron)]]; // use custom checkmark
	
	} else if (indexPath.section == kDemoSection1) {
		
		// Get key and string for row
		NSDictionary *usertypeChoices = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] usertypeChoices];
		NSArray *keys = [usertypeChoices keysSortedByValueUsingSelector:@selector(compare:)];
		id aKey = [keys objectAtIndex: indexPath.row];
		id anObject = [usertypeChoices objectForKey:aKey];
		//text = [NSString stringWithFormat:@"%@", anObject];
		text = [[NSString stringWithFormat:@"%@", anObject] substringFromIndex:3];

		// Get the checkmark value for the row
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		NSArray *myPrefs = [prefs objectForKey:kListenUserTypePref];
		NSUInteger i = (myPrefs == nil) ? NSNotFound : [myPrefs indexOfObject: aKey];
		// cell.accessoryType = (i == NSNotFound) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark; // use normal checkmark
		cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:((i == NSNotFound) ? kUncheckedChevron : kCheckedChevronAlternate)]]; // use custom checkmark
	}
	
	cell.textLabel.text = text;
	
    return cell;
}

// Override to support row selection in the table view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == kDemoSection0) {
		
		// Get key for row
		NSDictionary *demographicChoices = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] demographicChoices];
		//NSArray *keys = [demographicChoices allKeys];
		NSArray *keys = [demographicChoices keysSortedByValueUsingSelector:@selector(compare:)];
		id aKey = [keys objectAtIndex: indexPath.row];
		
		// Update preference for key
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		NSMutableArray *myPrefs = [[prefs objectForKey:kListenGenderAgePref] mutableCopy];
		if (myPrefs == nil)
			myPrefs = [[NSMutableArray array] retain];
		NSUInteger i = (myPrefs == nil) ? NSNotFound : [myPrefs indexOfObject: aKey];
		if (i == NSNotFound) {
			[myPrefs addObject: aKey];
		} else {
			[myPrefs removeObject: aKey];
		}
		[prefs setObject:myPrefs forKey:kListenGenderAgePref];
		[myPrefs release];
		
		// Update table
		[tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
	
	} else if (indexPath.section == kDemoSection1) {

		// Get key for row
		NSDictionary *usertypeChoices = [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] usertypeChoices];
		NSArray *keys = [usertypeChoices keysSortedByValueUsingSelector:@selector(compare:)];
		id aKey = [keys objectAtIndex: indexPath.row];
		
		// Update preference for key
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		NSMutableArray *myPrefs = [[prefs objectForKey:kListenUserTypePref] mutableCopy];
		if (myPrefs == nil)
			myPrefs = [[NSMutableArray array] retain];
		NSUInteger i = (myPrefs == nil) ? NSNotFound : [myPrefs indexOfObject: aKey];
		if (i == NSNotFound) {
			[myPrefs addObject: aKey];
		} else {
			[myPrefs removeObject: aKey];
		}
		[prefs setObject:myPrefs forKey:kListenUserTypePref];
		[myPrefs release];
		
		// Update table
		[tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
	}
}


@end