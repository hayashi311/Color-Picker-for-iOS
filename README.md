# Memo
Target reader: Engineer who developing mobile app.
Purpose of this description: Make them want to use this library.
Style: Fan & casual technical document. To make engineers feels easy.

----

# Colorful

Colorful is intuitive color picker library written in Swift.
It is designed easy to use for you and your app users.

[![CI Status](https://img.shields.io/travis/hayashi311/Colorful.svg?style=flat)](https://travis-ci.org/hayashi311/Colorful)
[![Version](https://img.shields.io/cocoapods/v/Colorful.svg?style=flat)](https://cocoapods.org/pods/Colorful)
[![License](https://img.shields.io/cocoapods/l/Colorful.svg?style=flat)](https://cocoapods.org/pods/Colorful)
[![Platform](https://img.shields.io/cocoapods/p/Colorful.svg?style=flat)](https://cocoapods.org/pods/Colorful)

## Reason why you choose colorful

### Intuitive UI.

It's include hue-saturation wheel and brightness slider.
UI interact quickly with perfect small animation and **haptic feedback**.

![](https://github.com/hayashi311/Color-Picker-for-iOS/raw/screenshot/ColorfulUI.gif)

### Wide color space support

Wide color space is supported from iOS10.
Now, `UIColor.red` is not "reddest" red any more.

```
// before iOS10
let red = UIColor.red // reddest

// Now
let red = UIColor(displayP3Red: 1, green: 0, blue: 0)
```

Extended sRGB Color Space is designed to support wide color space with keeping compatible from sRGB.

You can choose both color spaces with Colorful. 
Extended sRGB for choosing brilliant color, sRGB for compatible.

| Color Space |  |
| :-------: | :---------: |
| .extendedSRGB | Brilliant color |
| .sRGB | Compatibility |

![](https://github.com/hayashi311/Color-Picker-for-iOS/raw/screenshot/ColorPicker_ColorSpace.png)

### Dark mode support

Do you want to pick color in the dark? 
Colorful supports dark mode :)

![](https://github.com/hayashi311/Color-Picker-for-iOS/raw/screenshot/ColorPicker_Dark.png)


## How to use it

It's designed like UIKit standard ui components.
No surprise, You can use it as you think it.

### Podfile

```
platform :ios, '10.0'
pod "Colorful", "~> 3.0"
```

### Install

```
$ pod install
```

### Usage

```swift
let colorPicker = ColorPicker(frame: ...)
colorPicker.addTarget(self, action: #selector(...), for: .valueChanged)
colorPicker.set(color: .red, colorSpace: .extendedSRGB)
view.addSubview(colorPicker)
```

You can receive `.valueChanged` event when user changes color like ther UIKit's UIComponents.


## Requirements

iOS11 ~

## License

Colorful is available under new BSD License. See the LICENSE file for more info.
