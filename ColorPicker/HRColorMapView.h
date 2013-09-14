//
// Created by hayashi311 on 2013/09/14.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@protocol HRColorMapView
@property (nonatomic, readonly) UIColor *color;
@property (nonatomic) CGFloat brightness;
@end

@interface HRColorMapView : UIControl<HRColorMapView>

@property (nonatomic) NSInteger tileSize;
@property (nonatomic) float saturationUpperLimit;

@end