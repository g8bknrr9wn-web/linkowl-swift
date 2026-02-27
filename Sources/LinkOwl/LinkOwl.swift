import Foundation
import os.log

/// LinkOwl — attribution tracking for indie iOS developers.
///
/// Usage:
/// ```swift
/// // 1. Configure on app launch
/// LinkOwl.configure(apiKey: "lo_live_xxxx")
///
/// // 2. Track install (call once, SDK deduplicates)
/// LinkOwl.trackInstall()
///
/// // 3. Set RevenueCat user ID for purchase attribution
/// LinkOwl.setUserId(Purchases.shared.appUserID)
///
/// // 4. (Optional) Manual purchase tracking if not using RevenueCat webhook
/// LinkOwl.trackPurchase(transactionId: "txn_abc", revenue: 4.99, currency: "GBP")
/// ```
public enum LinkOwl {
    
    private static let logger = Logger(subsystem: "app.linkowl.sdk", category: "main")
    
    /// Configure LinkOwl with your API key. Call once on app startup.
    ///
    /// - Parameters:
    ///   - apiKey: Your LinkOwl API key (starts with `lo_live_`)
    ///   - baseURL: Override the API base URL (default: `https://linkowl.app`). For testing only.
    public static func configure(apiKey: String, baseURL: String? = nil) {
        Configuration.shared.configure(apiKey: apiKey, baseURL: baseURL)
        logger.debug("LinkOwl configured")
    }
    
    /// Track an app install. Safe to call multiple times — only fires once.
    ///
    /// Collects a privacy-safe fingerprint (no IDFA/IDFV) and sends it to the
    /// LinkOwl API for attribution matching. Runs in the background and never
    /// blocks the main thread or crashes your app.
    public static func trackInstall() {
        guard Configuration.shared.isConfigured else {
            logger.warning("trackInstall called before configure(). Ignoring.")
            return
        }
        
        guard !Storage.shared.isInstallTracked else {
            logger.debug("Install already tracked. Skipping.")
            return
        }
        
        let fingerprint = Fingerprint.collect()
        
        Task.detached(priority: .utility) {
            guard let installId = await APIClient.shared.trackInstall(fingerprint: fingerprint) else {
                return
            }
            Storage.shared.installId = installId
            Storage.shared.isInstallTracked = true
        }
    }
    
    /// Set the RevenueCat user ID to enable automatic purchase attribution via webhook.
    ///
    /// Call this after RevenueCat is configured:
    /// ```swift
    /// LinkOwl.setUserId(Purchases.shared.appUserID)
    /// ```
    ///
    /// - Parameter userId: The RevenueCat `appUserID`
    public static func setUserId(_ userId: String) {
        guard Configuration.shared.isConfigured else {
            logger.warning("setUserId called before configure(). Ignoring.")
            return
        }
        
        Storage.shared.userId = userId
        
        guard let installId = Storage.shared.installId else {
            logger.debug("No install_id yet. userId stored locally, will be sent with next install.")
            return
        }
        
        Task.detached(priority: .utility) {
            await APIClient.shared.setUserId(userId, installId: installId)
        }
    }
    
    /// Manually track a purchase. Use this only if you're NOT using the RevenueCat webhook.
    ///
    /// - Parameters:
    ///   - transactionId: Unique transaction identifier
    ///   - revenue: Purchase amount (e.g. 4.99)
    ///   - currency: ISO 4217 currency code (e.g. "GBP", "USD")
    public static func trackPurchase(transactionId: String, revenue: Double, currency: String) {
        guard Configuration.shared.isConfigured else {
            logger.warning("trackPurchase called before configure(). Ignoring.")
            return
        }
        
        let installId = Storage.shared.installId
        
        Task.detached(priority: .utility) {
            await APIClient.shared.trackPurchase(
                installId: installId,
                transactionId: transactionId,
                revenue: revenue,
                currency: currency
            )
        }
    }
}
