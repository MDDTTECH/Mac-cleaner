import Foundation

class CacheService {
    static let shared = CacheService()
    private let fileManager = FileManager.default
    
    private var homePath: String {
        NSHomeDirectory()
    }
    
    private var realHomePath: String {
        // Получаем реальный путь к домашней директории пользователя
        ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
    }
    
    func scanCaches() async -> CacheScanResult {
        var result = CacheScanResult()
        
        // Общий размер кэшей
        let cachesPath = "\(realHomePath)/Library/Caches"
        print("Scanning path: \(cachesPath)")
        
        let duCommand = "du -sh \"\(cachesPath)\" 2>/dev/null"
        print("Executing command: \(duCommand)")
        
        let duOutput = await shellCommand(duCommand)
        print("Command output: \(duOutput)")
        
        // Парсим только последнюю строку, которая содержит общий размер
        let lines = duOutput.components(separatedBy: .newlines)
        if let lastLine = lines.last(where: { $0.contains("\t") }) {
            result.totalSize = lastLine.components(separatedBy: "\t").first ?? "0B"
        } else {
            result.totalSize = "0B"
        }
        print("Parsed size: \(result.totalSize)")
        
        // Топ кэшей
        let topCachesCommand = "find \"\(cachesPath)\" -maxdepth 1 -mindepth 1 -type d -exec du -sh {} \\; 2>/dev/null | sort -hr | head -n 10"
        let topCachesOutput = await shellCommand(topCachesCommand)
        result.topCaches = topCachesOutput
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line -> CacheInfo? in
                let parts = line.components(separatedBy: "\t")
                guard parts.count == 2 else { return nil }
                return CacheInfo(path: parts[1], size: parts[0])
            }
        
        // Xcode кэши
        let xcodePaths = [
            "Library/Developer/Xcode/DerivedData": \XcodeCacheInfo.derivedData,
            "Library/Developer/Xcode/iOS DeviceSupport": \XcodeCacheInfo.deviceSupport,
            "Library/Developer/Xcode/Archives": \XcodeCacheInfo.archives,
            "Library/Developer/CoreSimulator": \XcodeCacheInfo.simulator
        ]
        
        var xcodeCaches = XcodeCacheInfo()
        for (path, keyPath) in xcodePaths {
            let fullPath = "\(realHomePath)/\(path)"
            let size = await shellCommand("du -sh \"\(fullPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
            let cacheInfo = CacheInfo(path: fullPath, size: size)
            xcodeCaches[keyPath: keyPath] = cacheInfo
        }
        result.xcodeCaches = xcodeCaches
        
        return result
    }
    
    func cleanCache(_ path: String) async -> Bool {
        let output = await shellCommand("/bin/rm -rf \"\(path)\" 2>/dev/null")
        return output.isEmpty
    }
    
    private func shellCommand(_ command: String) async -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            print("Error executing command: \(error)")
            return ""
        }
    }
} 