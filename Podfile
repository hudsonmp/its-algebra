# MyScript Interactive Ink SDK via CocoaPods
platform :ios, '14.0'

target 'its-algebra' do
  use_frameworks!

  # MyScript Interactive Ink SDK
  pod 'MyScriptInteractiveInk-Framework', '~> 2.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end

