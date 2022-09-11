//
//  ViewController.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/10/22.
//

import UIKit

class PlaylistViewController: UIViewController {

  let model: Model
  init(model: Model) {
    self.model = model

    super.init(nibName: nil, bundle: nil)
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
    view.addSubview(collectionView)

    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
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
