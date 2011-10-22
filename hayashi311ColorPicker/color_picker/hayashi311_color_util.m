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

#import "hayashi311_color_util.h"

void HSVColorFromRGBColor(const Hayashi311RGBColor* rgb,Hayashi311HSVColor* hsv){
    Hayashi311RGBColor rgb255 = {rgb->r * 255.0f,rgb->g * 255.0f,rgb->b * 255.0f};
    Hayashi311HSVColor hsv255 = {0.0f,0.0f,0.0f};
    
    float max = rgb255.r;
    if (max < rgb255.g) {
        max = rgb255.g;
    }
    if (max < rgb255.b) {
        max = rgb255.b;
    }
    hsv255.v = max;
    
    float min = rgb255.r;
    if (min > rgb255.g) {
        min = rgb255.g;
    }
    if (min > rgb255.b) {
        min = rgb255.b;
    }
    
    if (max == 0.0f) {
        hsv255.h = 0.0f;
        hsv255.s = 0.0f;
    }else{
        hsv255.s = 255*(max - min)/(double)max;
        int h = 0.0f;
        if(max == rgb255.r){
            h = 60 * (rgb255.g - rgb255.b) / (double)(max - min);
        }else if(max == rgb255.g){
            h = 60 * (rgb255.b - rgb255.r) / (double)(max - min) + 120;
        }else{
            h = 60 * (rgb255.r - rgb255.g) / (double)(max - min) + 240;
        }
        if(h < 0) h += 360;
        hsv255.h = (float)h;
    }
    hsv->h = hsv255.h / 360.0f;
    hsv->s = hsv255.s / 255.0f;
    hsv->v = hsv255.v / 255.0f;
}

/*
void RGBColorFromHSVColor(const Hayashi311HSVColor* hsv,Hayashi311RGBColor* rgb){
    UIColorには
    [UIColor colorWithHue:<#(CGFloat)#> saturation:<#(CGFloat)#> brightness:<#(CGFloat)#> alpha:<#(CGFloat)#>]
    があるので、必要ならRGBColorFromUIColorと組み合わせて使えばいいです。
}*/

void RGBColorFromUIColor(const UIColor* ui_color,Hayashi311RGBColor* rgb){
    const CGFloat* components = CGColorGetComponents(ui_color.CGColor);
    if(CGColorGetNumberOfComponents(ui_color.CGColor) == 2){
        rgb->r = components[0];
        rgb->g = components[0];
        rgb->b = components[0];
    }else{
        rgb->r = components[0];
        rgb->g = components[1];
        rgb->b = components[2];
    }
}

bool isEqual(const Hayashi311HSVColor* hsv1,const Hayashi311HSVColor* hsv2){
    return (hsv1->h == hsv2->h) && (hsv1->s == hsv2->s) && (hsv1->v == hsv2->v);
}