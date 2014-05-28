//
// Created by hayashi311 on 5/23/14.
// Copyright (c) 2014 Hayashi Ryota. All rights reserved.
//

#import "HRSampleColorPickerViewController3.h"
#import "HRColorPickerView.h"

@interface HRSampleColorPickerViewController3()

@property (nonatomic, weak) IBOutlet HRColorPickerView *colorPickerView;

@end


@implementation HRSampleColorPickerViewController3 {

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    [self.colorPickerView addTarget:self
                             action:@selector(colorDidChanged:)
                   forControlEvents:UIControlEventValueChanged];
}

- (void)colorDidChanged:(HRColorPickerView *)pickerView {
    [[[UIApplication sharedApplication] keyWindow] setTintColor:pickerView.color];
}

@end