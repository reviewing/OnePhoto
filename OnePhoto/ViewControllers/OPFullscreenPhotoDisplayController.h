//
//  OPFullscreenPhotoDisplayController.h
//  OnePhoto
//
//  Created by Hong Duan on 10/14/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class OPPhoto;
@protocol  OPFullscreenPhotoDisplayControllerDelegate;

@interface OPFullscreenPhotoDisplayController : NSObject

@property (nonatomic, weak) id <OPFullscreenPhotoDisplayControllerDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL isDisplayingPhoto;

+ (instancetype)sharedDisplayController;

- (void)showPhoto:(OPPhoto *)photo withThumbnailImageView:(UIImageView *)thumbnailImageView;

@end

@protocol OPFullscreenPhotoDisplayControllerDelegate <NSObject>

@optional
- (void)photoDisplayController:(OPFullscreenPhotoDisplayController *)photoDisplayController willShowSourceImage:(UIImage *)sourceImage forPhoto:(OPPhoto *)photo withThumbnailImageView:(UIImageView *)thumbnailImageView;
- (void)photoDisplayController:(OPFullscreenPhotoDisplayController *)photoDisplayController didShowSourceImage:(UIImage *)sourceImage forPhoto:(OPPhoto *)photo withThumbnailImageView:(UIImageView *)thumbnailImageView;

- (void)photoDisplayController:(OPFullscreenPhotoDisplayController *)photoDisplayController willHideSourceImage:(UIImage *)sourceImage forPhoto:(OPPhoto *)photo withThumbnailImageView:(UIImageView *)thumbnailImageView;
- (void)photoDisplayController:(OPFullscreenPhotoDisplayController *)photoDisplayController didHideSourceImage:(UIImage *)sourceImage forPhoto:(OPPhoto *)photo withThumbnailImageView:(UIImageView *)thumbnailImageView;

@end