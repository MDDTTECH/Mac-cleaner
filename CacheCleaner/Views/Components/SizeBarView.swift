import SwiftUI

/// Horizontal proportional size bar.
/// Width is proportional to `value / maxValue`.
struct SizeBarView: View {
    let value: Double
    let maxValue: Double
    let color: Color
    
    private var fraction: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.1))
                    .frame(height: 4)
                
                // Fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.gradient)
                    .frame(width: max(geo.size.width * fraction, fraction > 0 ? 4 : 0), height: 4)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    VStack(spacing: 12) {
        SizeBarView(value: 3.1, maxValue: 3.1, color: .blue)
        SizeBarView(value: 1.5, maxValue: 3.1, color: .blue)
        SizeBarView(value: 0.4, maxValue: 3.1, color: .orange)
        SizeBarView(value: 0, maxValue: 3.1, color: .green)
    }
    .padding()
    .frame(width: 300)
}
