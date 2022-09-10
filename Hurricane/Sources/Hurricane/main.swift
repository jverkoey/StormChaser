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

//try writeDatabaseToITunesXML(db: db) { track in
//  return !track.ratingComputed && track.rating >= 60
//}

