//
//  MultiPhotoViewer.m
//  OnePhoto
//
//  Created by Hong Duan on 11/13/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import "MultiPhotoViewer.h"
#import "OPPhoto.h"
#import "WXApi.h"

@interface MultiPhotoViewer () {
    UIViewController *_hostViewController;
    NSString *_date;
    NSString *_selectedPhoto;
    NSArray *_photosInCoreData;
    NSArray *_photoRelativelyPathsInCoreData;
    NSArray *_photoAbsolutelyUrlsIniCloud;
    NSMutableArray *_mergedPhotos;
}

@end

@implementation MultiPhotoViewer

- (instancetype)init {
    return [self initWithHost:nil date:nil selected:nil coreData:nil iCloud:nil];
}

- (instancetype)initWithHost:(UIViewController *)controller date:(NSString *)date selected:(NSString *)selectedPhoto coreData:(NSArray *)coreDataPhotos iCloud:(NSArray *)iCloudPhotos {
    if (self = [super init]) {
        _hostViewController = controller;
        _date = date;
        _selectedPhoto = selectedPhoto;
        _photosInCoreData = coreDataPhotos;
        _photoRelativelyPathsInCoreData = [self photoRelativelyPathsInCoreData];
        _photoAbsolutelyUrlsIniCloud = iCloudPhotos;
        _mergedPhotos = [self mergePhotos];
    }
    return self;
}

- (NSMutableArray *)mergePhotos {
    NSMutableArray *mergedPhotos = [NSMutableArray array];
    [mergedPhotos addObjectsFromArray:_photosInCoreData];
    for (NSURL *photoAbsolutelyUrlIniCloud in _photoAbsolutelyUrlsIniCloud) {
        if ([_photoRelativelyPathsInCoreData containsObject:[GlobalUtils last2PathComponentsOf:photoAbsolutelyUrlIniCloud]]) {
            continue;
        }
        [mergedPhotos addObject:photoAbsolutelyUrlIniCloud];
    }
    return mergedPhotos;
}

- (NSArray *)photoRelativelyPathsInCoreData {
    NSMutableArray *urls = [NSMutableArray array];
    for (OPPhoto *photo in _photosInCoreData) {
        [urls addObject:photo.source_image_url];
    }
    return [urls copy];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _mergedPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _mergedPhotos.count) {
        NSObject *photoObj = [_mergedPhotos objectAtIndex:index];
        NSURL *photoURL = nil;
        if ([photoObj isKindOfClass:[OPPhoto class]]) {
            NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
            photoURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:((OPPhoto *) photoObj).source_image_url];
        } else if ([photoObj isKindOfClass:[NSURL class]]) {
            photoURL = (NSURL *)photoObj;
        }
        MWPhoto *mwPhoto = [MWPhoto photoWithURL:photoURL];
        return mwPhoto;
    }
    return nil;
}

- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
    return [NSString stringWithFormat:@"%@ - %lu/%ld", [GlobalUtils chineseRepresentation:_date], index + 1, [_mergedPhotos count]];
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {

}

typedef void (^completionBlock)(void);

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser trashButtonPressedForPhotoAtIndex:(NSUInteger)index {
    UIBarButtonItem *trashButton = [photoBrowser valueForKey:@"_trashButton"];
    completionBlock completion = ^(){
        [_mergedPhotos removeObjectAtIndex:index];
        if (index >= [_mergedPhotos count]) {
            [photoBrowser setCurrentPhotoIndex:[_mergedPhotos count] - 1];
        }
        [photoBrowser reloadData];
        if ([_mergedPhotos count] == 0) {
            [_hostViewController dismissViewControllerAnimated:YES completion:nil];
        }
    };
    if ([[_mergedPhotos objectAtIndex:index] isKindOfClass:[OPPhoto class]]) {
        [GlobalUtils deletePhotoActionFrom:photoBrowser anchor:trashButton photo:[_mergedPhotos objectAtIndex:index] completion:completion];
    } else if ([[_mergedPhotos objectAtIndex:index] isKindOfClass:[NSURL class]]) {
        [GlobalUtils deletePhotoActionFrom:photoBrowser anchor:trashButton photoUrl:[_mergedPhotos objectAtIndex:index] completion:completion];
    }
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    NSObject *anchor;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8")) {
        anchor = [photoBrowser valueForKey:@"_actionButton"];
    }
    if ([[_mergedPhotos objectAtIndex:index] isKindOfClass:[OPPhoto class]]) {
        [GlobalUtils sharePhotoAction:photoBrowser anchor:anchor photo:[_mergedPhotos objectAtIndex:index]];
    } else if ([[_mergedPhotos objectAtIndex:index] isKindOfClass:[NSURL class]]) {
        [GlobalUtils sharePhotoAction:photoBrowser anchor:anchor photoUrl:[_mergedPhotos objectAtIndex:index]];
    }
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    [_hostViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
