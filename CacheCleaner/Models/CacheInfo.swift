import Foundation

struct CacheInfo: Identifiable {
    let id = UUID()
    let path: String
    let size: String
    var displayName: String {
        path.components(separatedBy: "/").last ?? path
    }
}

struct CacheScanResult {
    var totalSize: String = "0B"
    var topCaches: [CacheInfo] = []
    var xcodeCaches: XcodeCacheInfo = .empty
    
    static var empty: CacheScanResult {
        CacheScanResult()
    }
}

struct XcodeCacheInfo {
    var derivedData: CacheInfo?
    var deviceSupport: CacheInfo?
    var archives: CacheInfo?
    var simulator: CacheInfo?
    
    static var empty: XcodeCacheInfo {
        XcodeCacheInfo()
    }
} 