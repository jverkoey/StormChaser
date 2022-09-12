//
//  AppDelegate+menu.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/11/22.
//

import Foundation
import UIKit

extension AppDelegate {

  override func buildMenu(with builder: UIMenuBuilder) {
    super.buildMenu(with: builder)

    builder.remove(menu: .format)

    /* File Menu */

    builder.remove(menu: .newScene)

    /* History Menu */

    var controlsChildren:[UIMenuElement] = []
    controlsChildren.append(UIKeyCommand(title: "Play", action: NSSelectorFromString("togglePlaybackOfSelectedItem:"), input:" ", modifierFlags:[]))

    let controlsMenu = UIMenu(title: "Controls", children: controlsChildren)

    builder.insertSibling(controlsMenu, afterMenu: .view)
  }

  
}
