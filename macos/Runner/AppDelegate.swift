import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  static func migrateLegacyPreferences() {
    let defaults = UserDefaults.standard
    let marker = "SMTFusionLegacySettingsMigrated"
    if defaults.bool(forKey: marker) { return }
    let legacy = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Containers/com.smtcheck.smtCheck/Data/Library/Preferences/com.smtcheck.smtCheck.plist")
    if FileManager.default.fileExists(atPath: legacy.path) {
      do {
        let data = try Data(contentsOf: legacy)
        guard let values = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
          throw CocoaError(.propertyListReadCorrupt)
        }
        for (key, value) in values where key.hasPrefix("flutter.") && defaults.object(forKey: key) == nil {
          defaults.set(value, forKey: key)
        }
        defaults.removeObject(forKey: "flutter.settingsMigrationFailed")
      } catch {
        defaults.set(true, forKey: "flutter.settingsMigrationFailed")
        return
      }
    }
    defaults.set(true, forKey: marker)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
