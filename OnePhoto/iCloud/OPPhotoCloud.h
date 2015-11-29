//
//  OPPhotoCloud.h
//  OnePhoto
//
//  Created by Hong Duan on 10/19/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ONE_PHOTO_EXTENSION @"1photopkg"
#define ONE_PHOTO_KEY_NOTE @"1photo.note"

@interface OPPhotoCloud : UIDocument

@property (nonatomic, strong) NSData *imageData;

@property (nonatomic, strong) NSData *metaData;

@end
