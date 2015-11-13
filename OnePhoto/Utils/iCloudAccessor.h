//
//  iCloudAccessor.h
//  OnePhoto
//
//  Created by Hong Duan on 11/12/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iCloudAccessor : NSObject

+ (instancetype)shareAccessor;

- (void)stopQuery;

- (void)startQuery;

- (NSArray *)urlsAt:(NSString *)date;

- (void)deleteFileWithRelativelyPath:(NSString *)path;

- (void)deleteFileWithAbsolutelyURL:(NSURL *)url;

@end
