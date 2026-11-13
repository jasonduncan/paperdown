import SwiftUI

struct SettingsView: View {
    private let settingsStore: AppSettingsStore
    private let diagnosticsService: DiagnosticsService
    private let releaseReadinessService: ReleaseReadinessService

    @State private var settings: AppSettings
    @State private var diagnosticsSnapshot: DiagnosticsSnapshot
    @State private var releaseReadiness: ReleaseReadiness
    @State private var statusMessage: String?

    init(
        settingsStore: AppSettingsStore = AppSettingsStore(),
        diagnosticsService: DiagnosticsService = DiagnosticsService(),
        releaseReadinessService: ReleaseReadinessService = ReleaseReadinessService()
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsService = diagnosticsService
        self.releaseReadinessService = releaseReadinessService
        _settings = State(initialValue: (try? settingsStore.load()) ?? AppSettings())
        _diagnosticsSnapshot = State(initialValue: diagnosticsService.snapshot())
        _releaseReadiness = State(initialValue: releaseReadinessService.snapshot())
    }

    var body: some View {
        Form {
            Section("Compiled Defaults") {
                Toggle("Show cover page by default", isOn: compiledCoverBinding)
                Toggle("Show table of contents by default", isOn: compiledTocBinding)
            }

            Section("Diagnostics") {
                HStack(spacing: 12) {
                    Button("Open Latest Log") {
                        diagnosticsService.openLatestLogOrLogsDirectory()
                    }
                    Button("Open Logs") {
                        diagnosticsService.openLogsDirectory()
                    }
                    Button("Open Support Folder") {
                        diagnosticsService.openSupportDirectory()
                    }
                    Button("Open Installed Runtime") {
                        diagnosticsService.openInstalledRuntimeOrSupportDirectory()
                    }
                    Button("Open Services Folder") {
                        diagnosticsService.openServicesDirectory()
                    }
                    Button("Open Bundled Runtime") {
                        diagnosticsService.openBundledRuntimeOrSupportDirectory()
                    }
                    Button("Copy Support Report") {
                        diagnosticsService.copySupportReport(
                            status: currentStatus,
                            settings: settings,
                            releaseReadiness: releaseReadiness
                        )
                        statusMessage = "Copied a Paperdown diagnostics report to the clipboard."
                    }
                    Button("Refresh Release Checks") {
                        refreshDiagnostics()
                        statusMessage = "Refreshed Paperdown release-readiness checks."
                    }
                }
            }

            Section("Paths") {
                pathRow(title: "Settings File", value: diagnosticsSnapshot.settingsURL.path)
                pathRow(title: "Logs Folder", value: diagnosticsSnapshot.logsRoot.path)
                pathRow(title: "Latest Log", value: diagnosticsSnapshot.latestLogURL?.path ?? "No logs yet")
                pathRow(title: "Support Folder", value: diagnosticsSnapshot.supportRoot.path)
                pathRow(title: "Installed Runtime", value: diagnosticsSnapshot.installedRuntimeRoot.path)
                pathRow(title: "Services Folder", value: diagnosticsSnapshot.servicesRoot.path)
                pathRow(
                    title: "Bundled Runtime",
                    value: diagnosticsSnapshot.bundledRuntimeRoot?.path ?? "No bundled runtime detected"
                )
            }

            Section("App") {
                Text("Version \(diagnosticsSnapshot.appMetadata.version) (\(diagnosticsSnapshot.appMetadata.build))")
                    .foregroundStyle(.secondary)
            }

            Section("Install Status") {
                pathRow(
                    title: "Missing Actions",
                    value: currentStatus.missingWorkflowNames.isEmpty
                        ? "None"
                        : currentStatus.missingWorkflowNames.joined(separator: ", ")
                )
                pathRow(
                    title: "Actions Needing Repair",
                    value: currentStatus.invalidWorkflowNames.isEmpty
                        ? "None"
                        : currentStatus.invalidWorkflowNames.joined(separator: ", ")
                )
            }

            Section("Release Readiness") {
                pathRow(
                    title: "Developer ID Identities",
                    value: releaseReadiness.developerIDIdentities.isEmpty
                        ? "None"
                        : releaseReadiness.developerIDIdentities.joined(separator: ", ")
                )
                pathRow(
                    title: "Notary Profile",
                    value: "\(releaseReadiness.notaryProfileName) (\(releaseReadiness.notaryProfileConfigured ? "configured" : "missing"))"
                )
                pathRow(
                    title: "Release State",
                    value: releaseReadiness.state == .ready ? "Ready" : "Degraded"
                )
                pathRow(
                    title: "Release Messages",
                    value: releaseReadiness.messages.isEmpty ? "None" : releaseReadiness.messages.joined(separator: " | ")
                )
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 520)
        .onAppear {
            refreshDiagnostics()
        }
    }

    private var compiledCoverBinding: Binding<Bool> {
        Binding(
            get: { settings.compiledCoverPageEnabled },
            set: { newValue in
                settings.compiledCoverPageEnabled = newValue
                persistSettings()
            }
        )
    }

    private var compiledTocBinding: Binding<Bool> {
        Binding(
            get: { settings.compiledTableOfContentsEnabled },
            set: { newValue in
                settings.compiledTableOfContentsEnabled = newValue
                persistSettings()
            }
        )
    }

    private func persistSettings() {
        do {
            try settingsStore.save(settings)
            refreshDiagnostics()
            statusMessage = "Saved settings to \(settingsStore.settingsURL.path)."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func refreshDiagnostics() {
        diagnosticsSnapshot = diagnosticsService.snapshot()
        releaseReadiness = releaseReadinessService.snapshot()
    }

    private var currentStatus: InstallStatus {
        HealthCheckService(
            runtimeRoot: diagnosticsSnapshot.supportRoot,
            servicesRoot: diagnosticsSnapshot.servicesRoot
        ).currentStatus()
    }

    @ViewBuilder
    private func pathRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
            Text(value)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
}
