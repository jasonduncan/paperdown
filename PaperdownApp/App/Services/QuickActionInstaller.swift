import Foundation

enum QuickActionInstallerError: LocalizedError {
    case missingGeneratedWorkflows(String)
    case missingWorkflowDocument(String)

    var errorDescription: String? {
        switch self {
        case .missingGeneratedWorkflows(let path):
            return "Paperdown could not find generated Finder actions at \(path)."
        case .missingWorkflowDocument(let path):
            return "Paperdown expected a workflow document at \(path), but it was missing."
        }
    }
}

struct QuickActionInstaller {
    static let legacyWorkflowName = "Convert Markdown to PDF.workflow"

    let runtimeRoot: URL
    let servicesRoot: URL
    private let fileManager: FileManager

    init(
        runtimeRoot: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/paperdown/paperdown-runtime", isDirectory: true),
        servicesRoot: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services", isDirectory: true),
        fileManager: FileManager = .default
    ) {
        self.runtimeRoot = runtimeRoot
        self.servicesRoot = servicesRoot
        self.fileManager = fileManager
    }

    func installOrRepair() throws {
        let generatedWorkflowsRoot = runtimeRoot
            .appendingPathComponent("macos/quick-actions/generated", isDirectory: true)
        guard fileManager.fileExists(atPath: generatedWorkflowsRoot.path) else {
            throw QuickActionInstallerError.missingGeneratedWorkflows(generatedWorkflowsRoot.path)
        }

        let workflowURLs = try fileManager.contentsOfDirectory(
            at: generatedWorkflowsRoot,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension == "workflow" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard !workflowURLs.isEmpty else {
            throw QuickActionInstallerError.missingGeneratedWorkflows(generatedWorkflowsRoot.path)
        }

        try fileManager.createDirectory(at: servicesRoot, withIntermediateDirectories: true)
        try removeIfPresent(at: servicesRoot.appendingPathComponent(Self.legacyWorkflowName))

        for workflowURL in workflowURLs {
            let targetURL = servicesRoot.appendingPathComponent(workflowURL.lastPathComponent, isDirectory: true)
            try removeIfPresent(at: targetURL)
            try fileManager.copyItem(at: workflowURL, to: targetURL)
            try rewriteWorkflowPlaceholder(in: targetURL)
        }

        flushServicesCacheIfNeeded()
    }

    private func rewriteWorkflowPlaceholder(in workflowURL: URL) throws {
        let documentURL = workflowURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("document.wflow")
        guard fileManager.fileExists(atPath: documentURL.path) else {
            throw QuickActionInstallerError.missingWorkflowDocument(documentURL.path)
        }

        let contents = try String(contentsOf: documentURL, encoding: .utf8)
        let rewrittenContents = contents.replacingOccurrences(
            of: "__PAPERDOWN_REPO_ROOT__",
            with: runtimeRoot.path
        )
        try rewrittenContents.write(to: documentURL, atomically: true, encoding: .utf8)
    }

    private func removeIfPresent(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private func flushServicesCacheIfNeeded() {
        let defaultServicesRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services", isDirectory: true)
        guard servicesRoot.standardizedFileURL == defaultServicesRoot.standardizedFileURL else {
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/System/Library/CoreServices/pbs")
        process.arguments = ["-flush"]
        try? process.run()
        process.waitUntilExit()
    }
}
