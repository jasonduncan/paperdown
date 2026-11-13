import Foundation

struct HealthCheckService {
    static let expectedWorkflowNames = [
        "Convert to PDF (Report).workflow",
        "Convert to PDF (Memo).workflow",
        "Convert to PDF (Handout).workflow",
        "Merge to PDF (Packet).workflow",
        "Merge to PDF (Compiled).workflow",
    ]

    let runtimeRoot: URL
    let servicesRoot: URL
    private let fileManager: FileManager

    init(
        runtimeRoot: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/paperdown", isDirectory: true),
        servicesRoot: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services", isDirectory: true),
        fileManager: FileManager = .default
    ) {
        self.runtimeRoot = runtimeRoot
        self.servicesRoot = servicesRoot
        self.fileManager = fileManager
    }

    func currentStatus() -> InstallStatus {
        let installedRuntimeRoot = runtimeRoot
            .appendingPathComponent("paperdown-runtime", isDirectory: true)
        let runtimeBinary = installedRuntimeRoot
            .appendingPathComponent("bin", isDirectory: true)
            .appendingPathComponent("paperdown")

        let runtimeInstalled = fileManager.fileExists(atPath: runtimeBinary.path)
        let expectedQuickActionBinary = installedRuntimeRoot
            .appendingPathComponent("bin", isDirectory: true)
            .appendingPathComponent("paperdown-quick-action")
            .path

        var missingWorkflows: [String] = []
        var invalidWorkflows: [String] = []

        for workflowName in Self.expectedWorkflowNames {
            let workflowURL = servicesRoot.appendingPathComponent(workflowName, isDirectory: true)
            guard fileManager.fileExists(atPath: workflowURL.path) else {
                missingWorkflows.append(workflowName)
                continue
            }

            guard workflowPointsAtInstalledRuntime(workflowURL: workflowURL, expectedQuickActionBinary: expectedQuickActionBinary) else {
                invalidWorkflows.append(workflowName)
                continue
            }
        }

        let quickActionsInstalled = missingWorkflows.isEmpty && invalidWorkflows.isEmpty

        var messages: [String] = []
        if !runtimeInstalled {
            messages.append("Packaged runtime is missing.")
        }
        if !quickActionsInstalled {
            messages.append("Finder Quick Actions are missing or incomplete.")
        }
        if !missingWorkflows.isEmpty {
            messages.append("Missing Finder Quick Actions: \(missingWorkflows.joined(separator: ", "))")
        }
        if !invalidWorkflows.isEmpty {
            messages.append("Finder Quick Actions need repair: \(invalidWorkflows.joined(separator: ", "))")
        }

        let state: InstallStatus.State = messages.isEmpty ? .ready : .degraded
        return InstallStatus(
            state: state,
            runtimeInstalled: runtimeInstalled,
            quickActionsInstalled: quickActionsInstalled,
            missingWorkflowNames: missingWorkflows,
            invalidWorkflowNames: invalidWorkflows,
            messages: messages
        )
    }

    private func workflowPointsAtInstalledRuntime(workflowURL: URL, expectedQuickActionBinary: String) -> Bool {
        let documentURL = workflowURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("document.wflow")
        guard
            fileManager.fileExists(atPath: documentURL.path),
            let documentContents = try? String(contentsOf: documentURL, encoding: .utf8)
        else {
            return false
        }

        return documentContents.contains(expectedQuickActionBinary)
    }
}
