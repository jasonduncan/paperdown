import Foundation

struct AppSettings: Codable, Equatable {
    var compiledCoverPageEnabled: Bool
    var compiledTableOfContentsEnabled: Bool

    init(
        compiledCoverPageEnabled: Bool = true,
        compiledTableOfContentsEnabled: Bool = true
    ) {
        self.compiledCoverPageEnabled = compiledCoverPageEnabled
        self.compiledTableOfContentsEnabled = compiledTableOfContentsEnabled
    }
}

struct AppSettingsStore {
    let settingsURL: URL
    private let fileManager: FileManager
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(
        settingsURL: URL = AppSettingsStore.defaultSettingsURL(),
        fileManager: FileManager = .default
    ) {
        self.settingsURL = settingsURL
        self.fileManager = fileManager
    }

    func load() throws -> AppSettings {
        guard fileManager.fileExists(atPath: settingsURL.path) else {
            return AppSettings()
        }

        let data = try Data(contentsOf: settingsURL)
        return try decoder.decode(AppSettings.self, from: data)
    }

    func save(_ settings: AppSettings) throws {
        let parentDirectory = settingsURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(settings)
        try data.write(to: settingsURL, options: [.atomic])
    }

    static func defaultSettingsURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/paperdown", isDirectory: true)
            .appendingPathComponent("settings.json")
    }
}
