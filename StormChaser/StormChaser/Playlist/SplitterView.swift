//
//  File.swift
//  StormChaser
//
//  Created by Jeff Verkoeyen on 9/20/22.
//

import Foundation
import UIKit

protocol SplitterViewDelegate: AnyObject {
  func splitterView(_ splitterView: SplitterView, didTranslate offset: CGFloat)
}

final class SplitterView: UIView {
  weak var delegate: SplitterViewDelegate?

  private let fillView = UIView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .systemBackground

    fillView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(fillView)
    fillView.backgroundColor = .black

    let hover = UIHoverGestureRecognizer(target: self, action: #selector(self.hoverStateDidChange(_:)))
    addGestureRecognizer(hover)

    NSLayoutConstraint.activate([
      fillView.topAnchor.constraint(equalTo: topAnchor),
      fillView.bottomAnchor.constraint(equalTo: bottomAnchor),
      fillView.centerXAnchor.constraint(equalTo: centerXAnchor),
      fillView.widthAnchor.constraint(equalToConstant: 1),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: 5, height: UIView.noIntrinsicMetric)
  }

  @objc private func hoverStateDidChange(_ gestureRecognizer: UIHoverGestureRecognizer) {
    switch gestureRecognizer.state {
    case .began, .changed:
      NSCursor.resizeLeftRight.set()
    case .possible, .ended, .cancelled, .failed:
      NSCursor.arrow.set()
    @unknown default:
      NSCursor.arrow.set()
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)

    precondition(touches.count == 1)

    let touch = touches.first!
    let delta = touch.location(in: self).x - touch.previousLocation(in: self).x
    delegate?.splitterView(self, didTranslate: delta)
  }
}
