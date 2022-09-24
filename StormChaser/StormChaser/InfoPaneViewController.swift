//
//  InfoPaneViewController.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/12/22.
//

import UIKit

private enum CellTypes: String {
  case editableText
  case label
}

final class InfoPaneViewController: UIViewController {
  let model: Model
  init(model: Model) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var tableView: UITableView!
  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    tableView = UITableView(frame: view.bounds, style: .insetGrouped)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self

    tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellTypes.editableText.rawValue)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellTypes.label.rawValue)

    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
    ])
  }

  var mediaItemId: Int64? {
    didSet {
      // TODO: Subscribe to updates of this object.
      if let mediaItemId = mediaItemId {
        mediaItem = model.mediaItem(withId: mediaItemId)
      } else {
        mediaItem = nil
      }
    }
  }

  var mediaItem: MediaItem? {
    didSet {
      if isViewLoaded {
        tableView.reloadData()
      }
    }
  }
}

extension InfoPaneViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    switch indexPath.section {
    case 0:
      let cell = tableView.dequeueReusableCell(withIdentifier: CellTypes.editableText.rawValue, for: indexPath)
      var config = cell.textFieldConfiguration()
      config.text = mediaItem?.title
      cell.contentConfiguration = config
      return cell

    case 1:
      let cell = tableView.dequeueReusableCell(withIdentifier: CellTypes.editableText.rawValue, for: indexPath)
      var config = cell.defaultContentConfiguration()
      config.text = mediaItem?.url?.path
      cell.contentConfiguration = config
      return cell

    default:
      break
    }

    return UITableViewCell(frame: .zero)
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0:
      return "Title"
    case 1:
      return "Location"
    default:
      return nil
    }
  }
}

extension InfoPaneViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
    return false
  }

  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let actionProvider: UIContextMenuActionProvider = { _ in
      return UIMenu(title: "", children: [
        UIAction(title: "Copy") { _ in
          let pasteBoard = UIPasteboard.general
          pasteBoard.string = self.mediaItem?.url?.path
        }
      ])
    }

    return UIContextMenuConfiguration(identifier: "unique-ID" as NSCopying, previewProvider: nil, actionProvider: actionProvider)
  }
}
