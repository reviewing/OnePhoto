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

- (void)insertUser:(NSString *)display_name withID:(NSString *)user_id {
    OPUser *user = [NSEntityDescription insertNewObjectForEntityForName:@"OPUser" inManagedObjectContext:_context];
    user.display_name = display_name;
    user.user_id = user_id;
    NSError *error;
    if (_context.hasChanges && ![_context save:&error]) {
        DHLogError(@"couldn't save: %@", [error localizedDescription]);
    }
}

- (BOOL)isPhotoOfDateExists:(NSString *)date ofUser:(NSString *)user_id {
    return YES;
}

- (void)insertPhoto:(NSString *)source_image_url toUser:(NSString *)user_id {
    OPUser *user = [self fetchUserByID:user_id];
    if (user == nil) {
        DHLogError(@"user not exists! id: %@", user_id);
        return;
    }
    OPPhoto *photo = [NSEntityDescription insertNewObjectForEntityForName:@"OPPhoto" inManagedObjectContext:_context];
    photo.source_image_url = source_image_url;
    NSString *photoFileName = [source_image_url lastPathComponent];
    photo.dateString = [photoFileName substringToIndex:[photoFileName length] - 4];
    photo.user = user;
    [user addPhotosObject:photo];
    NSError *error;
    if (_context.hasChanges && ![_context save:&error]) {
        DHLogError(@"couldn't save: %@", [error localizedDescription]);
    }
}

- (OPUser *)fetchUserByID:(NSString *)user_id {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"OPUser" inManagedObjectContext:_context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id == %@", user_id];
    [request setPredicate:predicate];
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

@end
