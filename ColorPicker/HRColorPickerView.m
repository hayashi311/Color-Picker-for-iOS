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
#import "HRCgUtil.h"
#import "HRBrightnessCursor.h"
#import "HRColorCursor.h"

@interface HRColorPickerView()
- (void)createCacheImage;
- (void)update;
- (void)updateBrightnessCursor;
- (void)updateColorCursor;
- (void)clearInput;
- (void)setCurrentTouchPointInView:(UITouch *)touch;
- (void)setNeedsDisplay15FPS;
@end

@implementation HRColorPickerView

- (id)initWithFrame:(CGRect)frame defaultColor:(const HRRGBColor)defaultColor
{
    self = [super initWithFrame:frame];
    if (self) {
        _defaultRgbColor = defaultColor;
        _animating = FALSE;
        
        // RGBのデフォルトカラーをHSVに変換
        HSVColorFromRGBColor(&_defaultRgbColor, &_currentHsvColor);
        
        // パーツの配置
        _currentColorFrame = CGRectMake(10.0f, 30.0f, 40.0f, 40.0f);
        _brightnessPickerFrame = CGRectMake(120.0f, 30.0f, 190.0f, 40.0f);
        _brightnessPickerTouchFrame = CGRectMake(100.0f, 30.0f, 230.0f, 40.0f);
        _brightnessPickerShadowFrame = CGRectMake(120.0f-5.0f, 30.0f-5.0f, 190.0f+10.0f, 40.0f+10.0f);
        _colorMapFrame = CGRectMake(11.0f, 106.0f, 300.0f, 300.0f);
        _colorMapSideFrame = CGRectMake(10.0f, 105.0f, 300.0f, 300.0f);
        _pixelSize = 15.0f;
        _brightnessLowerLimit = 0.4f;
        _saturationUpperLimit = 0.95f;
        
        _brightnessCursor = [[HRBrightnessCursor alloc] initWithPoint:CGPointMake(_brightnessPickerFrame.origin.x, _brightnessPickerFrame.origin.y + _brightnessPickerFrame.size.height/2.0f)];
        
        // 色の隙間分ずらす
        _colorCursor = [[HRColorCursor alloc] initWithPoint:CGPointMake(_colorMapFrame.origin.x-1.0f, _colorMapFrame.origin.y-1.0f)];
        [self addSubview:_brightnessCursor];
        [self addSubview:_colorCursor];
        
        // 入力の初期化
        _isTapStart = FALSE;
        _isTapped = FALSE;
        _wasDragStart = FALSE;
        _isDragStart = FALSE;
        _isDragging = FALSE;
        _isDragEnd = FALSE;
        
        // 諸々初期化
        [self setBackgroundColor:[UIColor colorWithWhite:0.99f alpha:1.0f]];
        [self setMultipleTouchEnabled:FALSE];
        
        _brightnessPickerShadowImage = nil;
        [self createCacheImage];
        
        [self updateBrightnessCursor];
        [self updateColorCursor];
        
        // フレームレートの調整
        gettimeofday(&_lastDrawTime, NULL);
        
        _timeInterval15fps.tv_sec = 0.0;
        _timeInterval15fps.tv_usec = 1000000.0/15.0;
    }
    return self;
}


- (HRRGBColor)RGBColor{
    HRRGBColor rgbColor;
    RGBColorFromHSVColor(&_currentHsvColor, &rgbColor);
    return rgbColor;
}

- (float)BrightnessLowerLimit{
    return _brightnessLowerLimit;
}

- (void)setBrightnessLowerLimit:(float)brightnessUnderLimit{
    _brightnessLowerLimit = brightnessUnderLimit;
    [self updateBrightnessCursor];
}

- (float)SaturationUpperLimit{
    return _brightnessLowerLimit;
}

- (void)setSaturationUpperLimit:(float)saturationUpperLimit{
    _saturationUpperLimit = saturationUpperLimit;
    [self updateColorCursor];
}

/////////////////////////////////////////////////////////////////////////////
//
// プライベート
//
/////////////////////////////////////////////////////////////////////////////

