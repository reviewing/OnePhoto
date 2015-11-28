//
//  GlobalUtils.h
//  OnePhoto
//
//  Created by Hong Duan on 8/29/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define DEFAULTS_KEY_START_DATE @"start.date"
#define DEFAULTS_KEY_ENABLE_REMINDER @"enable.reminder"
#define DEFAULTS_KEY_REMINDER_TIME @"reminder.time"
#define DEFAULTS_KEY_ENABLE_PASSCODE @"enable.passcode"
#define DEFAULTS_KEY_ENABLE_TOUCH_ID @"enable.touchID"
#define DEFAULTS_KEY_PASSCODE_TIME @"passcode.time"
#define DEFAULTS_KEY_LAST_BACKGROUND_TIME @"last.background.time"
#define DEFAULTS_KEY_SAVE_TO_LIBRARY @"save.to.library"

FOUNDATION_EXPORT NSString * const OPCoreDataStoreUpdatedNotification;
FOUNDATION_EXPORT NSString * const OPiCloudPhotosMetadataUpdatedNotification;

FOUNDATION_EXPORT NSString * const OPNotificationType;
FOUNDATION_EXPORT NSString * const OPNotificationTypeDailyReminder;
FOUNDATION_EXPORT NSString * const OPUbiquitousKeyValueStoreHasPhotoKey;

@class OPPhoto;

@interface GlobalUtils : NSObject

+ (UIColor *)appBaseColor;

+ (UIColor *)appBaseLighterColor;

+ (UIColor *)appBaseDarkerColor;

+ (UIColor *)daySelectionColor;

+ (UIColor *)warningColor;

+ (void)setAppBaseColor:(UIColor *)color;

+ (CGFloat)monthLabelSize;

+ (NSDateFormatter *)dateFormatter;

+ (NSString *)stringFromDate:(NSDate *)date;

+ (NSDateFormatter *)HHmmFormatter;

+ (NSDateFormatter *)yyyyMMFormatter;

+ (NSDateFormatter *)chineseFormatter;

+ (NSString *)chineseRepresentation:(NSString *)dateString;

+ (NSUInteger)daysOfMonthByDate:(NSDate *)date;

+ (NSInteger)dayOfMonth:(NSDate *)date;

+ (NSDate *)HHmmToday:(NSString *)HHmm;

+ (NSDate *)addToDate:(NSDate *)date days:(NSInteger)days;

+ (void)setupNotificationSettings;

+ (void)setDailyNotification:(NSDate *)fireDate;

+ (BOOL)date:(NSString *)date1 isJustBefore:(NSString *)date2;

#pragma mark - Stats

+ (void)newEvent:(NSString *)eventId;

+ (void)newEvent:(NSString *)eventId type:(NSString *)type;

+ (void)newEvent:(NSString *)eventId attributes:(NSDictionary *)attrs;

#pragma mark - UI Utils

+ (void)popToRootOrAfterPop:(Class)viewControllerClass;

+ (UIViewController*)topMostController;

+ (void)alertMessage:(NSString *)message;

+ (void)alertError:(NSError *)error;

+ (UIImage *)imageWithColor:(UIColor *)color;

+ (UIImage *)squareAndSmall:(UIImage *)image;

+ (void)deletePhotoActionFrom:(UIViewController *)viewController anchor:(NSObject *)anchor photo:(OPPhoto *)photo completion:(void (^)(void))completion;

+ (void)deletePhotoActionFrom:(UIViewController *)viewController anchor:(NSObject *)anchor photoUrl:(NSURL *)url completion:(void (^)(void))completion;

+ (void)sharePhotoAction:(UIViewController *)viewController anchor:(NSObject *)anchor photo:(NSData *)data;

+ (void)presentAlertFrom:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message actions:(NSArray *)actions;

+ (void)presentActionSheetFrom:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message actions:(NSArray *)actions anchor:(NSObject *)anchor;

+ (void)renewPhotoCounts;

#pragma mark - Others

+ (NSString *)last2PathComponentsOf:(NSURL *)url;

+ (NSURL *)ubiqURLforPath:(NSString *)path;

@end
