//
//  SettingsViewController.swift
//  StormChaser
//
//  Created by Jeff Verkoeyen on 9/24/22.
//

import Combine
import Foundation
import SwiftUI
import UIKit

private final class SettingsDelegate: ObservableObject {
  @Published var tagExportMode: TagExportMode = .none
}

private struct SettingsView: View {
  @ObservedObject var delegate: SettingsDelegate
  
  var body: some View {
    Form {
      Section(header: Text("Track synchronization")) {
        HStack {
          Text("Export tags").foregroundColor(.gray)
          Picker("Tag export mode", selection: $delegate.tagExportMode) {
            Text("None").tag(TagExportMode.none)
            Text("Grouping").tag(TagExportMode.grouping)
          }
          .pickerStyle(.segmented)
        }
      }
    }
  }
}

final class SettingsViewController: UIViewController {
  let model: Model
  init(model: Model) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private let delegate = SettingsDelegate()
  private var cancellables: Set<AnyCancellable> = []

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Settings"

    let hostingController = UIHostingController(rootView: SettingsView(delegate: delegate))
    addChild(hostingController)

    hostingController.view.frame = view.bounds
    hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(hostingController.view)
    hostingController.didMove(toParent: self)

    if let prefs = model.prefs {
      delegate.tagExportMode = prefs.tagExportMode

      cancellables.insert(delegate.$tagExportMode.sink { [weak self] tagExportMode in
        guard let self = self else {
          return
        }
        self.model.prefs?.tagExportMode = tagExportMode
      })
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    model.savePreferences()
  }
}
