#
# Be sure to run `pod lib lint NasAPI.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NasAPI'
  s.version          = '0.4.0'
  s.summary          = 'API wrapper for the NASA API'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
NasAPI-Swift is an in development Nasa API wrapper.
                       DESC

  s.homepage         = 'https://github.com/MrLotu/NasAPI'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'MrLotu' => 'j.koopman@jarict.nl' }
  s.source           = { :git => 'https://github.com/MrLotu/NasAPI-Swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/LotUDev'

  s.ios.deployment_target = '8.0'

  s.source_files = 'NasAPI/Classes/**/*'
  
  # s.resource_bundles = {
  #   'NasAPI' => ['NasAPI/Assets/*.png']
  # }
  s.dependency 'Alamofire', '~> 4.5'
  s.dependency 'SwiftyJSON'
  s.dependency 'AlamofireImage', '~> 3.3'
end
