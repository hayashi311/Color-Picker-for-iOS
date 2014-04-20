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

@property (nonatomic, strong) NSDate *lastUpdate;
@end


@implementation HRBrightnessSlider

+ (HRBrightnessSlider *)brightnessSliderWithFrame:(CGRect)frame {
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

const CGFloat kHRFlatStyleBrightnessSliderHeight = 11.;
const CGFloat kHRFlatStyleBrightnessSliderMarginBottom = 18.;

@implementation HRFlatStyleBrightnessSlider {
    HRFlatStyleBrightnessCursor *_brightnessCursor;

    CAGradientLayer *_sliderLayer;
    CGFloat _brightness;
    UIColor *_color;
    CGFloat _brightnessLowerLimit;

    BOOL _needsToUpdateColor;

    CGRect _controlFrame;
    CGRect _renderingFrame;
}

@synthesize brightness = _brightness;
@synthesize brightnessLowerLimit = _brightnessLowerLimit;


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _sliderLayer = [[CAGradientLayer alloc] initWithLayer:self.layer];
        _sliderLayer.startPoint = CGPointMake(0, .5);
        _sliderLayer.endPoint = CGPointMake(1, .5);
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

        CGRect sliderFrame = CGRectMake(0, 0, frame.size.width, kHRFlatStyleBrightnessSliderHeight);
        sliderFrame = CGRectInset(sliderFrame, 20, 0);
        sliderFrame.origin.y = CGRectGetHeight(frame) - kHRFlatStyleBrightnessSliderHeight / 2 - kHRFlatStyleBrightnessSliderMarginBottom;
        self.sliderFrame = sliderFrame;

        _brightnessCursor = [[HRFlatStyleBrightnessCursor alloc] init];
        _brightnessCursor.origin = CGPointMake(
                CGRectGetMinX(_controlFrame),
                CGRectGetMidY(_controlFrame));
        [self addSubview:_brightnessCursor];

        _needsToUpdateColor = NO;

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = _renderingFrame;
    _sliderLayer.cornerRadius = frame.size.height / 2;
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

            _brightnessCursor.editing = NO;
            return;
        }
        CGPoint tapPoint = [sender locationOfTouch:0 inView:self];
        [self update:tapPoint];
        [self updateCursor];
        _brightnessCursor.editing = YES;
    }
}

- (void)update:(CGPoint)tapPoint {
    CGFloat selectedBrightness = 0;
    CGPoint tapPointInSlider = CGPointMake(tapPoint.x - _controlFrame.origin.x, tapPoint.y);
    tapPointInSlider.x = MIN(tapPointInSlider.x, _controlFrame.size.width);
    tapPointInSlider.x = MAX(tapPointInSlider.x, 0);

    selectedBrightness = 1.0 - tapPointInSlider.x / _controlFrame.size.width;
    selectedBrightness = selectedBrightness * (1.0 - self.brightnessLowerLimit) + self.brightnessLowerLimit;
    _brightness = selectedBrightness;

    [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)updateCursor {
    CGFloat brightnessCursorX = (1.0f - (self.brightness - self.brightnessLowerLimit) / (1.0f - self.brightnessLowerLimit));
    _brightnessCursor.center = CGPointMake(brightnessCursorX * _controlFrame.size.width + _controlFrame.origin.x, _brightnessCursor.center.y);
    _brightnessCursor.color = self.color;
}

- (void)setSliderFrame:(CGRect)sliderFrame {
    [super setSliderFrame:sliderFrame];
    _renderingFrame = sliderFrame;
    _controlFrame = CGRectInset(_renderingFrame, 8, 0);
}


@end


