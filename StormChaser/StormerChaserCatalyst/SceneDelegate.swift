//
//  SceneDelegate.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import UniformTypeIdentifiers
import UIKit


extension NSToolbarItem {
  @objc func setTrackTitle(_ string: String) {

  }
}


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  var sidebar: SidebarViewController!
  var playlistController: PlaylistViewController!

#if targetEnvironment(macCatalyst)
  var playerFieldItem: NSToolbarItem?
#endif

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    let model = Model()
    if let modelBookmark = UserDefaults.standard.data(forKey: UserDefaults.modelKey) {
      var isStale = false
      let url = try! URL(resolvingBookmarkData: modelBookmark, bookmarkDataIsStale: &isStale)
      if !isStale {
        if url.startAccessingSecurityScopedResource() {
          model.url = url
          url.stopAccessingSecurityScopedResource()
        }
      }
    }

    let window = UIWindow(windowScene: windowScene)
    let splitViewController = UISplitViewController(style: .doubleColumn)
    splitViewController.primaryBackgroundStyle = .sidebar
    splitViewController.preferredDisplayMode = .oneBesideSecondary
    splitViewController.preferredSplitBehavior = .tile
    splitViewController.displayModeButtonVisibility = .never

    sidebar = SidebarViewController(model: model)
    sidebar.delegate = self
    splitViewController.setViewController(sidebar, for: .primary)

    playlistController = PlaylistViewController(model: model)
    playlistController.delegate = self
    splitViewController.setViewController(playlistController, for: .secondary)

    let toolbar = NSToolbar(identifier: "main")
    toolbar.displayMode = .iconOnly
    toolbar.delegate = self

    if let titlebar = windowScene.titlebar {
      titlebar.toolbar = toolbar
      titlebar.toolbarStyle = .unified
      titlebar.titleVisibility = .hidden
    }

    window.rootViewController = splitViewController
    window.makeKeyAndVisible()

    self.window = window

    if let frameworksPath = Bundle.main.privateFrameworksPath {
      let bundlePath = "\(frameworksPath)/StormchaserBridge.framework"
      do {
        try Bundle(path: bundlePath)?.loadAndReturnError()

        _ = Bundle(path: bundlePath)!
        NSLog("[APPKIT BUNDLE] Loaded Successfully")

        if let statusItemClass = NSClassFromString("StormchaserBridge.PlayerFieldItem") as? NSToolbarItem.Type {
          playerFieldItem = statusItemClass.init(itemIdentifier: .player)
        }
      }
      catch {
        NSLog("[APPKIT BUNDLE] Error loading: \(error)")
      }
    }
  }
}

extension NSToolbarItem.Identifier {
  static let play = NSToolbarItem.Identifier(rawValue: "com.hurricane.play")
  static let player = NSToolbarItem.Identifier(rawValue: "com.hurricane.player")
}

extension SceneDelegate: NSToolbarDelegate {
  func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
    if itemIdentifier == NSToolbarItem.Identifier.player {
      return playerFieldItem
    }
    let item = NSToolbarItem(itemIdentifier: itemIdentifier)
    if itemIdentifier == NSToolbarItem.Identifier.play {
      item.image = UIImage(systemName: "play.fill")
      item.action = NSSelectorFromString("playSelectedItem:")
    }
    return item
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [
      NSToolbarItem.Identifier.play,
      NSToolbarItem.Identifier.flexibleSpace,
      NSToolbarItem.Identifier.player
    ]
  }

  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [
      NSToolbarItem.Identifier.play,
      NSToolbarItem.Identifier.flexibleSpace,
      NSToolbarItem.Identifier.player,
      NSToolbarItem.Identifier.flexibleSpace
    ]
  }
}

extension SceneDelegate: SidebarViewControllerDelegate {
  func sidebarViewController(_ sidebarViewController: SidebarViewController, didSelectPlaylist playlist: Playlist) {
    playlistController.playlist = playlist
  }
}

extension SceneDelegate: PlaylistViewControllerDelegate {
  func playlistViewController(_ playlistViewController: PlaylistViewController, playMediaItem mediaItem: MediaItem) {
    playerFieldItem?.setTrackTitle(mediaItem.title)
  }
}
