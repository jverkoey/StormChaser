//
//  TextFieldContentView.swift
//  StormChaser
//
//  Created by Jeff Verkoeyen on 9/20/22.
//

import Foundation
import UIKit

extension UIView {
  fileprivate func addPinnedSubview(_ subview: UIView, height: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)) {
    addSubview(subview)
    subview.translatesAutoresizingMaskIntoConstraints = false
    subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top).isActive = true
    subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left).isActive = true
    subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1.0 * insets.right).isActive = true
    subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1.0 * insets.bottom).isActive = true
    if let height = height {
      subview.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
  }
}

final class TextFieldContentView: UIView, UIContentView {
  struct Configuration: UIContentConfiguration {
    var text: String? = ""

    func makeContentView() -> UIView & UIContentView {
      return TextFieldContentView(self)
    }

    func updated(for state: UIConfigurationState) -> Self {
      return self
    }
  }

  let textField = UITextField()
  var configuration: UIContentConfiguration {
    didSet {
      configure(configuration: configuration)
    }
  }
  override var intrinsicContentSize: CGSize {
    CGSize(width: 0, height: 44)
  }

  init(_ configuration: UIContentConfiguration) {
    self.configuration = configuration
    super.init(frame: .zero)
    addPinnedSubview(textField, insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
    textField.clearButtonMode = .whileEditing
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(configuration: UIContentConfiguration) {
    guard let configuration = configuration as? Configuration else { return }
    textField.text = configuration.text
  }
}

extension UITableViewCell {
  func textFieldConfiguration() -> TextFieldContentView.Configuration {
    TextFieldContentView.Configuration()
  }
}
