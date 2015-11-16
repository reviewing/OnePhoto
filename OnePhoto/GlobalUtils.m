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
#import <MWPhotoBrowser/MWPhotoBrowser.h>

#import "OPPhoto.h"
#import "CoreDataHelper.h"
#import "iCloudAccessor.h"
#import "WXApi.h"

NSString * const OPCoreDataStoreUpdatedNotification = @"OPCoreDataStoreUpdatedNotification";
NSString * const OPiCloudPhotosMetadataUpdatedNotification = @"OPiCloudPhotosMetadataUpdatedNotification";
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

+ (UIColor *)warningColor {
    return UIColorFromRGB(0xFF3864);
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

+ (NSDateFormatter *)yyyyMMFormatter {
    NSDateFormatter *yyyyMMFormatter = [NSDateFormatter new];
    yyyyMMFormatter.timeZone = [NSTimeZone systemTimeZone];
    yyyyMMFormatter.locale = [NSLocale currentLocale];
    [yyyyMMFormatter setDateFormat:@"yyyy年MM月"];
    return yyyyMMFormatter;
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

+ (NSString *)chineseRepresentation:(NSString *)dateString {
    return [[GlobalUtils chineseFormatter] stringFromDate:[[GlobalUtils dateFormatter] dateFromString:dateString]];
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

+ (UIImage *)squareAndSmall:(UIImage *)image {
    CGSize finalsize = CGSizeMake(128,128);
    
    CGFloat scale = MAX(finalsize.width/image.size.width,
                        finalsize.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    
    CGRect rr = CGRectMake( 0, 0, width, height);
    UIGraphicsBeginImageContextWithOptions(finalsize, NO, 0);
    [image drawInRect:rr];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (void)deletePhotoActionFrom:(UIViewController *)viewController anchor:(NSObject *)anchor photo:(OPPhoto *)photo completion:(void (^)(void))completion {
    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * action) {
                                                             [[CoreDataHelper sharedHelper] deletePhoto:photo];
                                                             id reminderTime = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_REMINDER_TIME];
                                                             if ([reminderTime isKindOfClass:[NSDate class]]) {
                                                                 NSDate *fireDate = [GlobalUtils HHmmToday:[[GlobalUtils HHmmFormatter] stringFromDate:reminderTime]];
                                                                 [GlobalUtils setDailyNotification:fireDate];
                                                             }
                                                             [self renewPhotoCounts];
                                                             completion();
                                                         }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [self presentActionSheetFrom:viewController title:@"删除照片" message:@"警告：删除后不可恢复" actions:[NSArray arrayWithObjects:deleteAction, cancelAction, nil] anchor:anchor];
}

+ (void)deletePhotoActionFrom:(UIViewController *)viewController anchor:(NSObject *)anchor photoUrl:(NSURL *)url completion:(void (^)(void))completion {
    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * action) {
                                                             [[iCloudAccessor shareAccessor] deleteFileWithAbsolutelyURL:url];
                                                             completion();
                                                         }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [self presentActionSheetFrom:viewController title:@"删除照片" message:@"警告：删除后不可恢复" actions:[NSArray arrayWithObjects:deleteAction, cancelAction, nil] anchor:anchor];
}

+ (void)sharePhotoAction:(UIViewController *)viewController anchor:(NSObject *)anchor photo:(OPPhoto *)photo {
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:photo.source_image_url];
    [self sharePhotoAction:viewController anchor:anchor photoUrl:ubiquitousURL];
}

+ (void)sharePhotoAction:(UIViewController *)viewController anchor:(NSObject *)anchor photoUrl:(NSURL *)url {
    UIAlertAction* weixinAction = [UIAlertAction actionWithTitle:@"分享给微信朋友" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             if ([WXApi isWXAppInstalled]) {
                                                                 [self sendImageData:[NSData dataWithContentsOfURL:url]
                                                                             TagName:@"WECHAT_TAG_JUMP_APP"
                                                                          MessageExt:@"1 Photo"
                                                                              Action:@"<action>open</action>"
                                                                          ThumbImage:[GlobalUtils squareAndSmall:[UIImage imageWithContentsOfFile:url.path]]
                                                                             InScene:WXSceneSession];
                                                             } else {
                                                                 UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel
                                                                                                                      handler:^(UIAlertAction * action) {}];
                                                                 [self presentAlertFrom:viewController title:@"无法打开微信" message:@"未检测到微信，请确认是否安装了微信" actions:[NSArray arrayWithObject:cancelAction]];
                                                             }
                                                         }];
    UIAlertAction* weixinFCAction = [UIAlertAction actionWithTitle:@"分享到微信朋友圈" style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               if ([WXApi isWXAppInstalled]) {
                                                                   [self sendImageData:[NSData dataWithContentsOfURL:url]
                                                                               TagName:@"WECHAT_TAG_JUMP_APP"
                                                                            MessageExt:@"1 Photo"
                                                                                Action:@"<action>open</action>"
                                                                            ThumbImage:[GlobalUtils squareAndSmall:[UIImage imageWithContentsOfFile:url.path]]
                                                                               InScene:WXSceneTimeline];
                                                               } else {
                                                                   UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel
                                                                                                                        handler:^(UIAlertAction * action) {}];
                                                                   [self presentAlertFrom:viewController title:@"无法打开微信" message:@"未检测到微信，请确认是否安装了微信" actions:[NSArray arrayWithObject:cancelAction]];
                                                               }
                                                           }];
    UIAlertAction* systemAction = [UIAlertAction actionWithTitle:@"其它操作" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             if ([viewController respondsToSelector:@selector(showProgressHUDWithMessage:)]) {
                                                                 [viewController performSelector:@selector(showProgressHUDWithMessage:) withObject:nil];
                                                             }
                                                             NSMutableArray *items = [NSMutableArray arrayWithObject:[UIImage imageWithContentsOfFile:url.path]];
                                                             __block UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
                                                             
                                                             activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                                                                 activityViewController = nil;
                                                             };
                                                             if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8")) {
                                                                 if ([anchor isKindOfClass:[UIView class]]) {
                                                                     activityViewController.popoverPresentationController.sourceView = (UIView *)anchor;
                                                                 } else if ([anchor isKindOfClass:[UIBarButtonItem class]]) {
                                                                     activityViewController.popoverPresentationController.barButtonItem = (UIBarButtonItem *)anchor;
                                                                 }
                                                             }
                                                             [viewController presentViewController:activityViewController animated:YES completion:^(){
                                                                 if ([viewController respondsToSelector:@selector(hideProgressHUD:)]) {
                                                                     [viewController performSelector:@selector(hideProgressHUD:) withObject:@YES];
                                                                 }
                                                             }];
                                                             
                                                         }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [self presentActionSheetFrom:viewController title:@"分享照片" message:@"" actions:[NSArray arrayWithObjects:weixinAction, weixinFCAction, systemAction, cancelAction, nil] anchor:anchor];
}

