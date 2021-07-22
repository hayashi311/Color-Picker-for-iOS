//
//  ViewController.swift
//  Colorful
//
//  Created by hayashi311 on 05/08/2020.
//  Copyright (c) 2020 hayashi311. All rights reserved.
//

import UIKit
import Colorful

class ViewController: UIViewController {

    @IBOutlet weak var colorPicker: ColorPicker!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var sRGBSwitch: UISwitch!
    @IBOutlet weak var brightnessSwitch: UISwitch!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var colorSpaceLabel: UILabel!

    var colorSpace: HRColorSpace = .sRGB

    override func viewDidLoad() {
        super.viewDidLoad()
        colorPicker.addTarget(self, action: #selector(self.handleColorChanged(picker:)), for: .valueChanged)
        colorPicker.set(color: UIColor(displayP3Red: 1.0, green: 1.0, blue: 0, alpha: 1), colorSpace: colorSpace)
        updateColorSpaceText()
        handleColorChanged(picker: colorPicker)
        brightnessSlider.isHidden = !colorPicker.isBrightnessSliderHidden
    }

    @objc func handleColorChanged(picker: ColorPicker) {
        label.text = picker.color.description
    }

    @IBAction func handleRedButtonAction(_ sender: UIButton) {
        colorPicker.set(color: .red, colorSpace: colorSpace)
        handleColorChanged(picker: colorPicker)
    }

    @IBAction func handlePurpleButtonAction(_ sender: UIButton) {
        colorPicker.set(color: .purple, colorSpace: colorSpace)
        handleColorChanged(picker: colorPicker)
    }

    @IBAction func handleYellowButtonAction(_ sender: UIButton) {
        colorPicker.set(color: .yellow, colorSpace: colorSpace)
        handleColorChanged(picker: colorPicker)
    }

    @IBAction func handleSwitchAction(_ sender: UISwitch) {
        switch sender.tag {
        case 0:
            colorSpace = sender.isOn ? .extendedSRGB : .sRGB
            colorPicker.set(color: colorPicker.color, colorSpace: colorSpace)
            updateColorSpaceText()
            handleColorChanged(picker: colorPicker)
        case 1:
            colorPicker.isBrightnessSliderHidden.toggle()
            brightnessSlider.isHidden = !colorPicker.isBrightnessSliderHidden
            brightnessSlider.value = Float(colorPicker.brightnessLevel)
        default:
            break
        }
    }
    
    @IBAction func handleSliderAction(_ sender: UISlider) {
        colorPicker.brightnessLevel = CGFloat(sender.value)
    }
    
    func updateColorSpaceText() {
        switch colorSpace {
        case .extendedSRGB:
            colorSpaceLabel.text = "Extended sRGB"
        case .sRGB:
            colorSpaceLabel.text = "sRGB"
        }
    }
}

