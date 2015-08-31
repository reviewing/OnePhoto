//
//  OPCalendarWeekDayView.h
//  OnePhoto
//
//  Created by Hong Duan on 8/31/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JTCalendar/JTCalendar.h>

@interface OPCalendarWeekDayView : UIView <JTCalendarWeekDay>

@property (nonatomic, weak) JTCalendarManager *manager;

@property (nonatomic, readonly) NSArray *dayViews;

/*!
 * Rebuild the view, must be call if you change `weekDayFormat` or `firstWeekday`
 */
- (void)reload;

@end
