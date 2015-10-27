//
//  GlobalUtils.m
//  OnePhoto
//
//  Created by Hong Duan on 8/29/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "GlobalUtils.h"
#import "UIColor+Remix.h"

NSString * const OPCoreDataStoreMerged = @"OPCoreDataStoreMerged";

static UIColor *_appBaseColor = nil;

static NSDateFormatter *_dateFormatter = nil;

static NSDateFormatter *_HHmmFormatter = nil;

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

+ (CGFloat)monthLabelSize {
    return 17.0f;
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

+ (void)alertMessage:(NSString *)message {
#warning TODO: fix this later - memory leak here, don't know why
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
