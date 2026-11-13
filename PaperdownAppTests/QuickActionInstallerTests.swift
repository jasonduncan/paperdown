import XCTest
@testable import Paperdown

final class QuickActionInstallerTests: XCTestCase {
    func testRuntimeInstallerCopiesBundledRuntimeIntoAppSupport() throws {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let sourceRuntime = tempDirectory.appendingPathComponent("bundle/paperdown-runtime", isDirectory: true)
        let sourceBin = sourceRuntime.appendingPathComponent("bin", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceBin, withIntermediateDirectories: true)
        let sourceBinary = sourceBin.appendingPathComponent("paperdown")
        try Data("runtime".utf8).write(to: sourceBinary)

        let installer = RuntimeInstaller(
            sourceRuntimeRoot: sourceRuntime,
            appSupportRoot: tempDirectory.appendingPathComponent("Application Support/paperdown", isDirectory: true)
        )

        let installedRoot = try installer.install()

        XCTAssertEqual(installedRoot.lastPathComponent, "paperdown-runtime")
        XCTAssertTrue(FileManager.default.fileExists(atPath: installedRoot.appendingPathComponent("bin/paperdown").path))
    }

    func testQuickActionInstallerRewritesWorkflowPlaceholderToRuntimePath() throws {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let runtimeRoot = tempDirectory.appendingPathComponent("Application Support/paperdown/paperdown-runtime", isDirectory: true)
        let generatedRoot = runtimeRoot.appendingPathComponent("macos/quick-actions/generated/Convert to PDF (Report).workflow/Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: generatedRoot, withIntermediateDirectories: true)
        try Data("plist".utf8).write(to: generatedRoot.appendingPathComponent("Info.plist"))
        try Data("<string>__PAPERDOWN_REPO_ROOT__/bin/paperdown-quick-action</string>".utf8)
            .write(to: generatedRoot.appendingPathComponent("document.wflow"))

        let servicesRoot = tempDirectory.appendingPathComponent("Services", isDirectory: true)
        let installer = QuickActionInstaller(
            runtimeRoot: runtimeRoot,
            servicesRoot: servicesRoot
        )

        try installer.installOrRepair()

        let installedWorkflow = servicesRoot
            .appendingPathComponent("Convert to PDF (Report).workflow/Contents/document.wflow")
        let workflowContents = try String(contentsOf: installedWorkflow, encoding: .utf8)
        XCTAssertTrue(workflowContents.contains(runtimeRoot.path))
    }
}
