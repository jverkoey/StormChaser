//
//  PlayerFieldItem.swift
//  StormchaserBridge
//
//  Created by Jeff Verkoeyen on 9/11/22.
//

import AppKit

class PlayerFieldItem: NSToolbarItem, NSTextFieldDelegate {
  let titleLabel = NSTextField()

  override init(itemIdentifier: NSToolbarItem.Identifier) {
    super.init(itemIdentifier: itemIdentifier)

    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.darkGray.cgColor
    view.layer?.cornerRadius = 2

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.stringValue = ""
    titleLabel.alignment = .center
    titleLabel.maximumNumberOfLines = 1
    titleLabel.cell?.truncatesLastVisibleLine = true
    titleLabel.backgroundColor = nil
    titleLabel.textColor = .init(white: 0.95, alpha: 1)
    titleLabel.isBezeled = false
    titleLabel.isEditable = false
    titleLabel.font = NSFont.systemFont(ofSize: 10)
    view.addSubview(titleLabel)

    let padding: CGFloat = 6
    NSLayoutConstraint.activate([
      view.widthAnchor.constraint(equalToConstant: 600),
      view.heightAnchor.constraint(equalToConstant: 44),

      titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
      titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
      titleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding),
    ])
    self.view = view

    visibilityPriority = .high
  }

  @objc func setTrackTitle(_ string: String) {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    titleLabel.attributedStringValue = NSAttributedString(string: string, attributes: [
      .font: NSFont.systemFont(ofSize: 12),
      .paragraphStyle: paragraphStyle
    ])
  }
}
