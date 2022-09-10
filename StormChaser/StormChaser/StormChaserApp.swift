//
//  StormChaserApp.swift
//  StormChaser
//
//  Created by Jeff Verkoeyen on 9/8/22.
//

import AVKit
import SwiftUI
import SQLite
import HurricaneDB

func getDocumentsDirectory() -> URL {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  let documentsDirectory = paths[0]
  return documentsDirectory
}

private final class Playlist: Equatable, Identifiable, Hashable {
  internal init(id: Int64, parentId: Int64?, name: String, items: String, children: [Playlist]? = nil) {
    self.identifier = id
    self.parentId = parentId
    self.name = name
    self.items = items
    self.children = children
  }

  let identifier: Int64
  let parentId: Int64?
  let name: String
  let items: String
  var children: [Playlist]? = nil

  static func == (lhs: Playlist, rhs: Playlist) -> Bool {
    lhs === rhs
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
  }
}

struct MediaItem: Hashable, Identifiable {
  let id: Int64
  let title: String
  let artist: String
  let rating: Int64
  let ratingComputed: Bool
  let url: URL
}

struct PlaylistView: SwiftUI.View {
  private let playlist: Playlist
  private let mediaItems: [MediaItem]
  @SwiftUI.Binding private var selectedItem: MediaItem?
  private let audioPlayer: AVPlayer

  fileprivate init(playlist: Playlist, selectedItem: SwiftUI.Binding<MediaItem?>, audioPlayer: AVPlayer, db: Connection) {
    self.playlist = playlist
    self._selectedItem = selectedItem
    self.audioPlayer = audioPlayer

    if !playlist.items.isEmpty {
      let playlistOrder = playlist.items.components(separatedBy: ",").map { Int64(bitPattern: UInt64($0, radix: 16)!) }

      var artistNames: [Int64: String] = [:]

      let itemMap: [Int64: MediaItem] = try! db.prepare(
        MediaItemTable.table
          .select(
            MediaItemTable.id,
            MediaItemTable.title,
            MediaItemTable.artistId,
            MediaItemTable.rating,
            MediaItemTable.ratingComputed,
            MediaItemTable.location
          )
          .where( playlistOrder.contains(MediaItemTable.id) )
      ).reduce(into: [:], { partialResult, row in
        guard let location = row[MediaItemTable.location] else {
          return
        }
        let artistName: String?
        if let artistId = row[MediaItemTable.artistId] {
          if let name = artistNames[artistId] {
            artistName = name
          } else if let artist = try db.pluck(ArtistTable.table.select(ArtistTable.name).where(ArtistTable.id == artistId)) {
            artistName = artist[ArtistTable.name]
            artistNames[artistId] = artistName
          } else {
            artistName = nil
          }
        } else {
          artistName = nil
        }

        partialResult[row[MediaItemTable.id]] = MediaItem(
          id: row[MediaItemTable.id],
          title: row[MediaItemTable.title],
          artist: artistName ?? "",
          rating: row[MediaItemTable.rating],
          ratingComputed: row[MediaItemTable.ratingComputed],
          url: URL(string: location)!
        )
      })

      self.mediaItems = playlistOrder.map { itemMap[$0]! }
    } else {
      self.mediaItems = []
    }
  }

  var body: some SwiftUI.View {
    List(mediaItems, id: \.self, selection: $selectedItem) { item in
      HStack {
        Text(String(item.rating))
          .frame(minWidth: 50)
          .multilineTextAlignment(.leading)
        if item.ratingComputed {
          Text("Computed rating")
        }
        Text(item.title)
        Spacer()
        Text(item.artist)
      }
    }
  }
}

enum Utility {
  static func formatSecondsToHMS(_ seconds: TimeInterval) -> String {
    let secondsInt:Int = Int(seconds.rounded(.towardZero))

    let dh: Int = (secondsInt/3600)
    let dm: Int = (secondsInt - (dh*3600))/60
    let ds: Int = secondsInt - (dh*3600) - (dm*60)

    let hs = "\(dh > 0 ? "\(dh):" : "")"
    let ms = "\(dm<10 ? "0" : "")\(dm):"
    let s = "\(ds<10 ? "0" : "")\(ds)"

    return hs + ms + s
  }
}

class AudioPlayerObserver {
  var audioPlayerObserver: Any?
}

@main
struct StormChaserApp: App {
  private let documentsUrl = getDocumentsDirectory()
  private let db: Connection
  private let playlists: [Playlist]

  @State private var playingItem: MediaItem?
  @State private var selectedItem: MediaItem?
  @State private var selection: Playlist?
  private let audioPlayer = AVPlayer()
  @State private var currentTime: TimeInterval = 0
  @State private var currentDuration: TimeInterval = 0

