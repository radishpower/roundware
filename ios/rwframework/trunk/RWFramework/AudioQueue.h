//
//  AudioQueue.h
//  RWExample
//
//  Created by Joe Zobkiw on 11/27/11.
//  Copyright (c) 2011 Earsmack Music. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AudioQueue : NSManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * envelopeID;

@end
