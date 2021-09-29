Pod::Spec.new do |s|
  s.name             = 'TutuComposableArchitecture'
  s.version          = '0.7.7'
  s.summary          = 'A RxSwift fork of The Composable Architecture.'

  s.description      = <<-DESC
Point-Free’s The Composable Architecture uses Apple's Combine framework as the basis of its Effect type. Unfortunately, Combine is only available on iOS 13 and macOS 10.15 and above. In order to be able to use it with earlier versions of the OSes, this fork has adapted The Composable Architecture to use RxSwift as the basis for the Effect type. Much of this work was also inspired by the wonderful ReactiveSwift port of this project as well.
                       DESC

  s.homepage         = 'git@github.com:tutu-ru-mobile/rxswift-composable-architecture.git'
  s.author           = { 'Sukhanov Evgeny' => 'sukhanovee@tutu.tech' }
  s.source           = { :git => 'git@github.com:tutu-ru-mobile/rxswift-composable-architecture.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.1'
  s.swift_version = '5.4'
  s.default_subspecs = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'Sources/*.swift',
      'Sources/Effects/*.swift',
      'Sources/Helpers/*.swift',
      'Sources/Internal/*.swift',
      'Sources/UIKit/*.swift',
      'Sources/Debugging/*.swift'

    core.dependency 'CasePaths'
    core.dependency 'Overture'
    core.dependency 'RxSwift'
    core.dependency 'RxRelay'
  end

  s.subspec 'Debug' do |debug|
    debug.source_files = 'Sources/Debugging/*.swift'
    debug.dependency 'ComposableArchitecture/Core'
  end

  s.subspec 'Test' do |test|
    test.source_files = 'Sources/Testing/*.swift',
      'Sources/Debugging/*.swift'

    test.dependency 'ComposableArchitecture/Core'
    test.dependency 'RxTest'

    test.frameworks = "XCTest"
    test.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
  end
end

