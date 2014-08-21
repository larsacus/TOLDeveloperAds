Pod::Spec.new do |s|
  s.name = 'TOLDeveloperAds'
  s.version = '0.0.1'
  s.summary = 'Create beautiful, simple ads for your apps that link directly to the app store.'
  s.description = 'Create beautiful, simple ads for your apps that link directly to the app store via a native interface.'
  s.homepage = 'https://github.com/larsacus/TOLDeveloperAds/'
  s.author = {
    'Lars Anderson' => 'iAm@theonlylars.com'
  }
  s.source = {
    :git => 'git@github.com:larsacus/TOLDeveloperAds.git',
    :tag => s.version.to_s
  }
  s.platform = :ios, 6.0
  s.license = 'MIT'
  s.requires_arc = true
  s.frameworks = 'CoreGraphics', 'StoreKit'
  s.dependency 'LARSAdController', '~>3.0'
end