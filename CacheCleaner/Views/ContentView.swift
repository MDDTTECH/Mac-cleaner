import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CacheViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            
            if viewModel.isScanning {
                ProgressView("Сканирование...")
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        totalSizeSection
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
            .disabled(viewModel.isScanning)
        }
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
    
    private var topCachesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Топ 10 самых больших кэшей")
                .font(.headline)
            
            ForEach(viewModel.scanResult.topCaches) { cache in
                CacheRowView(cache: cache) {
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
            
            if let derivedData = viewModel.scanResult.xcodeCaches.derivedData {
                CacheRowView(cache: derivedData, description: "DerivedData - кэш сборки") {
                    viewModel.selectedCache = derivedData
                    viewModel.showingConfirmation = true
                }
            }
            
            if let deviceSupport = viewModel.scanResult.xcodeCaches.deviceSupport {
                CacheRowView(cache: deviceSupport, description: "iOS Device Support - символы отладки") {
                    viewModel.selectedCache = deviceSupport
                    viewModel.showingConfirmation = true
                }
            }
            
            if let archives = viewModel.scanResult.xcodeCaches.archives {
                CacheRowView(cache: archives, description: "Archives - архивы приложений") {
                    viewModel.selectedCache = archives
                    viewModel.showingConfirmation = true
                }
            }
            
            if let simulator = viewModel.scanResult.xcodeCaches.simulator {
                CacheRowView(cache: simulator, description: "CoreSimulator - кэши симулятора") {
                    viewModel.selectedCache = simulator
                    viewModel.showingConfirmation = true
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CacheRowView: View {
    let cache: CacheInfo
    let description: String?
    let onClean: () -> Void
    
    init(cache: CacheInfo, description: String? = nil, onClean: @escaping () -> Void) {
        self.cache = cache
        self.description = description
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
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
} 