//
//  CoreDataHelper.m
//  OnePhoto
//
//  Created by Hong Duan on 9/6/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "CoreDataHelper.h"
#import "OPPhoto.h"
#import "iCloudAccessor.h"
#import "AppDelegate.h"
#import <FastImageCache/FICImageCache.h>
#import <MMWormhole/MMWormhole.h>

#define PHOTO_COUNT_KEY @"kOPPhotoCount"
#define CONSECUTIVE_DAYS_KEY @"kOPConsecutiveDays"
#define TODAY_PHOTO_NAME @"kOPTodayPhotoName"
#define TODAT_IMAGE_DATA @"kOPTodayImageData"

@interface CoreDataHelper () {
    NSManagedObjectContext *_context;
}

@property (nonatomic, strong) MMWormhole *wormhole;

@end

@implementation CoreDataHelper

+ (instancetype)sharedHelper {
    static CoreDataHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CoreDataHelper alloc] init];
        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        sharedInstance->_context = [appDelegate managedObjectContext];
        sharedInstance.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.top.defaults.onephoto" optionalDirectory:@"wormhole"];
    });
    return sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OPiCloudPhotosMetadataUpdatedNotification object:nil];
    [[iCloudAccessor shareAccessor] stopQuery];
}

- (void)tryRefresh {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OPiCloudPhotosMetadataUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(iCloudPhotosMetadataUpdated:)
                                                 name:OPiCloudPhotosMetadataUpdatedNotification
                                               object:nil];
    [[iCloudAccessor shareAccessor] startQuery];
}

- (void)iCloudPhotosMetadataUpdated:(NSNotification *)notification {
    DHLogDebug(@"OPiCloudPhotosMetadataUpdatedNotification");
    [self perfromRefresh];
}

- (void)perfromRefresh {
    NSSet *photos = [self allPhotos];
    for (OPPhoto *photo in photos) {
        if (![[iCloudAccessor shareAccessor] relativelyPathExists:photo.source_image_url]) {
            [self deletePhoto:photo];
        }
    }
    NSArray *urls = [[iCloudAccessor shareAccessor] urls];
    for (NSURL *url in urls) {
        NSString *dateString = [[url.path lastPathComponent] substringToIndex:8];
        NSString *relativelyPath = [GlobalUtils last2PathComponentsOf:url];
        if (![self isPhotoOfDateExists:dateString]) {
            [self insertPhoto:relativelyPath];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:OPCoreDataStoreUpdatedNotification object:nil];
}

- (BOOL)isPhotoOfDateExists:(NSString *)date {
    return [[self getPhotosAt:date] count] > 0;
}

- (void)insertPhoto:(NSString *)source_image_url {
    NSString *photoFileName = [source_image_url lastPathComponent];
    NSString *dateString = [photoFileName substringToIndex:8];
    
    OPPhoto *photo = [NSEntityDescription insertNewObjectForEntityForName:@"OPPhoto" inManagedObjectContext:_context];
    photo.source_image_url = source_image_url;
    photo.dateString = dateString;
    NSError *error;
    if (_context.hasChanges && ![_context save:&error]) {
        DHLogError(@"couldn't save: %@", [error localizedDescription]);
    }
    [self cacheNewDataForAppGroup];
}

- (void)deletePhoto:(OPPhoto *)photo {
    NSString *photoPath = photo.source_image_url;
    [self deleteImageCache:photo];
    [_context deleteObject:photo];
    NSError *error;
    if (_context.hasChanges && ![_context save:&error]) {
        DHLogError(@"couldn't save: %@", [error localizedDescription]);
    } else {
        [[iCloudAccessor shareAccessor] deleteFileWithRelativelyPath:photoPath];
    }
    [self cacheNewDataForAppGroup];
}

- (NSArray *)getPhotosAt:(NSString *)date {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"OPPhoto" inManagedObjectContext:_context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dateString BEGINSWITH[c] %@", date];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *photos = [_context executeFetchRequest:request error:&error];
    if (error) {
        DHLogError(@"couldn't fetch: %@", [error localizedDescription]);
    }
    return photos;
}

- (NSArray *)getPhotosForAMonthView:(NSString *)month {
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
        [sortedPhotos removeObjectAtIndex:[[photo.dateString substringFromIndex:6] integerValue] - 1];
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

- (NSArray *)allPhotosSorted {
    return [[NSOrderedSet orderedSetWithSet:[self allPhotos]] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"dateString" ascending:YES]]];
}

- (NSInteger)countOfPhotos {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"OPPhoto" inManagedObjectContext:_context]];
    NSError *error;
    NSInteger count = [_context countForFetchRequest:request error:&error];
    if (error) {
        DHLogError(@"couldn't fetch: %@", [error localizedDescription]);
        count = -1;
    }
    return count;
}

- (void)cacheNewDataForAppGroup {
    NSUserDefaults * defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.top.defaults.onephoto"];
    [defaults setObject:[NSNumber numberWithInteger:[self countOfPhotos]] forKey:PHOTO_COUNT_KEY];
    
    NSArray *photos = [self allPhotosSorted];
    NSEnumerator *photosEnumerator = [photos reverseObjectEnumerator];
    NSInteger consecutiveDays = 0;
    NSString *today = [[GlobalUtils dateFormatter] stringFromDate:[NSDate date]];

    OPPhoto *photo;
    NSString *daySentinel = today;
    
    BOOL isTodayPhotoTaked = NO;
    while ((photo = [photosEnumerator nextObject])) {
        if (!isTodayPhotoTaked && [photo.dateString isEqualToString:today]) {
            isTodayPhotoTaked = YES;
            consecutiveDays++;
        } else {
            if ([GlobalUtils date:photo.dateString isJustBefore:daySentinel]) {
                consecutiveDays++;
                daySentinel = photo.dateString;
            } else if ([photo.dateString isEqualToString:daySentinel]) {
                continue;
            } else {
                break;
            }
        }
    }
    
    [defaults setObject:[NSNumber numberWithInteger:consecutiveDays] forKey:CONSECUTIVE_DAYS_KEY];
    if (isTodayPhotoTaked) {
        OPPhoto *todayPhoto = [photos lastObject];
        if (![[defaults stringForKey:TODAY_PHOTO_NAME] isEqualToString:todayPhoto.source_image_url]) {
            [defaults setObject:todayPhoto.source_image_url forKey:TODAY_PHOTO_NAME];
            [[FICImageCache sharedImageCache] asynchronouslyRetrieveImageForEntity:todayPhoto withFormatName:OPPhotoSquareImage32BitBGRFormatName completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
                [defaults setObject:UIImageJPEGRepresentation(image, 1.0) forKey:TODAT_IMAGE_DATA];
            }];
        }
    } else {
        [defaults setObject:nil forKey:TODAY_PHOTO_NAME];
        [defaults setObject:nil forKey:TODAT_IMAGE_DATA];
    }
    [self.wormhole passMessageObject:@{@"flag" : @"check"} identifier:@"update"];
}

- (void)deleteImageCache:(OPPhoto *)photo {
    FICImageCache *sharedImageCache = [FICImageCache sharedImageCache];
    [sharedImageCache deleteImageForEntity:photo withFormatName:OPPhotoSquareImage32BitBGRFormatName];
}

@end
