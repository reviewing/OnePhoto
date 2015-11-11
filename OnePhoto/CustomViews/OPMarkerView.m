//
//  OPMarkerView.m
//  OnePhoto
//
//  Created by Hong Duan on 11/11/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import "OPMarkerView.h"

@interface OPMarkerView () {
    OPMarkerViewPosition _position;
    OPMarkerViewType _type;
}

@property (nonatomic, strong) UILabel *sign;

@end

@implementation OPMarkerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    return self;
}

- (void)commonInit {
    _position = OPMarkerViewPositionBottomRight;
    _type = OPMarkerViewTypeMultipleWarning;
    self.backgroundColor = [UIColor clearColor];
    
    _sign = [UILabel new];
    [self addSubview:_sign];
    
    _sign.textColor = [UIColor whiteColor];
    _sign.textAlignment = NSTextAlignmentCenter;
    _sign.font = [UIFont boldSystemFontOfSize:15.0];
    _sign.text = @"!";
}

- (void)layoutSubviews {
    [_sign sizeToFit];
    _sign.frame = CGRectMake((self.frame.size.width - _sign.frame.size.width) / 2. + 6, 6, _sign.frame.size.width, _sign.frame.size.height);
}

- (void)setPosition:(OPMarkerViewPosition)position {
    _position = position;
    [self setNeedsDisplay];
}

- (void)setType:(OPMarkerViewType)type {
    _type = type;
    if (_type == OPMarkerViewTypeMultipleWarning) {
        _sign.text = @"!";
    }
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (_type == OPMarkerViewTypeMultipleWarning) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGContextBeginPath(ctx);
        CGContextMoveToPoint   (ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect));  // top left
        CGContextAddLineToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));  // mid right
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));  // bottom left
        CGContextClosePath(ctx);
    
        CGContextSetRGBFillColor(ctx, 1.0, 1.0/255.0, 1.0/255.0, 0.75);
        CGContextFillPath(ctx);
    }
}

@end
