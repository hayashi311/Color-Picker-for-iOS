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
#import "HRColorUtil.h"

@class HRColorPickerView;

__attribute__((deprecated))
@protocol HRColorPickerViewDelegate
- (void)colorWasChanged:(HRColorPickerView *)color_picker_view;
@end

struct HRColorPickerStyle {
    float width; // viewの横幅。デフォルトは320.0f;
    float headerHeight; // 明度スライダーを含むヘッダ部分の高さ(デフォルトは106.0f。70.0fくらいが下限になると思います)
    float colorMapTileSize; // カラーマップの中のタイルのサイズ。デフォルトは15.0f;
    int colorMapSizeWidth; // カラーマップの中にいくつのタイルが並ぶか (not view.width)。デフォルトは20;
    int colorMapSizeHeight; // 同じく縦にいくつ並ぶか。デフォルトは20;
    float brightnessLowerLimit; // 明度の下限
    float saturationUpperLimit; // 彩度の上限
};

typedef struct HRColorPickerStyle HRColorPickerStyle;

@class HRBrightnessCursor;
@class HRColorCursor;

@interface HRColorPickerView : UIControl

// スタイルを取得
+ (HRColorPickerStyle)defaultStyle;
+ (HRColorPickerStyle)fullColorStyle;

+ (HRColorPickerStyle)fitScreenStyle; // iPhone5以降の縦長スクリーンに対応しています。
+ (HRColorPickerStyle)fitScreenFullColorStyle;

// スタイルからviewのサイズを取得
+ (CGSize)sizeWithStyle:(HRColorPickerStyle)style;

- (id)initWithStyle:(HRColorPickerStyle)style defultUIColor:(UIColor *)defaultUIColor;

@property (nonatomic, readonly) UIColor *color;

#pragma - Deprecated
/////////////////////////////////////////////////////////////////////////////
//
// Deprecated : Old API.
//
/////////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame defaultColor:(const HRRGBColor)defaultColor __attribute__((deprecated)); // frameが反映されません

// スタイルを指定してデフォルトカラーで初期化
- (id)initWithStyle:(HRColorPickerStyle)style defaultColor:(const HRRGBColor)defaultColor __attribute__((deprecated));

- (HRRGBColor)RGBColor __attribute__((deprecated)); // colorを使ってください

- (void)BeforeDealloc __attribute__((deprecated)); // 呼び出す必要はありません。

@property (getter = BrightnessLowerLimit, setter = setBrightnessLowerLimit:) float BrightnessLowerLimit __attribute__((deprecated));
@property (getter = SaturationUpperLimit, setter = setSaturationUpperLimit:) float SaturationUpperLimit __attribute__((deprecated));
@property (nonatomic, weak) NSObject <HRColorPickerViewDelegate> *delegate __attribute__((deprecated));

@end
