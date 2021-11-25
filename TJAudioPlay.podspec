#
# Be sure to run `pod lib lint TJAudioPlay.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TJAudioPlay'
  s.version          = '0.1.0'
  s.summary          = 'A short description of TJAudioPlay.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/supersunS/TJAudioPlay'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'SuperSun' => 'sundaoran@tojoy.com' }
  s.source           = { :git => 'https://github.com/supersunS/TJAudioPlay.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  
  s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'TJAudioPlay/Classes/**/*'
  s.resource_bundles = {
     'TJAudioPlay' => ['TJAudioPlay/Assets/*.png']
  }
  s.dependency 'SDWebImage'
  s.dependency 'StreamingKit'
end
