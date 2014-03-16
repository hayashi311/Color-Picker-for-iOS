//
// Created by hayashi311 on 2013/09/14.
// Copyright (c) 2013 Hayashi Ryota. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

typedef void(^renderToContext)(CGContextRef, CGRect);

@interface UIImage (CoreGraphics)

+ (UIImage *)hr_imageWithSize:(CGSize)size renderer:(renderToContext)renderer;

+ (UIImage *)hr_imageWithSize:(CGSize)size opaque:(BOOL)opaque renderer:(renderToContext)renderer;

@end