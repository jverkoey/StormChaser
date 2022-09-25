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
  @Published var allTags: [Tag] = []
  @Published var tags: [Tag] = []
}

struct MultiSelectPickerView: View {
  //the list of all items to read from
  @State var sourceItems: [Tag]

  //a binding to the values we want to track
  @Binding var selectedItems: [Tag]

  var body: some View {
    Form {
      ForEach(sourceItems.sorted(by: { $0.name < $1.name }), id: \.id) { item in
        Button(action: {
          withAnimation {
            // At runtime, the following lines generate purple warnings. These appear to be a bug
            // in SwiftUI, as documented at https://www.donnywals.com/xcode-14-publishing-changes-from-within-view-updates-is-not-allowed-this-will-cause-undefined-behavior/
            // The warning: "Publishing changes from within view updates is not allowed, this will cause undefined behavior."
            if selectedItems.contains(item) {
              selectedItems.removeAll(where: { $0 == item })
            } else {
              selectedItems.append(item)
            }
          }
        }) {
          HStack {
            Image(systemName: "checkmark")
              .opacity(self.selectedItems.contains(item) ? 1.0 : 0.0)
            Text("\(item.name)")
          }
        }
        .foregroundColor(.primary)
      }
    }
    .listStyle(GroupedListStyle())
  }
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

          NavigationLink {
            MultiSelectPickerView(sourceItems: delegate.allTags, selectedItems: $delegate.tags)
              .navigationTitle("Edit tags")
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
                  WorkspaceCompatibility.perform(NSSelectorFromString("showInFinder:"), with:[URL(filePath: delegate.path)])
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
        let allTags = model.allTags()
        let tags = model.tags(for: mediaItem.id)

        delegate.title = mediaItem.title
        delegate.path = mediaItem.url!.path
        delegate.allTags = allTags
        delegate.tags = tags
      }
    }
  }
}
