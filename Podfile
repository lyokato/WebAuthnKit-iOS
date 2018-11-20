# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'WebAuthnKitDemo' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod "PromiseKit", "~> 6.3.4"
  pod "EllipticCurveKeyPair", "~> 2.0-beta1"
  pod "KeychainAccess", "~> 3.1.2"
  pod "CryptoSwift", "~> 0.13.0"
  pod "SwiftyRSA", "~> 1.5.0"

  # Pods for WebAuthnKitDemo

  target 'WebAuthnKit' do
    inherit! :search_paths
    pod "PromiseKit", "~> 6.3.4"
    pod "EllipticCurveKeyPair", "~> 2.0-beta1"
    pod "KeychainAccess", "~> 3.1.2"
    pod "CryptoSwift", "~> 0.13.0"
    pod "SwiftyRSA", "~> 1.5.0"
  end

  target 'WebAuthnKitTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