  init() {
    self.db = try! Connection(documentsUrl.appendingPathComponent("hurricane.sqlite3").absoluteString)

    var playlistMap: [Int64: Playlist] = [:]
    for row in try! db.prepare(PlaylistsTable.table
      .select(PlaylistsTable.id,
              PlaylistsTable.name,
              PlaylistsTable.parentId,
              PlaylistsTable.items
             )) {
      playlistMap[row[PlaylistsTable.id]] = Playlist(
        id: row[PlaylistsTable.id],
        parentId: row[PlaylistsTable.parentId],
        name: row[PlaylistsTable.name],
        items: row[PlaylistsTable.items]
      )
    }
    for playlist in playlistMap.values {
      guard let parentId = playlist.parentId else {
        continue
      }
      let parent = playlistMap[parentId]!
      if parent.children == nil {
        parent.children = []
      }
      parent.children?.append(playlist)
    }
    for playlist in playlistMap.values {
      playlist.children?.sort(by: { playlist1, playlist2 in
        if (playlist1.children == nil) == (playlist2.children == nil) {
          return playlist1.name < playlist2.name
        }
        return playlist1.children != nil
      })
    }
    self.playlists = Array(playlistMap.values).filter { $0.parentId == nil }.sorted(by: { playlist1, playlist2 in
      if (playlist1.children == nil) == (playlist2.children == nil) {
        return playlist1.name < playlist2.name
      }
      return playlist1.children != nil
    })
  }

  let audioPlayerObserver = AudioPlayerObserver()

  var body: some Scene {
    WindowGroup {
      NavigationView {
        // List must be keyed by .self in order for selection to persist.
        List(playlists, id: \.self, children: \.children, selection: $selection) { playlist in
          Text(playlist.name)
        }
        VStack {
          HStack {
            Button {
              playingItem = selectedItem

              currentDuration = 0
              if let playedItem = playingItem {
                audioPlayer.pause()
                let playerItem = AVPlayerItem(url: playedItem.url)
                audioPlayer.replaceCurrentItem(with: playerItem)
                audioPlayer.play()

                if audioPlayerObserver.audioPlayerObserver == nil {
                  let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                  audioPlayerObserver.audioPlayerObserver = audioPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                    currentTime = time.seconds
                    currentDuration = audioPlayer.currentItem!.duration.seconds
                    if currentDuration.isNaN {
                      currentDuration = 0
                    }
                  }
                }
              } else {
                if let audioPlayerObserver = audioPlayerObserver.audioPlayerObserver {
                  audioPlayer.removeTimeObserver(audioPlayerObserver)
                  self.audioPlayerObserver.audioPlayerObserver = nil
                }
                audioPlayer.pause()
              }
            } label: {
              if playingItem == nil {
                Image(systemName: "play.fill")
              } else {
                Image(systemName: "pause.fill")
              }
            }
            .disabled(selectedItem == nil && playingItem == nil)
            if let playingItem = playingItem {
              Text(playingItem.title)
            } else {
              Text("No track playing")
            }
            Slider(value: $currentTime,
                   in: 0...currentDuration,
                   onEditingChanged: sliderEditingChanged,
                   minimumValueLabel: Text("\(Utility.formatSecondsToHMS(currentTime))"),
                   maximumValueLabel: Text("\(Utility.formatSecondsToHMS(currentDuration))")) {
            }
          }
          if let selection = self.selection {
            PlaylistView(playlist: selection, selectedItem: $selectedItem, audioPlayer: audioPlayer, db: db)
          } else {
            Text("Pick a playlist")
          }
        }
      }
    }
  }

  private func sliderEditingChanged(editingStarted: Bool) {
    if editingStarted {
      // Tell the PlayerTimeObserver to stop publishing updates while the user is interacting
      // with the slider (otherwise it would keep jumping from where they've moved it to, back
      // to where the player is currently at)
      if let audioPlayerObserver = audioPlayerObserver.audioPlayerObserver {
        audioPlayer.removeTimeObserver(audioPlayerObserver)
        self.audioPlayerObserver.audioPlayerObserver = nil
      }
    }
    else {
      // Editing finished, start the seek
      let targetTime = CMTime(seconds: currentTime, preferredTimescale: 600)
      audioPlayer.seek(to: targetTime) { _ in
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        audioPlayerObserver.audioPlayerObserver = audioPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
          currentTime = time.seconds
          currentDuration = audioPlayer.currentItem!.duration.seconds
          if currentDuration.isNaN {
            currentDuration = 0
          }
        }
      }
    }
  }
}
