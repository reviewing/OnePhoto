//
//  GlobalUtils.m
//  OnePhoto
//
//  Created by Hong Duan on 8/29/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "GlobalUtils.h"
#import "UIColor+Remix.h"

static UIColor *appBaseColor = nil;

@implementation GlobalUtils

+ (UIColor *)appBaseColor {
    if (appBaseColor == nil) {
        appBaseColor = UIColorFromRGB(0x0DBEB2);
    }
    return appBaseColor;
}

+ (UIColor *)appBaseLighterColor {
    return [appBaseColor lighterColor];
}

+ (UIColor *)appBaseDarkerColor {
    return [appBaseColor darkerColor];
}

+ (void)setAppBaseColor:(UIColor *)color {
    appBaseColor = color;
}

@end
