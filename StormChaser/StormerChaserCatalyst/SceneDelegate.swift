//
//  SceneDelegate.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
    // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
    // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
    guard let windowScene = (scene as? UIWindowScene) else { return }

    let window = UIWindow(windowScene: windowScene)
    let splitViewController = UISplitViewController(style: .doubleColumn)
    splitViewController.primaryBackgroundStyle = .sidebar
    splitViewController.preferredDisplayMode = .oneBesideSecondary
    splitViewController.preferredSplitBehavior = .tile
    splitViewController.displayModeButtonVisibility = .never

    splitViewController.setViewController(SidebarViewController(), for: .primary)
    splitViewController.setViewController(ViewController(), for: .secondary)

    let toolbar = NSToolbar(identifier: "main")
    toolbar.displayMode = .iconOnly

    if let titlebar = windowScene.titlebar {
      titlebar.toolbar = toolbar
      titlebar.toolbarStyle = .automatic
    }

    window.rootViewController = splitViewController
    window.makeKeyAndVisible()
    self.window = window
  }
}

