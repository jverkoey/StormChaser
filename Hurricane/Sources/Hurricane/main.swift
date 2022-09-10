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
//
//let itunes = try ITLibrary(apiVersion: "1.0")
//for track in itunes.allMediaItems {
//  if let rating = track.value(forProperty: ITLibMediaItemPropertyRating) as? Int,
//     let albumRating = track.value(forProperty: ITLibMediaItemPropertyAlbumRating) as? Int,
//     albumRating != rating {
//    print("Title: ", track.title)
//    let albumRating = track.value(forProperty: ITLibMediaItemPropertyAlbumRating)
//    print("Album rating: ", albumRating)
//    print("Rating: ", rating, track.rating)
//  }
//}

private let documentsUrl = getDocumentsDirectory()
private let dbUrl = documentsUrl.appendingPathComponent("hurricane.sqlite3")
private let db = try Connection(dbUrl.absoluteString)

//try migrateItunesToDatabase(db: db)

try writeDatabaseToITunesXML(db: db) { track in
  return !track.ratingComputed && track.rating >= 60
}
