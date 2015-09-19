//
//  OPCalendarPageView.m
//  OnePhoto
//
//  Created by Hong Duan on 9/2/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "OPCalendarPageView.h"

#import "JTCalendarManager.h"
#import "OPCalendarWeekView.h"

#define MAX_WEEKS_BY_MONTH 6

@interface OPCalendarPageView (){
    UILabel *_monthLabel;
    NSMutableArray *_weeksViews;
    NSUInteger _numberOfWeeksDisplayed;
}

@end

@implementation OPCalendarPageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)commonInit
{
    // Maybe used in future
}

- (void)setDate:(NSDate *)date
{
    NSAssert(_manager != nil, @"manager cannot be nil");
    NSAssert(date != nil, @"date cannot be nil");
    
    self->_date = date;
    
    [self reload];
}

- (void)reload
{
    if (!_monthLabel) {
        _monthLabel = [UILabel new];
        _monthLabel.textColor = [GlobalUtils appBaseColor];
        _monthLabel.textAlignment = NSTextAlignmentCenter;
        _monthLabel.font = [UIFont systemFontOfSize:[GlobalUtils monthLabelSize]];
        [self addSubview:_monthLabel];
    }

    {
        NSString *monthText = nil;
        
        NSCalendar *calendar = _manager.dateHelper.calendar;
        NSDateComponents *comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:_date];
        NSInteger currentMonthIndex = comps.month;
        
        static NSDateFormatter *dateFormatter = nil;
        if (!dateFormatter) {
            dateFormatter = [_manager.dateHelper createDateFormatter];
        }
        
        while (currentMonthIndex <= 0) {
            currentMonthIndex += 12;
        }
        
        monthText = [dateFormatter shortMonthSymbols][currentMonthIndex - 1];
        [_monthLabel setText:monthText];
    }
    
    if(!_weeksViews){
        _weeksViews = [NSMutableArray new];
        
        for(int i = 0; i < MAX_WEEKS_BY_MONTH; ++i){
            UIView<JTCalendarWeek> *weekView = [_manager.delegateManager buildWeekView];
            [_weeksViews addObject:weekView];
            [self addSubview:weekView];
            
            weekView.manager = _manager;
        }
    }
    
    NSDate *weekDate = nil;
    
    if (_manager.settings.weekModeEnabled) {
        _numberOfWeeksDisplayed = MIN(MAX(_manager.settings.pageViewWeekModeNumberOfWeeks, 1), MAX_WEEKS_BY_MONTH);
        weekDate = [_manager.dateHelper firstWeekDayOfWeek:_date];
    } else {
        _numberOfWeeksDisplayed = MIN(_manager.settings.pageViewNumberOfWeeks, MAX_WEEKS_BY_MONTH);
        if (_numberOfWeeksDisplayed == 0) {
            _numberOfWeeksDisplayed = [_manager.dateHelper numberOfWeeks:_date];
        }
        
        weekDate = [_manager.dateHelper firstWeekDayOfMonth:_date];
    }
    
    for (NSUInteger i = 0; i < _numberOfWeeksDisplayed; i++) {
        UIView<JTCalendarWeek> *weekView = _weeksViews[i];
        
        weekView.hidden = NO;
        
        // Process the check on another month for the 1st, 4th and 5th weeks
        if (i == 0 || i >= 4) {
            [weekView setStartDate:weekDate updateAnotherMonth:YES monthDate:_date];
        } else {
            [weekView setStartDate:weekDate updateAnotherMonth:NO monthDate:_date];
        }
        
        weekDate = [_manager.dateHelper addToDate:weekDate weeks:1];
    }
    
    for (NSUInteger i = _numberOfWeeksDisplayed; i < MAX_WEEKS_BY_MONTH; i++) {
        UIView<JTCalendarWeek> *weekView = _weeksViews[i];
        
        weekView.hidden = YES;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!_weeksViews) {
        return;
    }
    
    CGFloat y = 0;
    CGFloat weekWidth = self.frame.size.width;
    CGFloat dayHeight = weekWidth / 7.f;

    CGFloat monthLabelHeight = _monthLabel.font.pointSize + 16;
    
    NSUInteger columnIndexOfFirstDay = 3;
    
    if ([[_weeksViews objectAtIndex:0] isKindOfClass:[OPCalendarWeekView class]]) {
        columnIndexOfFirstDay = [((OPCalendarWeekView *)[_weeksViews objectAtIndex:0]) columnIndexOfFirstDay];
    }
    
    _monthLabel.frame = CGRectMake(columnIndexOfFirstDay * dayHeight, 0, dayHeight, monthLabelHeight);
    y = monthLabelHeight;
    
    
    for (UIView *weekView in _weeksViews) {
        weekView.frame = CGRectMake(0, y, weekWidth, dayHeight);
        y += dayHeight;
    }
}

@end
