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
}

- (void)setPosition:(OPMarkerViewPosition)position {
    _position = position;
    [self setNeedsDisplay];
}

- (void)setType:(OPMarkerViewType)type {
    _type = type;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint   (ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect));  // top left
    CGContextAddLineToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));  // mid right
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));  // bottom left
    CGContextClosePath(ctx);
    
    CGContextSetRGBFillColor(ctx, 1.0, 1.0/255.0, 1.0/255.0, 0.75);
    CGContextFillPath(ctx);
}

@end
