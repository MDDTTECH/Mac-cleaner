import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CacheViewModel()
    @State private var isMultiSelectMode = false
    @State private var showCards = false
    @State private var hasScanned = false
    
    var body: some View {
        ZStack {
            if viewModel.isScanning {
                ScanningAnimationView(progressText: viewModel.scanningProgress)
                    .transition(.opacity)
            } else if viewModel.isCleaning {
                CleaningProgressView(
                    cacheName: viewModel.cleaningCacheName,
                    progressText: viewModel.cleaningProgress
                )
                .transition(.opacity)
            } else if hasScanned {
                mainContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isScanning)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isCleaning)
        .frame(minWidth: 680, minHeight: 700)
        .background(Color(nsColor: .windowBackgroundColor))
        .confirmationDialogs(viewModel: viewModel)
        .task {
            // Auto-scan on first launch
            if !hasScanned {
                await viewModel.scanCaches()
                hasScanned = true
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                HeroSection(
                    viewModel: viewModel,
                    isMultiSelectMode: $isMultiSelectMode
                )
                .padding(.top, AppTheme.Spacing.sm)
                
                GeneralCachesCard(
                    viewModel: viewModel,
                    isMultiSelectMode: isMultiSelectMode
                )
                .offset(y: showCards ? 0 : 20)
                .opacity(showCards ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: showCards)
                
                XcodeCachesCard(
                    viewModel: viewModel,
                    isMultiSelectMode: isMultiSelectMode
                )
                .offset(y: showCards ? 0 : 20)
                .opacity(showCards ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showCards)
                
                DevelopmentCachesCard(
                    viewModel: viewModel,
                    isMultiSelectMode: isMultiSelectMode
                )
                .offset(y: showCards ? 0 : 20)
                .opacity(showCards ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: showCards)
                
                if viewModel.isQuickScan {
                    QuickScanBanner(viewModel: viewModel)
                        .offset(y: showCards ? 0 : 20)
                        .opacity(showCards ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: showCards)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showCards = true
            }
        }
        .onChange(of: viewModel.isScanning) { _, newValue in
            if newValue {
                showCards = false
            } else {
                hasScanned = true
                withAnimation(.easeOut(duration: 0.5)) {
                    showCards = true
                }
            }
        }
    }
}

// MARK: - Confirmation Dialogs

private extension View {
    func confirmationDialogs(viewModel: CacheViewModel) -> some View {
        self
            .confirmationDialog(
                "Очистить кэш?",
                isPresented: Binding(
                    get: { viewModel.showingConfirmation },
                    set: { viewModel.showingConfirmation = $0 }
                ),
                presenting: viewModel.selectedCache
            ) { cache in
                Button("Очистить \(cache.displayName)") {
                    Task { await viewModel.cleanCache(cache) }
                }
                Button("Отмена", role: .cancel) {}
            } message: { cache in
                Text("Вы уверены, что хотите очистить \(cache.displayName)?")
            }
            .confirmationDialog(
                "Удалить символы устройства?",
                isPresented: Binding(
                    get: { viewModel.showingDeviceConfirmation },
                    set: { viewModel.showingDeviceConfirmation = $0 }
                ),
                presenting: viewModel.selectedDevice
            ) { device in
                Button("Удалить \(device.displayName)") {
                    Task { await viewModel.cleaniOSDevice(device) }
                }
                Button("Отмена", role: .cancel) {}
            } message: { device in
                Text("Удалить символы для \(device.detailedDescription)?\nРазмер: \(device.size)")
            }
            .confirmationDialog(
                "Удалить архив?",
                isPresented: Binding(
                    get: { viewModel.showingArchiveConfirmation },
                    set: { viewModel.showingArchiveConfirmation = $0 }
                ),
                presenting: viewModel.selectedArchive
            ) { archive in
                Button("Удалить \(archive.displayName)") {
                    Task { await viewModel.cleanArchive(archive) }
                }
                Button("Отмена", role: .cancel) {}
            } message: { archive in
                Text("Удалить архив \(archive.detailedDescription)?\nРазмер: \(archive.size)")
            }
            .confirmationDialog(
                "Удалить проект DerivedData?",
                isPresented: Binding(
                    get: { viewModel.showingDerivedDataConfirmation },
                    set: { viewModel.showingDerivedDataConfirmation = $0 }
                ),
                presenting: viewModel.selectedDerivedDataProject
            ) { project in
                Button("Удалить \(project.displayName)") {
                    Task { await viewModel.cleanDerivedDataProject(project) }
                }
                Button("Отмена", role: .cancel) {}
            } message: { project in
                Text("Удалить кэш сборки \(project.detailedDescription)?\nРазмер: \(project.size)")
            }
            .confirmationDialog(
                "Удалить Flutter пакет?",
                isPresented: Binding(
                    get: { viewModel.showingFlutterPackageConfirmation },
                    set: { viewModel.showingFlutterPackageConfirmation = $0 }
                ),
                presenting: viewModel.selectedFlutterPackage
            ) { package in
                Button("Удалить \(package.displayName)") {
                    Task { await viewModel.cleanFlutterPackageVersion(package) }
                }
                Button("Отмена", role: .cancel) {}
            } message: { package in
                Text("Удалить Flutter пакет \(package.displayName)?\nРазмер: \(package.size)")
            }
    }
}

