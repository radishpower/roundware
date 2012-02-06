//
//  RWAppDelegate.h
//  Test
//
//  Created by Joe Zobkiw on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

@class RWViewController;

@interface RWAppDelegate : UIResponder <UIApplicationDelegate, AVAudioSessionDelegate> {
	UIWindow *window;
	RWViewController *viewController;
	
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;	    
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RWViewController *viewController;

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSString *)applicationDocumentsDirectory;
- (void)saveContext;

@end

