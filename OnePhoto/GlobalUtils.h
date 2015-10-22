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

@interface GlobalUtils : NSObject

+ (UIColor *)appBaseColor;

+ (UIColor *)appBaseLighterColor;

+ (UIColor *)appBaseDarkerColor;

+ (void)setAppBaseColor:(UIColor *)color;

+ (CGFloat)monthLabelSize;

+ (NSDateFormatter *)dateFormatter;

+ (NSString *)stringFromDate:(NSDate *)date;

+ (NSUInteger)daysOfMonthByDate:(NSDate *)date;

+ (NSInteger)dayOfMonth:(NSDate *)date;

+ (void)alertMessage:(NSString *)message;

+ (void)alertError:(NSError *)error;

+ (void)newEvent:(NSString *)eventId;

+ (void)newEvent:(NSString *)eventId type:(NSString *)type;

+ (void)newEvent:(NSString *)eventId attributes:(NSDictionary *)attrs;

+ (UIImage *)imageWithColor:(UIColor *)color;

@end
