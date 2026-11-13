import XCTest
@testable import Paperdown

final class HealthCheckServiceTests: XCTestCase {
    func testAppSettingsDefaultToCompiledCoverAndTableOfContentsEnabled() {
        let settings = AppSettings()

        XCTAssertTrue(settings.compiledCoverPageEnabled)
        XCTAssertTrue(settings.compiledTableOfContentsEnabled)
    }

    func testAppSettingsPersistAndReloadToggledCompiledDefaults() throws {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let settingsURL = tempDirectory.appendingPathComponent("settings.json")
        let store = AppSettingsStore(settingsURL: settingsURL)

        var settings = AppSettings()
        settings.compiledCoverPageEnabled = false
        settings.compiledTableOfContentsEnabled = false
        try store.save(settings)

        let reloaded = try store.load()
        XCTAssertFalse(reloaded.compiledCoverPageEnabled)
        XCTAssertFalse(reloaded.compiledTableOfContentsEnabled)
    }

    func testMissingRuntimeReportsDegradedStatus() throws {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let service = HealthCheckService(
            runtimeRoot: tempDirectory.appendingPathComponent("Application Support/paperdown"),
            servicesRoot: tempDirectory.appendingPathComponent("Services")
        )

        let status = service.currentStatus()

        XCTAssertEqual(status.state, .degraded)
        XCTAssertFalse(status.runtimeInstalled)
        XCTAssertFalse(status.quickActionsInstalled)
        XCTAssertTrue(status.messages.contains("Packaged runtime is missing."))
    }

    func testMissingQuickActionsReportDegradedStatus() throws {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let runtimeRoot = tempDirectory.appendingPathComponent("Application Support/paperdown")
        let runtimeBin = runtimeRoot.appendingPathComponent("paperdown-runtime/bin")
        try FileManager.default.createDirectory(at: runtimeBin, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: runtimeBin.appendingPathComponent("paperdown").path, contents: Data())

        let service = HealthCheckService(
            runtimeRoot: runtimeRoot,
            servicesRoot: tempDirectory.appendingPathComponent("Services")
        )

        let status = service.currentStatus()

        XCTAssertEqual(status.state, .degraded)
        XCTAssertTrue(status.runtimeInstalled)
        XCTAssertFalse(status.quickActionsInstalled)
        XCTAssertTrue(status.messages.contains("Finder Quick Actions are missing or incomplete."))
    }

    func testHealthyRuntimeAndQuickActionsReportReadyStatus() throws {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let runtimeRoot = tempDirectory.appendingPathComponent("Application Support/paperdown")
        let runtimeBin = runtimeRoot.appendingPathComponent("paperdown-runtime/bin")
        try FileManager.default.createDirectory(at: runtimeBin, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: runtimeBin.appendingPathComponent("paperdown").path, contents: Data())

        let servicesRoot = tempDirectory.appendingPathComponent("Services")
        try FileManager.default.createDirectory(at: servicesRoot, withIntermediateDirectories: true)

        for workflow in HealthCheckService.expectedWorkflowNames {
            try writeWorkflow(
                named: workflow,
                servicesRoot: servicesRoot,
                runtimeRoot: runtimeRoot.appendingPathComponent("paperdown-runtime", isDirectory: true)
            )
        }

        let service = HealthCheckService(
            runtimeRoot: runtimeRoot,
            servicesRoot: servicesRoot
        )

        let status = service.currentStatus()

        XCTAssertEqual(status.state, .ready)
        XCTAssertTrue(status.runtimeInstalled)
        XCTAssertTrue(status.quickActionsInstalled)
        XCTAssertTrue(status.messages.isEmpty)
    }

    func testWorkflowPointingAtWrongRuntimeReportsDegradedStatus() throws {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let runtimeRoot = tempDirectory.appendingPathComponent("Application Support/paperdown")
        let installedRuntimeRoot = runtimeRoot.appendingPathComponent("paperdown-runtime", isDirectory: true)
        let runtimeBin = installedRuntimeRoot.appendingPathComponent("bin")
        try FileManager.default.createDirectory(at: runtimeBin, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: runtimeBin.appendingPathComponent("paperdown").path, contents: Data())

        let servicesRoot = tempDirectory.appendingPathComponent("Services")
        try FileManager.default.createDirectory(at: servicesRoot, withIntermediateDirectories: true)

        for workflow in HealthCheckService.expectedWorkflowNames {
            try writeWorkflow(
                named: workflow,
                servicesRoot: servicesRoot,
                runtimeRoot: installedRuntimeRoot
            )
        }

        try writeWorkflow(
            named: "Merge to PDF (Compiled).workflow",
            servicesRoot: servicesRoot,
            runtimeRoot: tempDirectory.appendingPathComponent("stale-runtime", isDirectory: true)
        )

        let service = HealthCheckService(
            runtimeRoot: runtimeRoot,
            servicesRoot: servicesRoot
        )

        let status = service.currentStatus()

        XCTAssertEqual(status.state, .degraded)
        XCTAssertTrue(status.runtimeInstalled)
        XCTAssertFalse(status.quickActionsInstalled)
        XCTAssertTrue(status.invalidWorkflowNames.contains("Merge to PDF (Compiled).workflow"))
        XCTAssertTrue(status.messages.contains("Finder Quick Actions need repair: Merge to PDF (Compiled).workflow"))
    }

