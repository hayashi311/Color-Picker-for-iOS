//
//  ColorMapView.swift
//  ColorPicker3
//
//  Created by Hayashi Ryota on 2019/02/16.
//  Copyright © 2019 Hayashi Ryota. All rights reserved.
//

import UIKit
import CoreFoundation

internal class ColorMapView: UIView {

    private var model = HRColorMapModel()

    private let borderWidth: CGFloat = 6
    private let backgounrdLayer = CAShapeLayer()
    private let colorMap = CALayer()
    private let maskLayer = CAShapeLayer()

    var colorSpace: HRColorSpace {
        get {
            return model.colorSpace
        }
        set {
            model.colorSpace = newValue
            setNeedsLayout()
        }
    }

    private static func createColorMapImage(size: CGSize, model: HRColorMapModel) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        let bufferSize: Int = width * height * 3
        let bitmapData: CFMutableData = CFDataCreateMutable(nil, 0)
        CFDataSetLength(bitmapData, CFIndex(bufferSize))
        guard let bitmap = CFDataGetMutableBytePtr(bitmapData) else { return nil }

        for y in stride(from: CGFloat(0), to: size.height, by: 1) {
            for x in stride(from: CGFloat(0), to: size.width, by: 1) {

                let normalizedPoint: CGPoint = CGPoint(x: x / size.width, y: y / size.height)

                let hsColor = model.color(at: normalizedPoint)

                let rgb = hsColor.with(brightness: 1).rgbColor

                let offset = (Int(x) + (Int(y) * width)) * 3
                bitmap[offset] = rgb.red
                bitmap[offset + 1] = rgb.green
                bitmap[offset + 2] = rgb.blue
            }
        }
        
        let colorSpace: CGColorSpace
        switch model.colorSpace {
        case .extendedSRGB:
            colorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
        case .sRGB:
            colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        }
        let dataProvider: CGDataProvider? = CGDataProvider(data: bitmapData)
        return CGImage(width: width, height: height,
                       bitsPerComponent: 8, bitsPerPixel: 24, bytesPerRow: width * 3,
                       space: colorSpace, bitmapInfo: [], provider: dataProvider!,
                       decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        updateStrokeColor()
        backgounrdLayer.backgroundColor = UIColor.black.cgColor
        backgounrdLayer.lineWidth = borderWidth
        layer.addSublayer(backgounrdLayer)
        colorMap.mask = maskLayer
        layer.addSublayer(colorMap)
    }

    private func updateStrokeColor() {
        let separatorColor: UIColor
        if #available(iOS 13.0, *) {
            separatorColor = UIColor.tertiarySystemGroupedBackground
        } else {
            separatorColor = #colorLiteral(red: 0.8940519691, green: 0.894156158, blue: 0.8940039277, alpha: 1)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgounrdLayer.strokeColor = separatorColor.cgColor
        CATransaction.commit()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateStrokeColor()
    }

    private func mapFrame() -> CGRect {
        let mapSize: CGFloat = min(bounds.width, bounds.height) - borderWidth * 2
        return  CGRect(x: (bounds.width - mapSize)/2, y: (bounds.height - mapSize)/2, width: mapSize, height: mapSize)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let mf = mapFrame()
        colorMap.frame = mf
        colorMap.contents = ColorMapView.createColorMapImage(size: mf.size, model: model)
        let onePixel = 1 / UIScreen.main.scale
        maskLayer.path = UIBezierPath(ovalIn: colorMap.bounds.insetBy(dx: -onePixel, dy: -onePixel)).cgPath
        backgounrdLayer.path = UIBezierPath(ovalIn: mf.insetBy(dx: -borderWidth/2, dy: -borderWidth/2)).cgPath
    }
    
    func set(brightness: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        colorMap.opacity = Float(brightness)
        CATransaction.commit()
    }

    private func normalize(positionInView: CGPoint) -> CGPoint {
        let mf = mapFrame()
        return CGPoint(x: (positionInView.x - mf.minX) / mf.width,
                       y: (positionInView.y - mf.minY) / mf.height)
    }

    private func inverseToPositionInView(normalizedPosition: CGPoint) -> CGPoint {
        let mf = mapFrame()
        return CGPoint(x: mf.minX + mf.width * normalizedPosition.x,
                       y: mf.minY + mf.height * normalizedPosition.y)
    }

    func color(at point: CGPoint) -> HSColor {
        let normalizedPosition = normalize(positionInView: point)
        return model.color(at: normalizedPosition)
    }
    
    func position(for color: HSColor) -> CGPoint {
        let normalizedPosition = model.normalizedPosition(for: color)
        return inverseToPositionInView(normalizedPosition: normalizedPosition)
    }
}

fileprivate class HRColorMapModel {
    private let center: CGFloat = 0.5
    fileprivate lazy var colorSpace: HRColorSpace = { preconditionFailure() }()

    fileprivate func color(at normalizedPosition: CGPoint) -> HSColor {
        let saturation = min(0.5, radius(normalizedPosition: normalizedPosition)) * 2
        let hue = normalize(radian: -angle(normalizedPosition: normalizedPosition)) / (CGFloat.pi * 2)
        return HSColor(colorSpace: colorSpace, hue: hue, saturation: saturation)
    }

    fileprivate func normalizedPosition(for color: HSColor) -> CGPoint {
        let radius = color.saturation / 2
        let angle = color.hue * (CGFloat.pi * -2)
        return CGPoint(x: (radius * cos(angle)) + center,
                       y: (radius * sin(angle)) + center)
    }

    private func radius(normalizedPosition: CGPoint) -> CGFloat {
        return hypot(normalizedPosition.x - center, normalizedPosition.y - center)
    }

    private func angle(normalizedPosition: CGPoint) -> CGFloat {
        return atan2(normalizedPosition.y - center, normalizedPosition.x - center)
    }

    private func normalize(radian: CGFloat) -> CGFloat {
        let pi2 = CGFloat.pi * 2
        let reminder = radian.truncatingRemainder(dividingBy: pi2)
        return radian < 0.0 ? reminder + pi2 : reminder
    }
}
