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
        var xcodeCaches = XcodeCacheInfo()
        
        // CoreSimulator кэши (только кэши, не все данные симуляторов)
        let simulatorBasePath = "\(realHomePath)/Library/Developer/CoreSimulator"
        let simulatorCachesPath = "\(simulatorBasePath)/Caches"
        let simulatorTempPath = "\(simulatorBasePath)/Temp"
        
        // Считаем размер системных кэшей
        var simulatorTotalBytes: Int = 0
        let cachesSize = await shellCommand("du -sh \"\(simulatorCachesPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        let tempSize = await shellCommand("du -sh \"\(simulatorTempPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        
        simulatorTotalBytes += parseSizeToBytes(cachesSize) ?? 0
        simulatorTotalBytes += parseSizeToBytes(tempSize) ?? 0
        
        // Считаем кэши внутри каждого симулятора (Devices/*/data/Library/Caches)
        let deviceCachesCommand = "find \"\(simulatorBasePath)/Devices\" -path '*/data/Library/Caches' -type d -exec du -sk {} \\; 2>/dev/null | awk '{sum+=$1} END {print sum}'"
        let deviceCachesSizeKB = await shellCommand(deviceCachesCommand)
        if let sizeKB = Int(deviceCachesSizeKB.trimmingCharacters(in: .whitespacesAndNewlines)), sizeKB > 0 {
            simulatorTotalBytes += sizeKB * 1024
        }
        
        let simulatorTotalSize = formatBytes(simulatorTotalBytes)
        let simulatorCacheInfo = CacheInfo(path: simulatorBasePath, size: simulatorTotalSize)
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
        
        // Сканируем проекты DerivedData
        let derivedDataPath = "\(realHomePath)/Library/Developer/Xcode/DerivedData"
        let derivedDataSize = await shellCommand("du -sh \"\(derivedDataPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        let derivedDataInfo = CacheInfo(path: derivedDataPath, size: derivedDataSize)
        xcodeCaches.derivedData = derivedDataInfo
        
        // Сканируем отдельные проекты DerivedData
        let projectDirs = await shellCommand("ls \"\(derivedDataPath)\" 2>/dev/null")
        var derivedDataProjects: [DerivedDataProjectInfo] = []
        
        for projectDir in projectDirs.components(separatedBy: "\n").filter({ !$0.isEmpty && !$0.contains(".noindex") }) {
            let projectPath = "\(derivedDataPath)/\(projectDir)"
            let projectSize = await shellCommand("du -sh \"\(projectPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
            
            // Читаем info.plist проекта
            let infoPlistPath = "\(projectPath)/info.plist"
            let plistContent = await shellCommand("plutil -p \"\(infoPlistPath)\" 2>/dev/null")
            
            if !plistContent.isEmpty {
                let projectInfo = parseDerivedDataProjectInfo(from: plistContent, path: projectPath, size: projectSize, projectDir: projectDir)
                derivedDataProjects.append(projectInfo)
            }
        }
        
        xcodeCaches.derivedDataProjects = derivedDataProjects
        
        // Новые папки для macOS 26+
        let developerDiskImagesPath = "\(realHomePath)/Library/Developer/DeveloperDiskImages"
        let developerDiskImagesSize = await shellCommand("du -sh \"\(developerDiskImagesPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        if developerDiskImagesSize != "0B" {
            xcodeCaches.developerDiskImages = CacheInfo(path: developerDiskImagesPath, size: developerDiskImagesSize)
        }
        
        let xcpgDevicesPath = "\(realHomePath)/Library/Developer/XCPGDevices"
        let xcpgDevicesSize = await shellCommand("du -sh \"\(xcpgDevicesPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        if xcpgDevicesSize != "0B" {
            xcodeCaches.xcpgDevices = CacheInfo(path: xcpgDevicesPath, size: xcpgDevicesSize)
        }
        
        let dvtDownloadsPath = "\(realHomePath)/Library/Developer/DVTDownloads"
        let dvtDownloadsSize = await shellCommand("du -sh \"\(dvtDownloadsPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        if dvtDownloadsSize != "0B" {
            xcodeCaches.dvtDownloads = CacheInfo(path: dvtDownloadsPath, size: dvtDownloadsSize)
        }
        
        let xcTestDevicesPath = "\(realHomePath)/Library/Developer/XCTestDevices"
        let xcTestDevicesSize = await shellCommand("du -sh \"\(xcTestDevicesPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        if xcTestDevicesSize != "0B" {
            xcodeCaches.xcTestDevices = CacheInfo(path: xcTestDevicesPath, size: xcTestDevicesSize)
        }
        
        // Рассчитываем общий размер кэшей Xcode
        let xcodeTotalSize = calculateXcodeTotalSize(xcodeCaches)
        result.xcodeTotalSize = xcodeTotalSize
        result.xcodeCaches = xcodeCaches
        
        return result
    }
    
    func cleanCache(_ path: String) async -> Bool {
        // Для CoreSimulator удаляем только кэши, не все данные симуляторов
        if path.contains("CoreSimulator") {
            let simulatorCachesPath = "\(realHomePath)/Library/Developer/CoreSimulator/Caches"
            let simulatorTempPath = "\(realHomePath)/Library/Developer/CoreSimulator/Temp"
            
            // Очищаем системные кэши
            _ = await shellCommand("/bin/rm -rf \"\(simulatorCachesPath)\"/* 2>/dev/null")
            _ = await shellCommand("/bin/rm -rf \"\(simulatorTempPath)\"/* 2>/dev/null")
            
            // Очищаем кэши внутри каждого симулятора (только папки Caches, не приложения)
            _ = await shellCommand("find \"\(realHomePath)/Library/Developer/CoreSimulator/Devices\" -path '*/data/Library/Caches/*' -maxdepth 10 -type f -delete 2>/dev/null")
            
            // Проверяем успешность (если нет ошибок, вернется пустая строка)
            return true
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
    
    func cleanDerivedDataProject(_ project: DerivedDataProjectInfo) async -> Bool {
        let output = await shellCommand("/bin/rm -rf \"\(project.path)\" 2>/dev/null")
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
    
    private func parseDerivedDataProjectInfo(from plistContent: String, path: String, size: String, projectDir: String) -> DerivedDataProjectInfo {
        // Извлекаем название проекта из имени папки (до первого дефиса)
        let projectName = projectDir.components(separatedBy: "-").first ?? projectDir
        let workspacePath = extractValue(from: plistContent, key: "WorkspacePath") ?? "Unknown"
        let lastAccessedDate = extractValue(from: plistContent, key: "LastAccessedDate") ?? "Unknown"
        
        return DerivedDataProjectInfo(
            projectName: projectName,
            workspacePath: workspacePath,
            lastAccessedDate: lastAccessedDate,
            path: path,
            size: size
        )
    }
    
    private func calculateXcodeTotalSize(_ xcodeCaches: XcodeCacheInfo) -> String {
        var totalBytes: Int = 0
        
        // Добавляем размеры основных кэшей
        if let derivedData = xcodeCaches.derivedData {
            totalBytes += parseSizeToBytes(derivedData.size) ?? 0
        }
        if let archives = xcodeCaches.archives {
            totalBytes += parseSizeToBytes(archives.size) ?? 0
        }
        if let simulator = xcodeCaches.simulator {
            totalBytes += parseSizeToBytes(simulator.size) ?? 0
        }
        
        // Добавляем размеры новых папок macOS 26+
        if let developerDiskImages = xcodeCaches.developerDiskImages {
            totalBytes += parseSizeToBytes(developerDiskImages.size) ?? 0
        }
        if let xcpgDevices = xcodeCaches.xcpgDevices {
            totalBytes += parseSizeToBytes(xcpgDevices.size) ?? 0
        }
        if let dvtDownloads = xcodeCaches.dvtDownloads {
            totalBytes += parseSizeToBytes(dvtDownloads.size) ?? 0
        }
        if let xcTestDevices = xcodeCaches.xcTestDevices {
            totalBytes += parseSizeToBytes(xcTestDevices.size) ?? 0
        }
        
        // Добавляем размеры устройств iOS Device Support
        for device in xcodeCaches.iosDevices {
            totalBytes += parseSizeToBytes(device.size) ?? 0
        }
        
        // Добавляем размеры архивов
        for archive in xcodeCaches.archiveList {
            totalBytes += parseSizeToBytes(archive.size) ?? 0
        }
        
        // Добавляем размеры проектов DerivedData
        for project in xcodeCaches.derivedDataProjects {
            totalBytes += parseSizeToBytes(project.size) ?? 0
        }
        
        return formatBytes(totalBytes)
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