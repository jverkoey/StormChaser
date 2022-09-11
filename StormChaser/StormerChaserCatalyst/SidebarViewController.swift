//
//  SidebarViewController.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import Foundation
import UniformTypeIdentifiers
import UIKit

extension UserDefaults {
  static let modelKey = "com.stormchaser.prefs.model"
}

final class SidebarViewController: UIViewController, UICollectionViewDelegate {
  let model: Model
  init(model: Model) {
    self.model = model

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var collectionView: UICollectionView!
  typealias DiffableDataSource = UICollectionViewDiffableDataSource<String, Playlist>
  var dataSource: DiffableDataSource!
  private var expandedNodes = Set<Int64>()

  override func viewDidLoad() {
    super.viewDidLoad()

    let config = UICollectionLayoutListConfiguration(appearance: .sidebar)
    let layout = UICollectionViewCompositionalLayout.list(using: config)
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.dragInteractionEnabled = true
    collectionView.dragDelegate = self
    collectionView.dropDelegate = self
    view.addSubview(collectionView)

    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
    ])

    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(gesture:)))
    collectionView.addGestureRecognizer(longPressGesture)

    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Playlist> { (cell, indexPath, playlist) in
      var content = cell.defaultContentConfiguration()
      content.text = playlist.name
      cell.contentConfiguration = content

      cell.accessories = ((playlist.children?.count ?? 0) > 0) ? [.outlineDisclosure()] : []
    }

    dataSource = DiffableDataSource(collectionView: collectionView) { (collectionView, indexPath, node) -> UICollectionViewCell? in
      return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: node)
    }

    dataSource.sectionSnapshotHandlers.willCollapseItem = { [weak self] playlist in
      self?.expandedNodes.remove(playlist.id)
    }
    dataSource.sectionSnapshotHandlers.willExpandItem = { [weak self] playlist in
      self?.expandedNodes.insert(playlist.id)
    }

    collectionView.dataSource = dataSource

    if model.url != nil {
      applySnapshot(animated: false)
    }
  }

  @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
    switch(gesture.state) {
    case .began:
      guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
        break
      }
      collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
    case .changed:
      collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view))
    case .ended:
      collectionView.endInteractiveMovement()
    default:
      collectionView.cancelInteractiveMovement()
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

#if targetEnvironment(macCatalyst)
    navigationController?.setNavigationBarHidden(true, animated: animated)
#endif
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if model.url == nil {
      let supportedTypes: [UTType] = [.folder]
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
      picker.delegate = self
      present(picker, animated: true)
    }
  }

  func applySnapshot(animated: Bool) {
    var nodesToExpand = Set<Playlist>()
    var snapshot = NSDiffableDataSourceSectionSnapshot<Playlist>()

    func addItems(_ playlists: [Playlist], to parent: Playlist?) {
      snapshot.append(playlists, to: parent)
      for playlist in playlists where playlist.children != nil {
        if expandedNodes.contains(playlist.id) {
          // I'll check here if the new one is an expanded one
          // and I should mark it as "to expand" on the next snapshot
          nodesToExpand.insert(playlist)
        }
        addItems(playlist.children!, to: playlist)
      }
    }
    addItems(model.playlists, to: nil)
    snapshot.expand(Array(nodesToExpand))

    dataSource.apply(snapshot, to: "", animatingDifferences: animated)
  }

}

extension SidebarViewController: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard urls.count == 1 else {
      fatalError("Unexpected number of urls: \(urls)")
    }

    let url = urls[0]

    guard url.startAccessingSecurityScopedResource() else {
      return
    }

    // Make sure you release the security-scoped resource when you finish.
    defer { url.stopAccessingSecurityScopedResource() }

    let bookmarkData = try! url.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil)
    UserDefaults.standard.set(bookmarkData, forKey: UserDefaults.modelKey)

    model.url = url

    applySnapshot(animated: false)
  }
}

extension SidebarViewController: UICollectionViewDragDelegate {
  func collectionView(
    _ collectionView: UICollectionView,
    itemsForBeginning session: UIDragSession,
    at indexPath: IndexPath
  ) -> [UIDragItem] {
    let playlist = dataSource.itemIdentifier(for: indexPath)!
    let item = NSItemProvider(object: PlaylistItem(playlist: playlist.id))
    let dragItem = UIDragItem(itemProvider: item)
    return [dragItem]
  }
}

extension SidebarViewController: UICollectionViewDropDelegate {
  func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
    guard collectionView.hasActiveDrag else {
      return UICollectionViewDropProposal(operation: .cancel)
    }
    guard session.items.count == 1 else {
      fatalError("Unhandled")
      // We don't allow dropping multiple items.
      //      return UICollectionViewDropProposal(operation: .cancel)
    }
    return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
  }

  func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
    let item = coordinator.items[0]
    let sourcePlaylist = dataSource.itemIdentifier(for: item.sourceIndexPath!)!
    let destinationPlaylist = dataSource.itemIdentifier(for: coordinator.destinationIndexPath!)!

    model.movePlaylist(sourcePlaylist, into: destinationPlaylist)

    applySnapshot(animated: true)
  }
}

final class PlaylistItem: NSObject, NSItemProviderWriting, NSItemProviderReading {
  let playlist: Int64
  init(playlist: Int64) {
    self.playlist = playlist
  }

  static var readableTypeIdentifiersForItemProvider: [String] = [UTType.commaSeparatedText.identifier]

  static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> PlaylistItem {
    return PlaylistItem(playlist: Int64(String(data: data, encoding: .ascii)!)!)
  }

  static var writableTypeIdentifiersForItemProvider: [String] = [UTType.commaSeparatedText.identifier]

  func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
    completionHandler("\(playlist)".data(using: .ascii), nil)
    return nil
  }
}
