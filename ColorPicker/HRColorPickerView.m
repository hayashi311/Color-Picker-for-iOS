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

#import "HRColorPickerView.h"
#import <sys/time.h>
#import "HRColorMapView.h"
#import "HRBrightnessSlider.h"
#import "HRColorInfoView.h"
#import "HRColorUtil.h"

typedef struct timeval timeval;

@interface HRColorPickerView () {
}

@end

@implementation HRColorPickerView {
    UIView <HRColorInfoView> *_colorInfoView;
    UIControl <HRColorMapView> *_colorMapView;
    UIControl <HRBrightnessSlider> *_brightnessSlider;

    // 色情報
    HRHSVColor _currentHsvColor;

    // フレームレート
    timeval _lastDrawTime;
    timeval _waitTimeDuration;
}

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self _init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self _init];
    }
    return self;
}

- (void)_init {
    // フレームレートの調整
    gettimeofday(&_lastDrawTime, NULL);

    _waitTimeDuration.tv_sec = (__darwin_time_t) 0.0;
    _waitTimeDuration.tv_usec = (__darwin_suseconds_t) (1000000.0 / 15.0);
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
}

- (UIColor *)color {
    return [UIColor colorWithHue:_currentHsvColor.h
                      saturation:_currentHsvColor.s
                      brightness:_currentHsvColor.v
                           alpha:1];
}

- (void)setColor:(UIColor *)color {
    // RGBのデフォルトカラーをHSVに変換
    HSVColorFromUIColor(color, &_currentHsvColor);
}

- (UIView <HRColorInfoView> *)colorInfoView {
    if (!_colorInfoView) {
        _colorInfoView = [HRColorInfoView colorInfoViewWithFrame:CGRectZero];
        _colorInfoView.color = self.color;
        [self addSubview:self.colorInfoView];
    }
    return _colorInfoView;
}

- (void)setColorInfoView:(UIView <HRColorInfoView> *)colorInfoView {
    _colorInfoView = colorInfoView;
    _colorInfoView.color = self.color;
}

- (UIControl <HRBrightnessSlider> *)brightnessSlider {
    if (!_brightnessSlider) {
        _brightnessSlider = [HRBrightnessSlider brightnessSliderWithFrame:CGRectZero];
        _brightnessSlider.brightnessLowerLimit = @0.4;
        _brightnessSlider.color = self.color;
        [_brightnessSlider addTarget:self
                              action:@selector(brightnessChanged:)
                    forControlEvents:UIControlEventEditingChanged];
        [self addSubview:_brightnessSlider];
    }
    return _brightnessSlider;
}

- (void)setBrightnessSlider:(UIControl <HRBrightnessSlider> *)brightnessSlider {
    _brightnessSlider = brightnessSlider;
    _brightnessSlider.color = self.color;
    [_brightnessSlider addTarget:self
                          action:@selector(brightnessChanged:)
                forControlEvents:UIControlEventEditingChanged];
}

- (UIControl <HRColorMapView> *)colorMapView {
    if (!_colorMapView) {
        HRColorMapView *colorMapView;
        colorMapView = [HRColorMapView colorMapWithFrame:CGRectZero
                                    saturationUpperLimit:0.9];
        colorMapView.tileSize = @16;
        _colorMapView = colorMapView;

        _colorMapView.brightness = _currentHsvColor.v;
        _colorMapView.color = self.color;
        [_colorMapView addTarget:self
                          action:@selector(colorMapColorChanged:)
                forControlEvents:UIControlEventEditingChanged];
        _colorMapView.backgroundColor = [UIColor redColor];
        [self addSubview:_colorMapView];
    }
    return _colorMapView;
}

- (void)setColorMapView:(UIControl <HRColorMapView> *)colorMapView {
    _colorMapView = colorMapView;
    _colorMapView.brightness = _currentHsvColor.v;
    _colorMapView.color = self.color;
    [_colorMapView addTarget:self
                      action:@selector(colorMapColorChanged:)
            forControlEvents:UIControlEventEditingChanged];
}

- (void)brightnessChanged:(UIControl <HRBrightnessSlider> *)slider {
    _currentHsvColor.v = slider.brightness.floatValue;
    self.colorMapView.brightness = _currentHsvColor.v;
    self.colorMapView.color = self.color;
    self.colorInfoView.color = self.color;
    [self sendActions];
}

- (void)colorMapColorChanged:(UIControl <HRColorMapView> *)colorMapView {
    HSVColorFromUIColor(colorMapView.color, &_currentHsvColor);
    self.brightnessSlider.color = colorMapView.color;
    self.colorInfoView.color = self.color;
    [self sendActions];
}

- (void)sendActions {
    timeval now, diff;
    gettimeofday(&now, NULL);
    timersub(&now, &_lastDrawTime, &diff);
    if (timercmp(&diff, &_waitTimeDuration, >)) {
        _lastDrawTime = now;
        [self sendActionsForControlEvents:UIControlEventEditingChanged];
    }
}

- (BOOL)usingAutoLayout {
    return self.constraints && self.constraints.count > 0;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.usingAutoLayout) {
        return;
    }

    CGFloat headerHeight = (20 + 44) * 1.625;
    self.colorInfoView.frame = CGRectMake(8, (headerHeight - 84) / 2.0f, 66, 84);

    CGFloat brightnessPickerTop = (headerHeight - 84.0f) / 2.0f;

    CGRect brightnessPickerFrame = CGRectMake(
            CGRectGetMaxX(self.colorInfoView.frame) + CGRectGetMinX(self.colorInfoView.frame),
            brightnessPickerTop,
            CGRectGetWidth(self.frame) - CGRectGetMaxX(self.colorInfoView.frame) - CGRectGetMinX(self.colorInfoView.frame) * 2,
            84.0f);

    CGRect brightnessPickerTouchFrame = CGRectInset(brightnessPickerFrame, 20, 0);
    self.brightnessSlider.frame = brightnessPickerTouchFrame;

    self.colorMapView.frame = CGRectMake(
            0, headerHeight,
            CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) - headerHeight
    );
}

@end

