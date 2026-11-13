import Foundation

struct CommandResult: Equatable {
    let terminationStatus: Int32
    let standardOutput: String
    let standardError: String
}

struct ReleaseReadiness: Equatable {
    enum State: Equatable {
        case ready
        case degraded
    }

    let state: State
    let developerIDIdentities: [String]
    let notaryProfileName: String
    let notaryProfileConfigured: Bool
    let messages: [String]

    var hasDeveloperIDIdentity: Bool {
        !developerIDIdentities.isEmpty
    }
}

struct ReleaseReadinessService {
    let notaryProfileName: String
    private let commandRunner: (String, [String]) -> CommandResult

    init(
        notaryProfileName: String = ReleaseReadinessService.defaultNotaryProfileName(),
        commandRunner: @escaping (String, [String]) -> CommandResult = ReleaseReadinessService.runCommand
    ) {
        self.notaryProfileName = notaryProfileName
        self.commandRunner = commandRunner
    }

    func snapshot() -> ReleaseReadiness {
        let securityResult = commandRunner("/usr/bin/security", ["find-identity", "-v", "-p", "codesigning"])
        let developerIDIdentities = parseDeveloperIDIdentities(from: securityResult.standardOutput)

        let notaryResult = commandRunner("/usr/bin/xcrun", ["notarytool", "history", "--keychain-profile", notaryProfileName])
        let notaryProfileConfigured = notaryResult.terminationStatus == 0

        var messages: [String] = []

        if developerIDIdentities.isEmpty {
            messages.append("No Developer ID Application signing identity is installed.")
        }

        if !notaryProfileConfigured {
            messages.append(notaryProfileMessage(for: notaryResult))
        }

        return ReleaseReadiness(
            state: messages.isEmpty ? .ready : .degraded,
            developerIDIdentities: developerIDIdentities,
            notaryProfileName: notaryProfileName,
            notaryProfileConfigured: notaryProfileConfigured,
            messages: messages
        )
    }

    private func parseDeveloperIDIdentities(from output: String) -> [String] {
        output
            .split(separator: "\n")
            .compactMap { line -> String? in
                guard let markerRange = line.range(of: "Developer ID Application:") else {
                    return nil
                }
                let suffix = line[markerRange.lowerBound...]
                if let trailingQuote = suffix.lastIndex(of: "\"") {
                    return String(suffix[..<trailingQuote])
                }
                return String(suffix)
            }
    }

    private func notaryProfileMessage(for result: CommandResult) -> String {
        let combinedOutput = [result.standardError, result.standardOutput]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")

        if combinedOutput.contains("No Keychain password item found for profile") {
            return "Notary profile '\(notaryProfileName)' is not configured."
        }

        if combinedOutput.contains("notarytool") && combinedOutput.contains("not found") {
            return "xcrun notarytool is unavailable on this Mac."
        }

        let trimmed = combinedOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Notary profile '\(notaryProfileName)' could not be validated."
        }
        return "Notary profile '\(notaryProfileName)' could not be validated: \(trimmed)"
    }

    static func defaultNotaryProfileName() -> String {
        let environment = ProcessInfo.processInfo.environment
        if let override = environment["PAPERDOWN_NOTARY_PROFILE"], !override.isEmpty {
            return override
        }
        if let profile = environment["NOTARY_KEYCHAIN_PROFILE"], !profile.isEmpty {
            return profile
        }
        return "paperdown"
    }

    private static func runCommand(_ command: String, _ arguments: [String]) -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return CommandResult(
                terminationStatus: 1,
                standardOutput: "",
                standardError: error.localizedDescription
            )
        }

        let standardOutput = String(
            data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let standardError = String(
            data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""

        return CommandResult(
            terminationStatus: process.terminationStatus,
            standardOutput: standardOutput,
            standardError: standardError
        )
    }
}
