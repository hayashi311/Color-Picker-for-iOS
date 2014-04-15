//
// Created by hayashi311 on 2013/09/14.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "HRColorMapView.h"
#import "HRColorUtil.h"
#import "UIImage+CoreGraphics.h"
#import "HRColorCursor.h"

@interface HRColorMapView () {
    UIColor *_color;
    CGFloat _brightness;
    CGFloat _saturationUpperLimit;
    HRColorCursor *_colorCursor;
}

@property (atomic, strong) CALayer *colorMapLayer; // brightness 1.0
@property (atomic, strong) CALayer *colorMapBackgroundLayer; // brightness 0 (= black)

@end

@implementation HRColorMapView {
    CALayer *_lineLayer;
}
@synthesize color = _color;
@synthesize saturationUpperLimit = _saturationUpperLimit;

+ (UIImage *)colorMapImageWithSize:(CGSize)size
                          tileSize:(CGFloat)tileSize
              saturationUpperLimit:(CGFloat)saturationUpperLimit {

    CGSize colorMapSize = size;
    void(^renderToContext)(CGContextRef, CGRect) = ^(CGContextRef context, CGRect rect) {
        CGFloat margin = 0;
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            margin = 2;
        }

        CGFloat height;
        int pixelCountX = (int) (rect.size.width / tileSize);
        int pixelCountY = (int) (rect.size.height / tileSize);

        HRHSVColor pixelHsv;
        HRRGBColor pixelRgb;
        for (int j = 0; j < pixelCountY; ++j) {
            height = tileSize * j + rect.origin.y;
            CGFloat pixelY = (CGFloat) j / (pixelCountY - 1); // Y(彩度)は0.0f~1.0f
            for (int i = 0; i < pixelCountX; ++i) {
                CGFloat pixelX = (CGFloat) i / pixelCountX; // X(色相)は1.0f=0.0fなので0.0f~0.95fの値をとるように

                pixelHsv.h = pixelX;
                pixelHsv.s = 1.0f - (pixelY * saturationUpperLimit);
                pixelHsv.v = 1.f;

                RGBColorFromHSVColor(&pixelHsv, &pixelRgb);
                CGContextSetRGBFillColor(context, pixelRgb.r, pixelRgb.g, pixelRgb.b, 1.0f);

                CGContextFillRect(context, CGRectMake(tileSize * i + rect.origin.x, height, tileSize - margin, tileSize - margin));
            }
        }
    };
    return [UIImage hr_imageWithSize:colorMapSize renderer:renderToContext];
}

+ (UIImage *)backgroundImageWithSize:(CGSize)size
                            tileSize:(CGFloat)tileSize {

    CGSize colorMapSize = size;
    void(^renderBackgroundToContext)(CGContextRef, CGRect) = ^(CGContextRef context, CGRect rect) {
        CGFloat margin = 0;
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            margin = 2;
        }

        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
        CGContextFillRect(context, rect);

        CGFloat height;
        int pixelCountX = (int) (rect.size.width / tileSize);
        int pixelCountY = (int) (rect.size.height / tileSize);

        CGContextSetGrayFillColor(context, 0, 1.0);
        for (int j = 0; j < pixelCountY; ++j) {
            height = tileSize * j + rect.origin.y;
            for (int i = 0; i < pixelCountX; ++i) {
                CGContextFillRect(context, CGRectMake(tileSize * i + rect.origin.x, height, tileSize - margin, tileSize - margin));
            }
        }
    };

    return [UIImage hr_imageWithSize:colorMapSize
                            renderer:renderBackgroundToContext];
}

+ (HRColorMapView *)colorMapWithFrame:(CGRect)frame {
    return [[HRColorMapView alloc] initWithFrame:frame saturationUpperLimit:0.95];
}

+ (HRColorMapView *)colorMapWithFrame:(CGRect)frame saturationUpperLimit:(CGFloat)saturationUpperLimit {
    return [[HRColorMapView alloc] initWithFrame:frame saturationUpperLimit:saturationUpperLimit];
}

- (id)initWithFrame:(CGRect)frame saturationUpperLimit:(CGFloat)saturationUpperLimit {
    self = [super initWithFrame:frame];
    if (self) {
        self.tileSize = 15;
        self.saturationUpperLimit = saturationUpperLimit;
        self.brightness = 0.5;
        self.backgroundColor = [UIColor whiteColor];

        CGFloat lineWidth = 1.f / [[UIScreen mainScreen] scale];
        _lineLayer = [[CALayer alloc] init];
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            // 囲むライン
            _lineLayer.borderColor = [[UIColor colorWithWhite:0.9f alpha:1.0f] CGColor];
            _lineLayer.borderWidth = lineWidth;
            _lineLayer.frame = CGRectMake(-1, -1, frame.size.width, frame.size.height);
        } else {
            // フラットデザイン用のラインはトップのみ
            _lineLayer.backgroundColor = [[UIColor colorWithWhite:0.7 alpha:1] CGColor];
            _lineLayer.frame = CGRectMake(0, -lineWidth, CGRectGetWidth(frame), lineWidth);
        }
        [self.layer addSublayer:_lineLayer];

        // タイルの中心にくるようにずらす
        CGPoint cursorOrigin = CGPointMake(
                -([HRColorCursor cursorSize].width - _tileSize) / 2.0f - [HRColorCursor shadowSize] / 2.0,
                -([HRColorCursor cursorSize].height - _tileSize) / 2.0f - [HRColorCursor shadowSize] / 2.0);
        _colorCursor = [HRColorCursor colorCursorWithPoint:cursorOrigin];
        [self addSubview:_colorCursor];

        UITapGestureRecognizer *tapGestureRecognizer;
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];

        UIPanGestureRecognizer *panGestureRecognizer;
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGestureRecognizer];
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self createColorMapLayer];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.layer insertSublayer:self.colorMapBackgroundLayer atIndex:0];
            self.colorMapLayer.opacity = self.brightness;
            [self.layer insertSublayer:self.colorMapLayer atIndex:1];
        });
    });
}


