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

#import "hayashi311_color_picker_view_controller.h"
#import "hayashi311_color_picker_view.h"

@implementation Hayashi311ColorPickerViewController

@synthesize delegate;

- (id)initWithDefaultColor:(UIColor*)default_color
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        Hayashi311RGBColor rgb_color;
        RGBColorFromUIColor(default_color, &rgb_color);
        color_picker_view = [[Hayashi311ColorPickerView alloc] initWithFrame:[self.view bounds] 
                                                             andDefaultColor:rgb_color];
        
        // すべての色を選択可能にしたい場合は以下をコメントをはずしてください。
        //[color_picker_view setBrightnessLowerLimit:0.0f];
        //[color_picker_view setSaturationUpperLimit:1.0f];
        [self setView:color_picker_view];
    }
    return self;
}

- (void)SaveColor:(id)sender{
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

/////////////////////////////////////////////////////////////////////////////
//
// ナビゲーションコントローラのデリゲートにして遷移を取得。もっといい方法がある気がする
//
/////////////////////////////////////////////////////////////////////////////

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if (viewController != self) {
        Hayashi311RGBColor rgb_color = [color_picker_view RGBColor];
        [self.delegate SetSelectedColor:[UIColor colorWithRed:rgb_color.r green:rgb_color.g blue:rgb_color.b alpha:1.0f]];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if (viewController != self) {
        [navigationController setDelegate:nil];
    }
}

#pragma mark - View lifecycle


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc{
    
    /////////////////////////////////////////////////////////////////////////////
    //
    // deallocでループを止めることができないので、BeforeDeallocを呼び出して下さい
    //
    /////////////////////////////////////////////////////////////////////////////
    
    [color_picker_view BeforeDealloc];
    [color_picker_view release];
    [super dealloc];
}

@end