// MARK: - Hero Section

struct HeroSection: View {
    @ObservedObject var viewModel: CacheViewModel
    @Binding var isMultiSelectMode: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            titleBar
            gaugeAndStats
        }
    }
    
    private var titleBar: some View {
        HStack {
            Text("Cache Cleaner")
                .font(.system(.title2, design: .rounded, weight: .bold))
            
            Spacer()
            
            actionButtons
        }
    }
    
    private var gaugeAndStats: some View {
        HStack(spacing: AppTheme.Spacing.xxxl) {
            RingGaugeView(
                generalSize: viewModel.scanResult.totalSize,
                xcodeSize: viewModel.scanResult.xcodeTotalSize,
                devSize: viewModel.scanResult.developmentTotalSize,
                grandTotal: viewModel.scanResult.grandTotalSize,
                isScanning: viewModel.isScanning,
                scanningText: viewModel.scanningProgress
            )
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                StatBadgeView(
                    icon: "folder.fill",
                    title: String(localized: "category.general", defaultValue: "Общие кэши"),
                    size: viewModel.scanResult.totalSize,
                    gradient: AppTheme.Gradient.general,
                    color: AppTheme.Category.general
                )
                StatBadgeView(
                    icon: "hammer.fill",
                    title: "Xcode",
                    size: viewModel.scanResult.xcodeTotalSize,
                    gradient: AppTheme.Gradient.xcode,
                    color: AppTheme.Category.xcode
                )
                StatBadgeView(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: String(localized: "category.dev", defaultValue: "Разработка"),
                    size: viewModel.scanResult.developmentTotalSize,
                    gradient: AppTheme.Gradient.development,
                    color: AppTheme.Category.development
                )
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
    
    private var actionButtons: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMultiSelectMode.toggle()
                    if !isMultiSelectMode {
                        viewModel.selectedCacheInfos.removeAll()
                        viewModel.selectedDerivedDataProjects.removeAll()
                        viewModel.selectediOSDevices.removeAll()
                        viewModel.selectedArchives.removeAll()
                    }
                }
            } label: {
                Image(systemName: isMultiSelectMode ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 16))
            }
            .buttonStyle(.bordered)
            .tint(isMultiSelectMode ? AppTheme.Category.general : nil)
            .disabled(viewModel.isScanning || viewModel.isCleaning)
            .help(String(localized: "button.multiSelect", defaultValue: "Выбрать несколько"))
            
            if isMultiSelectMode && viewModel.hasAnySelection {
                Button {
                    Task { await viewModel.cleanSelected() }
                } label: {
                    Label(
                        String(localized: "button.deleteSelected", defaultValue: "Удалить"),
                        systemImage: "trash.fill"
                    )
                    .font(.system(size: 13))
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.Category.destructive)
                .transition(.scale.combined(with: .opacity))
            }
            
            Button {
                Task { await viewModel.scanCaches() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isScanning || viewModel.isCleaning)
            .help(String(localized: "button.scan", defaultValue: "Сканировать"))
        }
    }
}

