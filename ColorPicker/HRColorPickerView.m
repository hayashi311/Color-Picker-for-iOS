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

typedef struct timeval timeval;

@interface HRColorPickerView () {
    NSObject <HRColorPickerViewDelegate> *__weak delegate;

    // 色情報
    HRHSVColor _currentHsvColor;

    // カラーマップ上のカーソルの位置
    CGPoint _colorCursorPosition;

    // パーツの配置
    CGRect _brightnessPickerFrame;
    CGRect _brightnessPickerTouchFrame;
    CGRect _colorMapFrame;
    CGFloat _tileSize;

    // フレームレート
    timeval _lastDrawTime;
    timeval _waitTimeDuration;

    bool _delegateHasSELColorWasChanged;
}

@end

@implementation HRColorPickerView


+ (HRColorPickerStyle)defaultStyle {
    HRColorPickerStyle style;
    style.width = 320.0f;
    style.headerHeight = 198 - 44 - 61;
    style.colorMapTileSize = 16;
    style.colorMapSizeWidth = 20;
    style.colorMapSizeHeight = 20;
    style.brightnessLowerLimit = 0.4f;
    style.saturationUpperLimit = 0.95f;
    return style;
}

+ (HRColorPickerStyle)fitScreenStyle {
    CGSize defaultSize = [[UIScreen mainScreen] applicationFrame].size;
    defaultSize.height -= 44.f;

    HRColorPickerStyle style = [HRColorPickerView defaultStyle];
    style.colorMapSizeHeight = (int) ((defaultSize.height - style.headerHeight) / style.colorMapTileSize);

    CGFloat colorMapMargin = (style.width - (style.colorMapSizeWidth * style.colorMapTileSize)) / 2.f;
    style.headerHeight = defaultSize.height - (style.colorMapSizeHeight * style.colorMapTileSize) - colorMapMargin;

    return style;
}

+ (HRColorPickerStyle)fullColorStyle {
    HRColorPickerStyle style = [HRColorPickerView defaultStyle];
    style.brightnessLowerLimit = 0.0f;
    style.saturationUpperLimit = 1.0f;
    return style;
}

+ (HRColorPickerStyle)fitScreenFullColorStyle {
    HRColorPickerStyle style = [HRColorPickerView fitScreenStyle];
    style.brightnessLowerLimit = 0.0f;
    style.saturationUpperLimit = 1.0f;
    return style;
}

+ (CGSize)sizeWithStyle:(HRColorPickerStyle)style {
    CGSize colorMapSize = CGSizeMake(style.colorMapTileSize * style.colorMapSizeWidth, style.colorMapTileSize * style.colorMapSizeHeight);
    CGFloat colorMapMargin = (style.width - colorMapSize.width) / 2.0f;
    return CGSizeMake(style.width, style.headerHeight + colorMapSize.height + colorMapMargin);
}

- (id)initWithStyle:(HRColorPickerStyle)style defultUIColor:(UIColor *)defaultUIColor {
    CGSize size = [HRColorPickerView sizeWithStyle:style];
    CGRect frame = CGRectMake(0.0f, 0.0f, size.width, size.height);

    self = [super initWithFrame:frame];
    if (self) {
        // RGBのデフォルトカラーをHSVに変換
        HSVColorFromUIColor(defaultUIColor, &_currentHsvColor);

        // UIの配置
        CGSize colorMapSize = CGSizeMake(style.colorMapTileSize * style.colorMapSizeWidth, style.colorMapTileSize * style.colorMapSizeHeight);
        CGFloat colorMapSpace = (style.width - colorMapSize.width) / 2.0f;

        self.colorInfoView = [HRColorInfoView colorInfoViewWithFrame:CGRectMake(8, (style.headerHeight - 84) / 2.0f, 66, 84)];

        self.colorInfoView.color = defaultUIColor;
        [self addSubview:self.colorInfoView];

        CGFloat brightnessPickerTop = (style.headerHeight - 84.0f) / 2.0f;
        _brightnessPickerFrame = CGRectMake(
                CGRectGetMaxX(self.colorInfoView.frame) + CGRectGetMinX(self.colorInfoView.frame),
                brightnessPickerTop,
                style.width - CGRectGetMaxX(self.colorInfoView.frame) - CGRectGetMinX(self.colorInfoView.frame) * 2,
                84.0f);
        _brightnessPickerTouchFrame = CGRectMake(_brightnessPickerFrame.origin.x - 20.0f,
                brightnessPickerTop,
                _brightnessPickerFrame.size.width + 40.0f,
                _brightnessPickerFrame.size.height);

        self.brightnessSlider = [HRBrightnessSlider brightnessSliderWithFrame:_brightnessPickerTouchFrame];
        self.brightnessSlider.color = defaultUIColor;
        self.brightnessSlider.brightnessLowerLimit = style.brightnessLowerLimit;
        [self.brightnessSlider addTarget:self
                                  action:@selector(brightnessChanged:)
                        forControlEvents:UIControlEventEditingChanged];

        [self addSubview:self.brightnessSlider];

        _colorMapFrame = CGRectMake(colorMapSpace, style.headerHeight, colorMapSize.width, colorMapSize.height);

        HRColorMapView *colorMapView;
        colorMapView = [HRColorMapView colorMapWithFrame:_colorMapFrame
                                    saturationUpperLimit:style.saturationUpperLimit];

        colorMapView.brightness = _currentHsvColor.v;
        colorMapView.tileSize = style.colorMapTileSize;

        colorMapView.color = defaultUIColor;
        [colorMapView addTarget:self
                         action:@selector(colorMapColorChanged:)
               forControlEvents:UIControlEventEditingChanged];

        self.colorMapView = colorMapView;

        [self addSubview:self.colorMapView];
        _tileSize = style.colorMapTileSize;

        // 諸々初期化
        [self setBackgroundColor:[UIColor colorWithWhite:0.99f alpha:1.0f]];
        [self setMultipleTouchEnabled:FALSE];

        // フレームレートの調整
        gettimeofday(&_lastDrawTime, NULL);

        _waitTimeDuration.tv_sec = (__darwin_time_t) 0.0;
        _waitTimeDuration.tv_usec = (__darwin_suseconds_t) (1000000.0 / 15.0);

        _delegateHasSELColorWasChanged = FALSE;
    }
    return self;
}

- (UIColor *)color {
    return [UIColor colorWithHue:_currentHsvColor.h
                      saturation:_currentHsvColor.s
                      brightness:_currentHsvColor.v
                           alpha:1];
}

- (void)brightnessChanged:(UIControl <HRBrightnessSlider> *)slider {
    _currentHsvColor.v = slider.brightness;
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
        if (_delegateHasSELColorWasChanged) {
            [delegate colorWasChanged:self];
        }
        [self sendActionsForControlEvents:UIControlEventEditingChanged];
    }
}

@end
