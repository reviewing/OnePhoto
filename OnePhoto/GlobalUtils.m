//
//  GlobalUtils.m
//  OnePhoto
//
//  Created by Hong Duan on 8/29/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "GlobalUtils.h"
#import "UIColor+Remix.h"
#import "LoadingViewController.h"
#import "LockSplashViewController.h"
#import <VENTouchLock/VENTouchLockEnterPasscodeViewController.h>

NSString * const OPCoreDataStoreMerged = @"OPCoreDataStoreMerged";
NSString * const OPNotificationType = @"OPNotificationType";
NSString * const OPNotificationTypeDailyReminder = @"OPNotificationTypeDailyReminder";
NSString * const OPUbiquitousKeyValueStoreHasPhotoKey = @"OPUbiquitousKeyValueStoreHasPhotoKey";

static UIColor *_appBaseColor = nil;

static NSDateFormatter *_dateFormatter = nil;

static NSDateFormatter *_HHmmFormatter = nil;

static NSDateFormatter *_chineseFormatter = nil;

static NSCalendar *_calendar = nil;

@implementation GlobalUtils

+ (UIColor *)appBaseColor {
    if (_appBaseColor == nil) {
        _appBaseColor = UIColorFromRGB(0x0DBEB2);
    }
    return _appBaseColor;
}

+ (UIColor *)appBaseLighterColor {
    return [_appBaseColor lighterColor];
}

+ (UIColor *)appBaseDarkerColor {
    return [self.appBaseColor darkerColor];
}

+ (void)setAppBaseColor:(UIColor *)color {
    _appBaseColor = color;
}

+ (UIColor *)daySelectionColor {
    return UIColorFromRGB(0xC589E8);
}

+ (CGFloat)monthLabelSize {
    return 17.0f;
}

+ (NSCalendar *)calendar {
    if(!_calendar){
#ifdef __IPHONE_8_0
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
#else
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
#endif
        _calendar.timeZone = [NSTimeZone systemTimeZone];
        _calendar.locale = [NSLocale currentLocale];
    }
    return _calendar;
}

+ (NSDateFormatter *)dateFormatter {
    if (_dateFormatter == nil) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone systemTimeZone];
        _dateFormatter.locale = [NSLocale currentLocale];
        [_dateFormatter setDateFormat:@"yyyyMMdd"];
    }
    return _dateFormatter;
}

+ (NSString *)stringFromDate:(NSDate *)date {
    return [[self dateFormatter] stringFromDate:date];
}

+ (NSDateFormatter *)HHmmFormatter {
    if (_HHmmFormatter == nil) {
        _HHmmFormatter = [NSDateFormatter new];
        _HHmmFormatter.timeZone = [NSTimeZone systemTimeZone];
        _HHmmFormatter.locale = [NSLocale currentLocale];
        [_HHmmFormatter setDateFormat:@"HH:mm"];
    }
    return _HHmmFormatter;
}

+ (NSDateFormatter *)chineseFormatter {
    if (_chineseFormatter == nil) {
        _chineseFormatter = [NSDateFormatter new];
        _chineseFormatter.timeZone = [NSTimeZone systemTimeZone];
        _chineseFormatter.locale = [NSLocale currentLocale];
        [_chineseFormatter setDateFormat:@"yyyy年MM月dd日"];
    }
    return _chineseFormatter;
}

+ (NSUInteger)daysOfMonthByDate:(NSDate *)date {
    NSCalendar *c = [NSCalendar currentCalendar];
    NSRange days = [c rangeOfUnit:NSCalendarUnitDay
                           inUnit:NSCalendarUnitMonth
                          forDate:date];
    return days.length;
}

+ (NSInteger)dayOfMonth:(NSDate *)date {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:date];
    return components.day;
}

