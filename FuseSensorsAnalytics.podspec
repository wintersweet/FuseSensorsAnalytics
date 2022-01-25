#
# Be sure to run `pod lib lint FuseSensorsAnalytics.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FuseSensorsAnalytics'
  s.version          = '1.0.4'
  s.summary          = 'A short description of FuseSensorsAnalytics.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/wintersweet/FuseSensorsAnalytics'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wintersweet' => 'hudongdong@fuse.co.id' }
  s.source           = { :git => 'https://github.com/wintersweet/FuseSensorsAnalytics.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.default_subspec = 'Core'
  s.frameworks = 'Foundation', 'SystemConfiguration'
  
  s.libraries = 'icucore', 'sqlite3', 'z'

  s.subspec 'Base' do |b|
     core_dir = "FuseSensorsAnalytics/Core/"
     b.source_files = core_dir + "**/*.{h,m}"
     b.exclude_files = core_dir + "SAAlertController.h", core_dir + "SAAlertController.m"
     b.public_header_files = core_dir + "SensorsAnalyticsSDK.h", core_dir + "SensorsAnalyticsSDK+Public.h", core_dir + "SAAppExtensionDataManager.h", core_dir + "SASecurityPolicy.h", core_dir + "SAConfigOptions.h", core_dir + "SAConstants.h"
     b.ios.resource = 'FuseSensorsAnalytics/SensorsAnalyticsSDK.bundle'
     b.ios.frameworks = 'CoreTelephony'
   end

  s.subspec 'Extension' do |e|
     e.dependency 'FuseSensorsAnalytics/Base'
   end

  s.subspec 'Common' do |c|
    c.dependency 'FuseSensorsAnalytics/Extension'
    c.public_header_files = 'FuseSensorsAnalytics/JSBridge/SensorsAnalyticsSDK+JavaScriptBridge.h'
    c.source_files = 'FuseSensorsAnalytics/Core/SAAlertController.{h,m}', 'FuseSensorsAnalytics/JSBridge/**/*.{h,m}'
    c.ios.source_files = 'FuseSensorsAnalytics/RemoteConfig/**/*.{h,m}', 'FuseSensorsAnalytics/ChannelMatch/**/*.{h,m}', 'FuseSensorsAnalytics/Encrypt/**/*.{h,m}', 'FuseSensorsAnalytics/Deeplink/**/*.{h,m}', 'FuseSensorsAnalytics/DebugMode/**/*.{h,m}', 'FuseSensorsAnalytics/Core/SAAlertController.h'
    c.ios.public_header_files = 'FuseSensorsAnalytics/{Encrypt,RemoteConfig,ChannelMatch,Deeplink,DebugMode}/{SAConfigOptions,SensorsAnalyticsSDK}+*.h', 'FuseSensorsAnalytics/Encrypt/SAEncryptProtocol.h', 'FuseSensorsAnalytics/Encrypt/SASecretKey.h'
  end
   
   s.subspec 'Core' do |c|
     c.ios.dependency 'FuseSensorsAnalytics/Visualized'
     c.osx.dependency 'FuseSensorsAnalytics/Common'
   end

   # 支持 CAID 渠道匹配
   s.subspec 'CAID' do |f|
     f.ios.deployment_target = '9.0'
     f.dependency 'FuseSensorsAnalytics/Core'
     f.source_files = "FuseSensorsAnalytics/CAID/**/*.{h,m}"
     f.private_header_files = 'FuseSensorsAnalytics/CAID/**/*.h'
   end

   # 全埋点
   s.subspec 'AutoTrack' do |g|
     g.ios.deployment_target = '9.0'
     g.dependency 'FuseSensorsAnalytics/Common'
     g.source_files = "FuseSensorsAnalytics/AutoTrack/**/*.{h,m}"
     g.public_header_files = 'FuseSensorsAnalytics/AutoTrack/SensorsAnalyticsSDK+SAAutoTrack.h', 'FuseSensorsAnalytics/AutoTrack/SAConfigOptions+AutoTrack.h'
     g.frameworks = 'UIKit'
   end

 # 可视化相关功能，包含可视化全埋点和点击图
   s.subspec 'Visualized' do |f|
     f.ios.deployment_target = '9.0'
     f.dependency 'FuseSensorsAnalytics/AutoTrack'
     f.source_files = "FuseSensorsAnalytics/Visualized/**/*.{h,m}"
     f.public_header_files = 'FuseSensorsAnalytics/Visualized/SensorsAnalyticsSDK+Visualized.h', 'FuseSensorsAnalytics/Visualized/SAConfigOptions+Visualized.h'
   end

   # 开启 GPS 定位采集
   s.subspec 'Location' do |f|
     f.ios.deployment_target = '9.0'
     f.frameworks = 'CoreLocation'
     f.dependency 'FuseSensorsAnalytics/Core'
     f.source_files = "FuseSensorsAnalytics/Location/**/*.{h,m}"
     f.public_header_files = 'FuseSensorsAnalytics/Location/SensorsAnalyticsSDK+Location.h'
   end

   # 开启设备方向采集
   s.subspec 'DeviceOrientation' do |f|
     f.ios.deployment_target = '9.0'
     f.dependency 'FuseSensorsAnalytics/Core'
     f.source_files = 'FuseSensorsAnalytics/DeviceOrientation/**/*.{h,m}'
     f.public_header_files = 'FuseSensorsAnalytics/DeviceOrientation/SensorsAnalyticsSDK+DeviceOrientation.h'
     f.frameworks = 'CoreMotion'
   end

   # 推送点击
   s.subspec 'AppPush' do |f|
     f.ios.deployment_target = '9.0'
     f.dependency 'FuseSensorsAnalytics/Core'
     f.source_files = "FuseSensorsAnalytics/AppPush/**/*.{h,m}"
     f.public_header_files = 'FuseSensorsAnalytics/AppPush/SAConfigOptions+AppPush.h'
   end

   # 使用崩溃事件采集
   s.subspec 'Exception' do |e|
     e.ios.deployment_target = '9.0'
     e.dependency 'FuseSensorsAnalytics/Common'
     e.source_files  =  "FuseSensorsAnalytics/Exception/**/*.{h,m}"
     e.public_header_files = 'FuseSensorsAnalytics/Exception/SAConfigOptions+Exception.h'
   end

   # 基于 UA，使用 WKWebView 进行打通
   s.subspec 'WKWebView' do |w|
     w.ios.deployment_target = '9.0'
     w.dependency 'FuseSensorsAnalytics/Core'
     w.source_files  =  "FuseSensorsAnalytics/WKWebView/**/*.{h,m}"
     w.public_header_files = 'FuseSensorsAnalytics/WKWebView/SensorsAnalyticsSDK+WKWebView.h'
   end
  s.dependency 'XMNetworking'
  s.dependency 'SSZipArchive'
end