+ (void)presentAlertFrom:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message actions:(NSArray *)actions {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    for (UIAlertAction *action in actions) {
        [alert addAction:action];
    }
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (void)presentActionSheetFrom:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message actions:(NSArray *)actions anchor:(NSObject *)anchor {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    for (UIAlertAction *action in actions) {
        [alert addAction:action];
    }
    
    if([alert respondsToSelector:@selector(popoverPresentationController)]) {
        if ([anchor isKindOfClass:[UIView class]]) {
            alert.popoverPresentationController.sourceView = (UIView *)anchor;
        } else if ([anchor isKindOfClass:[UIBarButtonItem class]]) {
            alert.popoverPresentationController.barButtonItem = (UIBarButtonItem *)anchor;
        }
    }
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (void)renewPhotoCounts {
    NSInteger count = [[CoreDataHelper sharedHelper] countOfPhotos];
    if (count < 0) {
        count = (NSInteger)[[NSUbiquitousKeyValueStore defaultStore] longLongForKey:OPUbiquitousKeyValueStoreHasPhotoKey] + 1;
    }
    DHLogDebug(@"renewPhotoCounts: %ld", (long)count);
    [[NSUbiquitousKeyValueStore defaultStore] setLongLong:count forKey:OPUbiquitousKeyValueStoreHasPhotoKey];
}

+ (BOOL)sendImageData:(NSData *)imageData
              TagName:(NSString *)tagName
           MessageExt:(NSString *)messageExt
               Action:(NSString *)action
           ThumbImage:(UIImage *)thumbImage
              InScene:(enum WXScene)scene {
    WXImageObject *ext = [WXImageObject object];
    ext.imageData = imageData;
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = nil;
    message.description = nil;
    message.mediaObject = ext;
    message.messageExt = messageExt;
    message.messageAction = action;
    message.mediaTagName = tagName;
    [message setThumbImage:thumbImage];
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.scene = scene;
    req.message = message;
    
    return [WXApi sendReq:req];
}

+ (void)deleteFileWithRelativelyPath:(NSString *)path {
    [[iCloudAccessor shareAccessor] deleteFileWithRelativelyPath:path];
}

#pragma mark - Others

+ (NSString *)last2PathComponentsOf:(NSURL *)url {
    NSString *last = [url lastPathComponent];
    NSString *secondLast = [[url URLByDeletingLastPathComponent] lastPathComponent];
    return [secondLast stringByAppendingPathComponent:last];
}

@end
