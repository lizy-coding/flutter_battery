Pod::Spec.new do |s|
  s.name             = 'flutter_battery'
  s.version          = '0.0.1'
  s.summary          = 'Flutter battery plugin macOS implementation'
  s.description      = 'A Flutter plugin for battery monitoring on macOS.'
  s.homepage         = 'https://github.com/yourorg/flutter_battery'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'flutter_battery/Classes/**/*'
  s.public_header_files = 'flutter_battery/Classes/**/*.h'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '5.0',
  }
  s.swift_version = '5.0'
end
