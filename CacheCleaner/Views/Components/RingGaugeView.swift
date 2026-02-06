import SwiftUI

/// Ring gauge split into 3 colored segments representing cache categories:
/// - Blue: General Caches (~Library/Caches)
/// - Orange: Xcode (DerivedData, archives, simulators)
/// - Green: Development (Flutter, Gradle, npm, .cache)
///
/// Each segment's arc is proportional to its share of the total.
/// Center shows the grand total size.
struct RingGaugeView: View {
    let generalSize: String
    let xcodeSize: String
    let devSize: String
    let grandTotal: String
    let isScanning: Bool
    let scanningText: String
    
    @State private var animatedFractions: [Double] = [0, 0, 0]
    @State private var rotationAngle: Double = 0
    
    private let gaugeSize = AppTheme.Gauge.size
    private let lineWidth = AppTheme.Gauge.lineWidth
    
    private var segments: [(fraction: Double, color: Color)] {
        let generalBytes = SizeHelper.parseSizeToBytes(generalSize)
        let xcodeBytes = SizeHelper.parseSizeToBytes(xcodeSize)
        let devBytes = SizeHelper.parseSizeToBytes(devSize)
        let total = generalBytes + xcodeBytes + devBytes
        
        guard total > 0 else { return [] }
        
        return [
            (generalBytes / total, AppTheme.Category.general),
            (xcodeBytes / total, AppTheme.Category.xcode),
            (devBytes / total, AppTheme.Category.development),
        ].filter { $0.fraction > 0 }
    }
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: lineWidth)
                .frame(width: gaugeSize, height: gaugeSize)
            
            if isScanning {
                scanningRing
            } else {
                segmentedRing
            }
            
            centerContent
        }
        .onChange(of: generalSize) { _, _ in animateSegments() }
        .onChange(of: xcodeSize) { _, _ in animateSegments() }
        .onChange(of: devSize) { _, _ in animateSegments() }
        .onAppear { animateSegments() }
    }
    
    // MARK: - Segmented Ring
    
    @ViewBuilder
    private var segmentedRing: some View {
        let segs = segments
        let gap: Double = segs.count > 1 ? 0.006 : 0 // small gap between segments
        
        ForEach(Array(segs.enumerated()), id: \.offset) { index, seg in
            let startFraction = startFraction(for: index, segments: segs, gap: gap)
            let endFraction = startFraction + animatedFractions[safe: index, default: 0] - (segs.count > 1 ? gap : 0)
            
            Circle()
                .trim(from: max(startFraction, 0), to: max(endFraction, startFraction))
                .stroke(
                    seg.color.gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: gaugeSize, height: gaugeSize)
                .rotationEffect(.degrees(-90))
        }
    }
    
    private func startFraction(for index: Int, segments: [(fraction: Double, color: Color)], gap: Double) -> Double {
        var start: Double = 0
        for i in 0..<index {
            start += animatedFractions[safe: i, default: 0]
        }
        return start
    }
    
    private func animateSegments() {
        let segs = segments
        let targets = (0..<3).map { i in
            i < segs.count ? segs[i].fraction : 0
        }
        withAnimation(.easeInOut(duration: 1.0)) {
            animatedFractions = targets
        }
    }
    
    // MARK: - Scanning Ring
    
    @ViewBuilder
    private var scanningRing: some View {
        Circle()
            .trim(from: 0, to: 0.3)
            .stroke(
                AppTheme.Gradient.general,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: gaugeSize, height: gaugeSize)
            .rotationEffect(.degrees(rotationAngle))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    rotationAngle = 360
                }
            }
            .onDisappear {
                rotationAngle = 0
            }
    }
    
    // MARK: - Center Content
    
    @ViewBuilder
    private var centerContent: some View {
        VStack(spacing: 2) {
            if isScanning {
                Text(scanningText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: gaugeSize - 40)
            } else {
                Text(grandTotal)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                
                Text(String(localized: "gauge.subtitle", defaultValue: "можно освободить"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Safe Array Index

private extension Array {
    subscript(safe index: Int, default defaultValue: Element) -> Element {
        indices.contains(index) ? self[index] : defaultValue
    }
}

#Preview {
    VStack(spacing: 30) {
        RingGaugeView(
            generalSize: "3.0G",
            xcodeSize: "16.15 GB",
            devSize: "15.67 GB",
            grandTotal: "34.82 GB",
            isScanning: false,
            scanningText: ""
        )
        RingGaugeView(
            generalSize: "0B",
            xcodeSize: "0B",
            devSize: "0B",
            grandTotal: "0 B",
            isScanning: true,
            scanningText: "Сканирование..."
        )
    }
    .padding(40)
}
