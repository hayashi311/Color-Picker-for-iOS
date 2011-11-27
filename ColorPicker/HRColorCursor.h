//
//  HRColorCursor.h
//  Hayashi311ColorPickerSample
//
//  Created by 林 亮太 on 11/11/27.
//  Copyright (c) 2011 Hayashi Ryota. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HRColorUtil.h"

@interface HRColorCursor : UIView{
    HRRGBColor _currentColor;
}

- (id)initWithPoint:(CGPoint)point;
- (void)setColorRed:(float)red andGreen:(float)green andBlue:(float)blue;

@end
