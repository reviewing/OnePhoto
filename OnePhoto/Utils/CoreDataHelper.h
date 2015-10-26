//
//  CoreDataHelper.h
//  OnePhoto
//
//  Created by Hong Duan on 9/6/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OPPhoto;

@interface CoreDataHelper : NSObject

+ (instancetype)sharedHelper;

- (BOOL)isPhotoOfDateExists:(NSString *)date;

- (void)insertPhoto:(NSString *)source_image_url;

- (void)deletePhoto:(OPPhoto *)photo;

- (OPPhoto *)getPhotoAt:(NSString *)date;

- (NSArray *)getPhotosInMonth:(NSString *)month;

- (NSDate *)firstDayIn1Photo;

- (NSSet *)allPhotos;

@end
