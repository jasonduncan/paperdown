import Foundation

struct InstallStatus: Equatable {
    enum State: String, Equatable {
        case unknown
        case ready
        case degraded
    }

    let state: State
    let runtimeInstalled: Bool
    let quickActionsInstalled: Bool
    let missingWorkflowNames: [String]
    let invalidWorkflowNames: [String]
    let messages: [String]

    static let unknown = InstallStatus(
        state: .unknown,
        runtimeInstalled: false,
        quickActionsInstalled: false,
        missingWorkflowNames: [],
        invalidWorkflowNames: [],
        messages: []
    )
}
