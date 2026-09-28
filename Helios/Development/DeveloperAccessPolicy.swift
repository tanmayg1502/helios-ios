/// Pure policy, separate from obtaining StoreKit evidence or changing application mode.
enum DeveloperAccessPolicy {
    enum Build: CaseIterable {
        case debug, testFlight, production
    }

    enum Environment {
        case sandbox, other
    }

    enum Evidence {
        case verified(environment: Environment, bundleID: String)
        case unverified
        case unavailable
    }

    static func allows(build: Build, evidence: Evidence, expectedBundleID: String?) -> Bool {
        switch build {
        case .debug:
            return true
        case .production:
            return false
        case .testFlight:
            guard let expectedBundleID, !expectedBundleID.isEmpty,
                  case .verified(.sandbox, let bundleID) = evidence else { return false }
            return bundleID == expectedBundleID
        }
    }
}
