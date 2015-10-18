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

- (BOOL)isPhotoOfDateExists:(NSString *)date ofUser:(NSString *)user_id;

- (void)insertUser:(NSString *)display_name withID:(NSString *)user_id;

- (void)insertPhoto:(NSString *)source_image_url toUser:(NSString *)user_id;

- (OPUser *)fetchUserByID:(NSString *)user_id;

- (OPPhoto *)getPhotoAt:(NSString *)date ofUser:(NSString *)user_id;

- (NSArray *)getPhotosInMonth:(NSString *)month ofUser:(NSString *)user_id;

- (NSSet *)allPhotos;

@end
