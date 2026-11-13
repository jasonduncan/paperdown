import AppKit
import Foundation

struct AppMetadata: Equatable {
    let version: String
    let build: String
}

struct DiagnosticsSnapshot: Equatable {
    let supportRoot: URL
    let servicesRoot: URL
    let logsRoot: URL
    let settingsURL: URL
    let installedRuntimeRoot: URL
    let bundledRuntimeRoot: URL?
    let latestLogURL: URL?
    let appMetadata: AppMetadata
}

struct DiagnosticsService {
    let supportRoot: URL
    let servicesRoot: URL
    let logsRoot: URL
    let settingsURL: URL
    let installedRuntimeRoot: URL
    let bundledRuntimeRoot: URL?
    private let fileManager: FileManager
    private let appMetadataProvider: () -> AppMetadata

    init(
        supportRoot: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/paperdown", isDirectory: true),
        servicesRoot: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services", isDirectory: true),
        logsRoot: URL? = nil,
        settingsURL: URL = AppSettingsStore.defaultSettingsURL(),
        installedRuntimeRoot: URL? = nil,
        bundledRuntimeRoot: URL? = DiagnosticsService.defaultBundledRuntimeRoot(),
        fileManager: FileManager = .default,
        appMetadataProvider: @escaping () -> AppMetadata = DiagnosticsService.defaultAppMetadata
    ) {
        self.supportRoot = supportRoot
        self.servicesRoot = servicesRoot
        self.logsRoot = logsRoot ?? DiagnosticsService.defaultLogsRoot()
        self.settingsURL = settingsURL
        self.installedRuntimeRoot = installedRuntimeRoot
            ?? supportRoot.appendingPathComponent("paperdown-runtime", isDirectory: true)
        self.bundledRuntimeRoot = bundledRuntimeRoot
        self.fileManager = fileManager
        self.appMetadataProvider = appMetadataProvider
    }

    func openSupportDirectory() {
        openDirectory(at: supportRoot)
    }

    func openServicesDirectory() {
        openDirectory(at: servicesRoot)
    }

    func openLogsDirectory() {
        openDirectory(at: logsRoot)
    }

    func openLatestLogOrLogsDirectory() {
        if let latestLogURL {
            NSWorkspace.shared.activateFileViewerSelecting([latestLogURL])
        } else {
            openLogsDirectory()
        }
    }

    func openInstalledRuntimeOrSupportDirectory() {
        if fileManager.fileExists(atPath: installedRuntimeRoot.path) {
            openDirectory(at: installedRuntimeRoot)
        } else {
            openSupportDirectory()
        }
    }

    func openBundledRuntimeOrSupportDirectory() {
        if let bundledRuntimeRoot {
            openDirectory(at: bundledRuntimeRoot)
        } else {
            openSupportDirectory()
        }
    }

    func supportReport(
        status: InstallStatus,
        settings: AppSettings,
        releaseReadiness: ReleaseReadiness? = nil
    ) -> String {
        let snapshot = snapshot()
        let missingWorkflows = status.missingWorkflowNames.isEmpty
            ? "none"
            : status.missingWorkflowNames.joined(separator: ", ")
        let invalidWorkflows = status.invalidWorkflowNames.isEmpty
            ? "none"
            : status.invalidWorkflowNames.joined(separator: ", ")
        let messages = status.messages.isEmpty ? "none" : status.messages.joined(separator: " | ")
        let releaseState = releaseReadiness.map {
            $0.state == .ready ? "ready" : "degraded"
        } ?? "unknown"
        let developerIDs = releaseReadiness.map {
            $0.developerIDIdentities.isEmpty ? "none" : $0.developerIDIdentities.joined(separator: ", ")
        } ?? "unknown"
        let notaryProfile = releaseReadiness.map {
            "\($0.notaryProfileName) (\($0.notaryProfileConfigured ? "configured" : "missing"))"
        } ?? "unknown"
        let releaseMessages = releaseReadiness.map {
            $0.messages.isEmpty ? "none" : $0.messages.joined(separator: " | ")
        } ?? "unknown"

        return [
            "Paperdown Diagnostics",
            "Version: \(snapshot.appMetadata.version) (\(snapshot.appMetadata.build))",
            "State: \(status.state.rawValue)",
            "Runtime Installed: \(status.runtimeInstalled ? "yes" : "no")",
            "Finder Actions Installed: \(status.quickActionsInstalled ? "yes" : "no")",
            "Compiled Cover Page Default: \(settings.compiledCoverPageEnabled ? "on" : "off")",
            "Compiled Table of Contents Default: \(settings.compiledTableOfContentsEnabled ? "on" : "off")",
            "Settings File: \(snapshot.settingsURL.path)",
            "Support Folder: \(snapshot.supportRoot.path)",
            "Installed Runtime: \(snapshot.installedRuntimeRoot.path)",
            "Bundled Runtime: \(snapshot.bundledRuntimeRoot?.path ?? "not detected")",
            "Services Folder: \(snapshot.servicesRoot.path)",
            "Logs Folder: \(snapshot.logsRoot.path)",
            "Latest Log: \(snapshot.latestLogURL?.path ?? "none")",
            "Release Readiness: \(releaseState)",
            "Developer ID Identities: \(developerIDs)",
            "Notary Profile: \(notaryProfile)",
            "Release Messages: \(releaseMessages)",
            "Missing Workflows: \(missingWorkflows)",
            "Invalid Workflows: \(invalidWorkflows)",
            "Messages: \(messages)",
        ].joined(separator: "\n")
    }

    func copySupportReport(
        status: InstallStatus,
        settings: AppSettings,
        releaseReadiness: ReleaseReadiness? = nil
    ) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(
            supportReport(status: status, settings: settings, releaseReadiness: releaseReadiness),
            forType: .string
        )
    }

    func snapshot() -> DiagnosticsSnapshot {
        DiagnosticsSnapshot(
            supportRoot: supportRoot,
            servicesRoot: servicesRoot,
            logsRoot: logsRoot,
            settingsURL: settingsURL,
            installedRuntimeRoot: installedRuntimeRoot,
            bundledRuntimeRoot: bundledRuntimeRoot,
            latestLogURL: latestLogURL,
            appMetadata: appMetadataProvider()
        )
    }

    var latestLogURL: URL? {
        let logURLs = (try? fileManager.contentsOfDirectory(
            at: logsRoot,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return logURLs
            .filter { $0.pathExtension == "log" }
            .max { lhs, rhs in
                let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhsDate < rhsDate
            }
    }

    private func openDirectory(at url: URL) {
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }

    private static func defaultLogsRoot() -> URL {
        if let override = ProcessInfo.processInfo.environment["PAPERDOWN_LOG_DIR"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/paperdown", isDirectory: true)
    }

    private static func defaultBundledRuntimeRoot() -> URL? {
        guard let resourceRoot = Bundle.main.resourceURL else {
            return nil
        }
        let bundledRuntimeRoot = resourceRoot.appendingPathComponent("paperdown-runtime", isDirectory: true)
        return FileManager.default.fileExists(atPath: bundledRuntimeRoot.path) ? bundledRuntimeRoot : nil
    }

    private static func defaultAppMetadata() -> AppMetadata {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = (info["CFBundleShortVersionString"] as? String)
            ?? (info["MARKETING_VERSION"] as? String)
            ?? "development"
        let build = (info["CFBundleVersion"] as? String)
            ?? (info["CURRENT_PROJECT_VERSION"] as? String)
            ?? "dev"
        return AppMetadata(version: version, build: build)
    }
}
