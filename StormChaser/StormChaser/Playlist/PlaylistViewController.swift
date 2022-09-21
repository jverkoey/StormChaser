//
//  ViewController.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import UniformTypeIdentifiers
import UIKit

protocol PlaylistViewControllerDelegate: AnyObject {
  func playlistViewController(_ playlistViewController: PlaylistViewController, togglePlaybackOfMediaItem mediaItem: MediaItem)
  func playlistViewController(_ playlistViewController: PlaylistViewController, playMediaItem mediaItem: MediaItem)
  func playlistViewControllerIsMediaPlaying(_ playlistViewController: PlaylistViewController) -> Bool

  func playlistViewController(_ playlistViewController: PlaylistViewController, didChangePlaylist playlist: Playlist, name: String)
}

final class PlaylistViewController: UIViewController {
  weak var delegate: PlaylistViewControllerDelegate?

  let playlistInfoViewController: PlaylistInfoViewController
  let infoPaneViewController: InfoPaneViewController

  let model: Model
  init(model: Model) {
    self.model = model
    self.playlistInfoViewController = PlaylistInfoViewController(model: model)
    self.infoPaneViewController = InfoPaneViewController(model: model)

    super.init(nibName: nil, bundle: nil)

    playlistInfoViewController.delegate = self

    addChild(playlistInfoViewController)
    addChild(infoPaneViewController)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var playlistId: Int64? {
    didSet {
      playlistInfoViewController.playlistId = playlistId

      // TODO: Subscribe to updates of this object.

      if let playlistId = playlistId {
        playlist = model.playlist(withId: playlistId)
      } else {
        playlist = nil
      }

      if isViewLoaded {
        applySnapshot(animated: false)
      }
    }
  }
  private var playlist: Playlist? {
    didSet {
      if let playlist = playlist {
        items = model.items(in: playlist)
      } else {
        items = nil
      }
    }
  }
  private var items: [MediaItem]? {
    didSet {
      guard isViewLoaded else {
        return
      }
      if let selectedItems = collectionView.indexPathsForSelectedItems {
        for indexPath in selectedItems {
          collectionView.deselectItem(at: indexPath, animated: false)
        }
      }
    }
  }

  var collectionView: UICollectionView!
  typealias DiffableDataSource = UICollectionViewDiffableDataSource<String, MediaItem>
  var dataSource: DiffableDataSource!

  private var infoPaneWidth: CGFloat = 400 {
    didSet {
      infoPaneWidthConstraint.constant = min(800, max(400, infoPaneWidth))
    }
  }
  private var infoPaneWidthConstraint: NSLayoutConstraint!

  override func viewDidLoad() {
    super.viewDidLoad()

    let config = UICollectionLayoutListConfiguration(appearance: .plain)
    let layout = UICollectionViewCompositionalLayout.list(using: config)
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
    collectionView.delegate = self
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.selectionFollowsFocus = true
    collectionView.dragInteractionEnabled = true
    collectionView.dragDelegate = self
    collectionView.dropDelegate = self

    playlistInfoViewController.view.translatesAutoresizingMaskIntoConstraints = false
    infoPaneViewController.view.translatesAutoresizingMaskIntoConstraints = false

    let splitterView = SplitterView()
    splitterView.translatesAutoresizingMaskIntoConstraints = false
    splitterView.delegate = self

    view.addSubview(playlistInfoViewController.view)
    view.addSubview(collectionView)
    view.addSubview(infoPaneViewController.view)
    view.addSubview(splitterView)

    playlistInfoViewController.didMove(toParent: self)
    infoPaneViewController.didMove(toParent: self)

    infoPaneWidthConstraint = infoPaneViewController.view.widthAnchor.constraint(equalToConstant: infoPaneWidth)

    NSLayoutConstraint.activate([
      playlistInfoViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      playlistInfoViewController.view.heightAnchor.constraint(equalToConstant: 400),

      collectionView.topAnchor.constraint(equalTo: playlistInfoViewController.view.bottomAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

      splitterView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      splitterView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

      playlistInfoViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      playlistInfoViewController.view.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
      splitterView.leadingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -1),
      splitterView.trailingAnchor.constraint(equalTo: infoPaneViewController.view.leadingAnchor),
      infoPaneViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

      infoPaneWidthConstraint,

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

/*
 Factorio death world marathon with rail world resource settings.
 >>>eNp1UjFIw1AQvbMWawXp0EXQ2sG1DurgIP1fEUREN3G1TVMIa
 CJpM6iDHRwVFxdF0NWK4uLgVhBEQUEUBLeKi4NSRFEHof5L8tsY9
 eAuL/fuv7v7CQLCMDjGAEos1KgYqZm9YjEJwDlAgYUVY25ONROGq
 XrTzYppZdSEof0sVnV1dj6RTuVUocgdL7CQZhq6XyGYyxv6z0zeV
 NUcIektlpnSNWvWfxbwFvanCssxIK8uQbxaJReoLJqSAxZEtagUO
 WlBZUbLZgHig8KHSAgRF6MHI/cL6wydmm6OVdsqbqaU5i41KsEE/
 5fqkqDPo9Nr26sHOE3zooVbHuJ14JDLRCJqHZPjEauSxK/dl+vx9
 DTD1eejnY/Tw6Qgm2jPhlrY3CA7lquA1Cwzl7pjeHlB9sQwSCeiF
 Hi/CKWxAGCkVaCdFRHi7SBHS0qZKMesbe9ykwcJbph/D3ERAyQeo
 3BGwW5YmwwdyNc48k7JttVLxPke8M6QqW94LtueePr7BvF+iN97+
 DJd/I/PEKaGmVp4DNSmEfd51STf+DbHAAGqehM55839/20p5xnh9
 nUT6y5PKQxvfX4Dln+xPQ==<<<
 */

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

extension PlaylistViewController: SplitterViewDelegate {
  func splitterView(_ splitterView: SplitterView, didTranslate offset: CGFloat) {
    infoPaneWidth -= offset
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
    let mediaItem = dataSource.itemIdentifier(for: indexPath)!
    infoPaneViewController.mediaItemId = mediaItem.id
  }
}

extension PlaylistViewController: PlaylistInfoDelegate {
  func playlistInfoViewController(_ playlistInfoViewController: PlaylistInfoViewController, didChangePlaylist playlist: Playlist, name: String) {
    delegate?.playlistViewController(self, didChangePlaylist: playlist, name: name)
  }
}

extension PlaylistViewController: UICollectionViewDragDelegate {
  func collectionView(
    _ collectionView: UICollectionView,
    itemsForBeginning session: UIDragSession,
    at indexPath: IndexPath
  ) -> [UIDragItem] {
    let mediaItem = dataSource.itemIdentifier(for: indexPath)!
    let item = NSItemProvider(object: TransportableMediaItem(mediaId: mediaItem.id))
    let dragItem = UIDragItem(itemProvider: item)
    return [dragItem]
  }
}

extension PlaylistViewController: UICollectionViewDropDelegate {
  func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
    guard collectionView.hasActiveDrag else {
      return UICollectionViewDropProposal(operation: .cancel)
    }
    return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
  }

  func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
    assert(coordinator.items.count == 1)
    let item = coordinator.items[0]
    let mediaItem = dataSource.itemIdentifier(for: item.sourceIndexPath!)!
    guard let destinationIndexPath = coordinator.destinationIndexPath else {
      return
    }

    model.moveItem(
      id: mediaItem.id,
      fromIndex: item.sourceIndexPath!.row,
      toIndex: destinationIndexPath.row,
      in: playlist!
    )

    playlist = model.playlist(withId: playlist!.id)
  }
}

private final class TransportableMediaItem: NSObject, NSItemProviderWriting, NSItemProviderReading {
  let mediaId: Int64
  init(mediaId: Int64) {
    self.mediaId = mediaId
  }

  static var readableTypeIdentifiersForItemProvider: [String] = [UTType.commaSeparatedText.identifier]

  static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> TransportableMediaItem {
    return TransportableMediaItem(mediaId: Int64(String(data: data, encoding: .ascii)!)!)
  }

  static var writableTypeIdentifiersForItemProvider: [String] = [UTType.commaSeparatedText.identifier]

  func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
    completionHandler("\(mediaId)".data(using: .ascii), nil)
    return nil
  }
}
