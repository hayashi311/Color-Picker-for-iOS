//
// Created by hayashi311 on 2013/09/14.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "HRBrightnessSlider.h"
#import "HRCgUtil.h"
#import "HRBrightnessCursor.h"

@interface HRBrightnessSlider ()

@property (nonatomic) CGRect sliderFrame;

@end


@interface HRFlatStyleBrightnessSlider : HRBrightnessSlider

@property (nonatomic, readonly) CGFloat brightness;
@property (nonatomic) UIColor *color;
@property (nonatomic) CGFloat brightnessLowerLimit;

@end

@interface HROldStyleBrightnessSlider : HRBrightnessSlider

@end


@implementation HRBrightnessSlider

+ (HRBrightnessSlider *)brightnessSliderWithFrame:(CGRect)frame {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return [[HROldStyleBrightnessSlider alloc] initWithFrame:frame];
    }
    return [[HRFlatStyleBrightnessSlider alloc] initWithFrame:frame];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGRect frameInView = (CGRect) {.origin = CGPointZero, .size = frame.size};
        self.sliderFrame = UIEdgeInsetsInsetRect(frameInView, UIEdgeInsetsMake(0, 20, 0, 20));
    }
    return self;
}


- (CGFloat)brightness {
    return 0;
}

- (UIColor *)color {
    return nil;
}

- (void)setColor:(UIColor *)color {
    // Do noting
}

- (CGFloat)brightnessLowerLimit {
    return 0;
}

- (void)setBrightnessLowerLimit:(CGFloat)brightnessLowerLimit {
    // Do noting
}

@end

@implementation HRFlatStyleBrightnessSlider {
    HRFlatStyleBrightnessCursor *_brightnessCursor;

    CAGradientLayer *_sliderLayer;
    CGFloat _brightness;
    UIColor *_color;
    CGFloat _brightnessLowerLimit;

    BOOL _needsToUpdateColor;
}

@synthesize brightness = _brightness;
@synthesize brightnessLowerLimit = _brightnessLowerLimit;


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _sliderLayer = [[CAGradientLayer alloc] initWithLayer:self.layer];
        _sliderLayer.startPoint = CGPointMake(0, .5);
        _sliderLayer.endPoint = CGPointMake(1, .5);
        _sliderLayer.cornerRadius = 3;
        _sliderLayer.borderColor = [[UIColor lightGrayColor] CGColor];
        _sliderLayer.borderWidth = 1.f / [[UIScreen mainScreen] scale];

        [self.layer addSublayer:_sliderLayer];

        self.backgroundColor = [UIColor clearColor];

        UITapGestureRecognizer *tapGestureRecognizer;
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];

        UIPanGestureRecognizer *panGestureRecognizer;
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGestureRecognizer];

        _brightnessCursor = [[HRFlatStyleBrightnessCursor alloc] init];
        _brightnessCursor.origin = CGPointMake(
                CGRectGetMinX(self.sliderFrame),
                CGRectGetMidY(self.sliderFrame));
        [self addSubview:_brightnessCursor];

        _needsToUpdateColor = NO;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.sliderFrame;
    frame.size.height = 6;
    frame.origin.y = (CGRectGetHeight(self.frame) - CGRectGetHeight(frame)) / 2;
    _sliderLayer.frame = frame;
}

- (UIColor *)color {
    if (_needsToUpdateColor) {
        HRHSVColor hsvColor;
        HSVColorFromUIColor(_color, &hsvColor);
        hsvColor.v = _brightness;
        _color = [[UIColor alloc] initWithHue:hsvColor.h
                                   saturation:hsvColor.s
                                   brightness:hsvColor.v
                                        alpha:1];
    }
    return _color;
}

- (void)setColor:(UIColor *)color {
    _color = color;

    CGFloat brightness;
    [_color getHue:NULL saturation:NULL brightness:&brightness alpha:NULL];
    _brightness = brightness;
    _needsToUpdateColor = YES;

    [self updateCursor];

    [CATransaction begin];
    [CATransaction setValue:(id) kCFBooleanTrue
                     forKey:kCATransactionDisableActions];

    HRHSVColor hsvColor;
    HSVColorFromUIColor(_color, &hsvColor);
    UIColor *darkColorFromHsv = [UIColor colorWithHue:hsvColor.h saturation:hsvColor.s brightness:self.brightnessLowerLimit alpha:1.0f];
    UIColor *lightColorFromHsv = [UIColor colorWithHue:hsvColor.h saturation:hsvColor.s brightness:1.0f alpha:1.0f];

    _sliderLayer.colors = @[(id) lightColorFromHsv.CGColor, (id) darkColorFromHsv.CGColor];

    [CATransaction commit];
}

