//
//  OPVerticalCalendarView.h
//  OnePhoto
//
//  Created by Hong Duan on 9/2/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JTContent.h"

@interface OPVerticalCalendarView : UITableView <JTContent>

@property (nonatomic, weak) JTCalendarManager *manager;
@property (nonatomic) NSDate *date;

- (void)scrollToCurrentMonth:(BOOL)animated;

@end
