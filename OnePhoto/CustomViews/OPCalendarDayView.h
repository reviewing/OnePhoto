//
//  OPCalendarDayView.h
//  OnePhoto
//
//  Created by Hong Duan on 8/31/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JTCalendar/JTCalendar.h>

@class OPPhoto;

typedef NS_ENUM(NSInteger, OP_DAY_TOUCH_EVENT) {
    OP_DAY_TOUCH_UP = 1,
    OP_DAY_TOUCH_DELETE = 2,
};

@interface OPCalendarDayView : UIView <JTCalendarDay>

@property (nonatomic, weak) JTCalendarManager *manager;

@property (nonatomic) NSDate *date;
@property (nonatomic, strong) UIImageView *photoView;

@property (nonatomic, readonly) UIView *dotView;
@property (nonatomic, readonly) UILabel *textLabel;

@property (nonatomic, strong) UIView *markerView;

@property (nonatomic) BOOL isFromAnotherMonth;

- (void)setPhoto:(OPPhoto *)photo;
- (OPPhoto *)photo;

@property (nonatomic) OP_DAY_TOUCH_EVENT touchEvent;

@end
