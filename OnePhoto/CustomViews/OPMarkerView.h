//
//  OPMarkerView.h
//  OnePhoto
//
//  Created by Hong Duan on 11/11/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OPMarkerViewPosition) {
    OPMarkerViewPositionBottomRight = 1,
};

typedef NS_ENUM(NSInteger, OPMarkerViewType) {
    OPMarkerViewTypeMultipleWarning = 1,
};

@interface OPMarkerView : UIView

- (void)setPosition:(OPMarkerViewPosition)position;

- (void)setType:(OPMarkerViewType)type;

@end
