//
//  OPCalendarWeekView.h
//  OnePhoto
//
//  Created by Hong Duan on 9/2/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JTCalendarWeek.h"

@interface OPCalendarWeekView : UIView<JTCalendarWeek>

@property (nonatomic, weak) JTCalendarManager *manager;
@property (nonatomic, readonly) NSDate *startDate;
@property (nonatomic, strong) NSArray *photos;

- (NSUInteger)columnIndexOfFirstDay;

@end
