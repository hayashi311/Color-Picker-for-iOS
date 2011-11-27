//
//  HRColorCursor.m
//  Hayashi311ColorPickerSample
//
//  Created by 林 亮太 on 11/11/27.
//  Copyright (c) 2011 Hayashi Ryota. All rights reserved.
//

#import "HRColorCursor.h"
#import "HRCgUtil.h"

@implementation HRColorCursor

- (id)initWithPoint:(CGPoint)point
{
    CGSize size = CGSizeMake(30.0f, 30.0f);
    CGRect frame = CGRectMake(point.x - size.width/2.0f, point.y - size.height/2.0f, size.width, size.height);
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setUserInteractionEnabled:FALSE];
        _currentColor.r = _currentColor.g = _currentColor.b = 1.0f;
    }
    return self;
}

- (void)setColorRed:(float)red andGreen:(float)green andBlue:(float)blue{
    _currentColor.r = red;
    _currentColor.g = green;
    _currentColor.b = blue;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    //CGContextAddRect(context, cursor_back_rect);
    HRSetRoundedRectanglePath(context, CGRectMake(2.0f, 2.0f, 26.0f, 26.0f), 2.0f);
    [[UIColor whiteColor] set];
    CGContextSetShadow(context, CGSizeMake(0.0f, 1.0f), 2.0f);
    CGContextDrawPath(context, kCGPathFill);
    CGContextRestoreGState(context);
    
    
    [[UIColor colorWithRed:_currentColor.r green:_currentColor.g blue:_currentColor.b alpha:1.0f] set];
    CGContextFillRect(context, CGRectMake(5.0f, 5.0f, 20.0f, 20.0f));
}


@end