- (void)createCacheImage{
    // 影のコストは高いので、事前に画像に書き出しておきます
    
    if (_brightnessPickerShadowImage != nil) {
        return;
    }
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(_brightnessPickerShadowFrame.size.width,
                                                      _brightnessPickerShadowFrame.size.height),
                                           FALSE,
                                           [[UIScreen mainScreen] scale]);
    CGContextRef brightness_picker_shadow_context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(brightness_picker_shadow_context, 0, _brightnessPickerShadowFrame.size.height);
    CGContextScaleCTM(brightness_picker_shadow_context, 1.0, -1.0);
    
    HRSetRoundedRectanglePath(brightness_picker_shadow_context, 
                                      CGRectMake(0.0f, 0.0f,
                                                 _brightnessPickerShadowFrame.size.width,
                                                 _brightnessPickerShadowFrame.size.height), 5.0f);
    CGContextSetLineWidth(brightness_picker_shadow_context, 10.0f);
    CGContextSetShadow(brightness_picker_shadow_context, CGSizeMake(0.0f, 0.0f), 10.0f);
    CGContextDrawPath(brightness_picker_shadow_context, kCGPathStroke);
    
    _brightnessPickerShadowImage = CGBitmapContextCreateImage(brightness_picker_shadow_context);
    UIGraphicsEndImageContext();
}

- (void)update{
    // タッチのイベントの度、更新されます
    if (_isDragging || _isDragStart || _isDragEnd || _isTapped) {
        CGPoint touchPosition = _activeTouchPosition;
        if (CGRectContainsPoint(_colorMapFrame,touchPosition)) {
            
            int pixelCount = _colorMapFrame.size.height/_pixelSize;
            HRHSVColor newHsv = _currentHsvColor;
            
            CGPoint newPosition = CGPointMake(touchPosition.x - _colorMapFrame.origin.x, touchPosition.y - _colorMapFrame.origin.y);
            
            float pixelX = (int)((newPosition.x)/_pixelSize)/(float)pixelCount; // X(色相)は1.0f=0.0fなので0.0f~0.95fの値をとるように
            float pixelY = (int)((newPosition.y)/_pixelSize)/(float)(pixelCount-1); // Y(彩度)は0.0f~1.0f
            
            HSVColorAt(&newHsv, pixelX, pixelY, _saturationUpperLimit, _currentHsvColor.v);
            
            if (!HRHSVColorEqualToColor(&newHsv,&_currentHsvColor)) {
                _currentHsvColor = newHsv;
                _colorCursorPosition.x = (int)(newPosition.x/_pixelSize) * _pixelSize  + _colorMapFrame.origin.x + _pixelSize/2.0f;
                _colorCursorPosition.y = (int)(newPosition.y/_pixelSize) * _pixelSize + _colorMapFrame.origin.y + _pixelSize/2.0f;
                
                [self setNeedsDisplay15FPS];
            }
            [self updateColorCursor];
        }else if(CGRectContainsPoint(_brightnessPickerTouchFrame,touchPosition)){
            if (CGRectContainsPoint(_brightnessPickerFrame,touchPosition)) {
                // 明度のスライダーの内側
                _currentHsvColor.v = (1.0f - ((touchPosition.x - _brightnessPickerFrame.origin.x )/ _brightnessPickerFrame.size.width )) * (1.0f - _brightnessLowerLimit) + _brightnessLowerLimit;
            }else{
                // 左右をタッチした場合
                if (touchPosition.x < _brightnessPickerFrame.origin.x) {
                    _currentHsvColor.v = 1.0f;
                }else if((_brightnessPickerFrame.origin.x + _brightnessPickerFrame.size.width) < touchPosition.x){
                    _currentHsvColor.v = _brightnessLowerLimit;
                }
            }
            [self updateBrightnessCursor];
            [self updateColorCursor];
            [self setNeedsDisplay15FPS];
        }
    }
    [self clearInput];
}

- (void)updateBrightnessCursor{
    // 明度スライダーの移動
    float brightnessCursorX = (1.0f - (_currentHsvColor.v - _brightnessLowerLimit)/(1.0f - _brightnessLowerLimit)) * _brightnessPickerFrame.size.width + _brightnessPickerFrame.origin.x;
    _brightnessCursor.transform = CGAffineTransformMakeTranslation(brightnessCursorX - _brightnessPickerFrame.origin.x, 0.0f);
    
}

