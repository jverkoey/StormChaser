//
//  InfoPaneViewController.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/12/22.
//

import Combine
import SwiftUI
import UIKit

private final class InfoPaneDelegate: ObservableObject {
  @Published var title: String = ""
  @Published var grouping: String = ""
  @Published var path: String = ""
  @Published var allTags: [Tag] = []
  @Published var tags: [Tag] = []
}

private struct InfoPane: View {
  @ObservedObject var delegate: InfoPaneDelegate

  var body: some View {
    VStack {
      Form {
        Section(header: Text("Track information")) {
          HStack {
            Text("Title").foregroundColor(.gray)
            TextField("Title", text: $delegate.title)
          }
          HStack {
            Text("Grouping").foregroundColor(.gray)
            TextField("Grouping", text: $delegate.grouping)
          }
        }

        Section(header: Text("Organization")) {
          NavigationLink {
            MultiSelectPickerView(sourceItems: delegate.allTags, selectedItems: $delegate.tags)
              .navigationTitle("Tags")
          } label: {
            HStack {
              Text("Tags").foregroundColor(.gray)
              Text(delegate.tags.map { $0.name }.joined(separator: ", "))
            }
          }
        }
      }

      Divider()

      Form {
        Section(header: Text("Track location")) {
          HStack(alignment: .top) {
            if !FileManager.default.fileExists(atPath: delegate.path) {
              Image(systemName: "questionmark.folder")
            }
            Text(delegate.path)
              .contextMenu {
                Button {
                  let pasteBoard = UIPasteboard.general
                  pasteBoard.string = delegate.path
                } label: {
                  Label("Copy", systemImage: "copy")
                }
                Button {
                  guard let WorkspaceCompatibility = NSClassFromString("StormchaserBridge.WorkspaceCompatibility") as AnyObject as? NSObjectProtocol else {
                    return
                  }
                  WorkspaceCompatibility.perform(NSSelectorFromString("showInFinder:"), with:[URL(fileURLWithPath: delegate.path)])
                } label: {
                  Label("Show in Finder", systemImage: "copy")
                }
              }
          }
        }
      }

      Spacer()
    }
  }
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

  private let delegate = InfoPaneDelegate()
  private var cancellables: Set<AnyCancellable> = []
  private var hostingController: UIHostingController<InfoPane>!
  private var tableView: UITableView!
  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    hostingController = UIHostingController(rootView: InfoPane(delegate: delegate))
    let navigationController = UINavigationController(rootViewController: hostingController)
    addChild(navigationController)

    navigationController.view.frame = view.bounds
    navigationController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(navigationController.view)
    navigationController.didMove(toParent: self)
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
      if let mediaItem = mediaItem {
        let allTags = model.allTags()
        let tags = model.tags(for: mediaItem.id)

        delegate.title = mediaItem.title
        delegate.grouping = mediaItem.grouping ?? ""
        delegate.path = mediaItem.url!.path
        delegate.allTags = allTags
        delegate.tags = tags
      }
    }
  }
}
