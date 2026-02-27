import Foundation

/// UserDefaults wrapper for LinkOwl persistence. All keys prefixed with `lo_`.
internal final class Storage {
    static let shared = Storage()
    
    private let defaults = UserDefaults.standard
    
    private enum Key: String {
        case installTracked = "lo_install_tracked"
        case installId = "lo_install_id"
        case userId = "lo_user_id"
        case apiKey = "lo_api_key"
    }
    
    var isInstallTracked: Bool {
        get { defaults.bool(forKey: Key.installTracked.rawValue) }
        set { defaults.set(newValue, forKey: Key.installTracked.rawValue) }
    }
    
    var installId: String? {
        get { defaults.string(forKey: Key.installId.rawValue) }
        set { defaults.set(newValue, forKey: Key.installId.rawValue) }
    }
    
    var userId: String? {
        get { defaults.string(forKey: Key.userId.rawValue) }
        set { defaults.set(newValue, forKey: Key.userId.rawValue) }
    }
}
