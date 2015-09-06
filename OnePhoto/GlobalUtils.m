//
//  GlobalUtils.m
//  OnePhoto
//
//  Created by Hong Duan on 8/29/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "GlobalUtils.h"
#import "UIColor+Remix.h"

static UIColor *_appBaseColor = nil;

static NSDateFormatter *_dateFormatter = nil;

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

@end
