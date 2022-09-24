//
//  WorkspaceCompatibility.swift
//  StormchaserBridge
//
//  Created by Jeff Verkoeyen on 9/23/22.
//

import AppKit
import Foundation

final class WorkspaceCompatibility {
  @objc class func showInFinder(_ urls: [URL]) {
    NSWorkspace.shared.activateFileViewerSelecting(urls)
  }
}
