//
// Created by hayashi311 on 2013/09/14.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "HRColorMapView.h"
#import "HRColorUtil.h"
#import "UIImage+CoreGraphics.h"

@interface HRColorMapView (){
    UIColor *_color;
    CGFloat _brightness;
}

@property (atomic, strong) CALayer *colorMapLayer; // brightness 1.0
@property (atomic, strong) CALayer *colorMapBackgroundLayer; // brightness 0 (= black)

@end

@implementation HRColorMapView
@synthesize color = _color;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.tileSize = 15;
        self.saturationUpperLimit = .95;
        self.brightness = 0.5;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self createColorMapLayer];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.layer addSublayer:self.colorMapBackgroundLayer];
                [self.layer addSublayer:self.colorMapLayer];
            });
        });

        UITapGestureRecognizer *tapGestureRecognizer;
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];

        UIPanGestureRecognizer *panGestureRecognizer;
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGestureRecognizer];
    }
    return self;
}


- (void)createColorMapLayer {
    CGSize colorMapSize = self.frame.size;

    void(^renderToContext)(CGContextRef, CGRect) = ^(CGContextRef context, CGRect rect) {

        float height;
        int pixelCountX = (int) (rect.size.width / self.tileSize);
        int pixelCountY = (int) (rect.size.height / self.tileSize);

        HRHSVColor pixelHsv;
        HRRGBColor pixelRgb;
        for (int j = 0; j < pixelCountY; ++j) {
            height = self.tileSize * j + rect.origin.y;
            float pixelY = (float) j / (pixelCountY - 1); // Y(彩度)は0.0f~1.0f
            for (int i = 0; i < pixelCountX; ++i) {
                float pixelX = (float) i / pixelCountX; // X(色相)は1.0f=0.0fなので0.0f~0.95fの値をとるように

                pixelHsv.h = pixelX;
                pixelHsv.s = 1.0f - (pixelY * self.saturationUpperLimit);
                pixelHsv.v = 1.f;

                RGBColorFromHSVColor(&pixelHsv, &pixelRgb);
                CGContextSetRGBFillColor(context, pixelRgb.r, pixelRgb.g, pixelRgb.b, 1.0f);

                CGContextFillRect(context, CGRectMake(self.tileSize * i + rect.origin.x, height, self.tileSize - 2.0f, self.tileSize - 2.0f));
            }
        }
    };

    self.colorMapLayer = [[CALayer alloc] initWithLayer:self.layer];
    self.colorMapLayer.frame = (CGRect) {.origin = CGPointZero, .size = self.layer.frame.size};
    UIImage *colorMapImage = [UIImage imageWithSize:colorMapSize renderer:renderToContext];
    self.colorMapLayer.contents = (id) colorMapImage.CGImage;

    void(^renderBackgroundToContext)(CGContextRef, CGRect) = ^(CGContextRef context, CGRect rect) {

        float height;
        int pixelCountX = (int) (rect.size.width / self.tileSize);
        int pixelCountY = (int) (rect.size.height / self.tileSize);

        CGContextSetGrayFillColor(context, 0, 1.0);
        for (int j = 0; j < pixelCountY; ++j) {
            height = self.tileSize * j + rect.origin.y;
            for (int i = 0; i < pixelCountX; ++i) {
                CGContextFillRect(context, CGRectMake(self.tileSize * i + rect.origin.x, height, self.tileSize - 2.0f, self.tileSize - 2.0f));
            }
        }
    };

    self.colorMapBackgroundLayer = [[CALayer alloc] initWithLayer:self.layer];
    self.colorMapBackgroundLayer.frame = (CGRect) {.origin = CGPointZero, .size = self.layer.frame.size};
    UIImage *backgroundImage = [UIImage imageWithSize:colorMapSize renderer:renderBackgroundToContext];
    self.colorMapBackgroundLayer.contents = (id) backgroundImage.CGImage;
}

- (CGFloat)brightness {
    return _brightness;
}


- (void)setBrightness:(CGFloat)brightness {

    _brightness = brightness;
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    self.colorMapLayer.opacity = _brightness;
    [CATransaction commit];
}


- (void)handleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (sender. numberOfTouches <= 0){
            return;
        }
        CGPoint tapPoint = [sender locationOfTouch:0 inView:self];
        [self update:tapPoint];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateChanged || sender.state == UIGestureRecognizerStateEnded) {
        if (sender. numberOfTouches <= 0){
            return;
        }
        CGPoint tapPoint = [sender locationOfTouch:0 inView:self];
        [self update:tapPoint];
    }
}


- (void)update: (CGPoint)tapPoint {
    int pixelCountX = (int) (self.frame.size.width/_tileSize);
    int pixelCountY = (int) (self.frame.size.height/_tileSize);

    float pixelX = (int)((tapPoint.x)/_tileSize)/(float)pixelCountX; // X(色相)は1.0f=0.0fなので0.0f~0.95fの値をとるように
    float pixelY = (int)((tapPoint.y)/_tileSize)/(float)(pixelCountY-1); // Y(彩度)は0.0f~1.0f

    float h, s, v, a;
    [self.color getHue:&h saturation:&s brightness:&v alpha:&a];

    HRHSVColor selectedHSVColor;
    HSVColorAt(&selectedHSVColor, pixelX, pixelY, self.saturationUpperLimit, self.brightness);

    UIColor *selectedColor = [UIColor colorWithHue:selectedHSVColor.h
                                        saturation:selectedHSVColor.s
                                        brightness:selectedHSVColor.v
                                             alpha:1.0];

    _color = selectedColor;

    [self sendActionsForControlEvents:UIControlEventEditingChanged];
}


@end