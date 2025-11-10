import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CacheViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            
            if viewModel.isScanning {
                ProgressView("Сканирование...")
            } else if viewModel.isCleaning {
                cleaningProgressSection
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        totalSizeSection
                        xcodeTotalSizeSection
                        topCachesSection
                        xcodeCachesSection
                    }
                    .padding()
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 800)
        .confirmationDialog(
            "Очистить кэш?",
            isPresented: $viewModel.showingConfirmation,
            presenting: viewModel.selectedCache
        ) { cache in
            Button("Очистить \(cache.displayName)") {
                Task {
                    await viewModel.cleanCache(cache)
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: { cache in
            Text("Вы уверены, что хотите очистить \(cache.displayName)?")
        }
        .confirmationDialog(
            "Удалить символы устройства?",
            isPresented: $viewModel.showingDeviceConfirmation,
            presenting: viewModel.selectedDevice
        ) { device in
            Button("Удалить \(device.displayName)") {
                Task {
                    await viewModel.cleaniOSDevice(device)
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: { device in
            Text("Вы уверены, что хотите удалить символы отладки для \(device.detailedDescription)?\n\nРазмер: \(device.size)\n\nСимволы будут перезагружены при следующем подключении устройства.")
        }
        .confirmationDialog(
            "Удалить архив?",
            isPresented: $viewModel.showingArchiveConfirmation,
            presenting: viewModel.selectedArchive
        ) { archive in
            Button("Удалить \(archive.displayName)") {
                Task {
                    await viewModel.cleanArchive(archive)
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: { archive in
            Text("Вы уверены, что хотите удалить архив \(archive.detailedDescription)?\n\nРазмер: \(archive.size)")
        }
        .confirmationDialog(
            "Удалить проект DerivedData?",
            isPresented: $viewModel.showingDerivedDataConfirmation,
            presenting: viewModel.selectedDerivedDataProject
        ) { project in
            Button("Удалить \(project.displayName)") {
                Task {
                    await viewModel.cleanDerivedDataProject(project)
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: { project in
            Text("Вы уверены, что хотите удалить кэш сборки для проекта \(project.detailedDescription)?\n\nРазмер: \(project.size)\n\nПроект будет пересобран при следующем открытии в Xcode.")
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Cache Cleaner")
                .font(.title)
                .bold()
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.scanCaches()
                }
            }) {
                Label("Сканировать", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isScanning || viewModel.isCleaning)
        }
    }
    
    private var cleaningProgressSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("Очистка кэша")
                    .font(.headline)
                
                if !viewModel.cleaningCacheName.isEmpty {
                    Text(viewModel.cleaningCacheName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(viewModel.cleaningProgress)
                    .font(.body)
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var totalSizeSection: some View {
        VStack(alignment: .leading) {
            Text("Общий размер кэшей")
                .font(.headline)
            Text(viewModel.scanResult.totalSize)
                .font(.title2)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var xcodeTotalSizeSection: some View {
        VStack(alignment: .leading) {
            Text("Размер кэшей Xcode")
                .font(.headline)
            Text(viewModel.scanResult.xcodeTotalSize)
                .font(.title2)
                .foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var topCachesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Топ 10 самых больших кэшей")
                .font(.headline)
            
            ForEach(viewModel.scanResult.topCaches) { cache in
                CacheRowView(cache: cache, isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = cache
                    viewModel.showingConfirmation = true
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var xcodeCachesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Кэши Xcode")
                .font(.headline)
            
            // DerivedData с раскрывающимся списком проектов
            if !viewModel.scanResult.xcodeCaches.derivedDataProjects.isEmpty {
                DisclosureGroup("DerivedData - кэш сборки") {
                    ForEach(viewModel.scanResult.xcodeCaches.derivedDataProjects) { project in
                        DerivedDataProjectRowView(project: project, isDisabled: viewModel.isCleaning) {
                            viewModel.selectedDerivedDataProject = project
                            viewModel.showingDerivedDataConfirmation = true
                        }
                    }
                }
            }
            
            // iOS Device Support с раскрывающимся списком устройств
            if !viewModel.scanResult.xcodeCaches.iosDevices.isEmpty {
                DisclosureGroup("iOS Device Support - символы отладки") {
                    ForEach(viewModel.scanResult.xcodeCaches.iosDevices) { device in
                        iOSDeviceRowView(device: device, isDisabled: viewModel.isCleaning) {
                            viewModel.selectedDevice = device
                            viewModel.showingDeviceConfirmation = true
                        }
                    }
                }
            }
            
            // Archives с раскрывающимся списком архивов
            if !viewModel.scanResult.xcodeCaches.archiveList.isEmpty {
                DisclosureGroup("Archives - архивы приложений") {
                    ForEach(viewModel.scanResult.xcodeCaches.archiveList) { archive in
                        ArchiveRowView(archive: archive, isDisabled: viewModel.isCleaning) {
                            viewModel.selectedArchive = archive
                            viewModel.showingArchiveConfirmation = true
                        }
                    }
                }
            }
            
            if let simulator = viewModel.scanResult.xcodeCaches.simulator {
                CacheRowView(cache: simulator, description: "CoreSimulator - кэши симуляторов (приложения и симуляторы сохраняются)", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = simulator
                    viewModel.showingConfirmation = true
                }
            }
            
            // Новые кэши для macOS 26+
            if let developerDiskImages = viewModel.scanResult.xcodeCaches.developerDiskImages {
                CacheRowView(cache: developerDiskImages, description: "DeveloperDiskImages - образы для разработки устройств", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = developerDiskImages
                    viewModel.showingConfirmation = true
                }
            }
            
            if let xcpgDevices = viewModel.scanResult.xcodeCaches.xcpgDevices {
                CacheRowView(cache: xcpgDevices, description: "XCPGDevices - данные подключенных устройств", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = xcpgDevices
                    viewModel.showingConfirmation = true
                }
            }
            
            if let dvtDownloads = viewModel.scanResult.xcodeCaches.dvtDownloads {
                CacheRowView(cache: dvtDownloads, description: "DVTDownloads - загрузки Xcode и инструменты", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = dvtDownloads
                    viewModel.showingConfirmation = true
                }
            }
            
            if let xcTestDevices = viewModel.scanResult.xcodeCaches.xcTestDevices {
                CacheRowView(cache: xcTestDevices, description: "XCTestDevices - данные для тестирования на устройствах", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = xcTestDevices
                    viewModel.showingConfirmation = true
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct iOSDeviceRowView: View {
    let device: iOSDeviceInfo
    let isDisabled: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.displayName)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                
                Text(device.detailedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(device.size)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.blue)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(isDisabled ? .gray : .red)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
        .padding(.vertical, 4)
    }
}

struct ArchiveRowView: View {
    let archive: ArchiveInfo
    let isDisabled: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(archive.displayName)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                
                Text(archive.detailedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(archive.size)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.blue)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(isDisabled ? .gray : .red)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
        .padding(.vertical, 4)
    }
}

struct DerivedDataProjectRowView: View {
    let project: DerivedDataProjectInfo
    let isDisabled: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.displayName)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                
                Text(project.detailedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(project.size)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.blue)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(isDisabled ? .gray : .red)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
        .padding(.vertical, 4)
    }
}

struct CacheRowView: View {
    let cache: CacheInfo
    let description: String?
    let onClean: () -> Void
    let isDisabled: Bool
    
    init(cache: CacheInfo, description: String? = nil, isDisabled: Bool = false, onClean: @escaping () -> Void) {
        self.cache = cache
        self.description = description
        self.isDisabled = isDisabled
        self.onClean = onClean
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(cache.displayName)
                    .font(.system(.body, design: .monospaced))
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(cache.size)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.blue)
            
            Button(action: onClean) {
                Image(systemName: "trash")
                    .foregroundColor(isDisabled ? .gray : .red)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
} 