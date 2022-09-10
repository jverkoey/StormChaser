import Foundation
import iTunesLibrary
import iTunesXML
import HurricaneDB
import SQLite

func getDocumentsDirectory() -> URL {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  let documentsDirectory = paths[0]
  return documentsDirectory
}

private let documentsUrl = getDocumentsDirectory()
private let dbUrl = documentsUrl.appendingPathComponent("hurricane.sqlite3")
private let db = try Connection(dbUrl.absoluteString)

//try migrateItunesToDatabase(db: db)

//for item in try db.prepare(MediaItemTable.table
//  .select(MediaItemTable.id,
//          MediaItemTable.location
//         ).where(!MediaItemTable.ratingComputed && MediaItemTable.rating == 40)
//) {
//  var location = item[MediaItemTable.location]!
//  location = location.replacingOccurrences(of: "/Volumes/CHOCOBO/", with: "/Users/featherless/Dropbox/Chocobo-2star/")
//  location = location.replacingOccurrences(of: "/Volumes/Chocobo/", with: "/Users/featherless/Dropbox/Chocobo-2star/")
//  if FileManager.default.fileExists(atPath: URL(string: location)!.path) {
//    let itemToUpdate = MediaItemTable.table.filter(MediaItemTable.id == item[MediaItemTable.id])
//    try db.run(itemToUpdate.update(MediaItemTable.location <- location))
//  }
//}
//let library = try buildInMemoryRepresentation(db: db)

// Move 1/2-star tracks over to Dropbox
//let fm = FileManager.default
//for (_, track) in library.tracks.filter { !$0.value.ratingComputed && $0.value.rating == 20 } {
//  let url = URL(string: track.location)!
//  if fm.fileExists(atPath: url.path), url.path.starts(with: "/Volumes/CHOCOBO/") {
//    let dropboxPath = url.path.replacingOccurrences(of: "/Volumes/CHOCOBO/", with: "/Users/featherless/Dropbox/Chocobo-1star/")
//    print("Moving \(url.path) to \(dropboxPath)...")
//    try fm.createDirectory(atPath: URL(fileURLWithPath: dropboxPath).deletingLastPathComponent().path, withIntermediateDirectories: true)
//    try fm.moveItem(atPath: url.path, toPath: dropboxPath)
//  }
//}
//
//for (_, track) in library.tracks.filter { !$0.value.ratingComputed && $0.value.rating == 40 } {
//  let url = URL(string: track.location)!
//  if fm.fileExists(atPath: url.path), url.path.starts(with: "/Volumes/CHOCOBO/") {
//    let dropboxPath = url.path.replacingOccurrences(of: "/Volumes/CHOCOBO/", with: "/Users/featherless/Dropbox/Chocobo-2star/")
//    print("Moving \(url.path) to \(dropboxPath)...")
//    try fm.createDirectory(atPath: URL(fileURLWithPath: dropboxPath).deletingLastPathComponent().path, withIntermediateDirectories: true)
//    try fm.moveItem(atPath: url.path, toPath: dropboxPath)
//  }
//}

//try writeDatabaseToITunesXML(db: db) { track in
//  return !track.ratingComputed && track.rating >= 60
//}

