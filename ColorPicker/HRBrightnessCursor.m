//
//  HRBrightnessCursor.m
//  Hayashi311ColorPickerSample
//
//  Created by 林 亮太 on 11/11/27.
//  Copyright (c) 2011 Hayashi Ryota. All rights reserved.
//

#import "HRBrightnessCursor.h"
#import "HRCgUtil.h"

@implementation HRBrightnessCursor

- (id)initWithPoint:(CGPoint)point
{
    CGSize size = CGSizeMake(18.0f, 40.0f);
    CGRect frame = CGRectMake(point.x - size.width/2.0f, point.y - size.height/2.0f, size.width, size.height);
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setUserInteractionEnabled:FALSE];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    HRSetRoundedRectanglePath(context, CGRectMake(2.0f, 13.0f, 14.0f, 14.0f), 2.0f);
    [[UIColor colorWithWhite:0.98f alpha:1.0f] set];
    CGContextSetLineWidth(context, 2.0f);
    CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 2.0f, [UIColor colorWithWhite:0.0f alpha:0.3f].CGColor);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    HRSetRoundedRectanglePath(context, CGRectMake(2.0f, 13.0f, 14.0f, 14.0f), 2.0f);
    CGContextClip(context);
    
    float top_color = 0.9f;
    float bottom_color = 0.98f;
    float alpha = 1.0f;
    CGFloat gradient_color[] = {
        top_color ,top_color ,top_color ,alpha,
        bottom_color ,bottom_color ,bottom_color ,alpha
    };
    CGGradientRef gradient;
    CGColorSpaceRef colorSpace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    colorSpace = CGColorSpaceCreateDeviceRGB();
    gradient = CGGradientCreateWithColorComponents(colorSpace, gradient_color,
                                                   locations, num_locations);
    
    CGPoint startPoint = CGPointMake(self.frame.size.width/2, 0.0);
    CGPoint endPoint = CGPointMake(self.frame.size.width/2, self.frame.size.height);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    // GradientとColorSpaceを開放する
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    [[UIColor colorWithWhite:1.0f alpha:1.0f] setStroke];
    CGContextMoveToPoint(context, 6.0f, 17.0f);
    CGContextAddLineToPoint(context, 6.0f, 24.0f);
    CGContextMoveToPoint(context, 9.0f, 17.0f);
    CGContextAddLineToPoint(context, 9.0f, 24.0f);
    CGContextMoveToPoint(context, 12.0f, 17.0f);
    CGContextAddLineToPoint(context, 12.0f, 24.0f);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextRestoreGState(context);
    
}


@end
