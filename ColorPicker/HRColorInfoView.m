//
// Created by hayashi311 on 2013/09/15.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "HRColorInfoView.h"
#import "HRCgUtil.h"

@interface HRColorInfoView(){
    UIColor *_color;
}
@end

@implementation HRColorInfoView
@synthesize color = _color;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.color = [UIColor whiteColor];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGRect colorFrame = CGRectMake(1, 5, 40.0f, 40.0f);


    /////////////////////////////////////////////////////////////////////////////
    //
    // カラー
    //
    /////////////////////////////////////////////////////////////////////////////

    CGContextSaveGState(context);
    HRDrawSquareColorBatch(context, CGPointMake(CGRectGetMidX(colorFrame), CGRectGetMidY(colorFrame)), self.color, colorFrame.size.width / 2.0f);
    CGContextRestoreGState(context);

    /////////////////////////////////////////////////////////////////////////////
    //
    // RGBのパーセント表示
    //
    /////////////////////////////////////////////////////////////////////////////

    float red, green, blue, alpha;
    [self.color getRed:&red green:&green blue:&blue alpha:&alpha];

    [[UIColor darkGrayColor] set];

    float textHeight = 20.0f;
    float textCenter = CGRectGetMidY(colorFrame) - 5.0f;
    [[NSString stringWithFormat:@"R:%3d%%", (int) (red * 100)] drawAtPoint:CGPointMake(colorFrame.origin.x + colorFrame.size.width + 10.0f, textCenter - textHeight) withFont:[UIFont boldSystemFontOfSize:12.0f]];
    [[NSString stringWithFormat:@"G:%3d%%", (int) (green * 100)] drawAtPoint:CGPointMake(colorFrame.origin.x + colorFrame.size.width + 10.0f, textCenter) withFont:[UIFont boldSystemFontOfSize:12.0f]];
    [[NSString stringWithFormat:@"B:%3d%%", (int) (blue * 100)] drawAtPoint:CGPointMake(colorFrame.origin.x + colorFrame.size.width + 10.0f, textCenter + textHeight) withFont:[UIFont boldSystemFontOfSize:12.0f]];
}



@end