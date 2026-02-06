import SwiftUI

@MainActor
class CacheViewModel: ObservableObject {
    @Published var scanResult = CacheScanResult.empty
    @Published var isScanning = false
    @Published var scanningProgress: String = "Сканирование..."
    @Published var isQuickScan = true
    
    // Множественный выбор для CacheInfo (топ-10, Xcode, кэши разработки)
    @Published var selectedCacheInfos: Set<UUID> = []
    
    // Множественный выбор для раскрывающихся списков с другими типами
    @Published var selectedDerivedDataProjects: Set<UUID> = []
    @Published var selectediOSDevices: Set<UUID> = []
    @Published var selectedArchives: Set<UUID> = []
    
    @Published var showingConfirmation = false
    @Published var selectedCache: CacheInfo?
    @Published var isCleaning = false
    @Published var cleaningProgress: String = ""
    @Published var cleaningCacheName: String = ""
    @Published var showingDeviceConfirmation = false
    @Published var selectedDevice: iOSDeviceInfo?
    @Published var showingArchiveConfirmation = false
    @Published var selectedArchive: ArchiveInfo?
    @Published var showingDerivedDataConfirmation = false
    @Published var selectedDerivedDataProject: DerivedDataProjectInfo?
    @Published var showingFlutterPackageConfirmation = false
    @Published var selectedFlutterPackage: FlutterPackageVersion?
    
    private let service = CacheService.shared
    
    var hasAnySelection: Bool {
        !selectedCacheInfos.isEmpty ||
        !selectedDerivedDataProjects.isEmpty ||
        !selectediOSDevices.isEmpty ||
        !selectedArchives.isEmpty
    }
    
    func scanCaches(quick: Bool = true) async {
        isScanning = true
        isQuickScan = quick
        scanningProgress = quick ? "Быстрое сканирование..." : "Полное сканирование..."
        scanResult = await service.scanCaches(quickScan: quick) { progress in
            await MainActor.run {
                self.scanningProgress = progress
            }
        }
        isScanning = false
    }
    
    func cleanCache(_ cache: CacheInfo) async {
        isCleaning = true
        cleaningCacheName = cache.displayName
        cleaningProgress = "Начинаем очистку..."
        
        let success = await service.cleanCache(cache.path)

        if success {
            cleaningProgress = "Очистка завершена. Обновляем данные..."
            // Обновляем результаты сканирования после очистки
            await scanCaches(quick: isQuickScan)
            cleaningProgress = "Готово!"
        } else {
            cleaningProgress = "Ошибка при очистке"
        }
        
        // Небольшая задержка чтобы пользователь увидел сообщение
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
        
        isCleaning = false
        cleaningProgress = ""
        cleaningCacheName = ""
    }
    
    /// Очистка всех выбранных элементов (любые разделы)
    func cleanSelected() async {
        guard hasAnySelection else { return }
        
        isCleaning = true
        cleaningCacheName = "Несколько элементов"
        cleaningProgress = "Начинаем очистку..."
        
        var hadError = false
        
        // Все CacheInfo, которые могут быть в интерфейсе
        var allCacheInfos: [CacheInfo] = []
        // Топ-10
        allCacheInfos.append(contentsOf: scanResult.topCaches)
        // Xcode верхнего уровня
        if let derivedData = scanResult.xcodeCaches.derivedData {
            allCacheInfos.append(derivedData)
        }
        if let deviceSupport = scanResult.xcodeCaches.deviceSupport {
            allCacheInfos.append(deviceSupport)
        }
        if let archives = scanResult.xcodeCaches.archives {
            allCacheInfos.append(archives)
        }
        if let simulator = scanResult.xcodeCaches.simulator {
            allCacheInfos.append(simulator)
        }
        if let developerDiskImages = scanResult.xcodeCaches.developerDiskImages {
            allCacheInfos.append(developerDiskImages)
        }
        if let xcpgDevices = scanResult.xcodeCaches.xcpgDevices {
            allCacheInfos.append(xcpgDevices)
        }
        if let dvtDownloads = scanResult.xcodeCaches.dvtDownloads {
            allCacheInfos.append(dvtDownloads)
        }
        if let xcTestDevices = scanResult.xcodeCaches.xcTestDevices {
            allCacheInfos.append(xcTestDevices)
        }
        // Кэши разработки
        if let pubCache = scanResult.developmentCaches.pubCache {
            allCacheInfos.append(pubCache)
        }
        if let gradleCache = scanResult.developmentCaches.gradleCache {
            allCacheInfos.append(gradleCache)
        }
        if let npmCache = scanResult.developmentCaches.npmCache {
            allCacheInfos.append(npmCache)
        }
        if let homeCache = scanResult.developmentCaches.homeCache {
            allCacheInfos.append(homeCache)
        }
        
        for cache in allCacheInfos where selectedCacheInfos.contains(cache.id) {
            cleaningCacheName = cache.displayName
            let success = await service.cleanCache(cache.path)
            if !success {
                hadError = true
            }
        }
        
        // Проекты DerivedData
        for project in scanResult.xcodeCaches.derivedDataProjects
            where selectedDerivedDataProjects.contains(project.id) {
            cleaningCacheName = project.displayName
            let success = await service.cleanDerivedDataProject(project)
            if !success {
                hadError = true
            }
        }
        
        // Устройства iOS
        for device in scanResult.xcodeCaches.iosDevices
            where selectediOSDevices.contains(device.id) {
            cleaningCacheName = device.displayName
            let success = await service.cleaniOSDevice(device)
            if !success {
                hadError = true
            }
        }
        
        // Архивы
        for archive in scanResult.xcodeCaches.archiveList
            where selectedArchives.contains(archive.id) {
            cleaningCacheName = archive.displayName
            let success = await service.cleanArchive(archive)
            if !success {
                hadError = true
            }
        }
        
        if !hadError {
            cleaningProgress = "Очистка завершена. Обновляем данные..."
            await scanCaches(quick: isQuickScan)
            cleaningProgress = "Готово!"
        } else {
            cleaningProgress = "Очистка завершена с ошибками"
        }
        
        // Небольшая задержка чтобы пользователь увидел сообщение
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
        
        isCleaning = false
        cleaningProgress = ""
        cleaningCacheName = ""
        
        // Сбрасываем выбор
        selectedCacheInfos.removeAll()
        selectedDerivedDataProjects.removeAll()
        selectediOSDevices.removeAll()
        selectedArchives.removeAll()
    }
    
