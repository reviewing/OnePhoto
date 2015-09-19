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

@interface OPCalendarDayView () {
    UIImageView *_photoView;
}

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
    }
    
    {
        _photoView = [UIImageView new];
        [self addSubview:_photoView];
    }
    
    _dotRatio = 1. / 9.;
    
    {
        _dotView = [UIView new];
        [self addSubview:_dotView];
        
        _dotView.backgroundColor = [UIColor redColor];
        _dotView.hidden = YES;
    }
    
    {
        _textLabel = [UILabel new];
        [self addSubview:_textLabel];
        
        _textLabel.textColor = [UIColor blackColor];
        _textLabel.shadowColor = [UIColor whiteColor];
        _textLabel.shadowOffset = CGSizeMake(1.0, 1.0);
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
    _textLabel.frame = CGRectMake((self.frame.size.width - _textLabel.frame.size.width - 4) / 2, 0, _textLabel.frame.size.width + 8, _textLabel.frame.size.height);
    
    CGFloat sizeDot = MIN(self.frame.size.width, self.frame.size.height);
    
    sizeDot = sizeDot * _dotRatio;    
    sizeDot = roundf(sizeDot);
    
    _dotView.frame = CGRectMake(0, 0, sizeDot, sizeDot);
    _dotView.center = CGPointMake(self.frame.size.width / 2., (self.frame.size.height / 2.) +sizeDot * 2.5);
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
    if (photo) {
        [[FICImageCache sharedImageCache] retrieveImageForEntity:photo withFormatName:OPPhotoSquareImage32BitBGRFormatName completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
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
    static NSDateFormatter *dateFormatter = nil;
    if(!dateFormatter){
        dateFormatter = [_manager.dateHelper createDateFormatter];
        [dateFormatter setDateFormat:@"d"];
    }
    
    _textLabel.text = [dateFormatter stringFromDate:_date];
    [_textLabel sizeToFit];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSRange weekdayRange = [calendar maximumRangeOfUnit:NSCalendarUnitWeekday];
    NSDateComponents *components = [calendar components:NSCalendarUnitWeekday fromDate:_date];
    NSUInteger weekdayOfDate = [components weekday];
    
    if (weekdayOfDate == weekdayRange.location || weekdayOfDate == weekdayRange.length) {
        _textLabel.textColor = [UIColor lightGrayColor];
    } else {
        _textLabel.textColor = [UIColor blackColor];
    }    
    [_manager.delegateManager prepareDayView:self];
}

- (void)didTouch
{
    [_manager.delegateManager didTouchDayView:self];
}

//- (void)drawRect:(CGRect)rect {
//    [super drawRect:rect];
//    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
//    
//    CGContextSetLineWidth(context, 1.0f);
//    CGContextMoveToPoint(context, 0.0f, 0.0f);
//    CGContextAddLineToPoint(context, self.frame.size.width, 0.0f);
//    
//    CGContextStrokePath(context);
//}

@end
