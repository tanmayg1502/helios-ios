import Foundation
import Observation
#if TESTFLIGHT_DEVELOPER_TOOLS && !DEBUG
import StoreKit
#endif

/// Eligibility only. Entering developer mode requires a separate, explicit session opt-in.
@MainActor
@Observable
final class DeveloperAccess {
    private(set) var isAvailable = false
    @ObservationIgnored private var verificationGeneration = 0

    func verify() async {
        verificationGeneration += 1
        let generation = verificationGeneration
        isAvailable = false

        #if DEBUG
        isAvailable = !Task.isCancelled
        #elseif TESTFLIGHT_DEVELOPER_TOOLS
        do {
            let result = try await AppTransaction.shared
            guard generation == verificationGeneration, !Task.isCancelled else { return }
            guard case .verified(let transaction) = result else { return }
            isAvailable = DeveloperAccessPolicy.allows(
                build: .testFlight,
                evidence: .verified(
                    environment: transaction.environment == .sandbox ? .sandbox : .other,
                    bundleID: transaction.bundleID
                ),
                expectedBundleID: Bundle.main.bundleIdentifier
            )
        } catch {
            // Missing, unavailable, or unauthenticated evidence never unlocks tools.
            if generation == verificationGeneration { isAvailable = false }
        }
        #else
        // Ordinary Release never queries StoreKit or accepts a runtime override.
        isAvailable = false
        #endif
    }
}