    func cleaniOSDevice(_ device: iOSDeviceInfo) async {
        isCleaning = true
        cleaningCacheName = device.displayName
        cleaningProgress = "Начинаем очистку..."
        
        let success = await service.cleaniOSDevice(device)
        
        if success {
            cleaningProgress = "Очистка завершена. Обновляем данные..."
            // Обновляем результаты сканирования после очистки
            await scanCaches(quick: isQuickScan)
            cleaningProgress = "Готово!"
        } else {
            cleaningProgress = "Ошибка при очистке"
        }
        
        // Небольшая задержка чтобы пользователь увидел сообщение
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
        
        isCleaning = false
        cleaningProgress = ""
        cleaningCacheName = ""
    }
    
    func cleanArchive(_ archive: ArchiveInfo) async {
        isCleaning = true
        cleaningCacheName = archive.displayName
        cleaningProgress = "Начинаем очистку..."
        
        let success = await service.cleanArchive(archive)
        
        if success {
            cleaningProgress = "Очистка завершена. Обновляем данные..."
            // Обновляем результаты сканирования после очистки
            await scanCaches(quick: isQuickScan)
            cleaningProgress = "Готово!"
        } else {
            cleaningProgress = "Ошибка при очистке"
        }
        
        // Небольшая задержка чтобы пользователь увидел сообщение
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
        
        isCleaning = false
        cleaningProgress = ""
        cleaningCacheName = ""
    }
    
    func cleanDerivedDataProject(_ project: DerivedDataProjectInfo) async {
        isCleaning = true
        cleaningCacheName = project.displayName
        cleaningProgress = "Начинаем очистку..."
        
        let success = await service.cleanDerivedDataProject(project)
        
        if success {
            cleaningProgress = "Очистка завершена. Обновляем данные..."
            // Обновляем результаты сканирования после очистки
            await scanCaches(quick: isQuickScan)
            cleaningProgress = "Готово!"
        } else {
            cleaningProgress = "Ошибка при очистке"
        }
        
        // Небольшая задержка чтобы пользователь увидел сообщение
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
        
        isCleaning = false
        cleaningProgress = ""
        cleaningCacheName = ""
    }
    
    func cleanFlutterPackageVersion(_ package: FlutterPackageVersion) async {
        isCleaning = true
        cleaningCacheName = package.displayName
        cleaningProgress = "Начинаем очистку..."
        
        let success = await service.cleanFlutterPackageVersion(package)
        
        if success {
            cleaningProgress = "Очистка завершена. Обновляем данные..."
            // Обновляем результаты сканирования после очистки
            await scanCaches(quick: isQuickScan)
            cleaningProgress = "Готово!"
        } else {
            cleaningProgress = "Ошибка при очистке"
        }
        
        // Небольшая задержка чтобы пользователь увидел сообщение
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
        
        isCleaning = false
        cleaningProgress = ""
        cleaningCacheName = ""
    }
} 