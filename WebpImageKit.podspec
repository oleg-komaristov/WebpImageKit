Pod::Spec.new do |s|
  s.name             = 'WebpImageKit'
  s.version          = '0.3.2'
  s.summary          = 'ObjC wrapper to WebP encoder/decoder from WebM Project.'
  s.description      = <<-DESC
  Provides WebP format support starting iOS 12, including encoding and decoding of animated WebP images.
  Only operates with image data located in memory.
                       DESC
  s.homepage         = 'https://github.com/oleg-komaristov/WebpImageKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Oleg Komaristov' => 'oleg.komaristov@gmail.com' }
  s.source           = { :git => 'https://github.com/oleg-komaristov/WebpImageKit.git', :tag => s.version.to_s }
  s.ios.deployment_target = '12.0'
  s.source_files = 'WebpImageKit/**/*'
  s.public_header_files = 'WebpImageKit/*.h'
  s.frameworks = 'UIKit', 'Accelerate'
  s.dependency 'libwebp', '~> 1.0'
end
