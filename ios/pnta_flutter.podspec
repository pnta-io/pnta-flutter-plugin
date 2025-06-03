#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pnta_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pnta_flutter'
  s.version          = '1.0.0'
  s.summary          = 'Official PNTA Flutter plugin to make push notifications suck less.'
  s.description      = <<-DESC
A Flutter plugin for requesting push notification permissions and identifying devices on iOS and Android. Integrates with PNTA backend for device registration and metadata collection.
                       DESC
  s.homepage         = 'https://pnta.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'pnta.io' => 'support@pnta.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'pnta_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
