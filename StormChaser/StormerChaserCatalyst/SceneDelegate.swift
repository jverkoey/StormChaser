//
//  SceneDelegate.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import AVKit
import UniformTypeIdentifiers
import UIKit

@objc protocol PlayerViewDelegate: AnyObject {
  func playerView(_ playerView: AnyObject, didScrubToPosition position: Double)
  func playerView(_ playerView: AnyObject, didStopScrubbingAtPosition position: Double)
}

extension NSToolbarItem {
  @objc func setTrackTitle(_ string: String) { fatalError("Unhandled") }
  @objc func set(currentTime: TimeInterval, duration: TimeInterval) { fatalError("Unhandled") }
  @objc func set(mediaUrl url: URL?) { fatalError("Unhandled") }
  @objc func setDelegate(_ delegate: PlayerViewDelegate?) { fatalError("Unhandled") }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  var sidebar: SidebarViewController!
  var playlistController: PlaylistViewController!

  let audioPlayer = AVPlayer()
  var loadedUrl: URL?

#if targetEnvironment(macCatalyst)
  var playerFieldItem: NSToolbarItem?
#endif
  let playPauseItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier.play)

  let model = Model()

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    audioPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      guard let strongSelf = self else {
        return
      }
      let duration = strongSelf.audioPlayer.currentItem!.duration.seconds
      strongSelf.playerFieldItem?.set(currentTime: time.seconds, duration: duration)
    }

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
          playerFieldItem?.setDelegate(self)
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
    if itemIdentifier == playPauseItem.itemIdentifier {
      playPauseItem.image = UIImage(systemName: "play.fill")
      playPauseItem.action = NSSelectorFromString("togglePlaybackOfSelectedItem:")
      return playPauseItem
    }
    return nil
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
  private func updatePlayer(with mediaItem: MediaItem) {
    playerFieldItem?.setTrackTitle(mediaItem.title)
    playerFieldItem?.set(mediaUrl: mediaItem.url)
  }

  private func updatePlaybackState() {
    print(audioPlayer.timeControlStatus.rawValue)
    playPauseItem.image = (audioPlayer.timeControlStatus == .playing
                           || audioPlayer.timeControlStatus == .waitingToPlayAtSpecifiedRate)
    ? UIImage(systemName: "pause.fill")
    : UIImage(systemName: "play.fill")
  }

  private func loadAndPlay(mediaItem: MediaItem) {
    updatePlayer(with: mediaItem)

    loadedUrl = mediaItem.url

    // Playing a new file
    audioPlayer.pause()

    if let url = mediaItem.url {
      let playerItem = AVPlayerItem(url: url)
      audioPlayer.replaceCurrentItem(with: playerItem)
      audioPlayer.play()
    }
    updatePlaybackState()
  }

  func playlistViewController(_ playlistViewController: PlaylistViewController, didChangePlaylist playlist: Playlist, name: String) {
    model.setPlaylist(playlist, name: name)

    sidebar.applySnapshot(animated: false)
  }

  func playlistViewController(_ playlistViewController: PlaylistViewController, togglePlaybackOfMediaItem mediaItem: MediaItem) {
    if loadedUrl == nil {
      loadAndPlay(mediaItem: mediaItem)
      return
    }
    if audioPlayer.timeControlStatus == .playing {
      audioPlayer.pause()
    } else {
      audioPlayer.play()
    }
    updatePlaybackState()
  }

  func playlistViewController(_ playlistViewController: PlaylistViewController, playMediaItem mediaItem: MediaItem) {
    updatePlayer(with: mediaItem)

    if loadedUrl == mediaItem.url {
      let targetTime = CMTime(seconds: 0, preferredTimescale: 600)
      audioPlayer.seek(to: targetTime)
      if audioPlayer.timeControlStatus != .playing {
        audioPlayer.play()
      }
      updatePlaybackState()
      return
    }

    loadAndPlay(mediaItem: mediaItem)
  }

  func playlistViewControllerIsMediaPlaying(_ playlistViewController: PlaylistViewController) -> Bool {
    return audioPlayer.timeControlStatus == .playing
  }
}

extension SceneDelegate: PlayerViewDelegate {
  func playerView(_ playerView: AnyObject, didScrubToPosition position: Double) {
    let duration = audioPlayer.currentItem!.duration.seconds
    let targetTime = CMTime(seconds: position * duration, preferredTimescale: 600)
    audioPlayer.seek(to: targetTime)
  }

  func playerView(_ playerView: AnyObject, didStopScrubbingAtPosition position: Double) {
//    audioPlayer.play()
  }
}
