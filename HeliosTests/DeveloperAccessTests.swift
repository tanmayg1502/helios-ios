import Testing
@testable import Helios

struct DeveloperAccessTests {
    @Test func productionDeniesEveryKindOfEvidence() {
        let evidence: [DeveloperAccessPolicy.Evidence] = [
            .verified(environment: .sandbox, bundleID: "com.pranav.helios"),
            .verified(environment: .other, bundleID: "com.pranav.helios"),
            .unverified,
            .unavailable
        ]
        for value in evidence {
            #expect(!DeveloperAccessPolicy.allows(
                build: .production, evidence: value, expectedBundleID: "com.pranav.helios"
            ))
        }
    }

    @Test func testFlightRequiresVerifiedSandboxAndMatchingIdentity() {
        let bundleID = "com.pranav.helios"
        #expect(DeveloperAccessPolicy.allows(
            build: .testFlight,
            evidence: .verified(environment: .sandbox, bundleID: bundleID),
            expectedBundleID: bundleID
        ))
        let deniedEvidence: [DeveloperAccessPolicy.Evidence] = [
            .verified(environment: .sandbox, bundleID: "another.application"),
            .verified(environment: .other, bundleID: bundleID),
            .unverified,
            .unavailable
        ]
        for value in deniedEvidence {
            #expect(!DeveloperAccessPolicy.allows(
                build: .testFlight, evidence: value, expectedBundleID: bundleID
            ))
        }
        for missingID: String? in [nil, ""] {
            #expect(!DeveloperAccessPolicy.allows(
                build: .testFlight,
                evidence: .verified(environment: .sandbox, bundleID: bundleID),
                expectedBundleID: missingID
            ))
        }
    }

    @Test @MainActor func availabilityStartsClosed() {
        #expect(!DeveloperAccess().isAvailable)
    }

    @Test @MainActor func compiledBuildPolicy() async {
        let access = DeveloperAccess()
        #if DEBUG
        await access.verify()
        #expect(access.isAvailable)
        #elseif !TESTFLIGHT_DEVELOPER_TOOLS
        await access.verify()
        #expect(!access.isAvailable)
        #endif
    }
}
