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
}

@end

@implementation iCloudAccessor

+ (instancetype)shareAccessor {
    static iCloudAccessor *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[iCloudAccessor alloc] init];
        sharedInstance->_iCloudURLs = [[NSMutableArray alloc] init];
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
        [_iCloudURLs addObject:fileURL];
    }
    
    DHLogDebug(@"Found %lu iCloud files.", (unsigned long)_iCloudURLs.count);
    [_query enableUpdates];
    [[NSNotificationCenter defaultCenter] postNotificationName:OPiCloudPhotosMetadataUpdatedNotification object:nil];
}

- (NSArray *)urlsAt:(NSString *)date {
    if (!_iCloudURLs) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastPathComponent BEGINSWITH[c] %@", date];
    NSArray *urls = [_iCloudURLs filteredArrayUsingPredicate:predicate];
    return urls;
}

- (void)deleteFileWithRelativelyPath:(NSString *)path {
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:path];
    [self deleteFileWithAbsolutelyURL:ubiquitousURL];
}

- (void)deleteFileWithAbsolutelyURL:(NSURL *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting
                                              error:nil byAccessor:^(NSURL* writingURL) {
                                                  NSFileManager* fileManager = [[NSFileManager alloc] init];
                                                  [fileManager removeItemAtURL:writingURL error:nil];
                                              }];
    });
}

@end
