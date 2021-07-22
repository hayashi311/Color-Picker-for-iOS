//
//  HRColorPicker.swift
//  ColorPicker3
//
//  Created by Hayashi Ryota on 2019/02/16.
//  Copyright © 2019 Hayashi Ryota. All rights reserved.
//

import UIKit

public final class ColorPicker: UIControl {
    
    private(set) lazy var colorSpace: HRColorSpace = { preconditionFailure() }()

    public var color: UIColor {
        get {
            return hsvColor.uiColor
        }
    }
    
    public var isBrightnessSliderHidden: Bool {
        set(hidden) {
            setBrightness(hidden ? brightnessLevel : brightnessSlider.brightness)
            brightnessSlider.isHidden = hidden
            brightnessCursor.isHidden = hidden
            layoutSubviews(withBrightnessSlider: !hidden)
            layoutIfNeeded()
        }
        get {
            return brightnessSlider.isHidden
        }
    }
    
    public var brightnessLevel: CGFloat {
        set(level) {
            setBrightness(level)
        }
        get {
            return hsvColor.brightness
        }
    }

    private let brightnessCursor = BrightnessCursor()
    private let brightnessSlider = BrightnessSlider()
    private let colorMap = ColorMapView()
    private let colorMapCursor = ColorMapCursor()

    private lazy var hsvColor: HSVColor = { preconditionFailure() }()

    private let feedbackGenerator = UISelectionFeedbackGenerator()
    
    private var layoutWithBrightness: [NSLayoutConstraint] = []
    private var layoutWithoutBrightness: [NSLayoutConstraint] = []
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        addSubview(colorMap)
        addSubview(brightnessSlider)
        addSubview(brightnessCursor)
        addSubview(colorMapCursor)
        
        setupConstraints()

        let colorMapPan = UIPanGestureRecognizer(target: self, action: #selector(self.handleColorMapPan(pan:)))
        colorMapPan.delegate = self
        colorMap.addGestureRecognizer(colorMapPan)

        let colorMapTap = UITapGestureRecognizer(target: self, action: #selector(self.handleColorMapTap(tap:)))
        colorMapTap.delegate = self
        colorMap.addGestureRecognizer(colorMapTap)

        brightnessSlider.delegate = self

        feedbackGenerator.prepare()
    }
    
    private func setupConstraints() {
        colorMap.translatesAutoresizingMaskIntoConstraints = false
        brightnessCursor.translatesAutoresizingMaskIntoConstraints = false
        brightnessSlider.translatesAutoresizingMaskIntoConstraints = false
        
        let margin: CGFloat = 12
        let brightnessWidth: CGFloat = 72
        let cursorHeight:CGFloat = 28
        
        layoutWithBrightness = [
            colorMap.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            colorMap.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
            colorMap.leftAnchor.constraint(equalTo: leftAnchor, constant: margin),
            colorMap.rightAnchor.constraint(equalTo: brightnessSlider.leftAnchor, constant: -margin),
            
            brightnessSlider.widthAnchor.constraint(equalToConstant: brightnessWidth),
            brightnessSlider.topAnchor.constraint(equalTo: topAnchor),
            brightnessSlider.bottomAnchor.constraint(equalTo: bottomAnchor),
            brightnessSlider.rightAnchor.constraint(equalTo: rightAnchor, constant: -margin),
            
            brightnessCursor.centerYAnchor.constraint(equalTo: brightnessSlider.centerYAnchor),
            brightnessCursor.centerXAnchor.constraint(equalTo: brightnessSlider.centerXAnchor),
            brightnessCursor.heightAnchor.constraint(equalToConstant: cursorHeight),
            brightnessCursor.widthAnchor.constraint(equalToConstant: brightnessWidth),
        ]
        
        layoutWithoutBrightness = [
            colorMap.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            colorMap.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
            colorMap.leftAnchor.constraint(equalTo: leftAnchor, constant: margin),
            colorMap.rightAnchor.constraint(equalTo: rightAnchor, constant: -margin),
        ]
    }

    public func set(color: UIColor, colorSpace: HRColorSpace) {
        self.colorSpace = colorSpace
        colorMap.colorSpace = colorSpace
        hsvColor = HSVColor(color: color, colorSpace: colorSpace)
        if superview != nil {
            mapColorToView(initialize: true)
        }
    }
    
    public override func layoutSubviews() {
        self.layoutSubviews(withBrightnessSlider: !self.brightnessSlider.isHidden)
        super.layoutSubviews()
        mapColorToView(initialize: true)
    }
    
    private func layoutSubviews(withBrightnessSlider: Bool) {
        if withBrightnessSlider {
            NSLayoutConstraint.deactivate(layoutWithoutBrightness)
            NSLayoutConstraint.activate(layoutWithBrightness)
        } else {
            NSLayoutConstraint.deactivate(layoutWithBrightness)
            NSLayoutConstraint.activate(layoutWithoutBrightness)
        }
    }
    
    private func mapColorToView(initialize: Bool = false) {
        brightnessCursor.set(hsv: hsvColor)
        colorMap.set(brightness: hsvColor.brightness)
        colorMapCursor.center =  colorMap.convert(colorMap.position(for: hsvColor.hueAndSaturation), to: self)
        colorMapCursor.set(hsvColor: hsvColor)
        brightnessSlider.set(hsColor: hsvColor.hueAndSaturation)
        if initialize {
            self.brightnessSlider.set(brightness: self.hsvColor.brightness)
        }
    }
    
    private func setBrightness(_ brightness: CGFloat) {
        hsvColor = hsvColor.hueAndSaturation.with(brightness: brightness)
        mapColorToView()
        feedbackIfNeeds()
        sendActionIfNeeds()
    }
    
    @objc
    private func handleColorMapPan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            colorMapCursor.startEditing()
        case .cancelled, .ended, .failed:
            colorMapCursor.endEditing()
        default:
            break
        }
        let selected = colorMap.color(at: pan.location(in: colorMap))
        hsvColor = selected.with(brightness: hsvColor.brightness)
        mapColorToView()
        feedbackIfNeeds()
        sendActionIfNeeds()
    }

    @objc
    private func handleColorMapTap(tap: UITapGestureRecognizer) {
        let selectedColor = colorMap.color(at: tap.location(in: colorMap))
        hsvColor = selectedColor.with(brightness: hsvColor.brightness)
        mapColorToView()
        feedbackIfNeeds()
        sendActionIfNeeds()
    }

    private var prevFeedbackedHSV: HSVColor?
    private func feedbackIfNeeds() {
        if prevFeedbackedHSV != hsvColor {
            feedbackGenerator.selectionChanged()
            prevFeedbackedHSV = hsvColor
        }
    }

    // ↑似た構造ではあるのだが、本質的に異なるので分けた
    private var prevSentActionHSV: HSVColor?
    private func sendActionIfNeeds() {
        if prevSentActionHSV != hsvColor {
            sendActions(for: .valueChanged)
            prevSentActionHSV = hsvColor
        }
    }
}

extension ColorPicker: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == colorMap, otherGestureRecognizer.view == colorMap {
            return true
        }
        return false
    }
}

extension ColorPicker: BrightnessSliderDelegate {
    func handleBrightnessChanged(slider: BrightnessSlider) {
        setBrightness(slider.brightness)
    }
}
