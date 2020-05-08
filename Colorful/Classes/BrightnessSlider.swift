//
//  HRBrightnessSlider.swift
//  ColorPicker3
//
//  Created by Hayashi Ryota on 2019/02/16.
//  Copyright © 2019 Hayashi Ryota. All rights reserved.
//

import UIKit

internal protocol BrightnessSliderDelegate: class {
    func handleBrightnessChanged(slider: BrightnessSlider)
}

internal class BrightnessSlider: UIView {

    weak var delegate: BrightnessSliderDelegate?

    var brightness: CGFloat {
        get {
            return brightness(for: scrollView.contentOffset.y)
        }
    }

    private var initialBrightness: CGFloat?

    private lazy var scales: [CALayer] = {
        var scales = (0..<20).map { _ -> CALayer in
            let layer = CALayer()
            layer.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1).cgColor
            return layer
        }
        return scales
    }()

    private let scrollView = UIScrollView()
    private let borderLayer = CAShapeLayer()

    private let topShadowLayer = CAGradientLayer()
    private let bottomShadowLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        scrollView.delegate = self
        scrollView.decelerationRate = .fast
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        for scale in scales {
            scrollView.layer.addSublayer(scale)
        }

        updateShadowColor()
        topShadowLayer.startPoint = CGPoint(x: 0.5, y: 0)
        topShadowLayer.endPoint = CGPoint(x: 0.5, y: 1)
        topShadowLayer.locations = [0, 1]
        layer.addSublayer(topShadowLayer)

        bottomShadowLayer.startPoint = CGPoint(x: 0.5, y: 1)
        bottomShadowLayer.endPoint = CGPoint(x: 0.5, y: 0)
        bottomShadowLayer.locations = [0, 1]
        layer.addSublayer(bottomShadowLayer)

        updateBorderColor()
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 6
        scrollView.layer.addSublayer(borderLayer)

        let sliderTap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(tap:)))
        scrollView.addGestureRecognizer(sliderTap)
    }

    private func updateBorderColor() {
        let separatorColor: UIColor
        if #available(iOS 13.0, *) {
            separatorColor = UIColor.tertiarySystemGroupedBackground
        } else {
            separatorColor = #colorLiteral(red: 0.8940519691, green: 0.894156158, blue: 0.8940039277, alpha: 1)
        }
        borderLayer.strokeColor = separatorColor.cgColor
    }

    private func updateShadowColor() {
        let bgColor: UIColor
        if #available(iOS 13.0, *) {
            bgColor = UIColor.systemBackground
        } else {
            bgColor = UIColor.white
        }
        topShadowLayer.colors = [bgColor.cgColor, bgColor.withAlphaComponent(0).cgColor]
        bottomShadowLayer.colors = [bgColor.cgColor, bgColor.withAlphaComponent(0).cgColor]
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateBorderColor()
        updateShadowColor()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: 500)
        scrollView.contentInset = UIEdgeInsets(top: scrollView.frame.size.height/2, left: 0,
                                               bottom: scrollView.frame.size.height/2, right: 0)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let height = scrollView.contentSize.height / CGFloat(scales.count)
        for (i, scale) in scales.enumerated() {
            let y = CGFloat(i) * height
            scale.frame = CGRect(x: (scrollView.frame.width - 40)/2, y: y, width: 40, height: height)
        }

        let shadowHeight: CGFloat = 26
        topShadowLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: shadowHeight)
        bottomShadowLayer.frame = CGRect(x: 0, y: bounds.height - shadowHeight, width: bounds.width, height: shadowHeight)
        borderLayer.path = UIBezierPath(roundedRect: CGRect(x: (bounds.width - 40)/2, y: -3, width: 40, height: scrollView.contentSize.height + 6), cornerRadius: 4).cgPath
        CATransaction.commit()

        if let b = initialBrightness {
            initialBrightness = nil
            set(brightness: b)
        }
    }
    
    func set(hsColor: HSColor) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (i, scale) in scales.reversed().enumerated() {
            let brightness = CGFloat(i) * 1 / CGFloat(scales.count)
            let color = hsColor.with(brightness: brightness)
            scale.backgroundColor = color.uiColor.cgColor
        }
        CATransaction.commit()
    }

    func set(brightness: CGFloat) {
        if scrollView.bounds.isEmpty {
            initialBrightness = brightness
        } else {
            let contentOffset = CGPoint(x: 0, y: contentOffsetY(for: brightness))
            let d = delegate
            delegate = nil
            scrollView.setContentOffset(contentOffset, animated: false)
            delegate = d
        }
    }

    @objc
    func handleTap(tap: UITapGestureRecognizer) {
        let y = min(max(tap.location(in: scrollView).y, 0), scrollView.contentSize.height)
        let offset = CGPoint(x: 0, y: y - scrollView.bounds.height/2)
        scrollView.setContentOffset(offset, animated: true)
    }

    private func brightness(for offsetY: CGFloat) -> CGFloat {
        let normalizedOffset = (offsetY + scrollView.contentInset.top) / scrollView.contentSize.height
        // 0 <= brightness <= 1, %.2f
        return max(0, min(1, round((normalizedOffset - 1) * -1 * 100) / 100))
    }

    private func contentOffsetY(for brightness: CGFloat) -> CGFloat {
        return (brightness - 1) * -1 * scrollView.contentSize.height - scrollView.contentInset.top
    }
}

extension BrightnessSlider: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.handleBrightnessChanged(slider: self)
    }
}
