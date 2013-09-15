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
#import "HRCgUtil.h"
#import "HRBrightnessCursor.h"
#import "HRColorCursor.h"
#import "HRColorMapView.h"
#import "HRBrightnessSlider.h"
#import "HRColorUtil.h"

typedef struct timeval timeval;

@interface HRColorPickerView () {
    NSObject <HRColorPickerViewDelegate> *__weak delegate;

    // 色情報
    HRHSVColor _currentHsvColor;

    // カラーマップ上のカーソルの位置
    CGPoint _colorCursorPosition;

    // パーツの配置
    CGRect _currentColorFrame;
    CGRect _brightnessPickerFrame;
    CGRect _brightnessPickerTouchFrame;
    CGRect _colorMapFrame;
    float _tileSize;
    float _brightnessLowerLimit;
    float _saturationUpperLimit;

    HRColorCursor *_colorCursor;

    // フレームレート
    timeval _lastDrawTime;
    timeval _timeInterval15fps;

    bool _delegateHasSELColorWasChanged;

    HRColorMapView *_colorMapView;
    HRBrightnessSlider *_brightnessSlider;
}

- (void)updateBrightnessCursor;
- (void)updateColorCursor;
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
        _currentColorFrame = CGRectMake(10.0f, headerPartsOriginY, 40.0f, 40.0f);
        _brightnessPickerFrame = CGRectMake(120.0f, headerPartsOriginY, style.width - 120.0f - 10.0f, 40.0f);
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
        [_colorMapView addTarget:self
                          action:@selector(colorMapColorChanged:)
                forControlEvents:UIControlEventEditingChanged];

        [self addSubview:_colorMapView];

        _tileSize = style.colorMapTileSize;
        _brightnessLowerLimit = style.brightnessLowerLimit;
        _saturationUpperLimit = style.saturationUpperLimit;



        // タイルの中心にくるようにずらす
        _colorCursor = [[HRColorCursor alloc] initWithPoint:CGPointMake(_colorMapFrame.origin.x - ([HRColorCursor cursorSize].width - _tileSize) / 2.0f - [HRColorCursor shadowSize] / 2.0,
                _colorMapFrame.origin.y - ([HRColorCursor cursorSize].height - _tileSize) / 2.0f - [HRColorCursor shadowSize] / 2.0)];
        [self addSubview:_colorCursor];

        // 諸々初期化
        [self setBackgroundColor:[UIColor colorWithWhite:0.99f alpha:1.0f]];
        [self setMultipleTouchEnabled:FALSE];

        [self updateBrightnessCursor];
        [self updateColorCursor];

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


- (void)brightnessChanged:(UIControl<HRBrightnessSlider> *)slider {
    _currentHsvColor.v = slider.brightness;
    _colorMapView.brightness = _currentHsvColor.v;
    [self updateColorCursor];
    [self setNeedsDisplay15FPS];
}

- (void)colorMapColorChanged:(UIControl<HRColorMapView> *)colorMapView {
    HSVColorFromUIColor(colorMapView.color, &_currentHsvColor);
    _brightnessSlider.color = colorMapView.color;
    [self updateColorCursor];
    [self setNeedsDisplay15FPS];
}

- (void)updateBrightnessCursor {
//    // 明度スライダーの移動
//    float brightnessCursorX = (1.0f - (_currentHsvColor.v - _brightnessLowerLimit) / (1.0f - _brightnessLowerLimit)) * _brightnessPickerFrame.size.width + _brightnessPickerFrame.origin.x;
//    _brightnessCursor.transform = CGAffineTransformMakeTranslation(brightnessCursorX - _brightnessPickerFrame.origin.x, 0.0f);

}

