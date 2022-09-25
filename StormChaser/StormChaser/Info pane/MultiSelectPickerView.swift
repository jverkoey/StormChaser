//
//  MultiSelectPickerView.swift
//  StormChaser
//
//  Created by Jeff Verkoeyen on 9/24/22.
//

import Foundation
import SwiftUI

struct MultiSelectPickerView: View {
  //the list of all items to read from
  @State var sourceItems: [Tag]

  //a binding to the values we want to track
  @Binding var selectedItems: [Tag]

  @State private var searchText = ""

  var body: some View {
    Form {
      ForEach(searchResults.sorted(by: { $0.name < $1.name }), id: \.id) { item in
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
    .searchable(text: $searchText)
    .listStyle(GroupedListStyle())
  }

  var searchResults: [Tag] {
    if searchText.isEmpty {
      return sourceItems
    } else {
      return sourceItems.filter { $0.name.contains(searchText) }
    }
  }
}
