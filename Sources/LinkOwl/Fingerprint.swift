import Foundation

/// Collects minimal contextual signals for attribution matching.
/// Privacy-first: no IDFA, no IDFV, no device model, no screen size.
/// Server captures IP from request headers (standard HTTP, not collected by SDK).
internal struct Fingerprint: Encodable {
    let timezone: String
    let locale: String
    let timestamp: String
    
    static func collect() -> Fingerprint {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return Fingerprint(
            timezone: TimeZone.current.identifier,
            locale: Locale.current.identifier,
            timestamp: formatter.string(from: Date())
        )
    }
}
