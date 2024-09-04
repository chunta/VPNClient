# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

target 'VPNClient' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for VPNClient
  pod 'OpenVPNAdapter', :git => 'https://github.com/ss-abramchuk/OpenVPNAdapter.git', :tag => '0.4.0'
  
end

target 'VPNClientNetwork' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for VPNClientNetwork
  pod 'OpenVPNAdapter', :git => 'https://github.com/ss-abramchuk/OpenVPNAdapter.git', :tag => '0.4.0'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14'
    end
  end
end
