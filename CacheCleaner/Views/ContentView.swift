import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CacheViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            
            if viewModel.isScanning {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text(viewModel.scanningProgress)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isCleaning {
                cleaningProgressSection
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Блок 1: Общие кэши
                        VStack(alignment: .leading, spacing: 10) {
                            totalSizeSection
                            topCachesSection
                        }
                        
                        Divider()
                        
                        // Блок 2: Xcode кэши
                        VStack(alignment: .leading, spacing: 10) {
                            xcodeTotalSizeSection
                            xcodeCachesSection
                        }
                        
                        Divider()
                        
                        // Блок 3: Кэши разработки
                        VStack(alignment: .leading, spacing: 10) {
                            developmentTotalSizeSection
                            developmentCachesSection
                        }
                        
                        if viewModel.isQuickScan {
                            Divider()
                            quickScanInfoSection
                        }
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
        .confirmationDialog(
            "Удалить Flutter пакет?",
            isPresented: $viewModel.showingFlutterPackageConfirmation,
            presenting: viewModel.selectedFlutterPackage
        ) { package in
            Button("Удалить \(package.displayName)") {
                Task {
                    await viewModel.cleanFlutterPackageVersion(package)
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: { package in
            Text("Вы уверены, что хотите удалить Flutter пакет \(package.displayName)?\n\nРазмер: \(package.size)\n\nПакет будет скачан при следующем запуске flutter pub get.")
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
    
    private var developmentTotalSizeSection: some View {
        VStack(alignment: .leading) {
            Text("Размер кэшей разработки (Flutter, Gradle, npm)")
                .font(.headline)
            Text(viewModel.scanResult.developmentTotalSize)
                .font(.title2)
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var quickScanInfoSection: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Быстрое сканирование")
                    .font(.headline)
                Text("Детальная информация о Xcode проектах и архивах скрыта для ускорения")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Полное сканирование") {
                Task {
                    await viewModel.scanCaches(quick: false)
                }
            }
            .disabled(viewModel.isScanning || viewModel.isCleaning)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var topCachesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !viewModel.scanResult.topCaches.isEmpty {
                DisclosureGroup {
                    ForEach(viewModel.scanResult.topCaches) { cache in
                        CacheRowView(cache: cache, isDisabled: viewModel.isCleaning) {
                            viewModel.selectedCache = cache
                            viewModel.showingConfirmation = true
                        }
                    }
                } label: {
                    HStack {
                        Text("Топ 10 самых больших папок")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func cacheHeaderLabel(cache: CacheInfo, description: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(cache.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(cache.size)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.orange)
            Button(action: {
                viewModel.selectedCache = cache
                viewModel.showingConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(viewModel.isCleaning ? .gray : .red)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isCleaning)
        }
    }
    
    private var xcodeCachesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // DerivedData с раскрывающимся списком проектов
            if let derivedData = viewModel.scanResult.xcodeCaches.derivedData {
                if !viewModel.scanResult.xcodeCaches.derivedDataProjects.isEmpty {
                    // Полное сканирование - показываем проекты
                    DisclosureGroup {
                        ForEach(viewModel.scanResult.xcodeCaches.derivedDataProjects) { project in
                            DerivedDataProjectRowView(project: project, isDisabled: viewModel.isCleaning) {
                                viewModel.selectedDerivedDataProject = project
                                viewModel.showingDerivedDataConfirmation = true
                            }
                        }
                    } label: {
                        cacheHeaderLabel(cache: derivedData, description: "кэш сборки")
                    }
                } else {
                    // Быстрое сканирование - только размер
                    CacheRowView(cache: derivedData, description: "кэш сборки", isDisabled: viewModel.isCleaning) {
                        viewModel.selectedCache = derivedData
                        viewModel.showingConfirmation = true
                    }
                }
            }
            
            // iOS Device Support с раскрывающимся списком устройств
            if let deviceSupport = viewModel.scanResult.xcodeCaches.deviceSupport {
                if !viewModel.scanResult.xcodeCaches.iosDevices.isEmpty {
                    // Полное сканирование - показываем устройства
                    DisclosureGroup {
                        ForEach(viewModel.scanResult.xcodeCaches.iosDevices) { device in
                            iOSDeviceRowView(device: device, isDisabled: viewModel.isCleaning) {
                                viewModel.selectedDevice = device
                                viewModel.showingDeviceConfirmation = true
                            }
                        }
                    } label: {
                        cacheHeaderLabel(cache: deviceSupport, description: "символы отладки")
                    }
                } else {
                    // Быстрое сканирование - только размер
                    CacheRowView(cache: deviceSupport, description: "символы отладки", isDisabled: viewModel.isCleaning) {
                        viewModel.selectedCache = deviceSupport
                        viewModel.showingConfirmation = true
                    }
                }
            }
            
            // Archives с раскрывающимся списком архивов
            if let archives = viewModel.scanResult.xcodeCaches.archives {
                if !viewModel.scanResult.xcodeCaches.archiveList.isEmpty {
                    // Полное сканирование - показываем архивы
                    DisclosureGroup {
                        ForEach(viewModel.scanResult.xcodeCaches.archiveList) { archive in
                            ArchiveRowView(archive: archive, isDisabled: viewModel.isCleaning) {
                                viewModel.selectedArchive = archive
                                viewModel.showingArchiveConfirmation = true
                            }
                        }
                    } label: {
                        cacheHeaderLabel(cache: archives, description: "архивы приложений")
                    }
                } else {
                    // Быстрое сканирование - только размер
                    CacheRowView(cache: archives, description: "архивы приложений", isDisabled: viewModel.isCleaning) {
                        viewModel.selectedCache = archives
                        viewModel.showingConfirmation = true
                    }
                }
            }
            
            if let simulator = viewModel.scanResult.xcodeCaches.simulator {
                CacheRowView(cache: simulator, description: "кэши симуляторов", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = simulator
                    viewModel.showingConfirmation = true
                }
            }
            
            // Новые кэши для macOS 26+
            if let developerDiskImages = viewModel.scanResult.xcodeCaches.developerDiskImages {
                CacheRowView(cache: developerDiskImages, description: "образы для разработки", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = developerDiskImages
                    viewModel.showingConfirmation = true
                }
            }
            
            if let xcpgDevices = viewModel.scanResult.xcodeCaches.xcpgDevices {
                CacheRowView(cache: xcpgDevices, description: "данные устройств", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = xcpgDevices
                    viewModel.showingConfirmation = true
                }
            }
            
            if let dvtDownloads = viewModel.scanResult.xcodeCaches.dvtDownloads {
                CacheRowView(cache: dvtDownloads, description: "загрузки и инструменты", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = dvtDownloads
                    viewModel.showingConfirmation = true
                }
            }
            
            if let xcTestDevices = viewModel.scanResult.xcodeCaches.xcTestDevices {
                CacheRowView(cache: xcTestDevices, description: "данные тестирования", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = xcTestDevices
                    viewModel.showingConfirmation = true
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var developmentCachesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Flutter Pub Cache (детальное сканирование отключено из-за медленности)
            if let pubCache = viewModel.scanResult.developmentCaches.pubCache {
                CacheRowView(cache: pubCache, description: "пакеты Dart/Flutter", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = pubCache
                    viewModel.showingConfirmation = true
                }
            }
            
            // Gradle cache
            if let gradleCache = viewModel.scanResult.developmentCaches.gradleCache {
                CacheRowView(cache: gradleCache, description: "кэш сборки Android", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = gradleCache
                    viewModel.showingConfirmation = true
                }
            }
            
            // npm cache
            if let npmCache = viewModel.scanResult.developmentCaches.npmCache {
                CacheRowView(cache: npmCache, description: "кэш Node.js пакетов", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = npmCache
                    viewModel.showingConfirmation = true
                }
            }
            
            // ~/.cache
            if let homeCache = viewModel.scanResult.developmentCaches.homeCache {
                CacheRowView(cache: homeCache, description: "системный кэш", isDisabled: viewModel.isCleaning) {
                    viewModel.selectedCache = homeCache
                    viewModel.showingConfirmation = true
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FlutterPackageVersionRowView: View {
    let package: FlutterPackageVersion
    let isDisabled: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(package.version)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .padding(.leading, 20)
            }
            
            Spacer()
            
            Text(package.size)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.green)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(isDisabled ? .gray : .red)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
        .padding(.vertical, 2)
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