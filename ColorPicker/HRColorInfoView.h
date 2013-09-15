//
// Created by hayashi311 on 2013/09/15.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@protocol HRColorInfoView
@property (nonatomic, strong) UIColor *color;
@end

@interface HRColorInfoView : UIView <HRColorInfoView>

+ (HRColorInfoView*)colorInfoViewWithFrame:(CGRect)frame;

@end