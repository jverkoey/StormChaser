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

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground
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
      print(mediaItem)
    }
  }
}
