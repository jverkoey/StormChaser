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

final class SidebarViewController: UIViewController {
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

  override func viewDidLoad() {
    super.viewDidLoad()

    let config = UICollectionLayoutListConfiguration(appearance: .sidebar)
    let layout = UICollectionViewCompositionalLayout.list(using: config)
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)

    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
    ])

    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Playlist> { (cell, indexPath, playlist) in
      var content = cell.defaultContentConfiguration()
      content.text = playlist.name
      cell.contentConfiguration = content

      cell.accessories = ((playlist.children?.count ?? 0) > 0) ? [.outlineDisclosure()] : []
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

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if model.url == nil {
      let supportedTypes: [UTType] = [UTType(filenameExtension: "sqlite3")!]
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
      picker.delegate = self
      present(picker, animated: true)
    }
  }

  func applySnapshot(animated: Bool) {
    var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Playlist>()
    sectionSnapshot.append(model.playlists)
    for playlist in model.playlists {
      addChildren(of: playlist, to: &sectionSnapshot)
    }

//    sectionSnapshot.expand(sectionSnapshot.items)

    dataSource.apply(sectionSnapshot, to: "", animatingDifferences: animated)
  }

  func addChildren(of node: Playlist, to sectionSnapshot: inout NSDiffableDataSourceSectionSnapshot<Playlist>) {
    guard let children = node.children else { return }

    sectionSnapshot.append(children, to: node)

    for child in children {
      addChildren(of: child, to: &sectionSnapshot)
    }
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
