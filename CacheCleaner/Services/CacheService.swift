import Foundation

class CacheService {
    static let shared = CacheService()
    private let fileManager = FileManager.default
    
    private var realHomePath: String {
        // В песочнице NSHomeDirectory() и $HOME указывают на контейнер приложения.
        // getpwuid читает из системной базы и возвращает реальный home directory.
        if let pw = getpwuid(getuid()), let home = pw.pointee.pw_dir {
            return String(cString: home)
        }
        return NSHomeDirectory()
    }
    
    func scanCaches(quickScan: Bool = true, progressCallback: @escaping (String) async -> Void = { _ in }) async -> CacheScanResult {
        print("=== CacheCleaner: Starting scan (quickScan: \(quickScan)) ===")
        print("CacheCleaner: NSHomeDirectory = \(NSHomeDirectory())")
        print("CacheCleaner: realHomePath = \(realHomePath)")
        var result = CacheScanResult()
        
        // Общий размер кэшей
        await progressCallback("Сканирование общих кэшей...")
        let cachesPath = "\(realHomePath)/Library/Caches"
        print("CacheCleaner: Scanning path: \(cachesPath)")
        
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
        
        // Топ кэшей - оптимизированная команда
        print("CacheCleaner: Analyzing top 10 caches...")
        await progressCallback("Анализ топ-10 кэшей...")
        let topCachesCommand = "du -sh \"\(cachesPath)\"/*/ 2>/dev/null | sort -hr | head -n 10"
        let topCachesOutput = await shellCommand(topCachesCommand)
        print("CacheCleaner: Top caches output length: \(topCachesOutput.count) chars")
        result.topCaches = topCachesOutput
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line -> CacheInfo? in
                let parts = line.components(separatedBy: "\t")
                guard parts.count == 2 else { return nil }
                return CacheInfo(path: parts[1], size: parts[0])
            }
        
        // Xcode кэши
        print("CacheCleaner: Scanning Xcode caches...")
        await progressCallback("Сканирование Xcode кэшей...")
        var xcodeCaches = XcodeCacheInfo()
        
        // CoreSimulator кэши (только кэши, не все данные симуляторов)
        print("CacheCleaner: Scanning CoreSimulator...")
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
        
        // Сканируем iOS Device Support
        let deviceSupportPath = "\(realHomePath)/Library/Developer/Xcode/iOS DeviceSupport"
        let deviceSupportSize = await shellCommand("du -sh \"\(deviceSupportPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        if deviceSupportSize != "0B" {
            xcodeCaches.deviceSupport = CacheInfo(path: deviceSupportPath, size: deviceSupportSize)
        }
        
        // Сканируем отдельные устройства iOS Device Support (только если не быстрое сканирование)
        var iosDevices: [iOSDeviceInfo] = []
        if !quickScan {
            await progressCallback("Детальное сканирование iOS Device Support...")
            let deviceDirs = await shellCommand("ls \"\(deviceSupportPath)\" 2>/dev/null")
            
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
        }
        xcodeCaches.iosDevices = iosDevices
        
