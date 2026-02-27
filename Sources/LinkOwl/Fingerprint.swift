import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Collects device fingerprint signals for attribution matching.
/// Privacy-first: no IDFA, no IDFV, no persistent device identifiers.
internal struct Fingerprint: Encodable {
    let screenWidth: Double
    let screenHeight: Double
    let timezone: String
    let locale: String
    let timestamp: String
    let deviceModel: String
    let osVersion: String
    
    static func collect() -> Fingerprint {
        let screenBounds: CGRect
        #if canImport(UIKit)
        screenBounds = UIScreen.main.bounds
        #else
        screenBounds = .zero
        #endif
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let model = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "unknown"
            }
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return Fingerprint(
            screenWidth: screenBounds.width,
            screenHeight: screenBounds.height,
            timezone: TimeZone.current.identifier,
            locale: Locale.current.identifier,
            timestamp: formatter.string(from: Date()),
            deviceModel: model,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString
        )
    }
}
