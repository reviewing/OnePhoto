//
//  GlobalUtils.h
//  OnePhoto
//
//  Created by Hong Duan on 8/29/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GlobalUtils : NSObject

+ (UIColor *)appBaseColor;

+ (UIColor *)appBaseLighterColor;

+ (UIColor *)appBaseDarkerColor;

+ (void)setAppBaseColor:(UIColor *)color;

@end
