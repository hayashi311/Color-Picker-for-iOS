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

#import "HRColorCursor.h"
#import "HRCgUtil.h"

@interface HRColorCursor ()
- (id)initWithPoint:(CGPoint)point;
@end

@interface HRFlatStyleColorCursor : HRColorCursor

@property (nonatomic) BOOL editing;
@property (nonatomic, getter=isGrayCursor) BOOL grayCursor;
@end

@interface HROldStyleColorCursor : HRColorCursor

@end

@implementation HRColorCursor

+ (CGSize)cursorSize {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return CGSizeMake(30.0, 30.0f);
    }
    return CGSizeMake(28.0, 28.0f);
}

+ (CGFloat)outlineSize {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return 4.0f;
    }
    return 0.0f;
}

+ (CGFloat)shadowSize {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return 2.0f;
    }
    return 0.0f;
}

+ (HRColorCursor *)colorCursorWithPoint:(CGPoint)point {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return [[HROldStyleColorCursor alloc] initWithPoint:point];
    }
    return [[HRFlatStyleColorCursor alloc] initWithPoint:point];
}

- (id)initWithPoint:(CGPoint)point {
    CGSize size = [HRColorCursor cursorSize];
    CGRect frame = CGRectMake(point.x, point.y, size.width, size.height);
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setUserInteractionEnabled:FALSE];
        self.color = [UIColor whiteColor];
    }
    return self;
}

@end

@implementation HRFlatStyleColorCursor {
    CALayer *_backLayer;
    CALayer *_colorLayer;
    UIColor *_color;
    BOOL _editing;
}
@synthesize color = _color;

- (id)initWithPoint:(CGPoint)point {
    self = [super initWithPoint:point];
    if (self) {
        CGRect backFrame = (CGRect) {.origin = CGPointZero, .size = self.frame.size};
        _backLayer = [[CALayer alloc] init];
        _backLayer.frame = backFrame;
        _backLayer.cornerRadius = CGRectGetHeight(self.frame) / 2;
        _backLayer.borderColor = [[UIColor colorWithWhite:0.65 alpha:1.] CGColor];
        _backLayer.borderWidth = 1.0 / [[UIScreen mainScreen] scale];
        _backLayer.backgroundColor = [[UIColor colorWithWhite:1. alpha:.7] CGColor];
        [self.layer addSublayer:_backLayer];

        _colorLayer = [[CALayer alloc] init];
        _colorLayer.frame = CGRectInset(backFrame, 5.5, 5.5);
        _colorLayer.cornerRadius = CGRectGetHeight(_colorLayer.frame) / 2;
        [self.layer addSublayer:_colorLayer];
    }
    return self;
}


- (void)setColor:(UIColor *)color {
    _color = color;
    HRHSVColor hsvColor;
    HSVColorFromUIColor(_color, &hsvColor);
    BOOL shouldBeGrayCursor = hsvColor.v > 0.7 && hsvColor.s < 0.4;


    [CATransaction begin];
    [CATransaction setValue:(id) kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    _colorLayer.backgroundColor = [_color CGColor];
    if (self.isGrayCursor != shouldBeGrayCursor) {
        if (shouldBeGrayCursor) {
            _backLayer.borderColor = [[UIColor colorWithWhite:0 alpha:0.3] CGColor];
            _backLayer.backgroundColor = [[UIColor colorWithWhite:0. alpha:0.2] CGColor];
        } else {
            _backLayer.borderColor = [[UIColor colorWithWhite:0.65 alpha:1] CGColor];
            _backLayer.backgroundColor = [[UIColor colorWithWhite:1. alpha:0.7] CGColor];
        }
        self.grayCursor = shouldBeGrayCursor;
    }

    [CATransaction commit];
    [self setNeedsDisplay];
}

- (void)setEditing:(BOOL)editing {
    if (editing == _editing) {
        return;
    }
    _editing = editing;
    void (^showState)() = ^{
        _backLayer.transform = CATransform3DMakeScale(1.6, 1.6, 1.0);
        _colorLayer.transform = CATransform3DMakeScale(1.4, 1.4, 1.0);
    };
    void (^hiddenState)() = ^{
        _backLayer.transform = CATransform3DIdentity;
        _colorLayer.transform = CATransform3DIdentity;
    };
    if (_editing) {
        hiddenState();
    } else {
        showState();
    }
    [UIView animateWithDuration:0.1
                     animations:_editing ? showState : hiddenState];
}

@end

@implementation HROldStyleColorCursor {
    UIColor *_cursorColor;
}
@synthesize color = _cursorColor;

- (void)setColor:(UIColor *)color {
    _cursorColor = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat outlineSize = [HRColorCursor outlineSize];
    CGSize cursorSize = [HRColorCursor cursorSize];
    CGFloat shadowSize = [HRColorCursor shadowSize];

    CGContextSaveGState(context);
    HRSetRoundedRectanglePath(context, CGRectMake(shadowSize, shadowSize, cursorSize.width - shadowSize * 2.0f, cursorSize.height - shadowSize * 2.0f), 2.0f);

    HRHSVColor hsvColor;
    HSVColorFromUIColor(self.color, &hsvColor);

    if (hsvColor.v > 0.7 && hsvColor.s < 0.4) {
        [[UIColor colorWithWhite:0.6 alpha:1] set];
    } else {
        [[UIColor whiteColor] set];
    }

    if (shadowSize) {
        CGContextSetShadow(context, CGSizeMake(0.0f, 1.0f), shadowSize);
    }
    CGContextDrawPath(context, kCGPathFill);
    CGContextRestoreGState(context);

    [self.color set];
    CGContextFillRect(context, CGRectMake(outlineSize + shadowSize, outlineSize + shadowSize, cursorSize.width - (outlineSize + shadowSize) * 2.0f, cursorSize.height - (outlineSize + shadowSize) * 2.0f));
}


@end