- (void)updateColorCursor {
    // カラーマップのカーソルの移動＆色の更新

    int pixelCountX = (int) (_colorMapFrame.size.width / _tileSize);
    int pixelCountY = (int) (_colorMapFrame.size.height / _tileSize);
    CGPoint newPosition;
    newPosition.x = _currentHsvColor.h * (float) pixelCountX * _tileSize + _tileSize / 2.0f;
    newPosition.y = (1.0f - _currentHsvColor.s) * (1.0f / _saturationUpperLimit) * (float) (pixelCountY - 1) * _tileSize + _tileSize / 2.0f;
    _colorCursorPosition.x = (int) (newPosition.x / _tileSize) * _tileSize;
    _colorCursorPosition.y = (int) (newPosition.y / _tileSize) * _tileSize;

    _colorCursor.cursorColor = self.color;
    _colorCursor.transform = CGAffineTransformMakeTranslation(_colorCursorPosition.x, _colorCursorPosition.y);

}

- (void)setNeedsDisplay15FPS {
    // 描画を20FPSに制限します
    timeval now, diff;
    gettimeofday(&now, NULL);
    timersub(&now, &_lastDrawTime, &diff);
    if (timercmp(&diff, &_timeInterval15fps, >)) {
        _lastDrawTime = now;
        [self setNeedsDisplay];
        if (_delegateHasSELColorWasChanged) {
            [delegate colorWasChanged:self];
        }
    } else {
        return;
    }
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();

    /////////////////////////////////////////////////////////////////////////////
    //
    // カレントのカラー
    //
    /////////////////////////////////////////////////////////////////////////////

    CGContextSaveGState(context);
    HRDrawSquareColorBatch(context, CGPointMake(CGRectGetMidX(_currentColorFrame), CGRectGetMidY(_currentColorFrame)), self.color, _currentColorFrame.size.width / 2.0f);
    CGContextRestoreGState(context);

    /////////////////////////////////////////////////////////////////////////////
    //
    // RGBのパーセント表示
    //
    /////////////////////////////////////////////////////////////////////////////

    float red, green, blue, alpha;
    [self.color getRed:&red green:&green blue:&blue alpha:&alpha];

    [[UIColor darkGrayColor] set];

    float textHeight = 20.0f;
    float textCenter = CGRectGetMidY(_currentColorFrame) - 5.0f;
    [[NSString stringWithFormat:@"R:%3d%%", (int) (red * 100)] drawAtPoint:CGPointMake(_currentColorFrame.origin.x + _currentColorFrame.size.width + 10.0f, textCenter - textHeight) withFont:[UIFont boldSystemFontOfSize:12.0f]];
    [[NSString stringWithFormat:@"G:%3d%%", (int) (green * 100)] drawAtPoint:CGPointMake(_currentColorFrame.origin.x + _currentColorFrame.size.width + 10.0f, textCenter) withFont:[UIFont boldSystemFontOfSize:12.0f]];
    [[NSString stringWithFormat:@"B:%3d%%", (int) (blue * 100)] drawAtPoint:CGPointMake(_currentColorFrame.origin.x + _currentColorFrame.size.width + 10.0f, textCenter + textHeight) withFont:[UIFont boldSystemFontOfSize:12.0f]];
}

- (void)setDelegate:(NSObject <HRColorPickerViewDelegate> *)picker_delegate {
    delegate = picker_delegate;
    _delegateHasSELColorWasChanged = FALSE;
    // 微妙に重いのでメソッドを持っているかどうかの判定をキャッシュ
    if ([delegate respondsToSelector:@selector(colorWasChanged:)]) {
        _delegateHasSELColorWasChanged = TRUE;
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
    return _brightnessLowerLimit;
}

- (void)setBrightnessLowerLimit:(float)brightnessUnderLimit {
    _brightnessLowerLimit = brightnessUnderLimit;
    [self updateBrightnessCursor];
}

- (float)SaturationUpperLimit {
    return _brightnessLowerLimit;
}

- (void)setSaturationUpperLimit:(float)saturationUpperLimit {
    _saturationUpperLimit = saturationUpperLimit;
    [self updateColorCursor];
}

@end
