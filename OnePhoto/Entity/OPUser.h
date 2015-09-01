//
//  OPUser.h
//  OnePhoto
//
//  Created by Hong Duan on 9/1/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NSManagedObject;

@interface OPUser : NSManagedObject

@property (nonatomic, retain) NSString * display_name;
@property (nonatomic, retain) NSNumber * user_id;
@property (nonatomic, retain) NSSet *photos;
@end

@interface OPUser (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(NSManagedObject *)value;
- (void)removePhotosObject:(NSManagedObject *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

@end