- (void)updateColorCursor{
    // カラーマップのカーソルの移動＆色の更新
    int pixelCount = _colorMapFrame.size.height/_pixelSize;
    CGPoint newPosition;
    newPosition.x = _currentHsvColor.h * (float)pixelCount * _pixelSize + _colorMapFrame.origin.x + _pixelSize/2.0f;
    newPosition.y = (1.0f - _currentHsvColor.s) * (1.0f/_saturationUpperLimit) * (float)(pixelCount - 1) * _pixelSize + _colorMapFrame.origin.y + _pixelSize/2.0f;
    _colorCursorPosition.x = (int)(newPosition.x/_pixelSize) * _pixelSize  + _colorMapFrame.origin.x - _pixelSize/2.0f;
    _colorCursorPosition.y = (int)(newPosition.y/_pixelSize) * _pixelSize + _pixelSize/2.0f;
    
    HRRGBColor currentRgbColor = [self RGBColor];
    [_colorCursor setColorRed:currentRgbColor.r andGreen:currentRgbColor.g andBlue:currentRgbColor.b];
    _colorCursor.transform = CGAffineTransformMakeTranslation(_colorCursorPosition.x - _colorMapFrame.origin.x,
                                                              _colorCursorPosition.y - _colorMapFrame.origin.y);
}

