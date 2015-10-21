//
//  OPFullscreenPhotoDisplayController.m
//  OnePhoto
//
//  Created by Hong Duan on 10/14/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import "OPFullscreenPhotoDisplayController.h"
#import "OPPhoto.h"
#import "OPPhotoCloud.h"

@interface OPFullscreenPhotoDisplayController () <UIGestureRecognizerDelegate> {
    OPPhoto *_photo;
    
    UIView *_fullscreenView;
    UIView *_backgroundView;

    UIImageView *_thumbnailImageView;
    CGRect _originalThumbnailImageViewFrame;
    NSUInteger _originalThumbnailImageViewSubviewIndex;
    UIView *_originalThumbnailImageViewSuperview;
    
    UIImageView *_sourceImageView;
    UITapGestureRecognizer *_tapGestureRecognizer;
}

@end

@implementation OPFullscreenPhotoDisplayController

+ (instancetype)sharedDisplayController {
    static OPFullscreenPhotoDisplayController *_sharedDisplayController = nil;
    
    if (_sharedDisplayController == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedDisplayController = [[[self class] alloc] init];
        });
    }
    
    return _sharedDisplayController;
}

- (instancetype)init {
    if (self = [super init]) {
        UIViewAutoresizing autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        
        _fullscreenView = [[UIView alloc] init];
        [_fullscreenView setAutoresizingMask:autoresizingMask];
        
        _backgroundView = [[UIView alloc] init];
        [_backgroundView setAutoresizingMask:autoresizingMask];
        [_backgroundView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.8]];
        
        _sourceImageView = [[UIImageView alloc] init];
        [_sourceImageView setAutoresizingMask:autoresizingMask];
        [_sourceImageView setContentMode:UIViewContentModeScaleAspectFill];
        [_sourceImageView setClipsToBounds:YES];
        
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerStateDidChange)];
        [_fullscreenView addGestureRecognizer:_tapGestureRecognizer];
    }
    
    return self;
}

- (BOOL)isDisplayingPhoto {
    return _photo != nil;
}

- (void)showPhoto:(OPPhoto *)photo withThumbnailImageView:(UIImageView *)thumbnailImageView {
    _photo = photo;
    
    _thumbnailImageView = thumbnailImageView;
    _originalThumbnailImageViewSuperview = [thumbnailImageView superview];
    _originalThumbnailImageViewFrame = [thumbnailImageView frame];
    _originalThumbnailImageViewSubviewIndex = [[[thumbnailImageView superview] subviews] indexOfObject:thumbnailImageView];

    UIView *rootViewControllerView = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
    [_fullscreenView setFrame:[rootViewControllerView bounds]];
    [rootViewControllerView addSubview:_fullscreenView];

    [_backgroundView setFrame:[_fullscreenView bounds]];
    [_backgroundView setAlpha:0];
    [_fullscreenView addSubview:_backgroundView];

    CGRect convertedThumbnailImageViewFrame = [_originalThumbnailImageViewSuperview convertRect:_originalThumbnailImageViewFrame toView:_fullscreenView];
    [_thumbnailImageView setFrame:convertedThumbnailImageViewFrame];
    
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:photo.source_image_url];
    OPPhotoCloud *photoCloud = [[OPPhotoCloud alloc] initWithFileURL:ubiquitousURL];
    [photoCloud openWithCompletionHandler:^(BOOL success) {
        if (success) {
            DHLogDebug(@"iCloud document opened");
            UIImage *sourceImage = [UIImage imageWithData:photoCloud.imageData];

            [_sourceImageView setImage:sourceImage];
            [_sourceImageView setFrame:convertedThumbnailImageViewFrame];
            [_sourceImageView setAlpha:0];
            [_fullscreenView addSubview:_sourceImageView];
            
            if ([_delegate respondsToSelector:@selector(photoDisplayController:willShowSourceImage:forPhoto:withThumbnailImageView:)]) {
                [_delegate photoDisplayController:self willShowSourceImage:sourceImage forPhoto:_photo withThumbnailImageView:_thumbnailImageView];
            }
            
            [UIView animateWithDuration:0.3 animations:^{
                [_backgroundView setAlpha:1];
                [_sourceImageView setAlpha:1];
                [_sourceImageView setFrame:[_fullscreenView bounds]];
            } completion:^(BOOL finished) {
                if ([_delegate respondsToSelector:@selector(photoDisplayController:didShowSourceImage:forPhoto:withThumbnailImageView:)]) {
                    [_delegate photoDisplayController:self didShowSourceImage:sourceImage forPhoto:_photo withThumbnailImageView:_thumbnailImageView];
                }
            }];
        } else {
            DHLogDebug(@"failed opening document from iCloud");
        }
    }];
}

- (void)hidePhoto {
    UIImage *sourceImage = [_sourceImageView image];
    if ([_delegate respondsToSelector:@selector(photoDisplayController:willHideSourceImage:forPhoto:withThumbnailImageView:)]) {
        [_delegate photoDisplayController:self willHideSourceImage:sourceImage forPhoto:_photo withThumbnailImageView:_thumbnailImageView];
    }
    
    CGRect convertedThumbnailImageViewFrame = [_originalThumbnailImageViewSuperview convertRect:_originalThumbnailImageViewFrame toView:_fullscreenView];
    [UIView animateWithDuration:0.3 animations:^{
        [_backgroundView setAlpha:0];
        [_sourceImageView setAlpha:0];
        [_sourceImageView setFrame:convertedThumbnailImageViewFrame];
    } completion:^(BOOL finished) {
        [_thumbnailImageView setFrame:_originalThumbnailImageViewFrame];
        [_originalThumbnailImageViewSuperview insertSubview:_thumbnailImageView atIndex:_originalThumbnailImageViewSubviewIndex];
        
        [_fullscreenView removeFromSuperview];
        
        if ([_delegate respondsToSelector:@selector(photoDisplayController:didHideSourceImage:forPhoto:withThumbnailImageView:)]) {
            [_delegate photoDisplayController:self didHideSourceImage:sourceImage forPhoto:_photo withThumbnailImageView:_thumbnailImageView];
        }
        
        _photo = nil;
        _thumbnailImageView = nil;
        _originalThumbnailImageViewSuperview = nil;
        _originalThumbnailImageViewFrame = CGRectZero;
        _originalThumbnailImageViewSubviewIndex = 0;
        _sourceImageView.image = nil;
    }];
}

- (void)tapGestureRecognizerStateDidChange {
    if ([_tapGestureRecognizer state] == UIGestureRecognizerStateEnded) {
        [self hidePhoto];
    }
}

@end
