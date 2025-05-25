import SwiftUI

@MainActor
class CacheViewModel: ObservableObject {
    @Published var scanResult = CacheScanResult.empty
    @Published var isScanning = false
    @Published var showingConfirmation = false
    @Published var selectedCache: CacheInfo?
    @Published var isCleaning = false
    
    private let service = CacheService.shared
    
    func scanCaches() async {
        isScanning = true
        scanResult = await service.scanCaches()
        isScanning = false
    }
    
    func cleanCache(_ cache: CacheInfo) async {
        isCleaning = true
        let success = await service.cleanCache(cache.path)
        if success {
            // Обновляем результаты сканирования после очистки
            await scanCaches()
        }
        isCleaning = false
    }
} 