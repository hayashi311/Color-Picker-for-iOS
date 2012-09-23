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


#import "SampleTopViewController.h"
#import "HRColorUtil.h"

@implementation SampleTopViewController


- (void)openColorPicker:(id)sender{
    HRColorPickerViewController* controller;
    switch ([sender tag]) {
    case 0:
        controller = [HRColorPickerViewController colorPickerViewControllerWithColor:[self.view backgroundColor]];
        break;
    case 1:
        controller = [HRColorPickerViewController cancelableColorPickerViewControllerWithColor:[self.view backgroundColor]];
        break;
    case 2:
        controller = [HRColorPickerViewController fullColorPickerViewControllerWithColor:[self.view backgroundColor]];
        break;
    case 3:
        controller = [HRColorPickerViewController cancelableFullColorPickerViewControllerWithColor:[self.view backgroundColor]];
        break;

    default:
        return;
        break;
    }
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (UIButton *)createButtonWithTitle:(NSString *)title index:(int)index
{
    float offsetY = index * 60;
    UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.tag = index;
    [button setFrame:CGRectMake(10.0f, 30.0f + offsetY, 300.0f, 50.0f)];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(openColorPicker:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    return button;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    
    self.title = @"Color Picker by Hayashi311";
    
    NSString *titles[] = { @"Limited color ->", @"Limited color with Save button ->", @"Full color ->", @"Full color with Save button ->" };
    
    int i;
    for (i = 0; i < sizeof(titles) / sizeof(titles[0]); i++) {
        [self createButtonWithTitle:titles[i] index:i];
    }
    
    hexColorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.f,
                                                              self.view.frame.size.height-46.f,
                                                              320.f,
                                                              46.f)];
    hexColorLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [hexColorLabel setTextAlignment:UITextAlignmentCenter];
    [hexColorLabel setBackgroundColor:[UIColor colorWithWhite:1.0f alpha:0.4f]];
    [self.view addSubview:hexColorLabel];
    
    [self setSelectedColor:[UIColor cyanColor]];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

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

#pragma mark - Hayashi311ColorPickerDelegate

- (void)setSelectedColor:(UIColor*)color{
    [self.view setBackgroundColor:color];
    [hexColorLabel setText:[NSString stringWithFormat:@"#%06x",HexColorFromUIColor(color)]];
}


@end
