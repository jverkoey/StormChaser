//
//  SplitViewController.swift
//  StormChaser
//
//  Created by Jeff Verkoeyen on 9/24/22.
//

import Foundation
import UIKit

final class SplitViewController: UISplitViewController {
  let model: Model
  init(style: UISplitViewController.Style, model: Model) {
    self.model = model
    super.init(style: style)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func openSettings(_ sender: Any) {
    let settingsController = SettingsViewController(model: model)
    settingsController.navigationItem.leadingItemGroups = [
      .fixedGroup(items: [
        UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissSettings(_:)))
      ])
    ]
    let navigationController = UINavigationController(rootViewController: settingsController)
    present(navigationController, animated: true)
  }

  @objc func dismissSettings(_ sender: Any) {
    dismiss(animated: true)
  }

}
