//
//  OPVerticalCalendarView.m
//  OnePhoto
//
//  Created by Hong Duan on 9/2/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "OPVerticalCalendarView.h"

#import "JTCalendarManager.h"
#import "OPCalendarPageView.h"
#import "CoreDataHelper.h"

@interface OPVerticalCalendarView () <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>{
    NSDate *_startDate;
    CGSize _lastSize;
    NSUInteger _numOfRows;
}

@end

@implementation OPVerticalCalendarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)commonInit {
    self.delegate = self;
    self.dataSource = self;
}

- (void)loadPreviousPageWithAnimation {

}

- (void)loadNextPageWithAnimation {

}

- (void)loadPreviousPage {
    
}

- (void)loadNextPage {

}

- (void)setDate:(NSDate *)date {
    NSAssert(date != nil, @"date cannot be nil");
    NSAssert(_manager != nil, @"manager cannot be nil");
    
    self->_date = date;
    [self reloadData];
}

- (void)setManager:(JTCalendarManager *)manager {
    self->_manager = manager;
}

- (void)reloadData {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_START_DATE]) {
        _startDate = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_START_DATE];
    } else {
        _startDate = [[CoreDataHelper sharedHelper] firstDayIn1Photo];
    }
    _numOfRows = [self monthsBetweenDate:_startDate with:_date] + 1;
    [super reloadData];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _numOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *monthCellIdentifier = @"MonthCell";
    OPCalendarPageView *cell = [tableView dequeueReusableCellWithIdentifier:monthCellIdentifier];
    cell.manager = _manager;
    cell.date = [self dateForIndexPath:indexPath];
    return cell;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self calculateRowHeightAtIndexPath:indexPath width:tableView.frame.size.width];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSDate *)dateForIndexPath:(NSIndexPath *)indexPath {
    return [_manager.dateHelper addToDate:_date months:indexPath.row - [self monthsBetweenDate:_startDate with:_date]];
}

- (CGFloat)calculateRowHeightAtIndexPath:(NSIndexPath *)indexPath width:(CGFloat)width {
    if ([_manager.dateHelper date:[self dateForIndexPath:indexPath] isTheSameMonthThan:_date]) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:[_manager.dateHelper firstDayOfMonth:_date]];
        NSInteger columnIndexOfFirstDay = [components weekday];
        components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:_date];
        NSInteger day = [components day];
        if (day > 0) {
            NSUInteger numberOfWeeks = (day - (7 - columnIndexOfFirstDay + 1)) / 7 + 1 + ((day - (7 - columnIndexOfFirstDay + 1)) % 7 == 0 ? 0 : 1);
            return width * (numberOfWeeks / 7.f) + [GlobalUtils monthLabelSize] + 16;
        }
    }

    NSUInteger numberOfWeeks = [self.manager.dateHelper numberOfWeeks:[self dateForIndexPath:indexPath]];
    return width * (numberOfWeeks / 7.f) + [GlobalUtils monthLabelSize] + 16;
}

- (void)scrollToCurrentMonth:(BOOL)animated {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self monthsBetweenDate:_startDate with:_date] inSection:0];
    [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (NSInteger)monthsBetweenDate:(NSDate *)date1 with:(NSDate *)date2 {
    NSInteger yearOfDate1;
    NSInteger monthOfDate1;
    NSInteger yearOfDate2;
    NSInteger monthOfDate2;
    NSCalendar *calendar = _manager.dateHelper.calendar;
    {
        NSDateComponents *comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:date1];
        yearOfDate1 = comps.year;
        monthOfDate1 = comps.month;
    }
    {
        NSDateComponents *comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:date2];
        yearOfDate2 = comps.year;
        monthOfDate2 = comps.month;
    }

    return (yearOfDate2 - yearOfDate1) * 12 + (monthOfDate2 - monthOfDate1);
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [self scrollToCurrentMonth:YES];
    return NO;
}

@end
