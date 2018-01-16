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
#import "HRHSVColorUtil.h"

typedef struct timeval timeval;

@interface HRColorPickerView () <UITextFieldDelegate>

// keyboard
@property (strong, nonatomic) UITapGestureRecognizer* tapHideKeyboard;
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

- (void)dealloc
{
    [self removeGestureRecognizer:self.tapHideKeyboard];
    self.tapHideKeyboard = nil;
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
    if (_brightnessSlider) self.brightnessSlider.color = self.color;
    if (_colorInfoView) self.colorInfoView.color = self.color;
    if (_colorMapView) {
        self.colorMapView.color = self.color;
        self.colorMapView.brightness = _currentHsvColor.v;
    }
    if (_textField) {
        if (!_textField.isFirstResponder) {
            _textField.text = [self hexStringFromColor:self.color];
            if (![[[self hexStringFromColor:self.color] lowercaseString] isEqualToString:@"#FFFFFF".lowercaseString]) {
                _textField.textColor = self.color;
            }
            else {
                _textField.textColor = [UIColor blackColor];
            }
        }
    }
}

- (void)setTextField:(UITextField *)textField
{
    _textField = textField;
    _textField.text = [self hexStringFromColor:self.color];
    if (![[[self hexStringFromColor:self.color] lowercaseString] isEqualToString:@"#FFFFFF".lowercaseString]) {
        _textField.textColor = self.color;
    }
    else {
        _textField.textColor = [UIColor blackColor];
    }
    [self addSubview:_textField];
    [self sendSubviewToBack:_textField];
    _textField.delegate = self;
    
    if (!self.tapHideKeyboard) {
        self.tapHideKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHideKeyboardTapDetected:)];
        self.tapHideKeyboard.numberOfTapsRequired = 1;
        [self addGestureRecognizer:self.tapHideKeyboard];
    }
}

- (UIView <HRColorInfoView> *)colorInfoView {
    if (!_colorInfoView) {
        _colorInfoView = [[HRColorInfoView alloc] init];
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
        _brightnessSlider = [[HRBrightnessSlider alloc] init];
        _brightnessSlider.brightnessLowerLimit = @0.4;
        _brightnessSlider.color = self.color;
        [_brightnessSlider addTarget:self
                              action:@selector(brightnessChanged:)
                    forControlEvents:UIControlEventValueChanged];
        [self addSubview:_brightnessSlider];
    }
    return _brightnessSlider;
}

- (void)setBrightnessSlider:(UIControl <HRBrightnessSlider> *)brightnessSlider {
    _brightnessSlider = brightnessSlider;
    _brightnessSlider.color = self.color;
    [_brightnessSlider addTarget:self
                          action:@selector(brightnessChanged:)
                forControlEvents:UIControlEventValueChanged];
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
                forControlEvents:UIControlEventValueChanged];
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
            forControlEvents:UIControlEventValueChanged];
}

- (void)brightnessChanged:(UIControl <HRBrightnessSlider> *)slider {
    _currentHsvColor.v = slider.brightness.floatValue;
    self.colorMapView.brightness = _currentHsvColor.v;
    self.colorMapView.color = self.color;
    self.colorInfoView.color = self.color;
    self.textField.text = [self hexStringFromColor:self.color];
    if (![[[self hexStringFromColor:self.color] lowercaseString] isEqualToString:@"#FFFFFF".lowercaseString]) {
        _textField.textColor = self.color;
    }
    else {
        _textField.textColor = [UIColor blackColor];
    }
    [self sendActions];
}

- (void)colorMapColorChanged:(UIControl <HRColorMapView> *)colorMapView {
    HSVColorFromUIColor(colorMapView.color, &_currentHsvColor);
    self.brightnessSlider.color = colorMapView.color;
    self.colorInfoView.color = self.color;
    self.textField.text = [self hexStringFromColor:self.color];
    if (![[[self hexStringFromColor:self.color] lowercaseString] isEqualToString:@"#FFFFFF".lowercaseString]) {
        _textField.textColor = self.color;
    }
    else {
        _textField.textColor = [UIColor blackColor];
    }
    [self sendActions];
}