// MARK: - General Caches Card

struct GeneralCachesCard: View {
    @ObservedObject var viewModel: CacheViewModel
    let isMultiSelectMode: Bool
    
    private var hasData: Bool {
        !viewModel.scanResult.topCaches.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                icon: "folder.fill",
                title: String(localized: "section.topCaches", defaultValue: "Топ кэшей"),
                subtitle: String(localized: "section.topCaches.subtitle", defaultValue: "Самые большие папки в ~/Library/Caches"),
                size: viewModel.scanResult.totalSize,
                color: AppTheme.Category.general
            )
            
            if hasData {
                cacheList
            } else {
                Text(String(localized: "section.topCaches.empty", defaultValue: "Кэши не найдены"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppTheme.Spacing.md)
            }
        }
        .glassCard(accent: AppTheme.Category.general)
    }
    
    private var cacheList: some View {
        let topCaches = viewModel.scanResult.topCaches
        let maxSize = SizeHelper.maxSizeBytes(topCaches.map(\.size))
        
        return ForEach(Array(topCaches.enumerated()), id: \.element.id) { index, cache in
            VStack(spacing: 0) {
                CacheItemRow.fromCache(
                    cache,
                    sizeBytes: SizeHelper.parseSizeToBytes(cache.size),
                    maxSizeBytes: maxSize,
                    accentColor: AppTheme.Category.general,
                    isMultiSelectMode: isMultiSelectMode,
                    isSelected: viewModel.selectedCacheInfos.contains(cache.id),
                    isDisabled: viewModel.isCleaning,
                    onToggleSelection: { toggleSelection(cache.id, in: &viewModel.selectedCacheInfos) },
                    onDelete: {
                        viewModel.selectedCache = cache
                        viewModel.showingConfirmation = true
                    }
                )
                
                if index < topCaches.count - 1 {
                    Divider().padding(.horizontal, AppTheme.Spacing.sm)
                }
            }
        }
    }
}

// MARK: - Xcode Caches Card

