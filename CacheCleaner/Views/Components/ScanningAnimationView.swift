import SwiftUI

/// Custom pulsing concentric rings animation for the scanning state.
struct ScanningAnimationView: View {
    let progressText: String
    
    @State private var pulse1: CGFloat = 0.6
    @State private var pulse2: CGFloat = 0.4
    @State private var pulse3: CGFloat = 0.2
    @State private var opacity1: Double = 0.3
    @State private var opacity2: Double = 0.2
    @State private var opacity3: Double = 0.1
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(AppTheme.Category.general.opacity(opacity3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulse3)
                
                // Middle ring
                Circle()
                    .stroke(AppTheme.Category.general.opacity(opacity2), lineWidth: 2)
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulse2)
                
                // Inner ring
                Circle()
                    .stroke(AppTheme.Category.general.opacity(opacity1), lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulse1)
                
                // Center icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppTheme.Category.general)
            }
            .frame(width: 140, height: 140)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulse1 = 1.1
                    pulse2 = 1.2
                    pulse3 = 1.3
                    opacity1 = 0.6
                    opacity2 = 0.4
                    opacity3 = 0.2
                }
            }
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(String(localized: "scanning.title", defaultValue: "Сканирование"))
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                
                Text(progressText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Cleaning progress view with animated checkmark on completion.
struct CleaningProgressView: View {
    let cacheName: String
    let progressText: String
    
    @State private var ringProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 6)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        AppTheme.Category.destructive.gradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: "trash.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.Category.destructive)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    ringProgress = 1.0
                }
            }
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(String(localized: "cleaning.title", defaultValue: "Очистка"))
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                
                if !cacheName.isEmpty {
                    Text(cacheName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Scanning") {
    ScanningAnimationView(progressText: "Сканирование общих кэшей...")
        .frame(width: 400, height: 400)
}

#Preview("Cleaning") {
    CleaningProgressView(cacheName: "DerivedData", progressText: "Удаляем файлы...")
        .frame(width: 400, height: 400)
}
