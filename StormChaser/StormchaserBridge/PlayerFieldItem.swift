//
//  PlayerFieldItem.swift
//  StormchaserBridge
//
//  Created by Jeff Verkoeyen on 9/11/22.
//

import AppKit

@objc protocol PlayerViewDelegate: AnyObject {
  func playerView(_ playerView: AnyObject, didScrubToPosition position: Double)
  func playerView(_ playerView: AnyObject, didStopScrubbingAtPosition position: Double)
}

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
  weak var delegate: PlayerViewDelegate?

  let titleLabel = createLabel()
  let currentTimeLabel = createLabel()
  let durationLabel = createLabel()
  let waveformImageView = NSImageView()
  let progressLayoutConstraint: NSLayoutConstraint

  override init(frame frameRect: NSRect) {
    let progressViewBackground = NSView()
    progressViewBackground.translatesAutoresizingMaskIntoConstraints = false
    progressViewBackground.wantsLayer = true
    progressViewBackground.layer?.backgroundColor = NSColor(white: 0.4, alpha: 1).cgColor

    progressLayoutConstraint = progressViewBackground.widthAnchor.constraint(equalToConstant: 0)

    super.init(frame: frameRect)

    wantsLayer = true
    layer?.backgroundColor = NSColor(white: 0.3, alpha: 1).cgColor
    layer?.cornerRadius = 2

    waveformImageView.translatesAutoresizingMaskIntoConstraints = false
    waveformImageView.wantsLayer = true
    waveformImageView.layer?.compositingFilter = "differenceBlendMode"

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.stringValue = ""
    titleLabel.alignment = .center
    titleLabel.textColor = .init(white: 0.95, alpha: 1)
    titleLabel.font = NSFont.systemFont(ofSize: 10)

    currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
    currentTimeLabel.stringValue = ""
    currentTimeLabel.alignment = .left
    currentTimeLabel.textColor = .init(white: 0.7, alpha: 1)
    currentTimeLabel.font = NSFont.systemFont(ofSize: 10)

    durationLabel.translatesAutoresizingMaskIntoConstraints = false
    durationLabel.stringValue = ""
    durationLabel.alignment = .left
    durationLabel.textColor = .init(white: 0.7, alpha: 1)
    durationLabel.font = NSFont.systemFont(ofSize: 10)
    durationLabel.isHidden = true

    addSubview(progressViewBackground)
    addSubview(waveformImageView)
    addSubview(titleLabel)
    addSubview(currentTimeLabel)
    addSubview(durationLabel)

    let padding: CGFloat = 6
    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalToConstant: 600),
      heightAnchor.constraint(equalToConstant: 44),

      progressViewBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
      progressViewBackground.topAnchor.constraint(equalTo: topAnchor),
      progressViewBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
      progressLayoutConstraint,

      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),

      waveformImageView.topAnchor.constraint(equalTo: topAnchor),
      waveformImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      waveformImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      waveformImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

      currentTimeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
      currentTimeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),

      durationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
      durationLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
    ])
  }

  override func mouseDown(with event: NSEvent) {
    super.mouseDown(with: event)

    let position = convert(event.locationInWindow, from: nil)
    delegate?.playerView(self, didScrubToPosition: max(0, min(1, position.x / bounds.width)))
  }

  override func mouseDragged(with event: NSEvent) {
    super.mouseDragged(with: event)

    let position = convert(event.locationInWindow, from: nil)
    delegate?.playerView(self, didScrubToPosition: max(0, min(1, position.x / bounds.width)))
  }

  override func mouseUp(with event: NSEvent) {
    super.mouseUp(with: event)

    let position = convert(event.locationInWindow, from: nil)
    delegate?.playerView(self, didStopScrubbingAtPosition: max(0, min(1, position.x / bounds.width)))
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

final class PlayerFieldItem: NSToolbarItem, NSTextFieldDelegate {
  let playerView = PlayerView(frame: NSRect.zero)
  var loadedUrl: URL?

  override init(itemIdentifier: NSToolbarItem.Identifier) {
    super.init(itemIdentifier: itemIdentifier)

    self.view = playerView

    visibilityPriority = .high
  }

  @objc func setDelegate(_ delegate: PlayerViewDelegate?) {
    playerView.delegate = delegate
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
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .left
    playerView.currentTimeLabel.attributedStringValue = NSAttributedString(string: Utility.formatSecondsToHMS(currentTime), attributes: [
      .font: NSFont.systemFont(ofSize: 10),
      .paragraphStyle: paragraphStyle
    ])

    if duration.isNaN {
      playerView.durationLabel.isHidden = true
      playerView.progressLayoutConstraint.constant = 0
    } else {
      playerView.durationLabel.isHidden = false
      playerView.durationLabel.attributedStringValue = NSAttributedString(string: Utility.formatSecondsToHMS(duration), attributes: [
        .font: NSFont.systemFont(ofSize: 10),
        .paragraphStyle: paragraphStyle
      ])

      let progress = currentTime / duration
      playerView.progressLayoutConstraint.constant = 600 * progress
    }
  }

  @objc func set(mediaUrl url: URL?) {
    self.playerView.waveformImageView.isHidden = true
    loadedUrl = url
    if let url = url {
      let waveformImageDrawer = WaveformImageDrawer()
      let config = Waveform.Configuration(
        size: playerView.bounds.size,
        style: .filled(NSColor.init(white: 0.45, alpha: 1)),
        position: .top
      )
      waveformImageDrawer.waveformImage(fromAudioAt: url, with: config) { image in
        DispatchQueue.main.async {
          guard self.loadedUrl == url else {
            return
          }
          self.playerView.waveformImageView.image = image
          self.playerView.waveformImageView.isHidden = false
        }
      }
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
