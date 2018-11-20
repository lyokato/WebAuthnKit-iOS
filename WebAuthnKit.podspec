Pod::Spec.new do |s|
  s.name         = "WebAuthnKit"
  s.version      = "0.0.1"
  s.summary      = "WebAuthn Client and Authenticator Support Library"

  s.description  = <<-DESC
                   DESC

  s.homepage     = "https://github.com/lyokato/WebAuthnKit"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author = { "lyokato" => "lyo.kato@gmail.com" }
  s.social_media_url = "http://twitter.com/lyokato"

  s.platform = :ios, "10.0"
  s.source = { :git => "https://github.com/lyokato/WebAuthnKit.git", :tag => "#{s.version}" }

  s.source_files  = "WebAuthnKit/Sources/**/*.swift"
  s.public_header_files = "WebAuthnKit/Headers/**/*.h"

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"

  s.framework  = "Foundation", "UIKit", "CoreBluetooth"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"

  # s.requires_arc = true
  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  s.dependency "PromiseKit", "~> 6.0"
  s.dependency "EllipticCurveKeyPair", "~> 2.0-beta1"
  s.dependency "KeychainAccess", "~> 3.1.2"
  s.dependency "CryptoSwift", "~> 0.13.0"
  s.dependency "SwiftyRSA", "~> 1.5.0"

  s.swift_version = "4.2"

end