- (void)setNeedsDisplay15FPS{
    // 描画を20FPSに制限します
    timeval now,diff;
    gettimeofday(&now, NULL);
    timersub(&now, &_lastDrawTime, &diff);
    if (timercmp(&diff, &_timeInterval15fps, >)) {
        _lastDrawTime = now;
        [self setNeedsDisplay];
    }else{
        return;
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    HRRGBColor currentRgbColor = [self RGBColor];
    
    /////////////////////////////////////////////////////////////////////////////
    //
    // 明度
    //
    /////////////////////////////////////////////////////////////////////////////
    
    CGContextSaveGState(context);
    
    HRSetRoundedRectanglePath(context, _brightnessPickerFrame, 5.0f);
    CGContextClip(context);
    
    CGGradientRef gradient;
    CGColorSpaceRef colorSpace;
    size_t numLocations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    HRRGBColor darkColor;
    HRRGBColor lightColor;
    UIColor* darkColorFromHsv = [UIColor colorWithHue:_currentHsvColor.h saturation:_currentHsvColor.s brightness:_brightnessLowerLimit alpha:1.0f];
    UIColor* lightColorFromHsv = [UIColor colorWithHue:_currentHsvColor.h saturation:_currentHsvColor.s brightness:1.0f alpha:1.0f];
    
    RGBColorFromUIColor(darkColorFromHsv, &darkColor);
    RGBColorFromUIColor(lightColorFromHsv, &lightColor);
    
    CGFloat gradientColor[] = {
        darkColor.r,darkColor.g,darkColor.b,1.0f,
        lightColor.r,lightColor.g,lightColor.b,1.0f,
    };
    
    gradient = CGGradientCreateWithColorComponents(colorSpace, gradientColor,
                                                   locations, numLocations);
    
    CGPoint startPoint = CGPointMake(_brightnessPickerFrame.origin.x + _brightnessPickerFrame.size.width, _brightnessPickerFrame.origin.y);
    CGPoint endPoint = CGPointMake(_brightnessPickerFrame.origin.x, _brightnessPickerFrame.origin.y);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    // GradientとColorSpaceを開放する
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    
    // 明度の内側の影 (キャッシュした画像を表示するだけ)
    CGContextDrawImage(context, _brightnessPickerShadowFrame, _brightnessPickerShadowImage);
    
    CGContextRestoreGState(context);
    
    
    /////////////////////////////////////////////////////////////////////////////
    //
    // カラーマップ
    //
    /////////////////////////////////////////////////////////////////////////////
    
    CGContextSaveGState(context);
    
    [[UIColor colorWithWhite:0.9f alpha:1.0f] set];
    CGContextAddRect(context, _colorMapSideFrame);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    float height;
    int pixelCount = _colorMapFrame.size.height/_pixelSize;
    
    HRHSVColor pixelHsv;
    HRRGBColor pixelRgb;
    for (int j = 0; j < pixelCount; ++j) {
        height =  _pixelSize * j + _colorMapFrame.origin.y;
        float pixelY = (float)j/(pixelCount-1); // Y(彩度)は0.0f~1.0f
        for (int i = 0; i < pixelCount; ++i) {
            float pixelX = (float)i/pixelCount; // X(色相)は1.0f=0.0fなので0.0f~0.95fの値をとるように
            HSVColorAt(&pixelHsv, pixelX, pixelY, _saturationUpperLimit, _currentHsvColor.v);
            RGBColorFromHSVColor(&pixelHsv, &pixelRgb);
            CGContextSetRGBFillColor(context, pixelRgb.r, pixelRgb.g, pixelRgb.b, 1.0f);
            CGContextFillRect(context, CGRectMake(_pixelSize*i+_colorMapFrame.origin.x, height, _pixelSize-2.0f, _pixelSize-2.0f));
        }
    }
    
    CGContextRestoreGState(context);
    
    /////////////////////////////////////////////////////////////////////////////
    //
    // カレントのカラー
    //
    /////////////////////////////////////////////////////////////////////////////
    
    CGContextSaveGState(context);
    HRDrawSquareColorBatch(context, CGPointMake(CGRectGetMidX(_currentColorFrame), CGRectGetMidY(_currentColorFrame)), &currentRgbColor, _currentColorFrame.size.width/2.0f);
    CGContextRestoreGState(context);
    
    /////////////////////////////////////////////////////////////////////////////
    //
    // RGBのパーセント表示
    //
    /////////////////////////////////////////////////////////////////////////////
    
    [[UIColor darkGrayColor] set];
    
    float textHeight = 20.0f;
    float textCenter = CGRectGetMidY(_currentColorFrame) - 5.0f;
    [[NSString stringWithFormat:@"R:%3d%%",(int)(currentRgbColor.r*100)] drawAtPoint:CGPointMake(_currentColorFrame.origin.x+_currentColorFrame.size.width+10.0f, textCenter - textHeight) withFont:[UIFont boldSystemFontOfSize:12.0f]];
    [[NSString stringWithFormat:@"G:%3d%%",(int)(currentRgbColor.g*100)] drawAtPoint:CGPointMake(_currentColorFrame.origin.x+_currentColorFrame.size.width+10.0f, textCenter) withFont:[UIFont boldSystemFontOfSize:12.0f]];
    [[NSString stringWithFormat:@"B:%3d%%",(int)(currentRgbColor.b*100)] drawAtPoint:CGPointMake(_currentColorFrame.origin.x+_currentColorFrame.size.width+10.0f, textCenter + textHeight) withFont:[UIFont boldSystemFontOfSize:12.0f]];
}


/////////////////////////////////////////////////////////////////////////////
//
// 入力
//
/////////////////////////////////////////////////////////////////////////////

- (void)clearInput{
    _isTapStart = FALSE;
    _isTapped = FALSE;
    _isDragStart = FALSE;
	_isDragEnd = FALSE;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if ([touches count] == 1) {
        UITouch* touch = [touches anyObject];
        [self setCurrentTouchPointInView:touch];
        _wasDragStart = TRUE;
        _isTapStart = TRUE;
        _touchStartPosition.x = _activeTouchPosition.x;
        _touchStartPosition.y = _activeTouchPosition.y;
        [self update];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	UITouch* touch = [touches anyObject];
    if ([touch tapCount] == 1) {
        _isDragging = TRUE;
        if (_wasDragStart) {
            _wasDragStart = FALSE;
            _isDragStart = TRUE;
        }
        [self setCurrentTouchPointInView:[touches anyObject]];
        [self update];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	UITouch* touch = [touches anyObject];
    
    if (_isDragging) {
        _isDragEnd = TRUE;
    }else{
        if ([touch tapCount] == 1) {
            _isTapped = TRUE;
        }
    }
    _isDragging = FALSE;
    [self setCurrentTouchPointInView:touch];
    [self update];
    [NSTimer scheduledTimerWithTimeInterval:1.0/20.0 target:self selector:@selector(setNeedsDisplay15FPS) userInfo:nil repeats:FALSE];
}

- (void)setCurrentTouchPointInView:(UITouch *)touch{
    CGPoint point;
	point = [touch locationInView:self];
    _activeTouchPosition.x = point.x;
    _activeTouchPosition.y = point.y;
}

- (void)BeforeDealloc{
    // 何も実行しません
}


- (void)dealloc{
    [_brightnessCursor release];
    [_colorCursor release];
    CGImageRelease(_brightnessPickerShadowImage);
    [super dealloc];
}

@end