    func testDiagnosticsSnapshotIncludesLatestLogAndSettingsPath() throws {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let supportRoot = tempDirectory.appendingPathComponent("Application Support/paperdown", isDirectory: true)
        let servicesRoot = tempDirectory.appendingPathComponent("Services", isDirectory: true)
        let logsRoot = tempDirectory.appendingPathComponent("Logs/paperdown", isDirectory: true)
        let bundledRuntimeRoot = tempDirectory.appendingPathComponent("Bundled/paperdown-runtime", isDirectory: true)

        try FileManager.default.createDirectory(at: supportRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: servicesRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: logsRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: bundledRuntimeRoot, withIntermediateDirectories: true)

        let settingsURL = supportRoot.appendingPathComponent("settings.json")
        try Data("{}".utf8).write(to: settingsURL)

        let oldLog = logsRoot.appendingPathComponent("paperdown-20260405-170000.log")
        let newLog = logsRoot.appendingPathComponent("paperdown-20260405-180000.log")
        try Data("old".utf8).write(to: oldLog)
        try Data("new".utf8).write(to: newLog)

        let oldDate = Date(timeIntervalSince1970: 100)
        let newDate = Date(timeIntervalSince1970: 200)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: oldLog.path)
        try FileManager.default.setAttributes([.modificationDate: newDate], ofItemAtPath: newLog.path)

        let diagnostics = DiagnosticsService(
            supportRoot: supportRoot,
            servicesRoot: servicesRoot,
            logsRoot: logsRoot,
            settingsURL: settingsURL,
            bundledRuntimeRoot: bundledRuntimeRoot,
            appMetadataProvider: { AppMetadata(version: "0.1.0", build: "7") }
        )

        let snapshot = diagnostics.snapshot()

        XCTAssertEqual(snapshot.settingsURL, settingsURL)
        XCTAssertEqual(snapshot.logsRoot, logsRoot)
        XCTAssertEqual(snapshot.servicesRoot, servicesRoot)
        XCTAssertEqual(snapshot.supportRoot, supportRoot)
        XCTAssertEqual(snapshot.bundledRuntimeRoot, bundledRuntimeRoot)
        XCTAssertEqual(
            snapshot.latestLogURL?.resolvingSymlinksInPath(),
            newLog.resolvingSymlinksInPath()
        )
        XCTAssertEqual(snapshot.appMetadata.version, "0.1.0")
        XCTAssertEqual(snapshot.appMetadata.build, "7")
    }

    func testDiagnosticsSupportReportIncludesStatusAndPaths() throws {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let supportRoot = tempDirectory.appendingPathComponent("Application Support/paperdown", isDirectory: true)
        let servicesRoot = tempDirectory.appendingPathComponent("Services", isDirectory: true)
        let logsRoot = tempDirectory.appendingPathComponent("Logs/paperdown", isDirectory: true)
        let bundledRuntimeRoot = tempDirectory.appendingPathComponent("Bundled/paperdown-runtime", isDirectory: true)

        try FileManager.default.createDirectory(at: supportRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: servicesRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: logsRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: bundledRuntimeRoot, withIntermediateDirectories: true)

        let settingsURL = supportRoot.appendingPathComponent("settings.json")
        try Data("{}".utf8).write(to: settingsURL)

        let diagnostics = DiagnosticsService(
            supportRoot: supportRoot,
            servicesRoot: servicesRoot,
            logsRoot: logsRoot,
            settingsURL: settingsURL,
            bundledRuntimeRoot: bundledRuntimeRoot,
            appMetadataProvider: { AppMetadata(version: "0.2.0", build: "11") }
        )

        var settings = AppSettings()
        settings.compiledCoverPageEnabled = false
        let status = InstallStatus(
            state: .degraded,
            runtimeInstalled: true,
            quickActionsInstalled: false,
            missingWorkflowNames: ["Convert to PDF (Memo).workflow"],
            invalidWorkflowNames: ["Merge to PDF (Compiled).workflow"],
            messages: ["Finder Quick Actions need repair: Merge to PDF (Compiled).workflow"]
        )

        let report = diagnostics.supportReport(status: status, settings: settings)

        XCTAssertTrue(report.contains("Paperdown Diagnostics"))
        XCTAssertTrue(report.contains("Version: 0.2.0 (11)"))
        XCTAssertTrue(report.contains("State: degraded"))
        XCTAssertTrue(report.contains("Compiled Cover Page Default: off"))
        XCTAssertTrue(report.contains("Missing Workflows: Convert to PDF (Memo).workflow"))
        XCTAssertTrue(report.contains("Invalid Workflows: Merge to PDF (Compiled).workflow"))
        XCTAssertTrue(report.contains("Settings File: \(settingsURL.path)"))
        XCTAssertTrue(report.contains("Bundled Runtime: \(bundledRuntimeRoot.path)"))
    }

    private func writeWorkflow(named workflowName: String, servicesRoot: URL, runtimeRoot: URL) throws {
        let contentsRoot = servicesRoot
            .appendingPathComponent(workflowName, isDirectory: true)
            .appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contentsRoot, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: contentsRoot.appendingPathComponent("Info.plist").path, contents: Data())
        let command = "\"\(runtimeRoot.path)/bin/paperdown-quick-action\" convert --style report \"$@\""
        try Data(command.utf8).write(to: contentsRoot.appendingPathComponent("document.wflow"))
    }
}
