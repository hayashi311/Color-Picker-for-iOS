//
// Created by hayashi311 on 2013/09/15.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "HRColorInfoView.h"
#import "HRCgUtil.h"

const CGFloat kHRFlatStyleColorInfoViewLabelHeight = 18.;
const CGFloat kHRFlatStyleColorInfoViewCornerRadius = 3.;

@interface HRColorInfoView () {
    UIColor *_color;
}
@end

@implementation HRColorInfoView {
    UILabel *_hexColorLabel;
    CALayer *_borderLayer;
}

@synthesize color = _color;


+ (HRColorInfoView *)colorInfoViewWithFrame:(CGRect)frame {
    return [[HRColorInfoView alloc] initWithFrame:frame];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _hexColorLabel = [[UILabel alloc] init];
        _hexColorLabel.backgroundColor = [UIColor clearColor];
        _hexColorLabel.font = [UIFont systemFontOfSize:12];
        _hexColorLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
        _hexColorLabel.textAlignment = NSTextAlignmentCenter;

        [self addSubview:_hexColorLabel];

        _borderLayer = [[CALayer alloc] initWithLayer:self.layer];
        _borderLayer.cornerRadius = kHRFlatStyleColorInfoViewCornerRadius;
        _borderLayer.borderColor = [[UIColor lightGrayColor] CGColor];
        _borderLayer.borderWidth = 1.f / [[UIScreen mainScreen] scale];
        [self.layer addSublayer:_borderLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _hexColorLabel.frame = CGRectMake(
            0,
            CGRectGetHeight(self.frame) - kHRFlatStyleColorInfoViewLabelHeight,
            CGRectGetWidth(self.frame),
            kHRFlatStyleColorInfoViewLabelHeight);

    _borderLayer.frame = (CGRect) {.origin = CGPointZero, .size = self.frame.size};

}

- (void)setColor:(UIColor *)color {
    _color = color;
    _hexColorLabel.text = [NSString stringWithFormat:@"#%06x", HexColorFromUIColor(color)];
}

- (void)drawRect:(CGRect)rect {
    CGRect colorRect = CGRectMake(0, 0, CGRectGetWidth(rect), CGRectGetHeight(rect) - kHRFlatStyleColorInfoViewLabelHeight);

    UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRoundedRect:colorRect byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(4, 4)];
    [rectanglePath closePath];
    [self.color setFill];
    [rectanglePath fill];
}

@end

