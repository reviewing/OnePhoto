//
//  GlobalUtils.h
//  OnePhoto
//
//  Created by Hong Duan on 8/29/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString * const OPCoreDataStoreMerged;
FOUNDATION_EXPORT NSString * const OPNotificationType;
FOUNDATION_EXPORT NSString * const OPNotificationTypeDailyReminder;
FOUNDATION_EXPORT NSString * const OPUbiquitousKeyValueStoreHasPhotoKey;

@interface GlobalUtils : NSObject

+ (UIColor *)appBaseColor;

+ (UIColor *)appBaseLighterColor;

+ (UIColor *)appBaseDarkerColor;

+ (void)setAppBaseColor:(UIColor *)color;

+ (CGFloat)monthLabelSize;

+ (NSDateFormatter *)dateFormatter;

+ (NSString *)stringFromDate:(NSDate *)date;

+ (NSDateFormatter *)HHmmFormatter;

+ (NSDateFormatter *)chineseFormatter;

+ (NSUInteger)daysOfMonthByDate:(NSDate *)date;

+ (NSInteger)dayOfMonth:(NSDate *)date;

+ (NSDate *)HHmmToday:(NSString *)HHmm;

+ (NSDate *)addToDate:(NSDate *)date days:(NSInteger)days;

+ (void)setDailyNotification:(NSDate *)fireDate;

+ (BOOL)date:(NSString *)date1 isJustBefore:(NSString *)date2;

#pragma mark - Stats

+ (void)newEvent:(NSString *)eventId;

+ (void)newEvent:(NSString *)eventId type:(NSString *)type;

+ (void)newEvent:(NSString *)eventId attributes:(NSDictionary *)attrs;

#pragma mark - UI Utils

+ (void)alertMessage:(NSString *)message;

+ (void)alertError:(NSError *)error;

+ (UIImage *)imageWithColor:(UIColor *)color;

@end
