//
//  OPPhoto.h
//  OnePhoto
//
//  Created by Hong Duan on 9/1/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <FastImageCache/FICEntity.h>

extern NSString *const OPPhotoImageFormatFamily;

extern NSString *const OPPhotoSquareImage32BitBGRFormatName;
extern NSString *const OPPhotoPixelImageFormatName;

extern CGSize OPPhotoSquareImageSize;
extern CGSize const OPPhotoPixelImageSize;

@class OPUser;

@interface OPPhoto : NSManagedObject <FICEntity>

@property (nonatomic, retain) NSString * source_image_url;
@property (nonatomic, retain) NSString * dateString;

- (UIImage *)sourceImage;

@end
