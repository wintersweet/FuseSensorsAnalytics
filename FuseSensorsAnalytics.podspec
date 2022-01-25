#
# Be sure to run `pod lib lint FuseSensorsAnalytics.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FuseSensorsAnalytics'
  s.version          = '1.0.1'
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

  s.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/SensorsAnalyticsExtension.h'
  
  s.subspec 'AppPush' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/AppPush/*'
   end
  s.subspec 'AutoTrack' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/AutoTrack/*'
   end
  s.subspec 'CAID' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/CAID/*'
   end
  s.subspec 'ChannelMatch' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/ChannelMatch/*'
   end
  s.subspec 'Core' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/Core/*'
   end
  s.subspec 'DebugMode' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/DebugMode/*'
   end
  
  s.subspec 'ChannelMatch' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/ChannelMatch/*'
   end
  s.subspec 'Core' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/Core/*'
   end
  s.subspec 'DebugMode' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/DebugMode/*'
   end
  
  s.subspec 'Deeplink' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/Deeplink/*'
   end
  s.subspec 'DeviceOrientation' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/DeviceOrientation/*'
   end
  s.subspec 'Encrypt' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/Encrypt/*'
   end
  
  s.subspec 'Exception' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/Exception/*'
   end
  s.subspec 'JSBridge' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/JSBridge/*'
   end
  s.subspec 'Location' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/Location/*'
   end
  
  s.subspec 'RemoteConfig' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/RemoteConfig/*'
   end
  s.subspec 'Visualized' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/Visualized/*'
   end
  s.subspec 'WKWebView' do |ss|
     ss.source_files = 'FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/WKWebView/*'
   end
  
  
  
  s.resource_bundles = {
    'FuseSensorsAnalytics' => ['FuseSensorsAnalytics/Classes/SensorsAnalyticsSDK/*.bundle']
   }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'XMNetworking'
  s.dependency 'SSZipArchive'
end
