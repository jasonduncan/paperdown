import XCTest
@testable import Paperdown

final class ReleaseReadinessServiceTests: XCTestCase {
    func testMissingDeveloperIDIdentityAndNotaryProfileReportDegraded() {
        let service = ReleaseReadinessService(
            notaryProfileName: "paperdown",
            commandRunner: { command, _ in
                switch command {
                case "/usr/bin/security":
                    return CommandResult(
                        terminationStatus: 0,
                        standardOutput: "     0 valid identities found\n",
                        standardError: ""
                    )
                case "/usr/bin/xcrun":
                    return CommandResult(
                        terminationStatus: 1,
                        standardOutput: "",
                        standardError: """
                        Error: No Keychain password item found for profile: paperdown

                        Run 'notarytool store-credentials' to create another credential profile.
                        """
                    )
                default:
                    XCTFail("Unexpected command: \(command)")
                    return CommandResult(terminationStatus: 1, standardOutput: "", standardError: "")
                }
            }
        )

        let readiness = service.snapshot()

        XCTAssertEqual(readiness.state, .degraded)
        XCTAssertTrue(readiness.developerIDIdentities.isEmpty)
        XCTAssertFalse(readiness.hasDeveloperIDIdentity)
        XCTAssertEqual(readiness.notaryProfileName, "paperdown")
        XCTAssertFalse(readiness.notaryProfileConfigured)
        XCTAssertTrue(readiness.messages.contains("No Developer ID Application signing identity is installed."))
        XCTAssertTrue(readiness.messages.contains("Notary profile 'paperdown' is not configured."))
    }

    func testDeveloperIDIdentityAndNotaryProfileReportReady() {
        let service = ReleaseReadinessService(
            notaryProfileName: "pdlabs-notary",
            commandRunner: { command, _ in
                switch command {
                case "/usr/bin/security":
                    return CommandResult(
                        terminationStatus: 0,
                        standardOutput: """
                             1) ABCDEF1234567890ABCDEF1234567890ABCDEF12 \"Developer ID Application: PD Labs (ABC1234567)\"
                                1 valid identities found
                            """,
                        standardError: ""
                    )
                case "/usr/bin/xcrun":
                    return CommandResult(
                        terminationStatus: 0,
                        standardOutput: "Successfully retrieved history.\n",
                        standardError: ""
                    )
                default:
                    XCTFail("Unexpected command: \(command)")
                    return CommandResult(terminationStatus: 1, standardOutput: "", standardError: "")
                }
            }
        )

        let readiness = service.snapshot()

        XCTAssertEqual(readiness.state, .ready)
        XCTAssertEqual(readiness.developerIDIdentities, ["Developer ID Application: PD Labs (ABC1234567)"])
        XCTAssertTrue(readiness.hasDeveloperIDIdentity)
        XCTAssertEqual(readiness.notaryProfileName, "pdlabs-notary")
        XCTAssertTrue(readiness.notaryProfileConfigured)
        XCTAssertTrue(readiness.messages.isEmpty)
    }

    func testDiagnosticsSupportReportIncludesReleaseReadiness() throws {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let supportRoot = tempDirectory.appendingPathComponent("Application Support/paperdown", isDirectory: true)
        let servicesRoot = tempDirectory.appendingPathComponent("Services", isDirectory: true)
        let logsRoot = tempDirectory.appendingPathComponent("Logs/paperdown", isDirectory: true)
        try FileManager.default.createDirectory(at: supportRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: servicesRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: logsRoot, withIntermediateDirectories: true)

        let diagnostics = DiagnosticsService(
            supportRoot: supportRoot,
            servicesRoot: servicesRoot,
            logsRoot: logsRoot,
            settingsURL: supportRoot.appendingPathComponent("settings.json"),
            appMetadataProvider: { AppMetadata(version: "0.2.0", build: "12") }
        )

        let report = diagnostics.supportReport(
            status: InstallStatus(
                state: .ready,
                runtimeInstalled: true,
                quickActionsInstalled: true,
                missingWorkflowNames: [],
                invalidWorkflowNames: [],
                messages: []
            ),
            settings: AppSettings(),
            releaseReadiness: ReleaseReadiness(
                state: .degraded,
                developerIDIdentities: [],
                notaryProfileName: "paperdown",
                notaryProfileConfigured: false,
                messages: [
                    "No Developer ID Application signing identity is installed.",
                    "Notary profile 'paperdown' is not configured.",
                ]
            )
        )

        XCTAssertTrue(report.contains("Release Readiness: degraded"))
        XCTAssertTrue(report.contains("Developer ID Identities: none"))
        XCTAssertTrue(report.contains("Notary Profile: paperdown (missing)"))
    }
}
