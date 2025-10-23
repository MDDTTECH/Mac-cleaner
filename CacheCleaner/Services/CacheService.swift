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
            "Library/Developer/Xcode/DerivedData": \XcodeCacheInfo.derivedData
        ]
        
        var xcodeCaches = XcodeCacheInfo()
        for (path, keyPath) in xcodePaths {
            let fullPath = "\(realHomePath)/\(path)"
            let sizeOutput = await shellCommand("du -sh \"\(fullPath)\" 2>/dev/null")
            let size: String
            
            if sizeOutput.isEmpty {
                // Если папка не существует или пуста, показываем 0B
                size = "0B"
            } else {
                size = sizeOutput.components(separatedBy: "\t").first ?? "0B"
            }
            
            let cacheInfo = CacheInfo(path: fullPath, size: size)
            xcodeCaches[keyPath: keyPath] = cacheInfo
        }
        
        // CoreSimulator кэши (только кэши, не все данные симуляторов)
        let simulatorCachesPath = "\(realHomePath)/Library/Developer/CoreSimulator/Caches"
        let simulatorTempPath = "\(realHomePath)/Library/Developer/CoreSimulator/Temp"
        
        let simulatorCachesSize = await shellCommand("du -sh \"\(simulatorCachesPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        let simulatorTempSize = await shellCommand("du -sh \"\(simulatorTempPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        
        // Подсчитываем общий размер кэшей симулятора
        let simulatorCacheInfo = CacheInfo(path: "\(realHomePath)/Library/Developer/CoreSimulator", size: simulatorCachesSize)
        xcodeCaches.simulator = simulatorCacheInfo
        
        // Сканируем отдельные устройства iOS Device Support
        let deviceSupportPath = "\(realHomePath)/Library/Developer/Xcode/iOS DeviceSupport"
        let deviceDirs = await shellCommand("ls \"\(deviceSupportPath)\" 2>/dev/null")
        
        var iosDevices: [iOSDeviceInfo] = []
        for deviceDir in deviceDirs.components(separatedBy: "\n").filter({ !$0.isEmpty }) {
            let devicePath = "\(deviceSupportPath)/\(deviceDir)"
            let deviceSize = await shellCommand("du -sh \"\(devicePath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
            
            // Парсим информацию об устройстве из названия папки
            // Формат: "iPhone16,1 26.0.1 (23A355)"
            let components = deviceDir.components(separatedBy: " ")
            if components.count >= 3 {
                let deviceModel = components[0]
                let iosVersion = components[1]
                let buildNumber = components[2].trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                
                let deviceInfo = iOSDeviceInfo(
                    deviceModel: deviceModel,
                    iosVersion: iosVersion,
                    buildNumber: buildNumber,
                    path: devicePath,
                    size: deviceSize
                )
                iosDevices.append(deviceInfo)
            }
        }
        
        xcodeCaches.iosDevices = iosDevices
        
        // Сканируем архивы
        let archivesPath = "\(realHomePath)/Library/Developer/Xcode/Archives"
        let archivesSize = await shellCommand("du -sh \"\(archivesPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        let archivesInfo = CacheInfo(path: archivesPath, size: archivesSize)
        xcodeCaches.archives = archivesInfo
        
        // Сканируем отдельные архивы
        let archiveDirs = await shellCommand("find \"\(archivesPath)\" -name \"*.xcarchive\" -type d 2>/dev/null")
        var archiveList: [ArchiveInfo] = []
        
        for archivePath in archiveDirs.components(separatedBy: "\n").filter({ !$0.isEmpty }) {
            let archiveSize = await shellCommand("du -sh \"\(archivePath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
            
            // Читаем Info.plist архива
            let infoPlistPath = "\(archivePath)/Info.plist"
            let plistContent = await shellCommand("plutil -p \"\(infoPlistPath)\" 2>/dev/null")
            
            if !plistContent.isEmpty {
                let archiveInfo = parseArchiveInfo(from: plistContent, path: archivePath, size: archiveSize)
                archiveList.append(archiveInfo)
            }
        }
        
        xcodeCaches.archiveList = archiveList
        result.xcodeCaches = xcodeCaches
        
        return result
    }
    
    func cleanCache(_ path: String) async -> Bool {
        // Для CoreSimulator удаляем только кэши, не все данные симуляторов
        if path.contains("CoreSimulator") {
            let simulatorCachesPath = "\(realHomePath)/Library/Developer/CoreSimulator/Caches"
            let simulatorTempPath = "\(realHomePath)/Library/Developer/CoreSimulator/Temp"
            
            let cachesResult = await shellCommand("/bin/rm -rf \"\(simulatorCachesPath)\"/* 2>/dev/null")
            let tempResult = await shellCommand("/bin/rm -rf \"\(simulatorTempPath)\"/* 2>/dev/null")
            
            // Также очищаем кэши приложений в симуляторах
            let appCachesResult = await shellCommand("find \"\(realHomePath)/Library/Developer/CoreSimulator/Devices\" -name \"*Cache*\" -type d -exec rm -rf {} \\; 2>/dev/null")
            
            return cachesResult.isEmpty && tempResult.isEmpty
        } else {
            // Проверяем, существует ли папка перед удалением
            let existsCheck = await shellCommand("test -d \"\(path)\" && echo 'exists' || echo 'not_exists'")
            if existsCheck.contains("not_exists") {
                // Папка уже не существует, считаем операцию успешной
                return true
            }
            
            let output = await shellCommand("/bin/rm -rf \"\(path)\" 2>/dev/null")
            return output.isEmpty
        }
    }
    
    func cleaniOSDevice(_ device: iOSDeviceInfo) async -> Bool {
        let output = await shellCommand("/bin/rm -rf \"\(device.path)\" 2>/dev/null")
        return output.isEmpty
    }
    
    func cleanArchive(_ archive: ArchiveInfo) async -> Bool {
        let output = await shellCommand("/bin/rm -rf \"\(archive.path)\" 2>/dev/null")
        return output.isEmpty
    }
    
    private func parseArchiveInfo(from plistContent: String, path: String, size: String) -> ArchiveInfo {
        // Простой парсинг plist контента
        let name = extractValue(from: plistContent, key: "Name") ?? "Unknown"
        let bundleId = extractValue(from: plistContent, key: "CFBundleIdentifier") ?? "Unknown"
        let version = extractValue(from: plistContent, key: "CFBundleShortVersionString") ?? "Unknown"
        let buildNumber = extractValue(from: plistContent, key: "CFBundleVersion") ?? "Unknown"
        let creationDate = extractValue(from: plistContent, key: "CreationDate") ?? "Unknown"
        
        return ArchiveInfo(
            name: name,
            bundleIdentifier: bundleId,
            version: version,
            buildNumber: buildNumber,
            creationDate: creationDate,
            path: path,
            size: size
        )
    }
    
    private func extractValue(from content: String, key: String) -> String? {
        let pattern = "\"\(key)\" => \"([^\"]+)\""
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, range: range) {
            if let range = Range(match.range(at: 1), in: content) {
                return String(content[range])
            }
        }
        return nil
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
    
    private func parseSizeToBytes(_ sizeString: String) -> Int? {
        let sizeString = sizeString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if sizeString.hasSuffix("K") {
            let number = String(sizeString.dropLast())
            return Int(Double(number) ?? 0) * 1024
        } else if sizeString.hasSuffix("M") {
            let number = String(sizeString.dropLast())
            return Int(Double(number) ?? 0) * 1024 * 1024
        } else if sizeString.hasSuffix("G") {
            let number = String(sizeString.dropLast())
            return Int(Double(number) ?? 0) * 1024 * 1024 * 1024
        } else if sizeString.hasSuffix("T") {
            let number = String(sizeString.dropLast())
            return Int(Double(number) ?? 0) * 1024 * 1024 * 1024 * 1024
        } else if sizeString.hasSuffix("B") {
            let number = String(sizeString.dropLast())
            return Int(Double(number) ?? 0)
        } else {
            return Int(Double(sizeString) ?? 0)
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
} 