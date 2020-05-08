# Colorful

[![CI Status](https://img.shields.io/travis/hayashi311/Colorful.svg?style=flat)](https://travis-ci.org/hayashi311/Colorful)
[![Version](https://img.shields.io/cocoapods/v/Colorful.svg?style=flat)](https://cocoapods.org/pods/Colorful)
[![License](https://img.shields.io/cocoapods/l/Colorful.svg?style=flat)](https://cocoapods.org/pods/Colorful)
[![Platform](https://img.shields.io/cocoapods/p/Colorful.svg?style=flat)](https://cocoapods.org/pods/Colorful)

### How to use it

#### Podfile

```
platform :ios, '10.0'
pod "Colorful", "~> 3.0"
```

#### Install

```
$ pod install
```

#### Usage

```swift
let colorPicker = ColorPicker(frame: ...)
colorPicker.addTarget(self, action: #selector(...), for: .valueChanged)
colorPicker.set(color: .red, colorSpace: .extendedSRGB)
view.add(subview: colorPicker)
```

You can receive `.valueChanged` event when user changes color.

### Reason why you choose colorful

#### Beautiful UI with haptic feedback.

![](https://github.com/hayashi311/Color-Picker-for-iOS/raw/screenshot/ColorfulUI.gif)

#### Wide color space support

| ColorSpace | Description |
| :-------: | :---------: |
| .extendedSRGB | The extended sRGB is color space for support wider and deeper representation of color. |
| .sRGB | sRGB (standard Red Green Blue) is often the "default" color space for images that contain no color space information |

![](https://github.com/hayashi311/Color-Picker-for-iOS/raw/screenshot/ColorPicker_ColorSpace.png)

#### Dark mode support

![](https://github.com/hayashi311/Color-Picker-for-iOS/raw/screenshot/ColorPicker_Dark.png)

## Requirements

iOS10 ~

## License

Colorful is available under new BSD License. See the LICENSE file for more info.
