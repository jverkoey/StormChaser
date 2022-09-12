//
//  PlayerFieldItem.swift
//  StormchaserBridge
//
//  Created by Jeff Verkoeyen on 9/11/22.
//

import AppKit

class PlayerFieldItem: NSToolbarItem, NSTextFieldDelegate {
  override init(itemIdentifier: NSToolbarItem.Identifier) {
    super.init(itemIdentifier: itemIdentifier)

    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.red.cgColor
    NSLayoutConstraint.activate([
      view.widthAnchor.constraint(equalToConstant: 100),
      view.heightAnchor.constraint(equalToConstant: 25),
    ])
    self.view = view
    
    visibilityPriority = .high
  }
}
