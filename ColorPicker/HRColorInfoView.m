//
// Created by hayashi311 on 2013/09/15.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "HRColorInfoView.h"
#import "HRCgUtil.h"


@interface HRColorInfoView () {
    UIColor *_color;
}
@end

@interface HRFlatStyleColorInfoView : HRColorInfoView

@end

@implementation HRColorInfoView
@synthesize color = _color;


+ (HRColorInfoView *)colorInfoViewWithFrame:(CGRect)frame {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return [[HRColorInfoView alloc] initWithFrame:frame];
    }
    return [[HRFlatStyleColorInfoView alloc] initWithFrame:frame];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.color = [UIColor whiteColor];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGRect colorFrame = CGRectMake(1, 5, 40.0f, 40.0f);

    /////////////////////////////////////////////////////////////////////////////
    //
    // カラー
    //
    /////////////////////////////////////////////////////////////////////////////

    CGContextSaveGState(context);
    HRDrawSquareColorBatch(context, CGPointMake(CGRectGetMidX(colorFrame), CGRectGetMidY(colorFrame)), self.color, colorFrame.size.width / 2.0f);
    CGContextRestoreGState(context);

    /////////////////////////////////////////////////////////////////////////////
    //
    // RGBのパーセント表示
    //
    /////////////////////////////////////////////////////////////////////////////

    CGFloat red, green, blue, alpha;
    [self.color getRed:&red green:&green blue:&blue alpha:&alpha];

    [[UIColor darkGrayColor] set];

    CGFloat textHeight = 20.0f;
    CGFloat textCenter = CGRectGetMidY(colorFrame) - 5.0f;
    [[NSString stringWithFormat:@"R:%3d%%", (int) (red * 100)] drawAtPoint:CGPointMake(colorFrame.origin.x + colorFrame.size.width + 10.0f, textCenter - textHeight) withFont:[UIFont boldSystemFontOfSize:12.0f]];
    [[NSString stringWithFormat:@"G:%3d%%", (int) (green * 100)] drawAtPoint:CGPointMake(colorFrame.origin.x + colorFrame.size.width + 10.0f, textCenter) withFont:[UIFont boldSystemFontOfSize:12.0f]];
    [[NSString stringWithFormat:@"B:%3d%%", (int) (blue * 100)] drawAtPoint:CGPointMake(colorFrame.origin.x + colorFrame.size.width + 10.0f, textCenter + textHeight) withFont:[UIFont boldSystemFontOfSize:12.0f]];
}

@end


const CGFloat kHRFlatStyleColorInfoViewLabelHeight = 20.;
const CGFloat kHRFlatStyleColorInfoViewCornerRadius = 3.;

@implementation HRFlatStyleColorInfoView {
    UILabel *_hexColorLabel;
    CALayer *_borderLayer;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
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
    [super setColor:color];
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
