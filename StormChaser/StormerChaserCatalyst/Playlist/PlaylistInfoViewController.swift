//
//  PlaylistInfoViewController.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/12/22.
//

import UIKit

final class PlaylistInfoViewController: UIViewController {
  init() {
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground
  }

  var playlist: Playlist?
}
