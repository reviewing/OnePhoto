//
//  MultiPhotoViewer.h
//  OnePhoto
//
//  Created by Hong Duan on 11/13/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>

@interface MultiPhotoViewer : NSObject <MWPhotoBrowserDelegate>

- (instancetype)initWithHost:(UIViewController *)controller date:(NSString *)date selected:(NSString *)selectedPhoto coreData:(NSArray *)coreDataPhotos iCloud:(NSArray *)iCloudPhotos NS_DESIGNATED_INITIALIZER;

@end
