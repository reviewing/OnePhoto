//
//  DHLogger.h
//  DHLogger
//
//  Created by Hong Duan on 8/7/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DHLogDebug(fmt, ...) [DHLogger logDebug:[NSString stringWithFormat:@"%s:%d " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]]
#define DHLogError(fmt, ...) [DHLogger logError:[NSString stringWithFormat:@"%s:%d " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]]
#define DHLogDebugWithClass(fmt, ...) [DHLogger logDebug:[NSString stringWithFormat:@"%@ %s:%d " fmt, [[self class] description], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]]
#define DHLogErrorWithClass(fmt, ...) [DHLogger logError:[NSString stringWithFormat:@"%@ %s:%d " fmt, [[self class] description], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]]

typedef NS_OPTIONS(NSInteger, DHLogLevel) {
    DH_LOG_OFF = 0,
    DH_LOG_ERROR = 1,
    DH_LOG_WARN = 2,
    DH_LOG_INFO = 3,
    DH_LOG_DEBUG = 4,
    DH_LOG_VERBOSE = 5,
};

@interface DHLogger : NSObject

/**
 * @brief 设置logLevel
 *
 * @param logLevel
 *            日志级别
 */
+ (void)setLogLevel:(DHLogLevel)logLevel;

/**
 * @brief 设置是否写日志文件
 *
 * @param logToFile
 *            是否写日志文件
 */
+ (void)logToFile:(BOOL)logToFile;

/**
 * @brief 设置是否写数据文件（注：开启后将会降低运行速度）
 *
 * @param flag
 *            是否写数据文件
 */
+ (void)setWriteDataToFile:(BOOL)flag;

/**
 * @return flag
 *            是否写数据文件
 */
+ (BOOL)shouldWriteDataToFile;

/**
 * @brief 当日志级别>=DH_LOG_DEBUG时输出日志
 *
 * @param logMessage
 *            日志信息
 */
+ (void)logDebug:(NSString *)logMessage;

/**
 * @brief 当日志级别>=DH_LOG_ERROR时输出日志
 *
 * @param logMessage
 *            日志信息
 */
+ (void)logError:(NSString *)logMessage;

@end
