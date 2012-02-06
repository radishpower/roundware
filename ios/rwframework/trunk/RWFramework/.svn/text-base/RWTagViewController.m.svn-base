//
//  RWTagViewController.m
//  RWExample
//
//  Created by Joe Zobkiw on 12/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RWTagViewController.h"

@implementation RWTagViewController

@synthesize _tag;
@synthesize _currentKeyName;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	[_tag release];
	_tag = nil;
	[_currentKeyName release];
	_currentKeyName = nil;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	//NSArray *tags = [[NSUserDefaults standardUserDefaults] objectForKey:@"tags_listen"];
	//NSDictionary *tag = [tags objectAtIndex:0];
	NSLog(@"%@", [_tag debugDescription]);
	NSArray *options = [_tag objectForKey:@"options"];
	return [options count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"RWCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
 	
	//NSArray *tags = [[NSUserDefaults standardUserDefaults] objectForKey:@"tags_listen"];
	//NSDictionary *tag = [tags objectAtIndex:0];
	NSArray *options = [_tag objectForKey:@"options"];
	NSDictionary *option = [options objectAtIndex:indexPath.row];
	cell.textLabel.text = [option objectForKey:@"value"];
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	cell.accessoryType = UITableViewCellAccessoryNone; // UITableViewCellAccessoryNone or UITableViewCellAccessoryCheckmark;
	NSInteger tag_id = [[option objectForKey:@"tag_id"] integerValue];
	NSArray *current = [[NSUserDefaults standardUserDefaults] objectForKey:_currentKeyName];
	[current enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if (tag_id == [obj integerValue])
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}];

    return cell;
}

// Override to support row selection in the table view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSArray *options = [_tag objectForKey:@"options"];

	NSString *select = [_tag objectForKey:@"select"];
	BOOL single_select = [select isEqualToString:@"single"];
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];            // returns nil if cell is not visible or index path is out of range
	if (single_select) {															// in single select mode...
		if (cell.accessoryType == UITableViewCellAccessoryNone) {					// if we are tapping an item that is current not selected...
			for (int i = 0 ; i < [options count]; i++) {							// deselect any others...
				NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
				UITableViewCell *c = [tableView cellForRowAtIndexPath:index];
				c.accessoryType = UITableViewCellAccessoryNone;
			}
			cell.accessoryType = UITableViewCellAccessoryCheckmark;					// ...then select the one we tapped
			
			// Update the current selection storage with selected tag id
			NSDictionary *option = [options objectAtIndex:indexPath.row];
			NSInteger tag_id = [[option objectForKey:@"tag_id"] integerValue];
			NSArray *newCurrent = [NSArray arrayWithObject:[NSNumber numberWithInt:tag_id]];
			[[NSUserDefaults standardUserDefaults] setObject:newCurrent forKey:_currentKeyName];
		}
	} else {																		// in multi select mode...simply toggle the item (allowing no selection is OK)
		cell.accessoryType = (cell.accessoryType == UITableViewCellAccessoryCheckmark) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
	
		// Update the current selection storage with selected tag id
		NSDictionary *option = [options objectAtIndex:indexPath.row];
		NSInteger tag_id = [[option objectForKey:@"tag_id"] integerValue];
		NSMutableArray *ma = [[NSMutableArray arrayWithArray: [[NSUserDefaults standardUserDefaults] arrayForKey:_currentKeyName]] retain];
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {				// Add to the stored array
			[ma addObject:[NSNumber numberWithInt:tag_id]];
		} else {																	// Remove from the stored array
			[ma removeObjectIdenticalTo:[NSNumber numberWithInt:tag_id]];
		}
		[[NSUserDefaults standardUserDefaults] setObject:ma forKey:_currentKeyName];
		[ma release];
	}
	
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
