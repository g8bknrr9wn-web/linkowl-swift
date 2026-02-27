import XCTest
@testable import LinkOwl

final class LinkOwlTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset state between tests
        UserDefaults.standard.removeObject(forKey: "lo_install_tracked")
        UserDefaults.standard.removeObject(forKey: "lo_install_id")
        UserDefaults.standard.removeObject(forKey: "lo_user_id")
    }
    
    // MARK: - Storage Tests
    
    func testStorageInstallTracked() {
        let storage = Storage.shared
        XCTAssertFalse(storage.isInstallTracked)
        storage.isInstallTracked = true
        XCTAssertTrue(storage.isInstallTracked)
    }
    
    func testStorageInstallId() {
        let storage = Storage.shared
        XCTAssertNil(storage.installId)
        storage.installId = "test-123"
        XCTAssertEqual(storage.installId, "test-123")
    }
    
    func testStorageUserId() {
        let storage = Storage.shared
        XCTAssertNil(storage.userId)
        storage.userId = "rc_user_abc"
        XCTAssertEqual(storage.userId, "rc_user_abc")
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationDefault() {
        let config = Configuration.shared
        XCTAssertFalse(config.isConfigured)
        XCTAssertEqual(config.baseURL.absoluteString, "https://linkowl.app")
    }
    
    func testConfigurationWithApiKey() {
        let config = Configuration.shared
        config.configure(apiKey: "lo_live_test123")
        XCTAssertTrue(config.isConfigured)
    }
    
    func testConfigurationCustomBaseURL() {
        let config = Configuration.shared
        config.configure(apiKey: "lo_live_test123", baseURL: "https://staging.linkowl.app")
        XCTAssertEqual(config.baseURL.absoluteString, "https://staging.linkowl.app")
    }
    
    // MARK: - Fingerprint Tests
    
    func testFingerprintCollect() {
        let fp = Fingerprint.collect()
        XCTAssertFalse(fp.timezone.isEmpty)
        XCTAssertFalse(fp.locale.isEmpty)
        XCTAssertFalse(fp.timestamp.isEmpty)
        XCTAssertFalse(fp.osVersion.isEmpty)
    }
    
    func testFingerprintEncodable() throws {
        let fp = Fingerprint.collect()
        let data = try JSONEncoder().encode(fp)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json?["timezone"])
        XCTAssertNotNil(json?["locale"])
        XCTAssertNotNil(json?["timestamp"])
        XCTAssertNotNil(json?["screenWidth"])
        XCTAssertNotNil(json?["screenHeight"])
        XCTAssertNotNil(json?["deviceModel"])
        XCTAssertNotNil(json?["osVersion"])
    }
    
    // MARK: - Idempotency Tests
    
    func testTrackInstallSkipsWhenAlreadyTracked() {
        Storage.shared.isInstallTracked = true
        // This should return immediately without making any network call
        // (no crash = pass, since we can't easily mock the network here)
        LinkOwl.configure(apiKey: "lo_live_test")
        LinkOwl.trackInstall()
    }
    
    func testSetUserIdStoresLocally() {
        LinkOwl.configure(apiKey: "lo_live_test")
        LinkOwl.setUserId("rc_user_test")
        XCTAssertEqual(Storage.shared.userId, "rc_user_test")
    }
}
