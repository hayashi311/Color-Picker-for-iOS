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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <sys/time.h>
#import "HRColorUtil.h"

typedef struct timeval timeval;

@class HRBrightnessCursor;
@class HRColorCursor;

@interface HRColorPickerView : UIControl{
    
 @private
    bool _animating;
    
    // 入力関係
    bool _isTapStart;
    bool _isTapped;
	bool _wasDragStart;
    bool _isDragStart;
	bool _isDragging;
	bool _isDragEnd;
    
	CGPoint _activeTouchPosition;
	CGPoint _touchStartPosition;
    
    // 色情報
    HRRGBColor _defaultRgbColor;
    HRHSVColor _currentHsvColor;
    
    // カラーマップ上のカーソルの位置
    CGPoint _colorCursorPosition;
    
    // パーツの配置
    CGRect _currentColorFrame;
    CGRect _brightnessPickerFrame;
    CGRect _brightnessPickerTouchFrame;
    CGRect _brightnessPickerShadowFrame;
    CGRect _colorMapFrame;
    CGRect _colorMapSideFrame;
    float _pixelSize;
    float _brightnessLowerLimit;
    float _saturationUpperLimit;
    
    HRBrightnessCursor* _brightnessCursor;
    HRColorCursor* _colorCursor;
    
    // キャッシュ
    CGImageRef _brightnessPickerShadowImage;
    
    // フレームレート
    timeval _lastDrawTime;
    timeval _timeInterval15fps;
}

// デフォルトカラーで初期化
- (id)initWithFrame:(CGRect)frame defaultColor:(const HRRGBColor)defaultColor;

// 現在選択している色をRGBで返す
- (HRRGBColor)RGBColor;

// 後方互換性のため。呼び出す必要はありません。
- (void)BeforeDealloc; 

@property (getter = BrightnessLowerLimit, setter = setBrightnessLowerLimit:) float BrightnessLowerLimit;
@property (getter = SaturationUpperLimit, setter = setSaturationUpperLimit:) float SaturationUpperLimit;

@end
