//
// Created by hayashi311 on 2013/09/14.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "UIImage+CoreGraphics.h"


@implementation UIImage (CoreGraphics)

+ (UIImage *)hr_imageWithSize:(CGSize)size renderer:(renderToContext)renderer {
    return [UIImage hr_imageWithSize:size opaque:YES renderer:renderer];
}

+ (UIImage *)hr_imageWithSize:(CGSize)size opaque:(BOOL)opaque renderer:(renderToContext)renderer {
    UIImage *image;

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGRect imageRect = CGRectMake(0.f, 0.f, size.width, size.height);

    renderer(context, imageRect);

    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end