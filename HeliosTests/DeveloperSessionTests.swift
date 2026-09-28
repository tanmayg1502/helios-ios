import Testing
@testable import Helios

struct DeveloperSessionTests {
    @Test @MainActor func unavailableAccessCannotEnableDemo() {
        let connection = LiveConnection()
        connection.setDeveloperMode(true, access: DeveloperAccess())
        connection.showDemo()
        #expect(!connection.developerMode)
        #expect(connection.useLive)
        #expect(connection.snapshot == nil)
    }

    @Test @MainActor func modeTransitionsDisconnectAndReturnToRobot() async {
        let access = DeveloperAccess()
        await access.verify()
        let connection = LiveConnection()
        #expect(!connection.developerMode)
        #expect(connection.useLive)
        connection.setDeveloperMode(true, access: access)
        #if DEBUG
        #expect(connection.developerMode)
        #expect(!connection.useLive)
        connection.connect(endpoint: "http://localhost:1", token: String(repeating: "a", count: 32))
        #expect(connection.isEnabled)
        #endif
        connection.setDeveloperMode(false, access: access)
        #expect(!connection.developerMode)
        #expect(connection.useLive)
        #expect(!connection.isEnabled)
        #expect(connection.snapshot == nil)
        #expect(connection.operations.catalog.isEmpty)
        #expect(connection.operations.jobs.isEmpty)
        #expect(!connection.operations.hasControl)
        #expect(!connection.operations.commandsEnabled)
        connection.showDemo()
        #expect(connection.useLive)
    }
}
