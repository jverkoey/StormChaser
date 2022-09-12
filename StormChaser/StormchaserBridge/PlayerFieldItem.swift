//
//  PlayerFieldItem.swift
//  StormchaserBridge
//
//  Created by Jeff Verkoeyen on 9/11/22.
//

import AppKit

private func createLabel() -> NSTextField {
  let textField = NSTextField()
  textField.maximumNumberOfLines = 1
  textField.cell?.truncatesLastVisibleLine = true
  textField.backgroundColor = nil
  textField.isBezeled = false
  textField.isEditable = false
  return textField
}

final class PlayerView: NSView {
  let titleLabel = createLabel()
  let durationLabel = createLabel()

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    wantsLayer = true
    layer?.backgroundColor = NSColor(white: 0.3, alpha: 1).cgColor
    layer?.cornerRadius = 2

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.stringValue = ""
    titleLabel.alignment = .center
    titleLabel.textColor = .init(white: 0.95, alpha: 1)
    titleLabel.font = NSFont.systemFont(ofSize: 10)
    addSubview(titleLabel)

    durationLabel.translatesAutoresizingMaskIntoConstraints = false
    durationLabel.stringValue = ""
    durationLabel.alignment = .left
    durationLabel.textColor = .init(white: 0.6, alpha: 1)
    durationLabel.font = NSFont.systemFont(ofSize: 10)
    durationLabel.isHidden = true
    addSubview(durationLabel)

    let progressViewBackground = NSView()
    progressViewBackground.translatesAutoresizingMaskIntoConstraints = false
    progressViewBackground.wantsLayer = true
    progressViewBackground.layer?.backgroundColor = NSColor(white: 0.4, alpha: 1).cgColor
    addSubview(progressViewBackground)

    let padding: CGFloat = 6
    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalToConstant: 600),
      heightAnchor.constraint(equalToConstant: 44),

      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
      titleLabel.bottomAnchor.constraint(equalTo: progressViewBackground.bottomAnchor, constant: -padding),

      durationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
      durationLabel.bottomAnchor.constraint(equalTo: progressViewBackground.topAnchor, constant: -8),

      progressViewBackground.heightAnchor.constraint(equalToConstant: 3),
      progressViewBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
      progressViewBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
      progressViewBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
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

  @objc func set(currentTime: TimeInterval, duration: TimeInterval) {
    if duration.isNaN {
      playerView.durationLabel.isHidden = true
    } else {
      playerView.durationLabel.isHidden = false
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .left
      playerView.durationLabel.attributedStringValue = NSAttributedString(string: Utility.formatSecondsToHMS(duration), attributes: [
        .font: NSFont.systemFont(ofSize: 10),
        .paragraphStyle: paragraphStyle
      ])
    }
  }
}

private enum Utility {
  static func formatSecondsToHMS(_ seconds: TimeInterval) -> String {
    let secondsInt:Int = Int(seconds.rounded(.towardZero))

    let dh: Int = (secondsInt/3600)
    let dm: Int = (secondsInt - (dh*3600))/60
    let ds: Int = secondsInt - (dh*3600) - (dm*60)

    let hs = "\(dh > 0 ? "\(dh):" : "")"
    let ms = "\(dm<10 ? "0" : "")\(dm):"
    let s = "\(ds<10 ? "0" : "")\(ds)"

    return hs + ms + s
  }
}