struct XcodeCachesCard: View {
    @ObservedObject var viewModel: CacheViewModel
    let isMultiSelectMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                icon: "hammer.fill",
                title: String(localized: "section.xcode", defaultValue: "Xcode"),
                subtitle: String(localized: "section.xcode.subtitle", defaultValue: "DerivedData, архивы, симуляторы"),
                size: viewModel.scanResult.xcodeTotalSize,
                color: AppTheme.Category.xcode
            )
            
            derivedDataSection
            deviceSupportSection
            archivesSection
            simpleItemsSection
        }
        .glassCard(accent: AppTheme.Category.xcode)
    }
    
    @ViewBuilder
    private var derivedDataSection: some View {
        if let derivedData = viewModel.scanResult.xcodeCaches.derivedData {
            let projects = viewModel.scanResult.xcodeCaches.derivedDataProjects
            Divider().padding(.horizontal, AppTheme.Spacing.sm)
            
            if !projects.isEmpty {
                DisclosureGroup {
                    derivedDataProjectsList(projects)
                } label: {
                    XcodeItemLabel(
                        cache: derivedData,
                        description: String(localized: "xcode.derivedData", defaultValue: "кэш сборки"),
                        isMultiSelectMode: isMultiSelectMode,
                        isSelected: viewModel.selectedCacheInfos.contains(derivedData.id),
                        isCleaning: viewModel.isCleaning,
                        onToggleSelection: { toggleSelection(derivedData.id, in: &viewModel.selectedCacheInfos) },
                        onDelete: { showClean(derivedData) }
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
            } else {
                CacheItemRow.fromCache(
                    derivedData,
                    description: String(localized: "xcode.derivedData", defaultValue: "кэш сборки"),
                    accentColor: AppTheme.Category.xcode,
                    isMultiSelectMode: isMultiSelectMode,
                    isSelected: viewModel.selectedCacheInfos.contains(derivedData.id),
                    isDisabled: viewModel.isCleaning,
                    onToggleSelection: { toggleSelection(derivedData.id, in: &viewModel.selectedCacheInfos) },
                    onDelete: { showClean(derivedData) }
                )
            }
        }
    }
    
    private func derivedDataProjectsList(_ projects: [DerivedDataProjectInfo]) -> some View {
        let maxSize = SizeHelper.maxSizeBytes(projects.map(\.size))
        return VStack(spacing: 0) {
            ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                CacheItemRow.fromProject(
                    project,
                    sizeBytes: SizeHelper.parseSizeToBytes(project.size),
                    maxSizeBytes: maxSize,
                    accentColor: AppTheme.Category.xcode,
                    isMultiSelectMode: isMultiSelectMode,
                    isSelected: viewModel.selectedDerivedDataProjects.contains(project.id),
                    isDisabled: viewModel.isCleaning,
                    onToggleSelection: { toggleSelection(project.id, in: &viewModel.selectedDerivedDataProjects) },
                    onDelete: {
                        viewModel.selectedDerivedDataProject = project
                        viewModel.showingDerivedDataConfirmation = true
                    }
                )
                if index < projects.count - 1 {
                    Divider().padding(.horizontal, AppTheme.Spacing.sm)
                }
            }
        }
        .padding(.top, AppTheme.Spacing.xs)
    }
    
    @ViewBuilder
    private var deviceSupportSection: some View {
        if let deviceSupport = viewModel.scanResult.xcodeCaches.deviceSupport {
            let devices = viewModel.scanResult.xcodeCaches.iosDevices
            Divider().padding(.horizontal, AppTheme.Spacing.sm)
            
            if !devices.isEmpty {
                DisclosureGroup {
                    devicesList(devices)
                } label: {
                    XcodeItemLabel(
                        cache: deviceSupport,
                        description: String(localized: "xcode.deviceSupport", defaultValue: "символы отладки"),
                        isMultiSelectMode: isMultiSelectMode,
                        isSelected: viewModel.selectedCacheInfos.contains(deviceSupport.id),
                        isCleaning: viewModel.isCleaning,
                        onToggleSelection: { toggleSelection(deviceSupport.id, in: &viewModel.selectedCacheInfos) },
                        onDelete: { showClean(deviceSupport) }
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
            } else {
                CacheItemRow.fromCache(
                    deviceSupport,
                    description: String(localized: "xcode.deviceSupport", defaultValue: "символы отладки"),
                    accentColor: AppTheme.Category.xcode,
                    isMultiSelectMode: isMultiSelectMode,
                    isSelected: viewModel.selectedCacheInfos.contains(deviceSupport.id),
                    isDisabled: viewModel.isCleaning,
                    onToggleSelection: { toggleSelection(deviceSupport.id, in: &viewModel.selectedCacheInfos) },
                    onDelete: { showClean(deviceSupport) }
                )
            }
        }
    }
    
    private func devicesList(_ devices: [iOSDeviceInfo]) -> some View {
        let maxSize = SizeHelper.maxSizeBytes(devices.map(\.size))
        return VStack(spacing: 0) {
            ForEach(Array(devices.enumerated()), id: \.element.id) { index, device in
                CacheItemRow.fromDevice(
                    device,
                    sizeBytes: SizeHelper.parseSizeToBytes(device.size),
                    maxSizeBytes: maxSize,
                    accentColor: AppTheme.Category.xcode,
                    isMultiSelectMode: isMultiSelectMode,
                    isSelected: viewModel.selectediOSDevices.contains(device.id),
                    isDisabled: viewModel.isCleaning,
                    onToggleSelection: { toggleSelection(device.id, in: &viewModel.selectediOSDevices) },
                    onDelete: {
                        viewModel.selectedDevice = device
                        viewModel.showingDeviceConfirmation = true
                    }
                )
                if index < devices.count - 1 {
                    Divider().padding(.horizontal, AppTheme.Spacing.sm)
                }
            }
        }
        .padding(.top, AppTheme.Spacing.xs)
    }
    
    @ViewBuilder
    private var archivesSection: some View {
        if let archives = viewModel.scanResult.xcodeCaches.archives {
            let archiveList = viewModel.scanResult.xcodeCaches.archiveList
            Divider().padding(.horizontal, AppTheme.Spacing.sm)
            
            if !archiveList.isEmpty {
                DisclosureGroup {
                    archivesList(archiveList)
                } label: {
                    XcodeItemLabel(
                        cache: archives,
                        description: String(localized: "xcode.archives", defaultValue: "архивы приложений"),
                        isMultiSelectMode: isMultiSelectMode,
                        isSelected: viewModel.selectedCacheInfos.contains(archives.id),
                        isCleaning: viewModel.isCleaning,
                        onToggleSelection: { toggleSelection(archives.id, in: &viewModel.selectedCacheInfos) },
                        onDelete: { showClean(archives) }
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
            } else {
                CacheItemRow.fromCache(
                    archives,
                    description: String(localized: "xcode.archives", defaultValue: "архивы приложений"),
                    accentColor: AppTheme.Category.xcode,
                    isMultiSelectMode: isMultiSelectMode,
                    isSelected: viewModel.selectedCacheInfos.contains(archives.id),
                    isDisabled: viewModel.isCleaning,
                    onToggleSelection: { toggleSelection(archives.id, in: &viewModel.selectedCacheInfos) },
                    onDelete: { showClean(archives) }
                )
            }
        }
    }
    
    private func archivesList(_ archives: [ArchiveInfo]) -> some View {
        let maxSize = SizeHelper.maxSizeBytes(archives.map(\.size))
        return VStack(spacing: 0) {
            ForEach(Array(archives.enumerated()), id: \.element.id) { index, archive in
                CacheItemRow.fromArchive(
                    archive,
                    sizeBytes: SizeHelper.parseSizeToBytes(archive.size),
                    maxSizeBytes: maxSize,
                    accentColor: AppTheme.Category.xcode,
                    isMultiSelectMode: isMultiSelectMode,
                    isSelected: viewModel.selectedArchives.contains(archive.id),
                    isDisabled: viewModel.isCleaning,
                    onToggleSelection: { toggleSelection(archive.id, in: &viewModel.selectedArchives) },
                    onDelete: {
                        viewModel.selectedArchive = archive
                        viewModel.showingArchiveConfirmation = true
                    }
                )
                if index < archives.count - 1 {
                    Divider().padding(.horizontal, AppTheme.Spacing.sm)
                }
            }
        }
        .padding(.top, AppTheme.Spacing.xs)
    }
    
    @ViewBuilder
    private var simpleItemsSection: some View {
        let xc = viewModel.scanResult.xcodeCaches
        
        simpleXcodeItem(xc.simulator, String(localized: "xcode.simulator", defaultValue: "кэши симуляторов"))
        simpleXcodeItem(xc.developerDiskImages, String(localized: "xcode.diskImages", defaultValue: "образы для разработки"))
        simpleXcodeItem(xc.xcpgDevices, String(localized: "xcode.xcpgDevices", defaultValue: "данные устройств"))
        simpleXcodeItem(xc.dvtDownloads, String(localized: "xcode.dvtDownloads", defaultValue: "загрузки и инструменты"))
        simpleXcodeItem(xc.xcTestDevices, String(localized: "xcode.testDevices", defaultValue: "данные тестирования"))
    }
    
    @ViewBuilder
    private func simpleXcodeItem(_ cache: CacheInfo?, _ description: String) -> some View {
        if let cache {
            Divider().padding(.horizontal, AppTheme.Spacing.sm)
            CacheItemRow.fromCache(
                cache,
                description: description,
                accentColor: AppTheme.Category.xcode,
                isMultiSelectMode: isMultiSelectMode,
                isSelected: viewModel.selectedCacheInfos.contains(cache.id),
                isDisabled: viewModel.isCleaning,
                onToggleSelection: { toggleSelection(cache.id, in: &viewModel.selectedCacheInfos) },
                onDelete: { showClean(cache) }
            )
        }
    }
    
    private func showClean(_ cache: CacheInfo) {
        viewModel.selectedCache = cache
        viewModel.showingConfirmation = true
    }
}

// MARK: - Xcode Item Label (for DisclosureGroup)

struct XcodeItemLabel: View {
    let cache: CacheInfo
    let description: String
    let isMultiSelectMode: Bool
    let isSelected: Bool
    let isCleaning: Bool
    let onToggleSelection: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            if isMultiSelectMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? AppTheme.Category.xcode : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(cache.displayName)
                    .font(.system(.body, weight: .medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(cache.size)
                .font(.system(.callout, design: .monospaced, weight: .medium))
                .foregroundStyle(AppTheme.Category.xcode)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(isCleaning ? Color.gray.opacity(0.4) : AppTheme.Category.destructive)
            }
            .buttonStyle(.plain)
            .disabled(isCleaning)
        }
    }
}

// MARK: - Development Caches Card

struct DevelopmentCachesCard: View {
    @ObservedObject var viewModel: CacheViewModel
    let isMultiSelectMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                icon: "chevron.left.forwardslash.chevron.right",
                title: String(localized: "section.dev", defaultValue: "Разработка"),
                subtitle: String(localized: "section.dev.subtitle", defaultValue: "Flutter, Gradle, npm, .cache"),
                size: viewModel.scanResult.developmentTotalSize,
                color: AppTheme.Category.development
            )
            
            devItem(viewModel.scanResult.developmentCaches.pubCache, String(localized: "dev.flutter", defaultValue: "пакеты Dart/Flutter"))
            devItem(viewModel.scanResult.developmentCaches.gradleCache, String(localized: "dev.gradle", defaultValue: "кэш сборки Android"))
            devItem(viewModel.scanResult.developmentCaches.npmCache, String(localized: "dev.npm", defaultValue: "кэш Node.js пакетов"))
            devItem(viewModel.scanResult.developmentCaches.homeCache, String(localized: "dev.homeCache", defaultValue: "системный кэш"))
        }
        .glassCard(accent: AppTheme.Category.development)
    }
    
    @ViewBuilder
    private func devItem(_ cache: CacheInfo?, _ description: String) -> some View {
        if let cache {
            Divider().padding(.horizontal, AppTheme.Spacing.sm)
            CacheItemRow.fromCache(
                cache,
                description: description,
                accentColor: AppTheme.Category.development,
                isMultiSelectMode: isMultiSelectMode,
                isSelected: viewModel.selectedCacheInfos.contains(cache.id),
                isDisabled: viewModel.isCleaning,
                onToggleSelection: { toggleSelection(cache.id, in: &viewModel.selectedCacheInfos) },
                onDelete: {
                    viewModel.selectedCache = cache
                    viewModel.showingConfirmation = true
                }
            )
        }
    }
}

// MARK: - Quick Scan Banner

struct QuickScanBanner: View {
    @ObservedObject var viewModel: CacheViewModel
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.Category.general)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "quickScan.title", defaultValue: "Быстрое сканирование"))
                    .font(.system(.subheadline, weight: .medium))
                Text(String(localized: "quickScan.subtitle", defaultValue: "Запустите полное сканирование для детальной информации о проектах и архивах"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(String(localized: "quickScan.button", defaultValue: "Полное сканирование")) {
                Task { await viewModel.scanCaches(quick: false) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(viewModel.isScanning || viewModel.isCleaning)
        }
        .glassCard(accent: AppTheme.Category.general, showBar: false)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let size: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.gradient.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(size)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
        }
        .padding(.bottom, AppTheme.Spacing.sm)
    }
}

// MARK: - Helpers

/// Toggle a UUID in a Set
func toggleSelection(_ id: UUID, in set: inout Set<UUID>) {
    if set.contains(id) {
        set.remove(id)
    } else {
        set.insert(id)
    }
}

// SizeHelper is defined in Theme/SizeHelper.swift

#Preview {
    ContentView()
}
