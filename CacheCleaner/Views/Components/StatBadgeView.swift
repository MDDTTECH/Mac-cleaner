import SwiftUI

/// A small summary badge showing icon + category name + size.
struct StatBadgeView: View {
    let icon: String
    let title: String
    let size: String
    let gradient: LinearGradient
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text(size)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

#Preview {
    HStack {
        StatBadgeView(
            icon: "folder.fill",
            title: "Общие",
            size: "5.8 GB",
            gradient: AppTheme.Gradient.general,
            color: AppTheme.Category.general
        )
        StatBadgeView(
            icon: "hammer.fill",
            title: "Xcode",
            size: "18 GB",
            gradient: AppTheme.Gradient.xcode,
            color: AppTheme.Category.xcode
        )
        StatBadgeView(
            icon: "chevron.left.forwardslash.chevron.right",
            title: "Разработка",
            size: "2.1 GB",
            gradient: AppTheme.Gradient.development,
            color: AppTheme.Category.development
        )
    }
    .padding()
}
