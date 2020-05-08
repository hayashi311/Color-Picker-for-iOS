//
//  HRBrightnessCursor.swift
//  ColorPicker3
//
//  Created by Ryota Hayashi on 2020/05/06.
//  Copyright © 2020 Hayashi Ryota. All rights reserved.
//

import UIKit

internal class BrightnessCursor: UIView {

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.5
        layer.borderWidth = 1
        if #available(iOS 13.0, *) {
            label.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .light)
        } else {
            label.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .light)
        }

        label.textAlignment = .center
        addSubview(label)
        isUserInteractionEnabled = false
    }

    func set(hsv: HSVColor) {
        backgroundColor = hsv.uiColor
        let borderColor = hsv.borderColor
        layer.borderColor = borderColor.cgColor
        label.textColor = borderColor
        label.text = hsv.rgbColor.hexString
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 6
        label.frame = bounds
    }
}

extension RGBColor {
    var hexString: String {
        return String(format: "#%02x%02x%02x", red, green, blue)
    }
}

