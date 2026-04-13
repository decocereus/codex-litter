import XCTest
@testable import Litter

@MainActor
final class MacPairingModelsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "litter.pairedMacs")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "litter.pairedMacs")
        super.tearDown()
    }

    func testHasTrustedPairingMatchesMacIdentity() {
        PairedMacStore.upsert(
            PairedMacRecord(
                displayName: "Litter Mac",
                host: "192.168.1.3",
                relayURL: "wss://relay.example.test",
                relaySessionId: "session-1",
                macDeviceId: "mac-1",
                macIdentityPublicKey: "pubkey-1",
                trustedPhoneDeviceId: nil,
                trustedPhoneIdentityPublicKey: nil,
                pairedAt: Date(timeIntervalSince1970: 0),
                localPairingMode: "code"
            )
        )

        XCTAssertTrue(
            PairedMacStore.hasTrustedPairing(
                macDeviceId: "mac-1",
                macIdentityPublicKey: "pubkey-1"
            )
        )
        XCTAssertFalse(
            PairedMacStore.hasTrustedPairing(
                macDeviceId: "mac-1",
                macIdentityPublicKey: "pubkey-2"
            )
        )
    }

    func testMatchesCurrentPhoneIdentityRequiresExactStoredMatchWhenPresent() {
        let record = PairedMacRecord(
            displayName: "Litter Mac",
            host: "192.168.1.3",
            relayURL: "wss://relay.example.test",
            relaySessionId: "session-1",
            macDeviceId: "mac-1",
            macIdentityPublicKey: "pubkey-1",
            trustedPhoneDeviceId: "phone-1",
            trustedPhoneIdentityPublicKey: "phone-pubkey-1",
            pairedAt: Date(timeIntervalSince1970: 0),
            localPairingMode: "code"
        )

        XCTAssertTrue(
            record.matchesCurrentPhoneIdentity(
                AppPhoneIdentityRecord(
                    phoneDeviceId: "phone-1",
                    phoneIdentityPublicKey: "phone-pubkey-1"
                )
            )
        )
        XCTAssertFalse(
            record.matchesCurrentPhoneIdentity(
                AppPhoneIdentityRecord(
                    phoneDeviceId: "phone-1",
                    phoneIdentityPublicKey: "phone-pubkey-2"
                )
            )
        )
    }
}
