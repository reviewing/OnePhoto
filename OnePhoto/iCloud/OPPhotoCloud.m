//
//  OPPhotoCloud.m
//  OnePhoto
//
//  Created by Hong Duan on 10/19/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import "OPPhotoCloud.h"

@implementation OPPhotoCloud

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    self.imageData = contents;
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
    return self.imageData;
}

@end
