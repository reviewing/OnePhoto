//
//  iCloudAccessor.m
//  OnePhoto
//
//  Created by Hong Duan on 11/12/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import "iCloudAccessor.h"

@interface iCloudAccessor () {
    NSMetadataQuery * _query;
    NSMutableArray *_iCloudURLs;
    NSMutableArray *_deletingQueue;
}

@end

@implementation iCloudAccessor

+ (instancetype)shareAccessor {
    static iCloudAccessor *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[iCloudAccessor alloc] init];
        sharedInstance->_iCloudURLs = [[NSMutableArray alloc] init];
        sharedInstance->_deletingQueue = [NSMutableArray array];
    });
    return sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMetadataQuery *)documentQuery {
    NSMetadataQuery * query = [[NSMetadataQuery alloc] init];
    if (query) {
        [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
        [query setPredicate:[NSPredicate predicateWithFormat:@"%K CONTAINS[c] %@ AND %K ENDSWITH %@", NSMetadataItemPathKey, @"/iCloud~top~defaults~OnePhoto/Documents/photos/", NSMetadataItemPathKey, @".jpg"]];
    }
    return query;
}

- (void)stopQuery {
    if (_query) {
        DHLogDebug(@"No longer watching iCloud dir...");
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidUpdateNotification object:nil];
        [_query stopQuery];
        _query = nil;
    }
}

- (void)startQuery {
    [self stopQuery];
    DHLogDebug(@"Starting to watch iCloud dir...");
    _query = [self documentQuery];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processiCloudFiles:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processiCloudFiles:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:nil];
    
    [_query startQuery];
}

- (void)processiCloudFiles:(NSNotification *)notification {
    [_query disableUpdates];
    [_iCloudURLs removeAllObjects];
    
    NSArray * queryResults = [_query results];
    for (NSMetadataItem * result in queryResults) {
        NSURL * fileURL = [result valueForAttribute:NSMetadataItemURLKey];
        NSNumber * aBool = nil;
        
        [fileURL getResourceValue:&aBool forKey:NSURLIsHiddenKey error:nil];
        if (aBool && ![aBool boolValue]) {
            [_iCloudURLs addObject:fileURL];
        }
    }
    
    DHLogDebug(@"Found %lu iCloud files.", (unsigned long)_iCloudURLs.count);
    [_query enableUpdates];
    [[NSNotificationCenter defaultCenter] postNotificationName:OPiCloudPhotosMetadataUpdatedNotification object:nil];
}

- (NSArray *)urls {
    return [self cleanURLs:_iCloudURLs cleanDeletingQueue:YES];
}

- (BOOL)relativelyPathExists:(NSString *)path {
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:path];
    return [self urlExists:ubiquitousURL];
}

- (BOOL)urlExists:(NSURL *)url {
    return [_iCloudURLs containsObject:url];
}

- (NSArray *)urlsAt:(NSString *)date {
    if (!_iCloudURLs) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastPathComponent BEGINSWITH[c] %@", date];
    NSArray *urls = [_iCloudURLs filteredArrayUsingPredicate:predicate];
    return [self cleanURLs:urls cleanDeletingQueue:NO];
}

- (NSArray *)cleanURLs:(NSArray *)rawURLs cleanDeletingQueue:(BOOL)cleanDQ {
    NSMutableArray *urls = [NSMutableArray array];
    
    if (cleanDQ) {
        NSMutableArray *deletingURLs = [_deletingQueue mutableCopy];
        for (NSURL *url in _deletingQueue) {
            if (![rawURLs containsObject:url]) {
                [deletingURLs removeObject:url];
            }
        }
        
        _deletingQueue = deletingURLs;
    }
    
    for (NSURL *url in rawURLs) {
        if (![_deletingQueue containsObject:url]) {
            [urls addObject:url];
        }
    }
    
    return [urls copy];
}

- (void)deleteFileWithRelativelyPath:(NSString *)path {
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:path];
    [self deleteFileWithAbsolutelyURL:ubiquitousURL];
}

- (void)deleteFileWithAbsolutelyURL:(NSURL *)url {
    [_deletingQueue addObject:url];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting
                                              error:nil byAccessor:^(NSURL* writingURL) {
                                                  NSFileManager* fileManager = [[NSFileManager alloc] init];
                                                  NSError *error;
                                                  [fileManager removeItemAtURL:writingURL error:&error];
                                                  if (error) {
                                                      DHLogError(@"removeItemAtURL:%@ error: %@", writingURL, error);
                                                  } else {
                                                      DHLogDebug(@"removeItemAtURL:%@ succeed!!!", writingURL);
                                                  }
                                              }];
    });
}

@end
