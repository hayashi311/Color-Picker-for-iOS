//
// Created by hayashi311 on 2013/09/14.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@protocol HRBrightnessSlider

@required
@property (nonatomic, readonly) CGFloat brightness;
@property (nonatomic) UIColor *color;

@optional
@property (nonatomic) CGFloat brightnessLowerLimit;

@end

@interface HRBrightnessSlider : UIControl <HRBrightnessSlider>

+ (HRBrightnessSlider *)brightnessSliderWithFrame:(CGRect)frame;

@end