//
//  DHLogger.m
//  DHLogger
//
//  Created by Hong Duan on 8/7/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "DHLogger.h"

#ifdef DH_DEBUG
static DHLogLevel g_logLevel = DH_LOG_DEBUG;
#else
static DHLogLevel g_logLevel = DH_LOG_OFF;
#endif

#ifdef DH_LOG_TO_FILE
static BOOL g_logToFile = YES;
#else
static BOOL g_logToFile = NO;
#endif

static BOOL g_write_data_to_file = NO;

@implementation DHLogger

+ (void)setLogLevel:(DHLogLevel)logLevel {
    g_logLevel = logLevel;
}

+ (void)logToFile:(BOOL)logToFile {
    g_logToFile = logToFile;
}

+ (void)setWriteDataToFile:(BOOL)flag {
    g_write_data_to_file = flag;
}

+ (BOOL)shouldWriteDataToFile {
    return g_write_data_to_file;
}

+ (void)logDebug:(NSString *)logMessage {
    if (g_logLevel < DH_LOG_DEBUG) {
        return;
    }
    [self printLogDebug:[NSString stringWithFormat:@"DEBUG|%@", logMessage]];
}

+ (void)logError:(NSString *)logMessage {
    if (g_logLevel < DH_LOG_ERROR) {
        return;
    }
    [self printLogError:[NSString stringWithFormat:@"ERROR|%@", logMessage]];
}

#define XCODE_COLORS_ESCAPE @"\033["

#define XCODE_COLORS_RESET_FG  XCODE_COLORS_ESCAPE @"fg;" // Clear any foreground color
#define XCODE_COLORS_RESET_BG  XCODE_COLORS_ESCAPE @"bg;" // Clear any background color
#define XCODE_COLORS_RESET     XCODE_COLORS_ESCAPE @";"   // Clear any foreground or background color

+ (void)printLogDebug:(NSString *)logMessage {
    if (g_logToFile) {
        [self writeLogToFileInDocuments:logMessage];
    }
    NSLog(@"%@", logMessage);
}

+ (void)printLogError:(NSString *)logMessage {
    if (g_logToFile) {
        [self writeLogToFileInDocuments:logMessage];
    }
    NSLog(XCODE_COLORS_ESCAPE @"fg255,0,0;" @"%@" XCODE_COLORS_RESET, logMessage);
}

+ (void)writeLogToFileInDocuments:(NSString *)logMessage {
    static NSLock *_logLock = nil;
    
    if (_logLock == nil) {
        _logLock = [[NSLock alloc] init];
    }
    
    [_logLock lock];
    // get the file path
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"DH_log.txt"];
    
    // create file if it doesn't exist
    if(![[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
    }
    
    // append text to file (you'll probably want to add a newline every write)
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
    [file seekToEndOfFile];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"H"]];
    NSString *logString = [[NSString alloc] initWithFormat:@"%@ %@\n", [dateFormatter stringFromDate:[NSDate date]], logMessage];
    
    [file writeData:[logString dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
    [_logLock unlock];
}

@end
