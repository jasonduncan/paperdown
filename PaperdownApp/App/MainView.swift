import SwiftUI

struct MainView: View {
    private let healthCheckService: HealthCheckService
    private let runtimeInstaller: RuntimeInstaller
    private let diagnosticsService: DiagnosticsService
    private let releaseReadinessService: ReleaseReadinessService
    @State private var status: InstallStatus
    @State private var diagnosticsSnapshot: DiagnosticsSnapshot
    @State private var releaseReadiness: ReleaseReadiness
    @State private var actionMessage: String?
    @State private var isWorking = false

    init(
        healthCheckService: HealthCheckService = HealthCheckService(),
        runtimeInstaller: RuntimeInstaller = RuntimeInstaller(),
        diagnosticsService: DiagnosticsService = DiagnosticsService(),
        releaseReadinessService: ReleaseReadinessService = ReleaseReadinessService()
    ) {
        self.healthCheckService = healthCheckService
        self.runtimeInstaller = runtimeInstaller
        self.diagnosticsService = diagnosticsService
        self.releaseReadinessService = releaseReadinessService
        _status = State(initialValue: .unknown)
        _diagnosticsSnapshot = State(initialValue: diagnosticsService.snapshot())
        _releaseReadiness = State(initialValue: releaseReadinessService.snapshot())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paperdown")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text(statusSummary)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Label(status.runtimeInstalled ? "Runtime installed" : "Runtime missing",
                      systemImage: status.runtimeInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                Label(status.quickActionsInstalled ? "Finder actions installed" : "Finder actions incomplete",
                      systemImage: status.quickActionsInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
            }
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(isWorking ? "Working…" : installButtonTitle) {
                    installOrRepair()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isWorking)

                Button("Refresh") {
                    refreshStatus()
                }
                .disabled(isWorking)
            }

            HStack(spacing: 12) {
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

                Button("Copy Support Report") {
                    diagnosticsService.copySupportReport(
                        status: status,
                        settings: currentSettings,
                        releaseReadiness: releaseReadiness
                    )
                    actionMessage = "Copied a Paperdown diagnostics report to the clipboard."
                }

                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
            }

            if let actionMessage {
                Text(actionMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            GroupBox("Diagnostics") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Version \(diagnosticsSnapshot.appMetadata.version) (\(diagnosticsSnapshot.appMetadata.build))")
                    Text(compiledDefaultsSummary)
                    Text("Settings: \(diagnosticsSnapshot.settingsURL.path)")
                    Text("Logs: \(diagnosticsSnapshot.logsRoot.path)")
                    Text("Latest log: \(diagnosticsSnapshot.latestLogURL?.path ?? "No logs yet")")
                    Text("Installed runtime: \(diagnosticsSnapshot.installedRuntimeRoot.path)")
                    Text("Bundled runtime: \(diagnosticsSnapshot.bundledRuntimeRoot?.path ?? "No bundled runtime detected")")
                    Text("Missing actions: \(status.missingWorkflowNames.isEmpty ? "None" : status.missingWorkflowNames.joined(separator: ", "))")
                    Text("Actions needing repair: \(status.invalidWorkflowNames.isEmpty ? "None" : status.invalidWorkflowNames.joined(separator: ", "))")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            GroupBox("Release Readiness") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(releaseReadiness.state == .ready
                         ? "This Mac is ready for Developer ID signing and notarization."
                         : "This Mac is not yet ready for live release signing/notarization.")
                    Text("Notary profile: \(releaseReadiness.notaryProfileName) (\(releaseReadiness.notaryProfileConfigured ? "configured" : "missing"))")
                    Text("Developer ID identities: \(releaseReadiness.developerIDIdentities.isEmpty ? "None" : releaseReadiness.developerIDIdentities.joined(separator: ", "))")
                    if !releaseReadiness.messages.isEmpty {
                        ForEach(releaseReadiness.messages, id: \.self) { message in
                            Text(message)
                        }
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            if !status.messages.isEmpty {
                Divider()

                ForEach(status.messages, id: \.self) { message in
                    Text(message)
                        .font(.body)
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 460, minHeight: 280)
        .onAppear {
            refreshStatus()
        }
    }

    private var installButtonTitle: String {
        status.state == .ready ? "Repair Setup" : "Install or Repair"
    }

    private var statusSummary: String {
        switch status.state {
        case .ready:
            return "Packaged runtime and Finder actions are installed."
        case .degraded:
            return "Paperdown needs setup attention."
        case .unknown:
            return "Checking installation status..."
        }
    }

    private func refreshStatus() {
        status = healthCheckService.currentStatus()
        diagnosticsSnapshot = diagnosticsService.snapshot()
        releaseReadiness = releaseReadinessService.snapshot()
    }

    private func installOrRepair() {
        isWorking = true
        defer {
            isWorking = false
            refreshStatus()
        }

        do {
            let installedRuntimeRoot = try runtimeInstaller.install()
            let quickActionInstaller = QuickActionInstaller(
                runtimeRoot: installedRuntimeRoot,
                servicesRoot: healthCheckService.servicesRoot
            )
            try quickActionInstaller.installOrRepair()
            actionMessage = "Installed the packaged runtime and refreshed Finder actions."
        } catch {
            actionMessage = error.localizedDescription
        }
    }

    private var compiledDefaultsSummary: String {
        let cover = currentSettings.compiledCoverPageEnabled ? "on" : "off"
        let toc = currentSettings.compiledTableOfContentsEnabled ? "on" : "off"
        return "Compiled defaults: cover \(cover), table of contents \(toc)."
    }

    private var currentSettings: AppSettings {
        (try? AppSettingsStore().load()) ?? AppSettings()
    }
}