        // Сканируем архивы
        await progressCallback("Сканирование Xcode архивов...")
        let archivesPath = "\(realHomePath)/Library/Developer/Xcode/Archives"
        let archivesSize = await shellCommand("du -sh \"\(archivesPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        let archivesInfo = CacheInfo(path: archivesPath, size: archivesSize)
        xcodeCaches.archives = archivesInfo
        
        // Сканируем отдельные архивы (только если не быстрое сканирование)
        var archiveList: [ArchiveInfo] = []
        if !quickScan {
            let archiveDirs = await shellCommand("find \"\(archivesPath)\" -name \"*.xcarchive\" -type d 2>/dev/null")
            
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
        }
        xcodeCaches.archiveList = archiveList
        
        // Сканируем проекты DerivedData
        await progressCallback("Сканирование DerivedData...")
        let derivedDataPath = "\(realHomePath)/Library/Developer/Xcode/DerivedData"
        let derivedDataSize = await shellCommand("du -sh \"\(derivedDataPath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        let derivedDataInfo = CacheInfo(path: derivedDataPath, size: derivedDataSize)
        xcodeCaches.derivedData = derivedDataInfo
        
        // Сканируем отдельные проекты DerivedData (только если не быстрое сканирование)
        var derivedDataProjects: [DerivedDataProjectInfo] = []
        if !quickScan {
            let projectDirs = await shellCommand("ls \"\(derivedDataPath)\" 2>/dev/null")
            
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
        
        // Сканируем кэши разработки (Flutter, Gradle, npm)
        await progressCallback("Сканирование кэшей разработки...")
        var developmentCaches = DevelopmentCacheInfo()
        
        // Flutter pub cache
        print("CacheCleaner: Scanning Flutter pub cache...")
        let pubCachePath = "\(realHomePath)/.pub-cache"
        let pubCacheSize = await shellCommand("du -sh \"\(pubCachePath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        print("CacheCleaner: Flutter pub cache size: \(pubCacheSize)")
        
        if pubCacheSize != "0B" {
            developmentCaches.pubCache = CacheInfo(path: pubCachePath, size: pubCacheSize)
            
            // Детальное сканирование Flutter пакетов отключено (слишком медленно для 1600+ пакетов)
            // Пользователь может удалить всю папку .pub-cache если нужно
            if false && !quickScan {
                print("CacheCleaner: Starting detailed Flutter package scan...")
                await progressCallback("Детальный анализ Flutter пакетов (это может занять время)...")
                let packagesPath = "\(pubCachePath)/hosted/pub.dev"
                print("CacheCleaner: Running du command for Flutter packages...")
                // Оптимизация: сортируем и берём только топ-50 сразу для экономии времени
                let packagesOutput = await shellCommand("du -sk \"\(packagesPath)\"/*-* 2>/dev/null | sort -rn | head -50")
                print("CacheCleaner: Flutter packages scan complete, parsing \(packagesOutput.components(separatedBy: "\n").count) lines...")
                
                var packageDict: [String: [FlutterPackageVersion]] = [:]
                
                for line in packagesOutput.components(separatedBy: "\n").filter({ !$0.isEmpty }) {
                    let parts = line.components(separatedBy: "\t")
                    guard parts.count == 2 else { continue }
                    
                    let sizeKB = parts[0]
                    let path = parts[1]
                    let packageFullName = path.components(separatedBy: "/").last ?? ""
                    
                    // Парсим имя пакета и версию (например: "rive_common-0.1.0")
                    if let lastDashIndex = packageFullName.lastIndex(of: "-") {
                        let packageName = String(packageFullName[..<lastDashIndex])
                        let version = String(packageFullName[packageFullName.index(after: lastDashIndex)...])
                        
                        let sizeBytes = (Int(sizeKB) ?? 0) * 1024
                        let size = formatBytes(sizeBytes)
                        
                        let packageVersion = FlutterPackageVersion(
                            packageName: packageName,
                            version: version,
                            path: path,
                            size: size
                        )
                        
                        packageDict[packageName, default: []].append(packageVersion)
                    }
                }
                
                // Группируем пакеты и сортируем по размеру
                var packageGroups: [FlutterPackageGroup] = []
                for (packageName, versions) in packageDict {
                    let totalBytes = versions.reduce(0) { $0 + (parseSizeToBytes($1.size) ?? 0) }
                    let totalSize = formatBytes(totalBytes)
                    
                    let sortedVersions = versions.sorted { (parseSizeToBytes($0.size) ?? 0) > (parseSizeToBytes($1.size) ?? 0) }
                    
                    let group = FlutterPackageGroup(
                        packageName: packageName,
                        versions: sortedVersions,
                        totalSize: totalSize
                    )
                    packageGroups.append(group)
                }
                
                // Сортируем группы по общему размеру и берём топ-30
                developmentCaches.pubPackages = packageGroups.sorted {
                    (parseSizeToBytes($0.totalSize) ?? 0) > (parseSizeToBytes($1.totalSize) ?? 0)
                }.prefix(30).map { $0 }
            }
        }
        
        // Gradle cache
        let gradleCachePath = "\(realHomePath)/.gradle"
        let gradleCacheSize = await shellCommand("du -sh \"\(gradleCachePath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        if gradleCacheSize != "0B" {
            developmentCaches.gradleCache = CacheInfo(path: gradleCachePath, size: gradleCacheSize)
        }
        
        // npm cache
        let npmCachePath = "\(realHomePath)/.npm"
        let npmCacheSize = await shellCommand("du -sh \"\(npmCachePath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        if npmCacheSize != "0B" {
            developmentCaches.npmCache = CacheInfo(path: npmCachePath, size: npmCacheSize)
        }
        
        // ~/.cache
        let homeCachePath = "\(realHomePath)/.cache"
        let homeCacheSize = await shellCommand("du -sh \"\(homeCachePath)\" 2>/dev/null").components(separatedBy: "\t").first ?? "0B"
        if homeCacheSize != "0B" {
            developmentCaches.homeCache = CacheInfo(path: homeCachePath, size: homeCacheSize)
        }
        
        // Рассчитываем общий размер кэшей разработки
        print("CacheCleaner: Calculating development total size...")
        let developmentTotalSize = calculateDevelopmentTotalSize(developmentCaches)
        result.developmentTotalSize = developmentTotalSize
        result.developmentCaches = developmentCaches
        
        print("=== CacheCleaner: Scan complete ===")
        print("  Total size: \(result.totalSize)")
        print("  Xcode size: \(result.xcodeTotalSize)")
        print("  Development size: \(result.developmentTotalSize)")
        print("  Top caches count: \(result.topCaches.count)")
        
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
    
    func cleanFlutterPackageVersion(_ package: FlutterPackageVersion) async -> Bool {
        let output = await shellCommand("/bin/rm -rf \"\(package.path)\" 2>/dev/null")
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
    
    private func calculateDevelopmentTotalSize(_ developmentCaches: DevelopmentCacheInfo) -> String {
        var totalBytes: Int = 0
        
        if let pubCache = developmentCaches.pubCache {
            totalBytes += parseSizeToBytes(pubCache.size) ?? 0
        }
        if let gradleCache = developmentCaches.gradleCache {
            totalBytes += parseSizeToBytes(gradleCache.size) ?? 0
        }
        if let npmCache = developmentCaches.npmCache {
            totalBytes += parseSizeToBytes(npmCache.size) ?? 0
        }
        if let homeCache = developmentCaches.homeCache {
            totalBytes += parseSizeToBytes(homeCache.size) ?? 0
        }
        
        return formatBytes(totalBytes)
    }
    
    private func calculateXcodeTotalSize(_ xcodeCaches: XcodeCacheInfo) -> String {
        var totalBytes: Int = 0
        
        // DerivedData - используем детальные размеры если есть, иначе общий
        if !xcodeCaches.derivedDataProjects.isEmpty {
            // Считаем отдельные проекты
            for project in xcodeCaches.derivedDataProjects {
                totalBytes += parseSizeToBytes(project.size) ?? 0
            }
        } else if let derivedData = xcodeCaches.derivedData {
            // Иначе считаем всю папку
            totalBytes += parseSizeToBytes(derivedData.size) ?? 0
        }
        
        // iOS Device Support - используем детальные размеры если есть, иначе общий
        if !xcodeCaches.iosDevices.isEmpty {
            // Считаем отдельные устройства
            for device in xcodeCaches.iosDevices {
                totalBytes += parseSizeToBytes(device.size) ?? 0
            }
        } else if let deviceSupport = xcodeCaches.deviceSupport {
            // Иначе считаем всю папку
            totalBytes += parseSizeToBytes(deviceSupport.size) ?? 0
        }
        
        // Archives - используем детальные размеры если есть, иначе общий
        if !xcodeCaches.archiveList.isEmpty {
            // Считаем отдельные архивы
            for archive in xcodeCaches.archiveList {
                totalBytes += parseSizeToBytes(archive.size) ?? 0
            }
        } else if let archives = xcodeCaches.archives {
            // Иначе считаем всю папку
            totalBytes += parseSizeToBytes(archives.size) ?? 0
        }
        
        // CoreSimulator - всегда общий размер
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