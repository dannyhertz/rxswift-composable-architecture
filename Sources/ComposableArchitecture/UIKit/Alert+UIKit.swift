//
//  File.swift
//
//
//  Created by Danny Hertz on 7/15/20.
//

#if canImport(UIKit)
  import Foundation
  import UIKit

  extension AlertState.Button {
    func toUIKit(send: @escaping (Action) -> Void) -> UIAlertAction {
      let action = { if let action = self.action { send(action) } }
      switch self.type {
      case let .cancel(.some(label)):
        return .init(title: label, style: .cancel, handler: { _ in action() })
      case .cancel(.none):
        return .init(title: nil, style: .cancel, handler: { _ in action() })
      case let .default(label):
        return .init(title: label, style: .default, handler: { _ in action() })
      case let .destructive(label):
        return .init(title: label, style: .destructive, handler: { _ in action() })
      }
    }
  }

  extension AlertState {
    func toUIKit(send: @escaping (Action) -> Void) -> UIAlertController {
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

      if let primaryButton = primaryButton {
        alert.addAction(primaryButton.toUIKit(send: send))
      }
      if let secondaryButton = secondaryButton {
        alert.addAction(secondaryButton.toUIKit(send: send))
      }

      return alert
    }
  }

  extension UIAlertController {
    public static func alert<Action>(_ alert: AlertState<Action>, send: @escaping (Action) -> Void)
      -> UIAlertController
    {
      return alert.toUIKit(send: send)
    }
  }
#endif
