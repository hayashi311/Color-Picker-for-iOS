/*-
 * Copyright (c) 2011 Ryota Hayashi
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $FreeBSD$
 */

#import "HRBrightnessCursor.h"
#import "HRCgUtil.h"


@implementation HRBrightnessCursor

- (void)setOrigin:(CGPoint)origin {
    _origin = origin;
    CGRect frame = self.frame;
    frame = CGRectMake(
            origin.x - frame.size.width / 2.0f,
            origin.y - frame.size.height / 2.0f,
            frame.size.width,
            frame.size.height);
    self.frame = frame;
}

@end

@implementation HRFlatStyleBrightnessCursor {
    CALayer *_colorLayer;
    UILabel *_brightnessLabel;
}

- (id)init {
    self = [super initWithFrame:CGRectMake(0, 0, 28, 28)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _colorLayer = [[CALayer alloc] init];
        _colorLayer.frame = CGRectInset(self.frame, 5.5, 5.5);
        _colorLayer.cornerRadius = CGRectGetHeight(_colorLayer.frame) / 2;
        [self.layer addSublayer:_colorLayer];

        _brightnessLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 16)];
        _brightnessLabel.center = CGPointMake(CGRectGetWidth(self.frame) / 2, -10);
        _brightnessLabel.backgroundColor = [UIColor clearColor];
        _brightnessLabel.textAlignment = NSTextAlignmentCenter;
        _brightnessLabel.font = [UIFont systemFontOfSize:12];
        _brightnessLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
        [self addSubview:_brightnessLabel];
    }
    return self;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [CATransaction begin];
    [CATransaction setValue:(id) kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    _colorLayer.backgroundColor = [color CGColor];
    [CATransaction commit];

    HRHSVColor hsvColor;
    HSVColorFromUIColor(_color, &hsvColor);

    NSMutableAttributedString *status;
    NSString *percent = [NSString stringWithFormat:@"%d", (int) (hsvColor.v * 100)];
    NSDictionary *attributes = @{
            NSFontAttributeName : [UIFont systemFontOfSize:12],
            NSForegroundColorAttributeName : [UIColor colorWithWhite:0.5 alpha:1]};

    status = [[NSMutableAttributedString alloc] initWithString:percent
                                                    attributes:attributes];

    NSDictionary *signAttributes = @{
            NSFontAttributeName : [UIFont systemFontOfSize:10],
            NSForegroundColorAttributeName : [UIColor colorWithWhite:0.5 alpha:1]};

    NSAttributedString *percentSign;
    percentSign = [[NSAttributedString alloc] initWithString:@"%"
                                                  attributes:signAttributes];

    [status appendAttributedString:percentSign];

    _brightnessLabel.attributedText = status;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat lineWidth = 0.5;
    CGRect ellipseRect = CGRectInset(rect, lineWidth, lineWidth);

    CGContextSaveGState(context);
    CGContextAddEllipseInRect(context, ellipseRect);
    [[UIColor colorWithWhite:1 alpha:0.7] setFill];
    [[UIColor colorWithWhite:0.75 alpha:1] setStroke];
    CGContextSetLineWidth(context, lineWidth);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextRestoreGState(context);
}

@end

@implementation HROldStyleBrightnessCursor

- (id)init {
    self = [super initWithFrame:CGRectMake(0, 0, 18, 40)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
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

    CGFloat topColor = 0.9f;
    CGFloat bottomColor = 0.98f;
    CGFloat alpha = 1.0f;
    CGFloat gradientColor[] = {
            topColor, topColor, topColor, alpha,
            bottomColor, bottomColor, bottomColor, alpha
    };

    CGGradientRef gradient;
    CGColorSpaceRef colorSpace;
    size_t numberOfLocations = 2;
    CGFloat locations[2] = {0.0, 1.0};
    colorSpace = CGColorSpaceCreateDeviceRGB();
    gradient = CGGradientCreateWithColorComponents(colorSpace, gradientColor,
            locations, numberOfLocations);

    CGPoint startPoint = CGPointMake(self.frame.size.width / 2, 0.0);
    CGPoint endPoint = CGPointMake(self.frame.size.width / 2, self.frame.size.height);
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

