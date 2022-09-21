//
//  InfoPaneViewController.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/12/22.
//

import UIKit

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
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

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

      tableView.reloadData()
    }
  }

  var mediaItem: MediaItem? {
    didSet {
      print(mediaItem)
    }
  }
}

extension InfoPaneViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.textFieldConfiguration()
    config.text = mediaItem?.title
    cell.contentConfiguration = config
    return cell
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return "Title"
  }
}
