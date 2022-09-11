//
//  SceneDelegate.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import UniformTypeIdentifiers
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  var sidebar: SidebarViewController!
  var playlistController: PlaylistViewController!

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
  }
}

extension NSToolbarItem.Identifier {
  static let play = NSToolbarItem.Identifier(rawValue: "com.hurricane.play")
}

extension SceneDelegate: NSToolbarDelegate {
  func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
    let item = NSToolbarItem(itemIdentifier: itemIdentifier)
    if itemIdentifier == NSToolbarItem.Identifier.play {
      item.image = UIImage(systemName: "play.fill")
    }
    return item
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [NSToolbarItem.Identifier.play]
  }

  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [NSToolbarItem.Identifier.play]
  }
}

extension SceneDelegate: SidebarViewControllerDelegate {
  func sidebarViewController(_ sidebarViewController: SidebarViewController, didSelectPlaylist playlist: Playlist) {
    playlistController.playlist = playlist
  }
}

