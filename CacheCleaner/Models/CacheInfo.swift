import Foundation

struct CacheInfo: Identifiable {
    let id = UUID()
    let path: String
    let size: String
    var displayName: String {
        // Убираем завершающий слэш если он есть
        let cleanPath = path.hasSuffix("/") ? String(path.dropLast()) : path
        return cleanPath.components(separatedBy: "/").last ?? path
    }
}

struct DerivedDataProjectInfo: Identifiable {
    let id = UUID()
    let projectName: String
    let workspacePath: String
    let lastAccessedDate: String
    let path: String
    let size: String
    
    var displayName: String {
        return projectName
    }
    
    var detailedDescription: String {
        let fileName = workspacePath.components(separatedBy: "/").last ?? workspacePath
        return "\(projectName)\nПуть: \(fileName)\nПоследний доступ: \(lastAccessedDate)"
    }
}

struct ArchiveInfo: Identifiable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let version: String
    let buildNumber: String
    let creationDate: String
    let path: String
    let size: String
    
    var displayName: String {
        return "\(name) \(version) (\(buildNumber))"
    }
    
    var detailedDescription: String {
        return "\(name) - \(bundleIdentifier)\nВерсия: \(version), Билд: \(buildNumber)\nСоздан: \(creationDate)"
    }
}

struct iOSDeviceInfo: Identifiable {
    let id = UUID()
    let deviceModel: String
    let iosVersion: String
    let buildNumber: String
    let path: String
    let size: String
    
    var displayName: String {
        return "\(humanReadableDeviceName) iOS \(iosVersion)"
    }
    
    var detailedDescription: String {
        return "\(humanReadableDeviceName) - iOS \(iosVersion) (\(buildNumber))"
    }
    
    private var humanReadableDeviceName: String {
        switch deviceModel {
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 14"
        case "iPhone15,5": return "iPhone 14 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone16,3": return "iPhone 15"
        case "iPhone16,4": return "iPhone 15 Plus"
        case "iPhone17,1": return "iPhone 16"
        case "iPhone17,2": return "iPhone 16 Plus"
        case "iPhone17,3": return "iPhone 16 Pro"
        case "iPhone17,4": return "iPhone 16 Pro Max"
        case "iPad13,1", "iPad13,2": return "iPad Air (4th gen)"
        case "iPad13,16", "iPad13,17": return "iPad Air (5th gen)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th gen)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9\" (4th gen)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11\" (2nd gen)"
        case "iPad14,3", "iPad14,4": return "iPad Pro 11\" (3rd gen)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 12.9\" (5th gen)"
        case "iPad14,7", "iPad14,8": return "iPad Pro 11\" (4th gen)"
        case "iPad14,9", "iPad14,10": return "iPad Pro 12.9\" (6th gen)"
        default: return deviceModel
        }
    }
}

struct CacheScanResult {
    var totalSize: String = "0B"
    var xcodeTotalSize: String = "0B"
    var developmentTotalSize: String = "0B"
    var topCaches: [CacheInfo] = []
    var xcodeCaches: XcodeCacheInfo = .empty
    var developmentCaches: DevelopmentCacheInfo = .empty
    
    /// Общий размер всех категорий (General + Xcode + Development)
    var grandTotalSize: String {
        let generalBytes = SizeHelper.parseSizeToBytes(totalSize)
        let xcodeBytes = SizeHelper.parseSizeToBytes(xcodeTotalSize)
        let devBytes = SizeHelper.parseSizeToBytes(developmentTotalSize)
        let total = generalBytes + xcodeBytes + devBytes
        
        if total <= 0 { return "0 B" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(total))
    }
    
    static var empty: CacheScanResult {
        CacheScanResult()
    }
}

struct FlutterPackageVersion: Identifiable {
    let id = UUID()
    let packageName: String
    let version: String
    let path: String
    let size: String
    
    var displayName: String {
        return "\(packageName) \(version)"
    }
}

struct FlutterPackageGroup: Identifiable {
    let id = UUID()
    let packageName: String
    let versions: [FlutterPackageVersion]
    let totalSize: String
    
    var displayName: String {
        let count = versions.count
        return "\(packageName) (\(count) \(count == 1 ? "версия" : count < 5 ? "версии" : "версий"))"
    }
}

struct DevelopmentCacheInfo {
    var pubCache: CacheInfo?
    var pubPackages: [FlutterPackageGroup] = []
    var gradleCache: CacheInfo?
    var npmCache: CacheInfo?
    var homeCache: CacheInfo?
    
    static var empty: DevelopmentCacheInfo {
        DevelopmentCacheInfo()
    }
}

struct XcodeCacheInfo {
    var derivedData: CacheInfo?
    var deviceSupport: CacheInfo?
    var archives: CacheInfo?
    var simulator: CacheInfo?
    var iosDevices: [iOSDeviceInfo] = []
    var archiveList: [ArchiveInfo] = []
    var derivedDataProjects: [DerivedDataProjectInfo] = []
    
    // Новые папки для macOS 26
    var developerDiskImages: CacheInfo?
    var xcpgDevices: CacheInfo?
    var dvtDownloads: CacheInfo?
    var xcTestDevices: CacheInfo?
    
    static var empty: XcodeCacheInfo {
        XcodeCacheInfo()
    }
} 