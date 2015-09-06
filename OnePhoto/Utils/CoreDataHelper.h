//
//  CoreDataHelper.h
//  OnePhoto
//
//  Created by Hong Duan on 9/6/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OPUser;
@class OPPhoto;

@interface CoreDataHelper : NSObject

+ (instancetype)sharedHelper;

- (void)insertUser:(NSString *)display_name withID:(NSString *)user_id;

- (void)insertPhoto:(NSString *)source_image_url toUser:(NSString *)user_id;

- (OPUser *)fetchUserByID:(NSString *)user_id;

@end
