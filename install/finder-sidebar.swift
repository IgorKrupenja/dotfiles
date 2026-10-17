// Prints the Finder sidebar favorites, one folder per line. With a file argument, sets them to the
// folders listed in it instead: mysides and the API it used can no longer change the sidebar, so
// this writes the file sharedfilelistd keeps it in. Restart sharedfilelistd and Finder after that.
import Foundation

let file = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(
  "Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteItems.sfl4")

func readList() throws -> [String: Any] {
  let classes = [NSDictionary.self, NSArray.self, NSString.self, NSNumber.self, NSData.self]
  return try NSKeyedUnarchiver.unarchivedObject(ofClasses: classes, from: Data(contentsOf: file)) as? [String: Any] ?? [:]
}

if CommandLine.arguments.count < 2 {
  for case let item as [String: Any] in try readList()["items"] as? [Any] ?? [] {
    var stale = false
    guard let bookmark = item["Bookmark"] as? Data,
      let url = try? URL(resolvingBookmarkData: bookmark, options: [.withoutUI, .withoutMounting], bookmarkDataIsStale: &stale),
      url.isFileURL
    else { continue }
    print((url.path as NSString).abbreviatingWithTildeInPath)
  }
} else {
  // Keeps the list's other properties
  var list = (try? readList()) ?? [:]
  var failed = false
  let paths = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8).split(separator: "\n")
  list["items"] = paths.compactMap { path -> [String: Any]? in
    let url = URL(fileURLWithPath: (String(path) as NSString).expandingTildeInPath)
    guard let bookmark = try? url.bookmarkData() else {
      fputs("Skipped \(path), it doesn't exist\n", stderr)
      failed = true
      return nil
    }
    return ["visibility": 0, "CustomItemProperties": [String: Any](), "uuid": UUID().uuidString, "Bookmark": bookmark]
  }
  try NSKeyedArchiver.archivedData(withRootObject: list, requiringSecureCoding: false).write(to: file, options: .atomic)
  exit(failed ? 1 : 0)
}
