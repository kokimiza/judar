import SwiftUI
import CloudKit
import SwiftData

// Phase 1 stub — shows informational alert. Phase 2 will implement CKShare flow.
@Observable
final class CloudSharingCoordinator {
    var showingPhase1Alert = false
    var sharingError: Error? = nil

    func prepareShare(modelContext: ModelContext) async {
        showingPhase1Alert = true
    }
}
