# MyScript Interactive Ink SDK via CocoaPods
platform :ios, '14.0'

project 'config/its-algebra.xcodeproj'

target 'its-algebra' do
  # MyScript Interactive Ink SDK
  pod 'MyScriptInteractiveInk-Runtime', '4.2.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end

