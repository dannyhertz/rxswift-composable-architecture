Pod::Spec.new do |s|
  s.name             = 'ComposableArchitecture'
  s.version          = '0.8.6'
  s.summary          = 'A RxSwift fork of The Composable Architecture.'

  s.description      = <<-DESC
Point-Free’s The Composable Architecture uses Apple's Combine framework as the basis of its Effect type. Unfortunately, Combine is only available on iOS 13 and macOS 10.15 and above. In order to be able to use it with earlier versions of the OSes, this fork has adapted The Composable Architecture to use RxSwift as the basis for the Effect type. Much of this work was also inspired by the wonderful ReactiveSwift port of this project as well.
                       DESC

  s.homepage         = 'https://github.com/dannyhertz/rxswift-composable-architecture'
  s.author           = { 'Danny Hertz' => 'me@dannyhertz.com', 'David Cairns' => 'dcairns@butterflynetinc.com' }
  s.source           = { :git => 'https://github.com/dannyhertz/rxswift-composable-architecture.git', :tag => s.version.to_s }
  s.license          = { :type => 'MIT' }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.2'

  s.source_files = 'Sources/ComposableArchitecture/**/*.swift'

  s.dependency 'CasePaths'
  s.dependency 'Overture'
  s.dependency 'RxSwift', '~> 5.1.1'
  s.dependency 'RxRelay'
  s.xcconfig = { 'ENABLE_BITCODE' => 'NO' }
end

