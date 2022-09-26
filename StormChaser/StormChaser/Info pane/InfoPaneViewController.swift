//
//  InfoPaneViewController.swift
//  StormerChaserCatalyst
//
//  Created by Jeff Verkoeyen on 9/12/22.
//

import Combine
import ID3TagEditor
import SwiftUI
import UIKit

private final class InfoPaneDelegate: ObservableObject {
  @Published var title: String = ""
  @Published var grouping: String = ""
  @Published var path: String = ""
  @Published var allTags: [Tag] = []
  @Published var tags: [Tag] = []

  @Published var id3Title: String? = nil
  @Published var id3Grouping: String? = nil
}

private struct InfoPane: View {
  @ObservedObject var delegate: InfoPaneDelegate

  var body: some View {
    VStack {
      Form {
        Section(header: Text("Track information")) {
          HStack {
            if delegate.title == delegate.id3Title {
              Image(systemName: "externaldrive.badge.checkmark").foregroundColor(.green)
            } else {
              // TODO: Make this a button that shows a menu for syncing the id3 data and the db
              Image(systemName: "externaldrive.badge.exclamationmark").foregroundColor(.red)
            }
            Text("Title").foregroundColor(.gray)
            TextField("Title", text: $delegate.title)
          }
          HStack {
            if delegate.grouping == delegate.id3Grouping {
              Image(systemName: "externaldrive.badge.checkmark").foregroundColor(.green)
            } else {
              // TODO: Make this a button that shows a menu for syncing the id3 data and the db
              Image(systemName: "externaldrive.badge.exclamationmark").foregroundColor(.red)
            }
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
        Section(header: Text("File location")) {
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

        Section(header: Text("id3 information")) {
          if let value = delegate.id3Title {
            HStack {
              Text("Title").foregroundColor(.gray)
              Text(value)
            }
          }
          if let value = delegate.id3Grouping {
            HStack {
              Text("Grouping").foregroundColor(.gray)
              Text(value)
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

    cancellables.insert(delegate.$title
      .debounce(for: .milliseconds(1000), scheduler: RunLoop.main)
      .sink { [weak self] title in
      guard let self = self,
            let id = self.mediaItemId else {
        return
      }
      guard self.mediaItem?.title != title else {
        return
      }
      try! self.model.updateTrack(id: id, title: title)
    })
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

        let editor = ID3TagEditor()
        if let loadedUrl = mediaItem.url,
           let id3tag = try? editor.read(from: loadedUrl.path) {
          let tagContentReader = ID3TagContentReader(id3Tag: id3tag)
          delegate.id3Title = tagContentReader.title()
          delegate.id3Grouping = (id3tag.frames[.iTunesGrouping] as? ID3FrameWithStringContent)?.content
        } else {
          delegate.id3Title = nil
          delegate.id3Grouping = nil
        }

        delegate.title = mediaItem.title
        delegate.grouping = mediaItem.grouping ?? ""
        delegate.path = mediaItem.url!.path
        delegate.allTags = allTags
        delegate.tags = tags
      }
    }
  }
}
