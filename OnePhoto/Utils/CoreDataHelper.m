//
//  CoreDataHelper.m
//  OnePhoto
//
//  Created by Hong Duan on 9/6/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "CoreDataHelper.h"
#import "OPUser.h"
#import "OPPhoto.h"
#import "AppDelegate.h"
#import <FastImageCache/FICImageCache.h>

@interface CoreDataHelper () {
    NSManagedObjectContext *_context;
}

@end

@implementation CoreDataHelper

+ (instancetype)sharedHelper {
    static CoreDataHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CoreDataHelper alloc] init];
        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        sharedInstance->_context = [appDelegate managedObjectContext];
    });
    return sharedInstance;
}

- (BOOL)isPhotoOfDateExists:(NSString *)date {
    return [self getPhotoAt:date] != nil;
}

- (void)initUser:(NSString *)display_name {
    OPUser *user = [NSEntityDescription insertNewObjectForEntityForName:@"OPUser" inManagedObjectContext:_context];
    user.display_name = display_name;
    user.user_id = @"1photo@icloud";
    NSError *error;
    if (_context.hasChanges && ![_context save:&error]) {
        DHLogError(@"couldn't save: %@", [error localizedDescription]);
    }
}

- (OPUser *)currentUser {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"OPUser" inManagedObjectContext:_context]];
    NSError *error;
    NSArray *users = [_context executeFetchRequest:request error:&error];
    if (error) {
        DHLogError(@"couldn't fetch: %@", [error localizedDescription]);
    }
    if ([users count] > 0) {
        OPUser *user = [users objectAtIndex:0];
        DHLogDebug(@"user: id(%@) name(%@)", user.user_id, user.display_name);
        return user;
    }
    return nil;
}

- (void)insertPhoto:(NSString *)source_image_url {
    OPUser *user = [self currentUser];
    if (user == nil) {
        DHLogError(@"user not exists!");
        return;
    }
    NSString *photoFileName = [source_image_url lastPathComponent];
    NSString *dateString = [photoFileName substringToIndex:[photoFileName length] - 4];
    
    // 删除老照片
    OPPhoto *oldPhoto = [self getPhotoAt:dateString];
    if (oldPhoto) {
        [_context deleteObject:oldPhoto];
        [self deleteImageCache:oldPhoto];
    }
    
    OPPhoto *photo = [NSEntityDescription insertNewObjectForEntityForName:@"OPPhoto" inManagedObjectContext:_context];
    photo.source_image_url = source_image_url;
    photo.dateString = dateString;
    photo.user = user;
    [user addPhotosObject:photo];
    NSError *error;
    if (_context.hasChanges && ![_context save:&error]) {
        DHLogError(@"couldn't save: %@", [error localizedDescription]);
    }
}

- (OPPhoto *)getPhotoAt:(NSString *)date {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"OPPhoto" inManagedObjectContext:_context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dateString == %@", date];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *photos = [_context executeFetchRequest:request error:&error];
    if (error) {
        DHLogError(@"couldn't fetch: %@", [error localizedDescription]);
    }
    
    if ([photos count] > 0) {
        return [photos objectAtIndex:0];
    }
    return nil;
}

- (NSArray *)getPhotosInMonth:(NSString *)month {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"OPPhoto" inManagedObjectContext:_context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dateString BEGINSWITH[c] %@", month];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *photos = [_context executeFetchRequest:request error:&error];
    NSUInteger daysInMonth = [GlobalUtils daysOfMonthByDate:[[GlobalUtils dateFormatter] dateFromString:[NSString stringWithFormat:@"%@01", month]]];
    NSMutableArray *sortedPhotos = [NSMutableArray array];
    for (int i = 0; i < daysInMonth; i++) {
        [sortedPhotos addObject:[NSNull null]];
    }
    for (OPPhoto *photo in photos) {
        [sortedPhotos insertObject:photo atIndex:[[photo.dateString substringFromIndex:6] integerValue] - 1];
    }
    if (error) {
        DHLogError(@"couldn't fetch: %@", [error localizedDescription]);
    }
    return sortedPhotos;
}

- (NSDate *)firstDayIn1Photo {
    NSSet *photos = [self allPhotos];
    NSDate *firstDay = [NSDate date];
    for (OPPhoto *photo in photos) {
        NSDate *date = [[GlobalUtils dateFormatter] dateFromString:photo.dateString];
        if ([firstDay compare:date] == NSOrderedDescending) {
            firstDay = date;
        }
    }
    return firstDay;
}

- (NSSet *)allPhotos {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"OPPhoto" inManagedObjectContext:_context]];
    NSError *error;
    NSArray *photos = [_context executeFetchRequest:request error:&error];
    if (error) {
        DHLogError(@"couldn't fetch: %@", [error localizedDescription]);
    }
    return [NSSet setWithArray:photos];
}

- (void)deleteImageCache:(OPPhoto *)photo {
    FICImageCache *sharedImageCache = [FICImageCache sharedImageCache];
    [sharedImageCache deleteImageForEntity:photo withFormatName:OPPhotoSquareImage32BitBGRFormatName];
}

@end
