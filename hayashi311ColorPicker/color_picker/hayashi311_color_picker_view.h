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
#import "hayashi311_color_util.h"

@interface Hayashi311ColorPickerView : UIControl{
    
 @private
    CADisplayLink* display_link_;
	bool animating_;
    
    // 入力関係
    bool is_tap_start_;
    bool is_tapped_;
	bool was_drag_start_;
    bool is_drag_start_;
	bool is_dragging_;
	bool is_drag_end_;
    
	CGPoint active_touch_position_;
	CGPoint touch_start_position_;
    
    // 色情報
    Hayashi311RGBColor default_rgb_color_;
    Hayashi311HSVColor current_hsv_color_;
    
    // カラーマップ上のカーソルの位置
    CGPoint color_cursor_position_;
    
    // パーツの配置
    CGRect current_color_frame_;
    CGRect brightness_picker_frame_;
    CGRect brightness_picker_shadow_frame_;
    CGRect color_map_frame_;
    CGRect color_map_side_frame_;
    float pixel_size_;
    float brightness_under_limit_;
    
    bool show_color_cursor_;
    
}

// デフォルトカラーで初期化
- (id)initWithFrame:(CGRect)frame andDefaultColor:(const Hayashi311RGBColor)default_color;

// 現在選択している色をRGBで返す
- (Hayashi311RGBColor)RGBColor;

/*
 * releaseを呼ぶ時にはちょっと注意が必要です。
 * 内部でLoopを呼んでいるのでこれを止めないとdeallocが呼ばれない。
 * releaseの前にBeforeDeallocを呼び出して下さい。
 */

- (void)BeforeDealloc;

@end
