#
# Be sure to run `pod lib lint Colorful.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Colorful'
  s.version          = '3.0.0'
  s.summary          = 'Colorful: iOS Color Picker built in Swift'

  s.description      = <<-DESC
Colorful is lightweight color picker for iOS.

- Beautiful UI with haptic feedback
- Dark mode support
- Extended sRGB (Wide color space) support
                       DESC

  s.homepage         = 'https://github.com/hayashi311/Color-Picker-for-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'new BSD License', :file => 'LICENSE' }
  s.author           = { 'hayashi311' => 'hayashi311@gmail.com' }
  s.source           = { :git => "https://github.com/hayashi311/Color-Picker-for-iOS.git", :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'Colorful/Classes/**/*'
  s.swift_version = '5.0'
end
