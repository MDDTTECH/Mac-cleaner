import SwiftUI

@MainActor
class CacheViewModel: ObservableObject {
    @Published var scanResult = CacheScanResult.empty
    @Published var isScanning = false
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
    
    private let service = CacheService.shared
    
    func scanCaches() async {
        isScanning = true
        scanResult = await service.scanCaches()
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
            await scanCaches()
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
    
    func cleaniOSDevice(_ device: iOSDeviceInfo) async {
        isCleaning = true
        cleaningCacheName = device.displayName
        cleaningProgress = "Начинаем очистку..."
        
        let success = await service.cleaniOSDevice(device)
        
        if success {
            cleaningProgress = "Очистка завершена. Обновляем данные..."
            // Обновляем результаты сканирования после очистки
            await scanCaches()
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
            await scanCaches()
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
            await scanCaches()
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