- (void)createColorMapLayer {
    if (self.colorMapLayer) {
        return;
    }

    UIImage *colorMapImage;
    colorMapImage = [HRColorMapView colorMapImageWithSize:self.frame.size
                                                 tileSize:self.tileSize
                                     saturationUpperLimit:self.saturationUpperLimit];

    UIImage *backgroundImage;
    backgroundImage = [HRColorMapView backgroundImageWithSize:self.frame.size
                                                     tileSize:self.tileSize];

    [CATransaction begin];
    [CATransaction setValue:(id) kCFBooleanTrue
                     forKey:kCATransactionDisableActions];

    self.colorMapLayer = [[CALayer alloc] initWithLayer:self.layer];
    self.colorMapLayer.frame = (CGRect) {.origin = CGPointZero, .size = self.layer.frame.size};
    self.colorMapLayer.contents = (id) colorMapImage.CGImage;
    self.colorMapBackgroundLayer = [[CALayer alloc] initWithLayer:self.layer];
    self.colorMapBackgroundLayer.frame = (CGRect) {.origin = CGPointZero, .size = self.layer.frame.size};
    self.colorMapBackgroundLayer.contents = (id) backgroundImage.CGImage;

    [CATransaction commit];
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self updateColorCursor];
}

- (CGFloat)brightness {
    return _brightness;
}

- (void)setBrightness:(CGFloat)brightness {
    _brightness = brightness;
    [CATransaction begin];
    [CATransaction setValue:(id) kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    self.colorMapLayer.opacity = _brightness;
    [CATransaction commit];
}

- (void)handleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (sender.numberOfTouches <= 0) {
            return;
        }
        CGPoint tapPoint = [sender locationOfTouch:0 inView:self];
        [self update:tapPoint];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateChanged || sender.state == UIGestureRecognizerStateEnded) {
        if (sender.numberOfTouches <= 0) {
            if ([_colorCursor respondsToSelector:@selector(setEditing:)]) {
                [_colorCursor setEditing:NO];
            }
            return;
        }
        CGPoint tapPoint = [sender locationOfTouch:0 inView:self];
        [self update:tapPoint];
        if ([_colorCursor respondsToSelector:@selector(setEditing:)]) {
            [_colorCursor setEditing:YES];
        }
    }
}


- (void)update:(CGPoint)tapPoint {
    if (!CGRectContainsPoint((CGRect) {.origin = CGPointZero, .size = self.frame.size}, tapPoint)) {
        return;
    }
    int pixelCountX = (int) (self.frame.size.width / _tileSize);
    int pixelCountY = (int) (self.frame.size.height / _tileSize);

    CGFloat pixelX = (int) ((tapPoint.x) / _tileSize) / (CGFloat) pixelCountX; // X(色相)
    CGFloat pixelY = (int) ((tapPoint.y) / _tileSize) / (CGFloat) (pixelCountY - 1); // Y(彩度)

    HRHSVColor selectedHSVColor;
    HSVColorAt(&selectedHSVColor, pixelX, pixelY, self.saturationUpperLimit, self.brightness);

    UIColor *selectedColor;
    selectedColor = [UIColor colorWithHue:selectedHSVColor.h
                               saturation:selectedHSVColor.s
                               brightness:selectedHSVColor.v
                                    alpha:1.0];
    _color = selectedColor;
    [self updateColorCursor];
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)updateColorCursor {
    // カラーマップのカーソルの移動＆色の更新
    CGPoint colorCursorPosition = CGPointZero;
    HRHSVColor hsvColor;
    HSVColorFromUIColor(self.color, &hsvColor);

    int pixelCountX = (int) (self.frame.size.width / _tileSize);
    int pixelCountY = (int) (self.frame.size.height / _tileSize);
    CGPoint newPosition;
    CGFloat hue = hsvColor.h;
    if (hue == 1) {
        hue = 0;
    }

    newPosition.x = hue * (CGFloat) pixelCountX * _tileSize + _tileSize / 2.0f;
    newPosition.y = (1.0f - hsvColor.s) * (1.0f / _saturationUpperLimit) * (CGFloat) (pixelCountY - 1) * _tileSize + _tileSize / 2.0f;
    colorCursorPosition.x = (int) (newPosition.x / _tileSize) * _tileSize;
    colorCursorPosition.y = (int) (newPosition.y / _tileSize) * _tileSize;
    _colorCursor.color = self.color;
    _colorCursor.transform = CGAffineTransformMakeTranslation(colorCursorPosition.x, colorCursorPosition.y);
}

@end