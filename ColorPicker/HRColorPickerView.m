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

@interface HRColorPickerView()
- (void)initColorCursor;
- (void)update;
- (void)clearInput;
- (void)setCurrentTouchPointInView:(UITouch *)touch;
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
        
        [self initColorCursor];
        
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
        
        _showColorCursor = TRUE;
        
    }
    return self;
}

- (float)BrightnessLowerLimit{
    return _brightnessLowerLimit;
}

- (void)setBrightnessLowerLimit:(float)brightnessUnderLimit{
    _brightnessLowerLimit = brightnessUnderLimit;
}

- (float)SaturationUpperLimit{
    return _brightnessLowerLimit;
}

- (void)setSaturationUpperLimit:(float)saturationUpperLimit{
    _saturationUpperLimit = saturationUpperLimit;
    [self initColorCursor];
}

- (void)initColorCursor{
    int pixelCount = _colorMapFrame.size.height/_pixelSize;
    CGPoint newPosition;
    newPosition.x = _currentHsvColor.h * (float)pixelCount * _pixelSize + _colorMapFrame.origin.x + _pixelSize/2.0f;
    newPosition.y = (1.0f - _currentHsvColor.s) * (1.0f/_saturationUpperLimit) * (float)(pixelCount - 1) * _pixelSize + _colorMapFrame.origin.y + _pixelSize/2.0f;
    _colorCursorPosition.x = (int)(newPosition.x/_pixelSize) * _pixelSize  + _colorMapFrame.origin.x - _pixelSize/2.0f;
    _colorCursorPosition.y = (int)(newPosition.y/_pixelSize) * _pixelSize + _pixelSize/2.0f;
}

- (HRRGBColor)RGBColor{
    HRRGBColor rgbColor;
    UIColor* colorFromHsv = [UIColor colorWithHue:_currentHsvColor.h saturation:_currentHsvColor.s brightness:_currentHsvColor.v alpha:1.0f];
    RGBColorFromUIColor(colorFromHsv,&rgbColor);
    return rgbColor;
}

- (void)update{
    if (!_showColorCursor) {
        _showColorCursor = TRUE;
        [self setNeedsDisplay];
    }
    
    if (_isDragging || _isDragStart || _isDragEnd || _isTapped) {
        CGPoint touchPosition = _activeTouchPosition;
        if (CGRectContainsPoint(_colorMapFrame,touchPosition)) {
            // カラーマップ
            
            // ドラッグ中は表示させない
            if (_isDragging && !_isDragEnd) {
                //_showColorCursor = FALSE;
            }
            
            int pixelCount = _colorMapFrame.size.height/_pixelSize;
            HRHSVColor newHsv = _currentHsvColor;
            
            CGPoint newPosition = CGPointMake(touchPosition.x - _colorMapFrame.origin.x, touchPosition.y - _colorMapFrame.origin.y);
            /*
            newHsv.h = (int)((newPosition.x)/_pixelSize) / (float)pixelCount;
            newHsv.s = 1.0f-(int)((newPosition.y)/_pixelSize) / (float)pixelCount;
            */
            
            float pixelX = (int)((newPosition.x)/_pixelSize)/(float)pixelCount; // X(色相)は1.0f=0.0fなので0.0f~0.95fの値をとるように
            float pixelY = (int)((newPosition.y)/_pixelSize)/(float)(pixelCount-1); // Y(彩度)は0.0f~1.0f
            
            HSVColorAt(&newHsv, pixelX, pixelY, _saturationUpperLimit, _currentHsvColor.v);
            
            if (!HRHSVColorEqualToColor(&newHsv,&_currentHsvColor)) {
                _currentHsvColor = newHsv;
                _colorCursorPosition.x = (int)(newPosition.x/_pixelSize) * _pixelSize  + _colorMapFrame.origin.x + _pixelSize/2.0f;
                _colorCursorPosition.y = (int)(newPosition.y/_pixelSize) * _pixelSize + _colorMapFrame.origin.y + _pixelSize/2.0f;
                
                [self setNeedsDisplay];
            }
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
            [self setNeedsDisplay];
        }
    }
    [self clearInput];
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
    
    // 明度の内側の影
    HRSetRoundedRectanglePath(context, _brightnessPickerShadowFrame, 5.0f);
    CGContextSetLineWidth(context, 10.0f);
    CGContextSetShadow(context, CGSizeMake(0.0f, 0.0f), 10.0f);
    CGContextDrawPath(context, kCGPathStroke);
    
    // 現在の明度を示す
    float pointerSize = 5.0f;
    float tappointX = (1.0f - (_currentHsvColor.v - _brightnessLowerLimit)/(1.0f - _brightnessLowerLimit)) * _brightnessPickerFrame.size.width + _brightnessPickerFrame.origin.x;
    
    CGRect rectEllipse = CGRectMake( tappointX - pointerSize,_brightnessPickerFrame.origin.y + _brightnessPickerFrame.size.height/2.0f - pointerSize, pointerSize*2, pointerSize*2);
    [[UIColor whiteColor] set];
    CGContextSetShadow(context, CGSizeMake(0.0f, 1.0f), 5.0f);
    CGContextAddEllipseInRect(context, rectEllipse);
    CGContextDrawPath(context, kCGPathFill);
    
    CGContextRestoreGState(context);
    
    
    CGContextSaveGState(context);
    
    CGContextRestoreGState(context);
    
    /////////////////////////////////////////////////////////////////////////////
    //
    // カラーマップ
    //
    /////////////////////////////////////////////////////////////////////////////
    
    CGContextSaveGState(context);
    
    [[UIColor colorWithWhite:0.9f alpha:1.0f] set];
    //[[UIColor lightTextColor] set];
    //CGContextSetShadow(context, CGSizeMake(0.0f, 0.0f), 4.0f);
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
    
    /////////////////////////////////////////////////////////////////////////////
    //
    // カーソル
    //
    /////////////////////////////////////////////////////////////////////////////
    
    if (_showColorCursor) {
        float cursorSize = _pixelSize + 2.0f;
        float cursorBackSize = cursorSize + 8.0f;
        // 隙間分引く
        CGRect cursorBackRect = CGRectMake(_colorCursorPosition.x - cursorBackSize/2.0f -1.0f, _colorCursorPosition.y - cursorBackSize/2.0f -1.0f, cursorBackSize, cursorBackSize);
        CGRect cursorRect = CGRectMake(_colorCursorPosition.x - cursorSize/2.0f -1.0f, _colorCursorPosition.y - cursorSize/2.0f -1.0f, cursorSize, cursorSize);
        
        CGContextSaveGState(context);
        CGContextAddRect(context, cursorBackRect);
        [[UIColor whiteColor] set];
        CGContextSetShadow(context, CGSizeMake(0.0f, 1.0f), 3.0f);
        CGContextDrawPath(context, kCGPathFill);
        CGContextRestoreGState(context);
        
        CGContextSaveGState(context);
        CGContextAddRect(context, cursorRect);
        [[UIColor colorWithRed:currentRgbColor.r green:currentRgbColor.g blue:currentRgbColor.b alpha:1.0f] set];
        CGContextDrawPath(context, kCGPathFill);
        CGContextRestoreGState(context);
    }
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
}

- (void)setCurrentTouchPointInView:(UITouch *)touch{
    CGPoint point;
	point = [touch locationInView:self];
    _activeTouchPosition.x = point.x;
    _activeTouchPosition.y = point.y;
}

- (void)BeforeDealloc{
    
}


- (void)dealloc{
    [super dealloc];
}

@end
