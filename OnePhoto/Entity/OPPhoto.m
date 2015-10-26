//
//  OPPhoto.m
//  OnePhoto
//
//  Created by Hong Duan on 9/1/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "OPPhoto.h"
#import "OPPhotoCloud.h"
#import <FastImageCache/FICUtilities.h>

NSString *const OPPhotoImageFormatFamily = @"OPPhotoImageFormatFamily";

NSString *const OPPhotoSquareImage32BitBGRFormatName = @"top.defaults.OnePhoto.OPPhotoSquareImage32BitBGRFormatName";
NSString *const OPPhotoPixelImageFormatName = @"top.defaults.OnePhoto.OPPhotoPixelImageFormatName";

CGSize OPPhotoSquareImageSize = {375.f/7.f, 375.f/7.f};
CGSize const OPPhotoPixelImageSize = {1, 1};

@interface OPPhoto () {
    NSString *_UUID;
}

@end

@implementation OPPhoto

@dynamic source_image_url;
@dynamic dateString;

- (UIImage *)sourceImage {
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:self.source_image_url];
    OPPhotoCloud *photoCloud = [[OPPhotoCloud alloc] initWithFileURL:ubiquitousURL];
    dispatch_semaphore_t waitForICloud = dispatch_semaphore_create(0);
    [photoCloud openWithCompletionHandler:^(BOOL success) {
        if (success) {
            DHLogDebug(@"iCloud document opened");
        } else {
            DHLogDebug(@"failed opening document from iCloud");
        }
        dispatch_semaphore_signal(waitForICloud);
    }];

    dispatch_semaphore_wait(waitForICloud, DISPATCH_TIME_FOREVER);
    UIImage *sourceImage = [UIImage imageWithData:photoCloud.imageData];
    DHLogDebug(@"%@", [ubiquitousURL absoluteString]);
    return sourceImage;
}

#pragma mark - Image Helper Functions

static CGMutablePathRef _OPCreateRoundedRectPath(CGRect rect, CGFloat cornerRadius) {
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat minX = CGRectGetMinX(rect);
    CGFloat midX = CGRectGetMidX(rect);
    CGFloat maxX = CGRectGetMaxX(rect);
    CGFloat minY = CGRectGetMinY(rect);
    CGFloat midY = CGRectGetMidY(rect);
    CGFloat maxY = CGRectGetMaxY(rect);
    
    CGPathMoveToPoint(path, NULL, minX, midY);
    CGPathAddArcToPoint(path, NULL, minX, maxY, midX, maxY, cornerRadius);
    CGPathAddArcToPoint(path, NULL, maxX, maxY, maxX, midY, cornerRadius);
    CGPathAddArcToPoint(path, NULL, maxX, minY, midX, minY, cornerRadius);
    CGPathAddArcToPoint(path, NULL, minX, minY, minX, midY, cornerRadius);
    
    return path;
}

static UIImage * _OPSquareImageFromImage(UIImage *image) {
    UIImage *squareImage = nil;
    CGSize imageSize = [image size];
    
    if (imageSize.width == imageSize.height) {
        squareImage = image;
    } else {
        // Compute square crop rect
        CGFloat smallerDimension = MIN(imageSize.width, imageSize.height);
        CGRect cropRect = CGRectMake(0, 0, smallerDimension, smallerDimension);
        
        // Center the crop rect either vertically or horizontally, depending on which dimension is smaller
        if (imageSize.width <= imageSize.height) {
            cropRect.origin = CGPointMake(0, rintf((imageSize.height - smallerDimension) / 2.0));
        } else {
            cropRect.origin = CGPointMake(rintf((imageSize.width - smallerDimension) / 2.0), 0);
        }
        
        CGImageRef croppedImageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
        squareImage = [UIImage imageWithCGImage:croppedImageRef];
        CGImageRelease(croppedImageRef);
    }
    
    return squareImage;
}

static UIImage * _OPStatusBarImageFromImage(UIImage *image) {
    CGSize imageSize = [image size];
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    CGRect cropRect = CGRectMake(0, 0, imageSize.width, statusBarSize.height);
    
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    UIImage *statusBarImage = [UIImage imageWithCGImage:croppedImageRef];
    CGImageRelease(croppedImageRef);
    
    return statusBarImage;
}

#pragma mark - FICImageCacheEntity

- (NSString *)UUID {
    if (_UUID == nil) {
        // MD5 hashing is expensive enough that we only want to do it once
        NSString *imageName = [self.source_image_url lastPathComponent];
        CFUUIDBytes UUIDBytes = FICUUIDBytesFromMD5HashOfString(imageName);
        _UUID = FICStringWithUUIDBytes(UUIDBytes);
    }
    
    return _UUID;
}

- (NSString *)sourceImageUUID {
    return [self UUID];
}

- (NSURL *)sourceImageURLWithFormatName:(NSString *)formatName {
    return [NSURL URLWithString:self.source_image_url];
}

- (FICEntityImageDrawingBlock)drawingBlockForImage:(UIImage *)image withFormatName:(NSString *)formatName {
    FICEntityImageDrawingBlock drawingBlock = ^(CGContextRef contextRef, CGSize contextSize) {
        CGRect contextBounds = CGRectZero;
        contextBounds.size = contextSize;
        CGContextClearRect(contextRef, contextBounds);
        
        if ([formatName isEqualToString:OPPhotoPixelImageFormatName]) {
            UIImage *statusBarImage = _OPStatusBarImageFromImage(image);
            CGContextSetInterpolationQuality(contextRef, kCGInterpolationMedium);
            
            UIGraphicsPushContext(contextRef);
            [statusBarImage drawInRect:contextBounds];
            UIGraphicsPopContext();
        } else {
            UIImage *squareImage = _OPSquareImageFromImage(image);
                        
            UIGraphicsPushContext(contextRef);
            [squareImage drawInRect:contextBounds];
            UIGraphicsPopContext();
        }
    };
    
    return drawingBlock;
}

@end