+ (NSDate *)HHmmToday:(NSString *)HHmm {
    NSDateComponents *components = [[self calendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    NSDateComponents *HHmmComponents = [[self calendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:[[self HHmmFormatter] dateFromString:HHmm]];
    components.hour = HHmmComponents.hour;
    components.minute = HHmmComponents.minute;
    components.second = 0;
    NSDate *date = [[self calendar] dateFromComponents:components];
    return date;
}

+ (NSDate *)addToDate:(NSDate *)date days:(NSInteger)days {
    NSDateComponents *components = [NSDateComponents new];
    components.day = days;
    return [[self calendar] dateByAddingComponents:components toDate:date options:0];
}

+ (void)setupNotificationSettings {
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
        UIUserNotificationType notificationTypes = UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
        UIMutableUserNotificationAction *ignoreAction = [UIMutableUserNotificationAction new];
        ignoreAction.identifier = @"ignore.1photo";
        ignoreAction.title = @"我知道了";
        ignoreAction.activationMode = UIUserNotificationActivationModeBackground;
        ignoreAction.destructive = YES;
        ignoreAction.authenticationRequired = NO;

        UIMutableUserNotificationAction *addPhotoAction = [UIMutableUserNotificationAction new];
        addPhotoAction.identifier = @"add.1photo";
        addPhotoAction.title = @"现在就去！";
        addPhotoAction.activationMode = UIUserNotificationActivationModeForeground;
        addPhotoAction.destructive = NO;
        addPhotoAction.authenticationRequired = YES;

        NSArray *actions = [NSArray arrayWithObjects:ignoreAction, addPhotoAction, nil];
        UIMutableUserNotificationCategory *category = [UIMutableUserNotificationCategory new];
        category.identifier = @"add1photo";
        [category setActions:actions forContext:UIUserNotificationActionContextDefault];
        [category setActions:actions forContext:UIUserNotificationActionContextMinimal];
        
        NSSet *categories = [NSSet setWithObject:category];
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:categories];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
}

+ (void)setDailyNotification:(NSDate *)fireDate {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    if (fireDate == nil) {
        return;
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification == nil) {
        [self alertMessage:@"设置提醒失败，请重试"];
        return;
    }
    
    NSTimeInterval time = floor([fireDate timeIntervalSinceReferenceDate] / 60.0) * 60.0;
    NSDate *dateWith0Second = [NSDate dateWithTimeIntervalSinceReferenceDate:time];
    notification.fireDate = dateWith0Second;
    
    DHLogDebug(@"设置提醒：%@", fireDate);
    
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.repeatInterval = NSCalendarUnitDay;
    
    notification.alertBody = @"马上拍下今天的1 Photo吧！";
    notification.alertAction = @"现在就去";
    notification.alertTitle = @"1 Photo";
    notification.category = @"add1photo";
    notification.userInfo = [NSDictionary dictionaryWithObject:OPNotificationTypeDailyReminder forKey:OPNotificationType];
    
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.applicationIconBadgeNumber = 1;
    
    [self setupNotificationSettings];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

+ (BOOL)date:(NSString *)date1 isJustBefore:(NSString *)date2 {
    return [date2 isEqualToString:[[self dateFormatter] stringFromDate:[self addToDate:[[self dateFormatter] dateFromString:date1] days:1]]];
}

#pragma mark - Stats

+ (void)newEvent:(NSString *)eventId {
    [self newEvent:eventId attributes:[NSDictionary dictionaryWithObject:@"null" forKey:@"type"]];
}

+ (void)newEvent:(NSString *)eventId type:(NSString *)type {
    if ([type length] > 0) {
        [self newEvent:eventId attributes:[NSDictionary dictionaryWithObject:type forKey:@"type"]];
    } else {
        [self newEvent:eventId attributes:[NSDictionary dictionaryWithObject:@"null" forKey:@"type"]];
    }
}

+ (void)newEvent:(NSString *)eventId attributes:(NSDictionary *)attrs {
    [MobClick event:eventId attributes:attrs == nil ? [NSDictionary dictionaryWithObject:@"null" forKey:@"type"] : attrs];
}

#pragma mark - UI Utils

+ (void)popToRootOrAfterPop:(Class)viewControllerClass {
    UIViewController *topController = [self topMostController];
    while (topController.presentingViewController) {
        if ([self viewController:topController.presentingViewController isKindOfClass:[LoadingViewController class]] || [self viewController:topController.presentingViewController isKindOfClass:[LockSplashViewController class]]) {
            break;
        }
        [topController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        if ([self viewController:topController isKindOfClass:viewControllerClass]) {
            break;
        }
        topController = topController.presentingViewController;
    }
}

+ (BOOL)viewController:(UIViewController *)viewController isKindOfClass:(Class)viewControllerClass {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = [((UINavigationController *)viewController).viewControllers objectAtIndex:0];
    }
    return [viewController isKindOfClass:viewControllerClass];
}

+ (UIViewController*)topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

+ (void)alertMessage:(NSString *)message {
    UIAlertView *toast = [[UIAlertView alloc] initWithTitle:@"提示"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"确认"
                                          otherButtonTitles:nil, nil];
    [toast show];
}

+ (void)alertError:(NSError *)error {
    [self alertMessage:[NSString stringWithFormat:@"%@(code: %ld)", error.localizedDescription, (long)error.code]];
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
