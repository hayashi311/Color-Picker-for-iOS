//
//  Entity.swift
//  ColorPicker3
//
//  Created by Hayashi Ryota on 2019/02/16.
//  Copyright © 2019 Hayashi Ryota. All rights reserved.
//

import UIKit

public enum HRColorSpace {
    case extendedSRGB
    case sRGB
}

internal struct HSVColor: Equatable {
    let colorSpace: HRColorSpace
    let hue: CGFloat
    let saturation: CGFloat
    let brightness: CGFloat
}

internal struct HSColor: Equatable {
    let colorSpace: HRColorSpace
    let hue: CGFloat
    let saturation: CGFloat
}

internal struct RGBColor: Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
}

extension HSVColor {
    init(color: UIColor, colorSpace: HRColorSpace) {

        let cgColorSpace: CGColorSpace
        switch colorSpace {
        case .extendedSRGB:
            cgColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
        case .sRGB:
            cgColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        }

        let converted = color.cgColor.converted(to: cgColorSpace, intent: .defaultIntent, options: nil)!
        let components: [CGFloat] = converted.components!

        let red: CGFloat; let green: CGFloat; let blue: CGFloat;
        if components.count >= 3 {
            red = components[0]; green = components[1]; blue = components[2];
        } else {
            red = components[0]; green = components[0]; blue = components[0];
        }

        var h: CGFloat = 0; var s: CGFloat = 0; var b: CGFloat = 0
        UIColor(red: red, green: green, blue: blue, alpha: 1).getHue(&h, saturation: &s, brightness: &b, alpha: nil)
        hue = h
        saturation = s
        brightness = b
        self.colorSpace = colorSpace
    }

    var hueAndSaturation: HSColor {
        return HSColor(colorSpace: colorSpace, hue: hue, saturation: saturation)
    }

    var rgbColor: RGBColor {
        let uint8Max = CGFloat(UInt8.max)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0
        sRGBUIColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        return RGBColor(red: UInt8(r * uint8Max), green: UInt8(g * uint8Max), blue: UInt8(b * uint8Max))
    }

    private var sRGBUIColor: UIColor {
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }

    private var extendedSRGBUIColor: UIColor {
        let uint8Max = CGFloat(UInt8.max)
        let rgb = self.rgbColor
        // https://developer.apple.com/documentation/uikit/uicolor/1648568-init
        // > Return Value: The color information represented by this object is in an extended range sRGB colorspace.
        return UIColor(displayP3Red: CGFloat(rgb.red) / uint8Max,
                       green: CGFloat(rgb.green) / uint8Max,
                       blue: CGFloat(rgb.blue) / uint8Max,
                       alpha: 1)
    }

    var uiColor: UIColor {
        switch colorSpace {
        case .extendedSRGB:
            return extendedSRGBUIColor
        case .sRGB:
            return sRGBUIColor
        }
    }

    var borderColor: UIColor {
        let isLightColor: Bool = brightness > 0.7 && saturation < 0.4

        if isLightColor {
            return UIColor(white: 0.1, alpha: 1)
        } else {
            return UIColor(white: 1, alpha: 1)
        }
    }
}

extension HSColor {
    func with(brightness: CGFloat) -> HSVColor {
        return HSVColor(colorSpace: colorSpace, hue: hue, saturation: saturation, brightness: brightness)
    }
}
