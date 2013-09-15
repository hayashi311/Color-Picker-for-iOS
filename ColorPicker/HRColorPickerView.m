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
    float _tileSize;

    // フレームレート
    timeval _lastDrawTime;
    timeval _timeInterval15fps;

    bool _delegateHasSELColorWasChanged;

    HRColorInfoView *_colorInfoView;
    HRColorMapView *_colorMapView;
    HRBrightnessSlider *_brightnessSlider;
}

- (void)setNeedsDisplay15FPS;
@end

@implementation HRColorPickerView

@synthesize delegate;

+ (HRColorPickerStyle)defaultStyle {
    HRColorPickerStyle style;
    style.width = 320.0f;
    style.headerHeight = 106.0f;
    style.colorMapTileSize = 15.0f;
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

    float colorMapMargin = (style.width - (style.colorMapSizeWidth * style.colorMapTileSize)) / 2.f;
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
    float colorMapMargin = (style.width - colorMapSize.width) / 2.0f;
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
        float colorMapSpace = (style.width - colorMapSize.width) / 2.0f;
        float headerPartsOriginY = (style.headerHeight - 40.0f) / 2.0f;
        _brightnessPickerFrame = CGRectMake(120.0f, headerPartsOriginY, style.width - 120.0f - 10.0f, 40.0f);

        _colorInfoView = [[HRColorInfoView alloc] initWithFrame:CGRectMake(10, headerPartsOriginY - 5, 100, 60)];
        _colorInfoView.color = defaultUIColor;
        [self addSubview:_colorInfoView];

        _brightnessPickerTouchFrame = CGRectMake(_brightnessPickerFrame.origin.x - 20.0f,
                headerPartsOriginY,
                _brightnessPickerFrame.size.width + 40.0f,
                _brightnessPickerFrame.size.height);

        _brightnessSlider = [HRBrightnessSlider brightnessSliderWithFrame:_brightnessPickerTouchFrame];
        _brightnessSlider.color = defaultUIColor;
        _brightnessSlider.brightnessLowerLimit = style.brightnessLowerLimit;
        [_brightnessSlider addTarget:self
                              action:@selector(brightnessChanged:)
                    forControlEvents:UIControlEventEditingChanged];

        [self addSubview:_brightnessSlider];

        _colorMapFrame = CGRectMake(colorMapSpace + 1.0f, style.headerHeight, colorMapSize.width, colorMapSize.height);

        _colorMapView = [[HRColorMapView alloc] initWithFrame:_colorMapFrame];
        _colorMapView.brightness = _currentHsvColor.v;
        _colorMapView.color = defaultUIColor;
        [_colorMapView addTarget:self
                          action:@selector(colorMapColorChanged:)
                forControlEvents:UIControlEventEditingChanged];

        [self addSubview:_colorMapView];

        _tileSize = style.colorMapTileSize;


        // 諸々初期化
        [self setBackgroundColor:[UIColor colorWithWhite:0.99f alpha:1.0f]];
        [self setMultipleTouchEnabled:FALSE];

        // フレームレートの調整
        gettimeofday(&_lastDrawTime, NULL);

        _timeInterval15fps.tv_sec = (__darwin_time_t) 0.0;
        _timeInterval15fps.tv_usec = (__darwin_suseconds_t) (1000000.0 / 15.0);

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
    _colorMapView.brightness = _currentHsvColor.v;
    _colorMapView.color = self.color;
    _colorInfoView.color = self.color;
    [self sendCallBack];
}

- (void)colorMapColorChanged:(UIControl <HRColorMapView> *)colorMapView {
    HSVColorFromUIColor(colorMapView.color, &_currentHsvColor);
    _brightnessSlider.color = colorMapView.color;
    _colorInfoView.color = self.color;
    [self sendCallBack];
}

- (void)sendCallBack {
    timeval now, diff;
    gettimeofday(&now, NULL);
    timersub(&now, &_lastDrawTime, &diff);
    if (timercmp(&diff, &_timeInterval15fps, >)) {
        _lastDrawTime = now;
        if (_delegateHasSELColorWasChanged) {
            [delegate colorWasChanged:self];
        }
        [self sendActionsForControlEvents:UIControlEventEditingChanged];
    } else {
        return;
    }
}



#pragma - deprecated
/////////////////////////////////////////////////////////////////////////////
//
// deprecated
//
/////////////////////////////////////////////////////////////////////////////


- (id)initWithFrame:(CGRect)frame defaultColor:(const HRRGBColor)defaultColor {
    return [self initWithStyle:[HRColorPickerView defaultStyle] defaultColor:defaultColor];
}

- (id)initWithStyle:(HRColorPickerStyle)style defaultColor:(const HRRGBColor)defaultColor {
    UIColor *uiColor = [UIColor colorWithRed:defaultColor.r green:defaultColor.g blue:defaultColor.b alpha:1];

    return [self initWithStyle:style defultUIColor:uiColor];
}

- (HRRGBColor)RGBColor {
    HRRGBColor rgbColor;
    RGBColorFromHSVColor(&_currentHsvColor, &rgbColor);
    return rgbColor;
}


- (void)BeforeDealloc {
    // 何も実行しません
    NSAssert(NO, @"Deprecated");
}

- (float)BrightnessLowerLimit {
    if ([_brightnessSlider respondsToSelector:@selector(brightnessLowerLimit)]) {
        return [_brightnessSlider brightnessLowerLimit];
    }
    return 0.0;
}

- (void)setBrightnessLowerLimit:(float)brightnessUnderLimit {
    if ([_brightnessSlider respondsToSelector:@selector(setBrightnessLowerLimit:)]) {
        [_brightnessSlider setBrightnessLowerLimit:brightnessUnderLimit];
    }
}

- (float)SaturationUpperLimit {
    if ([_colorMapView respondsToSelector:@selector(saturationUpperLimit)]) {
        return _colorMapView.saturationUpperLimit;
    }
    return 1.0;
}

- (void)setSaturationUpperLimit:(float)saturationUpperLimit {
    if ([_colorMapView respondsToSelector:@selector(setSaturationUpperLimit:)]) {
        [_colorMapView setSaturationUpperLimit:saturationUpperLimit];
    }
}

- (void)setDelegate:(NSObject <HRColorPickerViewDelegate> *)picker_delegate {
    delegate = picker_delegate;
    _delegateHasSELColorWasChanged = FALSE;
    // 微妙に重いのでメソッドを持っているかどうかの判定をキャッシュ
    if ([delegate respondsToSelector:@selector(colorWasChanged:)]) {
        _delegateHasSELColorWasChanged = TRUE;
    }
}

@end