- (void)setBrightnessLowerLimit:(CGFloat)brightnessLowerLimit {
    _brightnessLowerLimit = brightnessLowerLimit;
    [self updateCursor];
    self.color = _color;
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
    CGPoint tapPointInSlider = CGPointMake(tapPoint.x - self.sliderFrame.origin.x, tapPoint.y);
    tapPointInSlider.x = MIN(tapPointInSlider.x, self.sliderFrame.size.width);
    tapPointInSlider.x = MAX(tapPointInSlider.x, 0);

    selectedBrightness = 1.0 - tapPointInSlider.x / self.sliderFrame.size.width;
    selectedBrightness = selectedBrightness * (1.0 - self.brightnessLowerLimit) + self.brightnessLowerLimit;
    _brightness = selectedBrightness;

    [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)updateCursor {
    CGFloat brightnessCursorX = (1.0f - (self.brightness - self.brightnessLowerLimit) / (1.0f - self.brightnessLowerLimit));
    _brightnessCursor.center = CGPointMake(brightnessCursorX * self.sliderFrame.size.width + self.sliderFrame.origin.x, _brightnessCursor.center.y);
    _brightnessCursor.color = self.color;
}


@end


@implementation HROldStyleBrightnessSlider {
    void *_brightnessPickerShadowImage;

    HRBrightnessCursor *_brightnessCursor;

    CGRect _shadowFrame;
    CGFloat _brightness;
    UIColor *_color;
    CGFloat _brightnessLowerLimit;
}

@synthesize brightness = _brightness;
@synthesize color = _color;
@synthesize brightnessLowerLimit = _brightnessLowerLimit;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.brightnessLowerLimit = 0;
        _shadowFrame = CGRectInset(self.sliderFrame, -5, -5);

        [self createCacheShadowImage];

        UITapGestureRecognizer *tapGestureRecognizer;
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];

        UIPanGestureRecognizer *panGestureRecognizer;
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGestureRecognizer];

        _brightnessCursor = [[HROldStyleBrightnessCursor alloc] init];
        _brightnessCursor.origin = CGPointMake(
                CGRectGetMinY(self.sliderFrame),
                CGRectGetMidY(self.sliderFrame));
        [self addSubview:_brightnessCursor];
    }
    return self;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    CGFloat brightness;
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
    CGPoint tapPointInSlider = CGPointMake(tapPoint.x - self.sliderFrame.origin.x, tapPoint.y);
    tapPointInSlider.x = MIN(tapPointInSlider.x, self.sliderFrame.size.width);
    tapPointInSlider.x = MAX(tapPointInSlider.x, 0);

    selectedBrightness = 1.0 - tapPointInSlider.x / self.sliderFrame.size.width;
    selectedBrightness = selectedBrightness * (1.0 - self.brightnessLowerLimit) + self.brightnessLowerLimit;
    _brightness = selectedBrightness;

    [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)updateCursor {
    CGFloat brightnessCursorX = (1.0f - (self.brightness - self.brightnessLowerLimit) / (1.0f - self.brightnessLowerLimit));
    _brightnessCursor.center = CGPointMake(brightnessCursorX * self.sliderFrame.size.width + self.sliderFrame.origin.x, _brightnessCursor.center.y);
}


- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);

    HRSetRoundedRectanglePath(context, self.sliderFrame, 5.0f);
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

    CGPoint startPoint = CGPointMake(self.sliderFrame.origin.x + self.sliderFrame.size.width, self.sliderFrame.origin.y);
    CGPoint endPoint = CGPointMake(self.sliderFrame.origin.x, self.sliderFrame.origin.y);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

    // GradientとColorSpaceを開放する
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);

    // 明度の内側の影 (キャッシュした画像を表示するだけ)
    CGContextDrawImage(context, _shadowFrame, _brightnessPickerShadowImage);

    CGContextRestoreGState(context);
}


@end