- (void)sendActions {
    timeval now, diff;
    gettimeofday(&now, NULL);
    timersub(&now, &_lastDrawTime, &diff);
    if (timercmp(&diff, &_waitTimeDuration, >)) {
        _lastDrawTime = now;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
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
    self.colorMapView.frame = CGRectMake(0,
                                         headerHeight,
                                         CGRectGetWidth(self.frame),
                                         MAX(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) - headerHeight));
    // use intrinsicContentSize for 3.5inch screen
    CGSize sizeOfColorMapView = self.colorMapView.intrinsicContentSize;
    if (sizeOfColorMapView.height + headerHeight > self.bounds.size.height) {
        sizeOfColorMapView = CGSizeMake(self.bounds.size.width, self.bounds.size.height - headerHeight);
    }
    else {
        sizeOfColorMapView = CGSizeMake(self.bounds.size.width, self.bounds.size.height - headerHeight);
    }
    CGRect colorMapFrame = (CGRect) {
        .origin = CGPointZero,
        .size = sizeOfColorMapView
    };
    colorMapFrame.origin.y = CGRectGetHeight(self.frame) - CGRectGetHeight(colorMapFrame);
    self.colorMapView.frame = colorMapFrame;
    headerHeight = CGRectGetMinY(colorMapFrame);
    
    self.colorInfoView.frame = CGRectMake(8, (headerHeight - 84) / 2.0f, 66, 84);
    
    CGFloat hexLabelHeight = 18;
    CGFloat sliderHeight = 11;
    CGFloat brightnessPickerTop = CGRectGetMaxY(self.colorInfoView.frame) - hexLabelHeight - sliderHeight;
    
    CGRect brightnessPickerFrame = CGRectMake(CGRectGetMaxX(self.colorInfoView.frame) + 9,
                                              brightnessPickerTop,
                                              CGRectGetWidth(self.frame) - CGRectGetMaxX(self.colorInfoView.frame) - 9 * 2,
                                              sliderHeight);
    
    self.brightnessSlider.frame = [self.brightnessSlider frameForAlignmentRect:brightnessPickerFrame];
    self.textField.frame = CGRectMake(self.colorInfoView.frame.origin.x + self.colorInfoView.frame.size.width + 16.0,
                                      self.colorInfoView.frame.origin.y,
                                      200.0,
                                      30.0);
}

- (NSString *)hexStringFromColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}

- (UIColor *)colorWithHexString:(NSString *)hex
{
    NSString *cString = [hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].uppercaseString;
    
    // String should be 6 or 8 characters
    if (cString.length < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    // #으로 시작해도 #을 지워준다.
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
    
    if (cString.length != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    //NSLog(@"%s: %@", __PRETTY_FUNCTION__, textField.text);
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //NSLog(@"%s: %@", __PRETTY_FUNCTION__, textField.text);
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    // 다른 칸으로 이동하면 여기가 호출됨
    //NSLog(@"%s: %@", __PRETTY_FUNCTION__, textField.text);
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //NSLog(@"%s: %@", __PRETTY_FUNCTION__, textField.text);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    //NSLog(@"%s: %@, %@", __PRETTY_FUNCTION__, textField.text, string);
    
    NSString *inputString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    //NSLog(@"inputText = %@", inputString);
    
    UIColor *color = [self colorWithHexString:inputString];
    self.color = color;
    if (![[[self hexStringFromColor:self.color] lowercaseString] isEqualToString:@"#FFFFFF".lowercaseString]) {
        _textField.textColor = self.color;
    }
    else {
        _textField.textColor = [UIColor blackColor];
    }
    
    self.brightnessSlider.color = self.color;
    self.colorInfoView.color = self.color;
    self.colorMapView.color = self.color;
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    //NSLog(@"%s: %@", __PRETTY_FUNCTION__, textField.text);
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // next 버튼을 누르면 여기가 호출됨
    //NSLog(@"%s: %@", __PRETTY_FUNCTION__, textField.text);
    return YES;
}

- (void)actionHideKeyboardTapDetected:(UITapGestureRecognizer *)sender
{
    [_textField resignFirstResponder];
}

@end

