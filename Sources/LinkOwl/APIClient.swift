import Foundation
import os.log

/// Internal network client. Silent failures — logs via os_log but never throws to callers.
internal final class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let logger = Logger(subsystem: "app.linkowl.sdk", category: "api")
    private let maxRetries = 1
    private let retryDelay: TimeInterval = 2.0
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Install Tracking
    
    struct InstallResponse: Decodable {
        let install_id: String
    }
    
    func trackInstall(fingerprint: Fingerprint) async -> String? {
        guard let config = validConfig() else { return nil }
        
        let url = config.baseURL.appendingPathComponent("api/v1/installs")
        let body = InstallBody(api_key: config.apiKey, fingerprint: fingerprint)
        
        guard let data = await post(url: url, body: body, apiKey: config.apiKey) else { return nil }
        
        do {
            let response = try JSONDecoder().decode(InstallResponse.self, from: data)
            logger.debug("Install tracked: \(response.install_id)")
            return response.install_id
        } catch {
            logger.error("Failed to decode install response: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - User ID
    
    func setUserId(_ userId: String, installId: String) async {
        guard let config = validConfig() else { return }
        
        let url = config.baseURL
            .appendingPathComponent("api/v1/installs")
            .appendingPathComponent(installId)
        
        let body = ["rc_user_id": userId]
        await patch(url: url, body: body, apiKey: config.apiKey)
    }
    
    // MARK: - Purchase Tracking
    
    struct PurchaseBody: Encodable {
        let install_id: String?
        let transaction_id: String
        let revenue: Double
        let currency: String
    }
    
    func trackPurchase(installId: String?, transactionId: String, revenue: Double, currency: String) async {
        guard let config = validConfig() else { return }
        
        let url = config.baseURL.appendingPathComponent("api/v1/purchases")
        let body = PurchaseBody(
            install_id: installId,
            transaction_id: transactionId,
            revenue: revenue,
            currency: currency
        )
        await post(url: url, body: body, apiKey: config.apiKey)
    }
    
    // MARK: - Private
    
    private struct ValidConfig {
        let apiKey: String
        let baseURL: URL
    }
    
    private func validConfig() -> ValidConfig? {
        let config = Configuration.shared
        guard let apiKey = config.apiKey else {
            logger.warning("LinkOwl not configured. Call LinkOwl.configure(apiKey:) first.")
            return nil
        }
        return ValidConfig(apiKey: apiKey, baseURL: config.baseURL)
    }
    
    private struct InstallBody: Encodable {
        let api_key: String
        let fingerprint: Fingerprint
    }
    
    @discardableResult
    private func post<T: Encodable>(url: URL, body: T, apiKey: String, attempt: Int = 0) async -> Data? {
        await request(method: "POST", url: url, body: body, apiKey: apiKey, attempt: attempt)
    }
    
    @discardableResult
    private func patch<T: Encodable>(url: URL, body: T, apiKey: String, attempt: Int = 0) async -> Data? {
        await request(method: "PATCH", url: url, body: body, apiKey: apiKey, attempt: attempt)
    }
    
    private func request<T: Encodable>(method: String, url: URL, body: T, apiKey: String, attempt: Int = 0) async -> Data? {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        req.timeoutInterval = 10
        
        do {
            req.httpBody = try JSONEncoder().encode(body)
        } catch {
            logger.error("Failed to encode body: \(error.localizedDescription)")
            return nil
        }
        
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else { return nil }
            
            if (200...299).contains(http.statusCode) {
                return data
            } else {
                logger.warning("\(method) \(url.path) returned \(http.statusCode)")
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    return await request(method: method, url: url, body: body, apiKey: apiKey, attempt: attempt + 1)
                }
                return nil
            }
        } catch {
            logger.warning("\(method) \(url.path) failed: \(error.localizedDescription)")
            if attempt < maxRetries {
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                return await request(method: method, url: url, body: body, apiKey: apiKey, attempt: attempt + 1)
            }
            return nil
        }
    }
}
