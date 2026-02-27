import Foundation

/// Internal configuration store for LinkOwl SDK.
internal final class Configuration {
    static let shared = Configuration()
    
    private(set) var apiKey: String?
    private(set) var baseURL: URL = URL(string: "https://linkowl.app")!
    
    var isConfigured: Bool { apiKey != nil }
    
    func configure(apiKey: String, baseURL: String? = nil) {
        self.apiKey = apiKey
        if let baseURL, let url = URL(string: baseURL) {
            self.baseURL = url
        }
    }
}
