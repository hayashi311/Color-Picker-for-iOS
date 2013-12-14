//
// Created by hayashi311 on 2013/09/14.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "HRBrightnessSlider.h"
#import "HRCgUtil.h"
#import "HRBrightnessCursor.h"


@interface HRBrightnessSlider () {
    HRBrightnessCursor *_brightnessCursor;

    CGRect _sliderFrame;
    CGRect _shadowFrame;
    CGFloat _brightness;
    UIColor *_color;
    CGFloat _brightnessLowerLimit;
}

@end

@implementation HRBrightnessSlider
@synthesize brightness = _brightness;
@synthesize color = _color;
@synthesize brightnessLowerLimit = _brightnessLowerLimit;


+ (HRBrightnessSlider *)brightnessSliderWithFrame:(CGRect)frame {
    return [[HRBrightnessSlider alloc] initWithFrame:frame];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.brightnessLowerLimit = 0;
        CGRect frameInView = (CGRect) {.origin = CGPointZero, .size = frame.size};
        _sliderFrame = UIEdgeInsetsInsetRect(frameInView, UIEdgeInsetsMake(0, 20, 0, 20));
        _shadowFrame = CGRectInset(_sliderFrame, -5, -5);
        [self createCacheShadowImage];

        UITapGestureRecognizer *tapGestureRecognizer;
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];

        UIPanGestureRecognizer *panGestureRecognizer;
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGestureRecognizer];

        _brightnessCursor = [[HRBrightnessCursor alloc] initWithPoint:CGPointMake(_sliderFrame.origin.x, _sliderFrame.origin.y + _sliderFrame.size.height / 2.0f)];
        [self addSubview:_brightnessCursor];
    }
    return self;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    float brightness;
    [_color getHue:NULL saturation:NULL brightness:&brightness alpha:NULL];
    _brightness = brightness;
    [self updateCursor];
    [self setNeedsDisplay];
}

- (void)setBrightnessLowerLimit:(CGFloat)brightnessLowerLimit {
    _brightnessLowerLimit = brightnessLowerLimit;
    [self updateCursor];
}


- (void)createCacheShadowImage {
    // 影のコストは高いので、事前に画像に書き出しておきます

    if (_brightnessPickerShadowImage != nil) {
        return;
    }

    UIGraphicsBeginImageContextWithOptions(_shadowFrame.size, NO, 0);
    CGContextRef brightnessPickerShadowContext = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(brightnessPickerShadowContext, 0, _shadowFrame.size.height);
    CGContextScaleCTM(brightnessPickerShadowContext, 1.0, -1.0);

    HRSetRoundedRectanglePath(brightnessPickerShadowContext,
            CGRectMake(0.0f, 0.0f,
                    _shadowFrame.size.width,
                    _shadowFrame.size.height), 5.0f);
    CGContextSetLineWidth(brightnessPickerShadowContext, 10.0f);
    CGContextSetShadow(brightnessPickerShadowContext, CGSizeMake(0.0f, 0.0f), 10.0f);
    CGContextDrawPath(brightnessPickerShadowContext, kCGPathStroke);

    _brightnessPickerShadowImage = CGBitmapContextCreateImage(brightnessPickerShadowContext);
    UIGraphicsEndImageContext();
}

- (void)handleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (sender.numberOfTouches <= 0) {
            return;
        }
        CGPoint tapPoint = [sender locationOfTouch:0 inView:self];
        [self update:tapPoint];
        [self updateCursor];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateChanged || sender.state == UIGestureRecognizerStateEnded) {
        if (sender.numberOfTouches <= 0) {
            return;
        }
        CGPoint tapPoint = [sender locationOfTouch:0 inView:self];
        [self update:tapPoint];
        [self updateCursor];
    }
}


- (void)update:(CGPoint)tapPoint {
    CGFloat selectedBrightness = 0;
    CGPoint tapPointInSlider = CGPointMake(tapPoint.x - _sliderFrame.origin.x, tapPoint.y);
    tapPointInSlider.x = MIN(tapPointInSlider.x, _sliderFrame.size.width);
    tapPointInSlider.x = MAX(tapPointInSlider.x, 0);

    selectedBrightness = 1.0 - tapPointInSlider.x / _sliderFrame.size.width;
    selectedBrightness = selectedBrightness * (1.0 - self.brightnessLowerLimit) + self.brightnessLowerLimit;
    _brightness = selectedBrightness;

    [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)updateCursor {
    float brightnessCursorX = (1.0f - (self.brightness - self.brightnessLowerLimit) / (1.0f - self.brightnessLowerLimit));
    _brightnessCursor.center = CGPointMake(brightnessCursorX * _sliderFrame.size.width + _sliderFrame.origin.x, _brightnessCursor.center.y);
}


- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);

    HRSetRoundedRectanglePath(context, _sliderFrame, 5.0f);
    CGContextClip(context);

    CGGradientRef gradient;
    CGColorSpaceRef colorSpace;
    size_t numLocations = 2;
    CGFloat locations[2] = {0.0, 1.0};
    colorSpace = CGColorSpaceCreateDeviceRGB();

    HRHSVColor hsvColor;
    HSVColorFromUIColor(self.color, &hsvColor);

    self.color;
    HRRGBColor darkColor;
    HRRGBColor lightColor;

    UIColor *darkColorFromHsv = [UIColor colorWithHue:hsvColor.h saturation:hsvColor.s brightness:self.brightnessLowerLimit alpha:1.0f];
    UIColor *lightColorFromHsv = [UIColor colorWithHue:hsvColor.h saturation:hsvColor.s brightness:1.0f alpha:1.0f];

    RGBColorFromUIColor(darkColorFromHsv, &darkColor);
    RGBColorFromUIColor(lightColorFromHsv, &lightColor);

    CGFloat gradientColor[] = {
            darkColor.r, darkColor.g, darkColor.b, 1.0f,
            lightColor.r, lightColor.g, lightColor.b, 1.0f,
    };

    gradient = CGGradientCreateWithColorComponents(colorSpace, gradientColor,
            locations, numLocations);

    CGPoint startPoint = CGPointMake(_sliderFrame.origin.x + _sliderFrame.size.width, _sliderFrame.origin.y);
    CGPoint endPoint = CGPointMake(_sliderFrame.origin.x, _sliderFrame.origin.y);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

    // GradientとColorSpaceを開放する
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);

    // 明度の内側の影 (キャッシュした画像を表示するだけ)
    CGContextDrawImage(context, _shadowFrame, _brightnessPickerShadowImage);

    CGContextRestoreGState(context);
}


@end