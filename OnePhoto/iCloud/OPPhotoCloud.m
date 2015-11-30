//
//  OPPhotoCloud.m
//  OnePhoto
//
//  Created by Hong Duan on 10/19/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import "OPPhotoCloud.h"

#define METADATA_FILENAME   @"photo.metadata"
#define PHOTO_FILENAME      @"photo.jpg"

@interface OPPhotoCloud ()

@property (nonatomic, strong) NSFileWrapper *fileWrapper;

@end

@implementation OPPhotoCloud

- (void)encodeObject:(id<NSCoding>)object toWrappers:(NSMutableDictionary *)wrappers filename:(NSString *)preferredFilename {
    @autoreleasepool {
        NSMutableData * data = [NSMutableData data];
        NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:object forKey:@"data"];
        [archiver finishEncoding];
        NSFileWrapper * wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
        [wrappers setObject:wrapper forKey:preferredFilename];
    }
}

- (id)decodeObjectFromWrapperWithFilename:(NSString *)filename {
    NSFileWrapper * fileWrapper = [self.fileWrapper.fileWrappers objectForKey:filename];
    if (!fileWrapper) {
        return nil;
    }
    
    NSData * data = [fileWrapper regularFileContents];
    NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    return [unarchiver decodeObjectForKey:@"data"];
}

- (NSData *)imageData {
    if (_imageData == nil) {
        if (self.fileWrapper != nil) {
            self.imageData = [self decodeObjectFromWrapperWithFilename:PHOTO_FILENAME];
        }
    }
    return _imageData;
}

- (NSData *)metaData {
    if (_metaData == nil) {
        if (self.fileWrapper != nil) {
            self.metaData = [self decodeObjectFromWrapperWithFilename:METADATA_FILENAME];
        }
    }
    return _metaData;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    self.fileWrapper = contents;
    self.imageData = nil;
    self.metaData = nil;
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
    NSMutableDictionary * wrappers = [NSMutableDictionary dictionary];
    if (self.imageData) {
        [self encodeObject:self.imageData toWrappers:wrappers filename:PHOTO_FILENAME];        
    }
    if (self.metaData) {
        [self encodeObject:self.metaData toWrappers:wrappers filename:METADATA_FILENAME];
    }
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:wrappers];
    return fileWrapper;
}

@end
