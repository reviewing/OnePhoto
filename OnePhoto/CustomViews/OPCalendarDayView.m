//
//  OPCalendarDayView.m
//  OnePhoto
//
//  Created by Hong Duan on 8/31/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "OPCalendarDayView.h"
#import "CoreDataHelper.h"
#import "OPPhoto.h"

#import <FastImageCache/FICImageCache.h>

@interface OPCalendarDayView ()

@end

@implementation OPCalendarDayView

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
    self.opaque = NO;
    self.clipsToBounds = YES;
    
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
        _dotView = [UIView new];
        [self addSubview:_dotView];
        
        _dotView.backgroundColor = [GlobalUtils appBaseColor];
    }
    
    {
        _textLabel = [UILabel new];
        [self addSubview:_textLabel];
        
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    
    {
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTouch)];
        
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:gesture];
    }
}

- (void)layoutSubviews
{
    _photoView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    [_textLabel sizeToFit];
    _textLabel.frame = CGRectMake((self.frame.size.width - _textLabel.frame.size.width) / 2., 4, _textLabel.frame.size.width, _textLabel.frame.size.height);
    
    CGFloat sizeDot = MAX(_textLabel.frame.size.width, _textLabel.frame.size.height) + 4;
    
    sizeDot = roundf(sizeDot);
    
    _dotView.frame = CGRectMake(0, 0, sizeDot, sizeDot);
    _dotView.center = CGPointMake(self.frame.size.width / 2., 4 + (_textLabel.frame.size.height / 2.));
    _dotView.layer.cornerRadius = sizeDot / 2.;
}

- (void)setDate:(NSDate *)date
{
    NSAssert(date != nil, @"date cannot be nil");
    NSAssert(_manager != nil, @"manager cannot be nil");
    
    self->_date = date;
    [self reload];
}

- (void)setPhoto:(OPPhoto *)photo {
    __block NSDate *date = [_date copy];
    if (photo && ![photo isEqual:[NSNull null]]) {
        [[FICImageCache sharedImageCache] asynchronouslyRetrieveImageForEntity:photo withFormatName:OPPhotoSquareImage32BitBGRFormatName completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
            if (date == _date) {
                [_photoView setImage:image];
            }
        }];
    } else {
        [_photoView setImage:nil];
    }
}

- (void)reload
{
    _textLabel.text = [NSString stringWithFormat:@"%ld", (long)[GlobalUtils dayOfMonth:_date]];
    [_textLabel sizeToFit];

//    NSCalendar *calendar = [NSCalendar currentCalendar];
//    NSRange weekdayRange = [calendar maximumRangeOfUnit:NSCalendarUnitWeekday];
//    NSDateComponents *components = [calendar components:NSCalendarUnitWeekday fromDate:_date];
//    NSUInteger weekdayOfDate = [components weekday];
//    
//    if (weekdayOfDate == weekdayRange.location || weekdayOfDate == weekdayRange.length) {
//        _textLabel.textColor = [UIColor whiteColor];
//    } else {
//        _textLabel.textColor = [UIColor whiteColor];
//    }
    
    [_manager.delegateManager prepareDayView:self];
}

- (void)didTouch
{
    [_manager.delegateManager didTouchDayView:self];
}

@end
