import Foundation

enum RuntimeInstallerError: LocalizedError {
    case missingSourceRuntime
    case buildScriptFailed(String)
    case stagedRuntimeMissing(String)

    var errorDescription: String? {
        switch self {
        case .missingSourceRuntime:
            return "Paperdown could not find a bundled runtime to install."
        case .buildScriptFailed(let details):
            return "Paperdown could not prepare its runtime. \(details)"
        case .stagedRuntimeMissing(let path):
            return "Paperdown prepared a runtime bundle, but the runtime was missing at \(path)."
        }
    }
}

private struct PreparedRuntimeSource {
    let runtimeRoot: URL
    let cleanupRoot: URL?
}

struct RuntimeInstaller {
    let sourceRuntimeRoot: URL?
    let buildRuntimeScript: URL?
    let appSupportRoot: URL
    private let fileManager: FileManager

    init(
        sourceRuntimeRoot: URL? = RuntimeInstaller.defaultSourceRuntimeRoot(),
        buildRuntimeScript: URL? = RuntimeInstaller.defaultBuildRuntimeScript(),
        appSupportRoot: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/paperdown", isDirectory: true),
        fileManager: FileManager = .default
    ) {
        self.sourceRuntimeRoot = sourceRuntimeRoot
        self.buildRuntimeScript = buildRuntimeScript
        self.appSupportRoot = appSupportRoot
        self.fileManager = fileManager
    }

    func install() throws -> URL {
        let preparedRuntime = try preparedRuntimeSource()
        defer {
            if let cleanupRoot = preparedRuntime.cleanupRoot {
                try? fileManager.removeItem(at: cleanupRoot)
            }
        }

        let installedRuntimeRoot = appSupportRoot.appendingPathComponent("paperdown-runtime", isDirectory: true)
        try fileManager.createDirectory(at: appSupportRoot, withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: installedRuntimeRoot.path) {
            try fileManager.removeItem(at: installedRuntimeRoot)
        }
        try fileManager.copyItem(at: preparedRuntime.runtimeRoot, to: installedRuntimeRoot)
        return installedRuntimeRoot
    }

    private func preparedRuntimeSource() throws -> PreparedRuntimeSource {
        if let sourceRuntimeRoot, fileManager.fileExists(atPath: sourceRuntimeRoot.path) {
            return PreparedRuntimeSource(runtimeRoot: sourceRuntimeRoot, cleanupRoot: nil)
        }

        guard let buildRuntimeScript, fileManager.isExecutableFile(atPath: buildRuntimeScript.path) else {
            throw RuntimeInstallerError.missingSourceRuntime
        }

        let stagingRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("paperdown-runtime-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [buildRuntimeScript.path, "--output-dir", stagingRoot.path]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw RuntimeInstallerError.buildScriptFailed(error.localizedDescription)
        }
        process.waitUntilExit()

        let stderr = String(
            data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stdout = String(
            data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            let details = stderr.isEmpty ? stdout : stderr
            throw RuntimeInstallerError.buildScriptFailed(details.isEmpty ? "Unknown build-runtime-bundle.sh failure." : details)
        }

        let runtimeRoot = stagingRoot.appendingPathComponent("paperdown-runtime", isDirectory: true)
        guard fileManager.fileExists(atPath: runtimeRoot.path) else {
            throw RuntimeInstallerError.stagedRuntimeMissing(runtimeRoot.path)
        }

        return PreparedRuntimeSource(runtimeRoot: runtimeRoot, cleanupRoot: stagingRoot)
    }

    static func defaultSourceRuntimeRoot(fileManager: FileManager = .default) -> URL? {
        guard let resourceRoot = Bundle.main.resourceURL else {
            return nil
        }
        let bundledRuntimeRoot = resourceRoot.appendingPathComponent("paperdown-runtime", isDirectory: true)
        return fileManager.fileExists(atPath: bundledRuntimeRoot.path) ? bundledRuntimeRoot : nil
    }

    static func defaultBuildRuntimeScript(fileManager: FileManager = .default) -> URL? {
        let scriptURL = developerRepoRoot()
            .appendingPathComponent("Packaging", isDirectory: true)
            .appendingPathComponent("build-runtime-bundle.sh")
        return fileManager.isExecutableFile(atPath: scriptURL.path) ? scriptURL : nil
    }

    private static func developerRepoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
