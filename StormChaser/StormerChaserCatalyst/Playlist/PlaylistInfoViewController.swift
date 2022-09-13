//
//  PlaylistInfoViewController.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/12/22.
//

import UIKit

protocol PlaylistInfoDelegate: AnyObject {
  func playlistInfoViewController(_ playlistInfoViewController: PlaylistInfoViewController, didChangePlaylist playlist: Playlist, name: String)
}

final class PlaylistInfoViewController: UIViewController {
  weak var delegate: PlaylistInfoDelegate?
  init() {
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let nameLabel = UITextField()
  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.textColor = .label
    nameLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
    nameLabel.layer.cornerRadius = 4
    nameLabel.layer.borderColor = UIColor.systemBlue.cgColor
    nameLabel.addTarget(self, action: #selector(updateName(_:)), for: .editingDidEnd)
    view.addSubview(nameLabel)

    let layoutGuide = UILayoutGuide()
    view.addLayoutGuide(layoutGuide)

    NSLayoutConstraint.activate([
      // Define the content boundaries
      layoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
      layoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
      layoutGuide.topAnchor.constraint(equalTo: view.topAnchor, constant: 32),
      layoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32),

      nameLabel.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
      nameLabel.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
    ])
  }

  @objc func updateName(_ sender: Any) {
    if let text = nameLabel.text, !text.isEmpty {
      if let playlist = playlist, text != playlist.name {
        delegate?.playlistInfoViewController(self, didChangePlaylist: playlist, name: text)
      }
    } else {
      // Reset the label to the current model value.
      nameLabel.text = playlist?.name
    }
  }

  override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
    super.didUpdateFocus(in: context, with: coordinator)

    if context.nextFocusedView == nameLabel {
      nameLabel.layer.borderWidth = 2
    } else {
      nameLabel.layer.borderWidth = 0
    }
  }

  var playlist: Playlist? {
    didSet {
      nameLabel.text = playlist?.name
    }
  }
}
