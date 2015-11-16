//
//  OPCalendarDayView.m
//  OnePhoto
//
//  Created by Hong Duan on 8/31/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "OPCalendarDayView.h"
#import "CoreDataHelper.h"
#import "iCloudAccessor.h"
#import "OPPhoto.h"
#import "OPMarkerView.h"

#import <FastImageCache/FICImageCache.h>

@interface OPCalendarDayView ()

@property (nonatomic, strong) OPPhoto *photo;

@end

@implementation OPCalendarDayView

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
    self.opaque = NO;
    self.clipsToBounds = YES;
    
    self.backgroundColor = [UIColor clearColor];
    
    {
        // This will stuck the scrolling
//        self.layer.cornerRadius = 5.0;
        // This solved the problem above
//        self.layer.masksToBounds = NO;
    }
    
    {
        _photoView = [UIImageView new];
        [self addSubview:_photoView];
    }
    
    {
        _dayLabelBG = [UIView new];
        [self addSubview:_dayLabelBG];
        
        _dayLabelBG.backgroundColor = [[GlobalUtils appBaseColor] colorWithAlphaComponent:0.75];
    }
    
    {
        _dayLabel = [UILabel new];
        [self addSubview:_dayLabel];
        
        _dayLabel.textColor = [UIColor whiteColor];
        _dayLabel.textAlignment = NSTextAlignmentCenter;
        _dayLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    
    {
        _markerView = [OPMarkerView new];
        [self addSubview:_markerView];
    }
    
    {
        self.userInteractionEnabled = YES;

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTouch)];
        [self addGestureRecognizer:tapGesture];
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        [self addGestureRecognizer:longPressGesture];
    }
}

- (void)layoutSubviews {
    _photoView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    [self setDayLabelStatus:!_photo];
    
    _markerView.frame = CGRectMake(0, 0, 24, 24);
    _markerView.center = CGPointMake(self.frame.size.width - 12, self.frame.size.height - 12);
}

- (void)setDayLabelStatus:(BOOL)empty {
    if (empty) {
        _dayLabel.font = [UIFont systemFontOfSize:self.frame.size.width - 16 weight:UIFontWeightThin];
        [_dayLabel sizeToFit];
        _dayLabel.frame = CGRectMake((self.frame.size.width - _dayLabel.frame.size.width) / 2., (self.frame.size.height - _dayLabel.frame.size.height) / 2., _dayLabel.frame.size.width, _dayLabel.frame.size.height);

        _dayLabelBG.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _dayLabelBG.center = CGPointMake(self.frame.size.width / 2., (self.frame.size.height / 2.));
        _dayLabelBG.layer.cornerRadius = 0;
    } else {
        _dayLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        [_dayLabel sizeToFit];
        _dayLabel.frame = CGRectMake((self.frame.size.width - _dayLabel.frame.size.width) / 2., 4, _dayLabel.frame.size.width, _dayLabel.frame.size.height);

        CGFloat sizeDot = MAX(_dayLabel.frame.size.width, _dayLabel.frame.size.height) + 4;
        sizeDot = roundf(sizeDot);
        _dayLabelBG.frame = CGRectMake(0, 0, sizeDot, sizeDot);
        _dayLabelBG.center = CGPointMake(self.frame.size.width / 2., 4 + (_dayLabel.frame.size.height / 2.));
        _dayLabelBG.layer.cornerRadius = sizeDot / 2.;
    }
}

- (void)setDate:(NSDate *)date {
    NSAssert(date != nil, @"date cannot be nil");
    NSAssert(_manager != nil, @"manager cannot be nil");
    
    self->_date = date;
    [self reload];
}

- (void)setPhoto:(OPPhoto *)photo {
    if ([photo isEqual:_photo] || (_photo == nil && [photo isEqual:[NSNull null]])) {
        return;
    }
    __block NSString *date = [[GlobalUtils dateFormatter] stringFromDate:_date];
    if (photo && ![photo isEqual:[NSNull null]]) {
        _photo = photo;
        [[FICImageCache sharedImageCache] asynchronouslyRetrieveImageForEntity:photo withFormatName:OPPhotoSquareImage32BitBGRFormatName completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
            if ([date isEqualToString:[[GlobalUtils dateFormatter] stringFromDate:_date]]) {
                [_photoView setImage:image];
            }
        }];
    } else {
        _photo = nil;
        [_photoView setImage:nil];
    }
    [self setDayLabelStatus:!_photo];
}

- (void)reload {
    _dayLabel.text = [NSString stringWithFormat:@"%ld", (long)[GlobalUtils dayOfMonth:_date]];
    [_dayLabel sizeToFit];

//    NSCalendar *calendar = [NSCalendar currentCalendar];
//    NSRange weekdayRange = [calendar maximumRangeOfUnit:NSCalendarUnitWeekday];
//    NSDateComponents *components = [calendar components:NSCalendarUnitWeekday fromDate:_date];
//    NSUInteger weekdayOfDate = [components weekday];
//    
//    if (weekdayOfDate == weekdayRange.location || weekdayOfDate == weekdayRange.length) {
//        _dayLabel.textColor = [UIColor whiteColor];
//    } else {
//        _dayLabel.textColor = [UIColor whiteColor];
//    }
    
    NSString *dateString = [[GlobalUtils dateFormatter] stringFromDate:_date];
    if ([[[CoreDataHelper sharedHelper] getPhotosAt:dateString] count] > 1 || [[[iCloudAccessor shareAccessor] urlsAt:dateString] count] > 1
        || ([[[CoreDataHelper sharedHelper] getPhotosAt:dateString] count] == 0 && [[[iCloudAccessor shareAccessor] urlsAt:dateString] count] > 0)) {
        self.markerView.hidden = NO;
    } else {
        self.markerView.hidden = YES;
    }
    
    [_manager.delegateManager prepareDayView:self];
}

- (void)didTouch {
    self.touchEvent = OP_DAY_TOUCH_UP;
    [_manager.delegateManager didTouchDayView:self];
}

- (void)handleLongPressGesture:(UIGestureRecognizer *)recognizer  {
    if (recognizer.state == UIGestureRecognizerStateRecognized) {
        [self becomeFirstResponder];
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        [menuController setTargetRect:recognizer.view.frame inView:recognizer.view.superview];
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (!self.photo) {
        return NO;
    }
    return (action == @selector(delete:));
}

- (void)delete:(id)sender {
    self.touchEvent = OP_DAY_TOUCH_DELETE;
    [_manager.delegateManager didTouchDayView:self];
}

@end
