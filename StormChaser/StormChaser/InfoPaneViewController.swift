//
//  InfoPaneViewController.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/12/22.
//

import Combine
import SwiftUI
import UIKit

private enum CellTypes: String {
  case editableText
  case label
}

private final class InfoPaneDelegate: ObservableObject {
  @Published var title: String = ""
  @Published var path: String = ""
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
                  WorkspaceCompatibility.perform(NSSelectorFromString("showInFinder:"), with:[URL(string: delegate.path)])
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
    addChild(hostingController)

    hostingController.view.frame = view.bounds
    hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(hostingController.view)
    hostingController.didMove(toParent: self)

//    cancellables.insert(delegate.$title.sink { title in
//      print(title)
//    })
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
        delegate.title = mediaItem.title
        delegate.path = mediaItem.url!.path
      }
    }
  }
}
