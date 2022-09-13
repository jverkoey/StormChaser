//
//  ViewController.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import UIKit

protocol PlaylistViewControllerDelegate: AnyObject {
  func playlistViewController(_ playlistViewController: PlaylistViewController, togglePlaybackOfMediaItem mediaItem: MediaItem)
  func playlistViewController(_ playlistViewController: PlaylistViewController, playMediaItem mediaItem: MediaItem)
  func playlistViewControllerIsMediaPlaying(_ playlistViewController: PlaylistViewController) -> Bool
}

final class PlaylistViewController: UIViewController {
  weak var delegate: PlaylistViewControllerDelegate?

  let playlistInfoViewController = PlaylistInfoViewController()
  let infoPaneViewController = InfoPaneViewController()

  let model: Model
  init(model: Model) {
    self.model = model

    super.init(nibName: nil, bundle: nil)

    addChild(playlistInfoViewController)
    addChild(infoPaneViewController)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var playlist: Playlist? {
    didSet {
      if let playlist = playlist {
        items = model.items(in: playlist)
        if let selectedItems = collectionView.indexPathsForSelectedItems {
          for indexPath in selectedItems {
            collectionView.deselectItem(at: indexPath, animated: false)
          }
        }
      } else {
        items = nil
      }
    }
  }
  var items: [MediaItem]? {
    didSet {
      if items != nil {
        applySnapshot(animated: false)
      }
    }
  }

  var collectionView: UICollectionView!
  typealias DiffableDataSource = UICollectionViewDiffableDataSource<String, MediaItem>
  var dataSource: DiffableDataSource!

  override func viewDidLoad() {
    super.viewDidLoad()

    let config = UICollectionLayoutListConfiguration(appearance: .plain)
    let layout = UICollectionViewCompositionalLayout.list(using: config)
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
    collectionView.delegate = self
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.selectionFollowsFocus = true

    playlistInfoViewController.view.translatesAutoresizingMaskIntoConstraints = false
    infoPaneViewController.view.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(playlistInfoViewController.view)
    view.addSubview(collectionView)
    view.addSubview(infoPaneViewController.view)

    playlistInfoViewController.didMove(toParent: self)
    infoPaneViewController.didMove(toParent: self)

    NSLayoutConstraint.activate([
      playlistInfoViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      playlistInfoViewController.view.heightAnchor.constraint(equalToConstant: 400),

      collectionView.topAnchor.constraint(equalTo: playlistInfoViewController.view.bottomAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

      playlistInfoViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      playlistInfoViewController.view.trailingAnchor.constraint(equalTo: infoPaneViewController.view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: infoPaneViewController.view.leadingAnchor),
      infoPaneViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      infoPaneViewController.view.widthAnchor.constraint(equalToConstant: 350),

      infoPaneViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      infoPaneViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])

    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, MediaItem> { (cell, indexPath, item) in
      var content = UIListContentConfiguration.valueCell()
      content.text = item.title
      content.secondaryText = item.grouping
      cell.contentConfiguration = content
    }

    dataSource = DiffableDataSource(collectionView: collectionView) { (collectionView, indexPath, node) -> UICollectionViewCell? in
      return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: node)
    }

    collectionView.dataSource = dataSource

    if model.url != nil {
      applySnapshot(animated: false)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

#if targetEnvironment(macCatalyst)
    navigationController?.setNavigationBarHidden(true, animated: animated)
#endif
  }

  func applySnapshot(animated: Bool) {
    guard let items = items else {
      return
    }
    var snapshot = NSDiffableDataSourceSectionSnapshot<MediaItem>()
    snapshot.append(items)
    dataSource.apply(snapshot, to: "", animatingDifferences: animated)
  }

  // MARK: - Actions

  @objc func togglePlaybackOfSelectedItem(_ sender: Any) {
    if let indexPath = collectionView.indexPathsForSelectedItems?.first {
      let mediaItem = dataSource.itemIdentifier(for: indexPath)!
      delegate?.playlistViewController(self, togglePlaybackOfMediaItem: mediaItem)
    }
  }

  @objc func playSelectedItem(_ sender: Any) {
    if let indexPath = collectionView.indexPathsForSelectedItems?.first {
      let mediaItem = dataSource.itemIdentifier(for: indexPath)!
      delegate?.playlistViewController(self, playMediaItem: mediaItem)
    }
  }

  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(togglePlaybackOfSelectedItem(_:)) || action == #selector(playSelectedItem(_:)) {
      // TODO: togglePlaybackOfSelectedItem should technically just check if an item is loaded at all.
      return collectionView.indexPathsForSelectedItems?.first != nil
    }
    return super.canPerformAction(action, withSender: sender)
  }

  override func validate(_ command: UICommand) {
    super.validate(command)

    if command.action == NSSelectorFromString("togglePlaybackOfSelectedItem:") {
      command.title = delegate!.playlistViewControllerIsMediaPlaying(self) ? "Pause" : "Play"
    }
  }

  override var keyCommands: [UIKeyCommand]? {
    return [
      UIKeyCommand(title: "Play", action: NSSelectorFromString("playSelectedItem:"), input:"\r", modifierFlags:[])
    ]
  }
}

extension PlaylistViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    return true
  }
  func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    return true
  }
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//    let system = UIFocusSystem.focusSystem(for: self.view.window!)
//    let cell = collectionView.cellForItem(at: indexPath)!
//    system?.requestFocusUpdate(to: cell)
  }
}
