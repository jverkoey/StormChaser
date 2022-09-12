//
//  PlayerFieldItem.swift
//  StormchaserBridge
//
//  Created by Jeff Verkoeyen on 9/11/22.
//

import AppKit

final class PlayerView: NSView {
  let titleLabel = NSTextField()

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    wantsLayer = true
    layer?.backgroundColor = NSColor.darkGray.cgColor
    layer?.cornerRadius = 2

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
    addSubview(titleLabel)

    let padding: CGFloat = 6
    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalToConstant: 600),
      heightAnchor.constraint(equalToConstant: 44),

      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

final class PlayerFieldItem: NSToolbarItem, NSTextFieldDelegate {
  let playerView = PlayerView(frame: NSRect.zero)

  override init(itemIdentifier: NSToolbarItem.Identifier) {
    super.init(itemIdentifier: itemIdentifier)

    self.view = playerView

    visibilityPriority = .high
  }

  @objc func setTrackTitle(_ string: String) {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    playerView.titleLabel.attributedStringValue = NSAttributedString(string: string, attributes: [
      .font: NSFont.systemFont(ofSize: 12),
      .paragraphStyle: paragraphStyle
    ])
  }
}
