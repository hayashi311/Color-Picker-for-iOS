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

#import "HRSampleColorPickerViewController2.h"
#import "HRColorPickerView.h"

@implementation HRSampleColorPickerViewController2

@synthesize delegate;

- (id)initWithColor:(UIColor *)defaultColor fullColor:(BOOL)fullColor {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _color = defaultColor;
        _fullColor = fullColor;
    }
    return self;
}

- (void)loadView {
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];

    colorPickerView = [[HRColorPickerView alloc] init];
    colorPickerView.color = _color;

//    Please uncomment. If you want to catch the color change event.
//    [colorPickerView addTarget:self
//                        action:@selector(colorWasChanged:)
//              forControlEvents:UIControlEventEditingChanged];

    [self.view addSubview:colorPickerView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    colorPickerView.frame = (CGRect){.origin = CGPointZero, .size = self.view.frame.size};

    if ([self respondsToSelector:@selector(topLayoutGuide)]){
        CGRect frame = colorPickerView.frame;
        frame.origin.y = self.topLayoutGuide.length;
        colorPickerView.frame = frame;
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.delegate) {
        [self.delegate setSelectedColor:colorPickerView.color];
    }
}

@end
