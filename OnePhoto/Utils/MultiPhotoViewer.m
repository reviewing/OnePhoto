//
//  MultiPhotoViewer.m
//  OnePhoto
//
//  Created by Hong Duan on 11/13/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import "MultiPhotoViewer.h"
#import "OPPhoto.h"
#import "OPPhotoCloud.h"
#import "iCloudAccessor.h"
#import "WXApi.h"

@interface MultiPhotoViewer () {
    UIViewController *_hostViewController;
    NSString *_date;
    NSString *_selectedPhoto;
    NSArray *_photosInCoreData;
    NSArray *_photoRelativelyPathsInCoreData;
    NSArray *_photoAbsolutelyUrlsIniCloud;
    NSMutableArray *_mergedPhotos;
    
    NSMutableDictionary *_imageCache;
    NSInteger _displayingIndex;
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
        _imageCache = [NSMutableDictionary dictionary];
        _displayingIndex = -1;
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
        if (![[photoURL lastPathComponent] hasSuffix:@".jpg"]) {
            UIImage *image = [_imageCache objectForKey:[photoURL lastPathComponent]];
            if (!image) {
                OPPhotoCloud *photoCloud = [[OPPhotoCloud alloc] initWithFileURL:photoURL];
                [photoCloud openWithCompletionHandler:^(BOOL success) {
                    if (success) {
                        DHLogDebug(@"iCloud document opened");
                        UIImage *image = [UIImage imageWithData:photoCloud.imageData];
                        if ([_imageCache count] > 3) {
                            [_imageCache removeAllObjects];
                        }
                        if (image) {
                            [_imageCache setObject:image forKey:[photoURL lastPathComponent]];
                            [photoCloud closeWithCompletionHandler:^(BOOL success) {
                                if (success) {
                                    DHLogDebug(@"iCloud document closed");
                                } else {
                                    DHLogDebug(@"failed closing document from iCloud");
                                }
                            }];
                            if (_displayingIndex == index) {
                                [photoBrowser reloadData];
                            } else {
                                MWPhoto *tempMWPhoto = [MWPhoto photoWithImage:image];
                                [photoBrowser replaceObjectAtIndex:index withObject:tempMWPhoto];
                            }
                        }
                    } else {
                        DHLogDebug(@"failed opening document from iCloud");
                    }
                }];
            } else {
                mwPhoto = [MWPhoto photoWithImage:image];
                mwPhoto.caption = @"1 Photo";
            }
        }
        return mwPhoto;
    }
    return nil;
}

- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
    return [NSString stringWithFormat:@"%@ - %lu/%ld", [GlobalUtils chineseRepresentation:_date], index + 1, [_mergedPhotos count]];
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    _displayingIndex = index;
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *photoData;
        if ([[_mergedPhotos objectAtIndex:index] isKindOfClass:[OPPhoto class]]) {
            photoData = UIImageJPEGRepresentation([((OPPhoto *)[_mergedPhotos objectAtIndex:index]) sourceImage], 0.8);
        } else if ([[_mergedPhotos objectAtIndex:index] isKindOfClass:[NSURL class]]) {
            photoData = [[iCloudAccessor shareAccessor] photoDataOfRelativelyPath:[_mergedPhotos objectAtIndex:index]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [GlobalUtils sharePhotoAction:photoBrowser anchor:anchor photo:photoData];
        });
    });
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    [_hostViewController dismissViewControllerAnimated:YES completion:nil];
    [_imageCache removeAllObjects];
    _imageCache = nil;
}

@end
