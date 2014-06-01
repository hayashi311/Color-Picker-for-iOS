## HRColorPicker  
***HRColorPicker*** is a lightweight color picker for iOS  
that's easy to use for both users and developers.  


### Try HRColorPicker
To try HRColorPicker, open Terminal.app and enter the following command:  

    $ pod try Color-Picker-for-iOS

![](https://raw.githubusercontent.com/hayashi311/Color-Picker-for-iOS/eb95b42707d1319cc5e43562ac275e44f3eb6376/screen_shot2.png)

### How to use it

#### Podfile

    platform :ios, '7.0'
    pod "Color-Picker-for-iOS", "~> 2.0"

#### Install

    $ pod install

#### Usage

    colorPickerView = [[HRColorPickerView alloc] init];
    colorPickerView.color = self.color;
    [colorPickerView addTarget:self
                        action:@selector(action:)
              forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:colorPickerView];
  
HRColorPicker is optimized for ***Interface Builder*** and ***AutoLayout***.

### How to customize

#### Interface Builder
Layout, color, and tile size can be changed only through the Interface Builder.

image

#### Without Interface Builder
As shown below, you can also programmatically customize HRColorPicker.

    colorPickerView.colorMapView.saturationUpperLimit = @1;

If you would like to change the layout, it is strongly recommended that you use the Interface Builder and AutoLayout.

### Changing the UI components

If you would like to customize the user interface, HRColorPicker allows you to completely change out certain UI components.

    @property (nonatomic, strong) IBOutlet UIView <HRColorInfoView> *colorInfoView;
    @property (nonatomic, strong) IBOutlet UIControl <HRColorMapView> *colorMapView;
    @property (nonatomic, strong) IBOutlet UIControl <HRBrightnessSlider> *brightnessSlider;

Create your custom UI class that implement protocol methods.

    YourAwesomeBrightnessSlider *slider = [[YourAwesomeBrightnessSlider alloc] init];
    [colorPickerView addSubview:slider];
    colorPickerView.brightnessSlider = slider;

### Lisence

- new BSD License 


### requirement
- iOS7.x~
  
