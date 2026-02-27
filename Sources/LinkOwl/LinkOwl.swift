import Foundation
import os.log

/// LinkOwl — attribution tracking for indie iOS developers.
///
/// **One line to set up:**
/// ```swift
/// LinkOwl.start("lo_live_xxxx")
/// ```
///
/// **With RevenueCat:**
/// ```swift
/// LinkOwl.start("lo_live_xxxx")
/// LinkOwl.setUserId(Purchases.shared.appUserID)
/// ```
///
/// **With Superwall:**
/// ```swift
/// LinkOwl.start("lo_live_xxxx")
/// LinkOwl.setUserId(Superwall.shared.userId)
/// ```
public enum LinkOwl {
    
    private static let logger = Logger(subsystem: "app.linkowl.sdk", category: "main")
    private static var hasStarted = false
    
    // MARK: - Public API
    
    /// Start LinkOwl. Configures and tracks the install in one call.
    ///
    /// Call once on app launch (in your App init or AppDelegate).
    /// Safe to call multiple times — only fires once.
    ///
    /// - Parameter apiKey: Your API key from linkowl.app (starts with `lo_live_`)
    public static func start(_ apiKey: String) {
        guard !hasStarted else { return }
        hasStarted = true
        
        Configuration.shared.configure(apiKey: apiKey)
        logger.debug("LinkOwl started")
        trackInstall()
    }
    
    /// Link a RevenueCat or Superwall user ID for purchase attribution.
    ///
    /// Call after your paywall SDK is configured:
    /// ```swift
    /// LinkOwl.setUserId(Purchases.shared.appUserID)
    /// ```
    ///
    /// - Parameter userId: The user ID from your paywall provider
    public static func setUserId(_ userId: String) {
        guard Configuration.shared.isConfigured else {
            logger.warning("setUserId called before start(). Ignoring.")
            return
        }
        
        Storage.shared.userId = userId
        
        guard let installId = Storage.shared.installId else {
            logger.debug("No install_id yet. userId stored, will send later.")
            return
        }
        
        Task.detached(priority: .utility) {
            await APIClient.shared.setUserId(userId, installId: installId)
        }
    }
    
    /// Manually track a purchase. Only if NOT using RevenueCat/Superwall webhooks.
    ///
    /// - Parameters:
    ///   - transactionId: Unique transaction ID
    ///   - revenue: Amount (e.g. 4.99)
    ///   - currency: ISO 4217 code (e.g. "GBP")
    public static func trackPurchase(transactionId: String, revenue: Double, currency: String) {
        guard Configuration.shared.isConfigured else {
            logger.warning("trackPurchase called before start(). Ignoring.")
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
    
    // MARK: - Internal (used by start)
    
    /// Configure without tracking. Use `start()` instead.
    internal static func configure(apiKey: String, baseURL: String? = nil) {
        Configuration.shared.configure(apiKey: apiKey, baseURL: baseURL)
    }
    
    internal static func trackInstall() {
        guard Configuration.shared.isConfigured else { return }
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
}
