import Foundation

public struct ITunesPlaylist: Codable {
  public init(name: String, description: String, master: Bool? = nil, playlistID: Int, playlistPersistentID: String, parentPersistentID: String? = nil, visible: Bool? = nil, allItems: Bool, folder: Bool? = nil, playlistItems: [ITunesPlaylistItem]? = nil) {
    self.name = name
    self.description = description
    self.master = master
    self.playlistID = playlistID
    self.playlistPersistentID = playlistPersistentID
    self.parentPersistentID = parentPersistentID
    self.visible = visible
    self.allItems = allItems
    self.folder = folder
    self.playlistItems = playlistItems
  }

  public let name: String
  public let description: String
  public let master: Bool?
  public let playlistID: Int
  public let playlistPersistentID: String
  public let parentPersistentID: String?
  public let visible: Bool?
  public let allItems: Bool
  public let folder: Bool?
  public let playlistItems: [ITunesPlaylistItem]?

  enum CodingKeys: String, CodingKey {
    case name = "Name"
    case description = "Description"
    case master = "Master"
    case playlistID = "Playlist ID"
    case playlistPersistentID = "Playlist Persistent ID"
    case parentPersistentID = "Parent Persistent ID"
    case visible = "Visible"
    case allItems = "All Items"
    case folder = "Folder"
    case playlistItems = "Playlist Items"
  }
}
