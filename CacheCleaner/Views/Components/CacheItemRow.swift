import SwiftUI

/// Unified row view that replaces 8 separate row views.
/// Supports normal mode, selectable mode, size bar, hover highlight.
struct CacheItemRow: View {
    let title: String
    let subtitle: String?
    let size: String
    let sizeBytes: Double
    let maxSizeBytes: Double
    let accentColor: Color
    
    // Selection
    let isMultiSelectMode: Bool
    let isSelected: Bool
    let onToggleSelection: (() -> Void)?
    
    // Deletion
    let isDisabled: Bool
    let onDelete: () -> Void
    
    init(
        title: String,
        subtitle: String? = nil,
        size: String,
        sizeBytes: Double = 0,
        maxSizeBytes: Double = 0,
        accentColor: Color = .blue,
        isMultiSelectMode: Bool = false,
        isSelected: Bool = false,
        onToggleSelection: (() -> Void)? = nil,
        isDisabled: Bool = false,
        onDelete: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.size = size
        self.sizeBytes = sizeBytes
        self.maxSizeBytes = maxSizeBytes
        self.accentColor = accentColor
        self.isMultiSelectMode = isMultiSelectMode
        self.isSelected = isSelected
        self.onToggleSelection = onToggleSelection
        self.isDisabled = isDisabled
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Checkbox (multi-select mode)
            if isMultiSelectMode, let toggle = onToggleSelection {
                Button(action: toggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .default, weight: .medium))
                    .lineLimit(1)
                
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Size bar
                if maxSizeBytes > 0 {
                    SizeBarView(
                        value: sizeBytes,
                        maxValue: maxSizeBytes,
                        color: accentColor
                    )
                    .padding(.top, 2)
                }
            }
            
            Spacer(minLength: 8)
            
            // Size label
            Text(size)
                .font(.system(.callout, design: .monospaced, weight: .medium))
                .foregroundStyle(accentColor)
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(isDisabled ? Color.gray.opacity(0.4) : AppTheme.Category.destructive)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
        .hoverHighlight()
    }
}

// MARK: - Convenience Constructors

extension CacheItemRow {
    /// Create from CacheInfo model
    static func fromCache(
        _ cache: CacheInfo,
        description: String? = nil,
        sizeBytes: Double = 0,
        maxSizeBytes: Double = 0,
        accentColor: Color = .blue,
        isMultiSelectMode: Bool = false,
        isSelected: Bool = false,
        isDisabled: Bool = false,
        onToggleSelection: (() -> Void)? = nil,
        onDelete: @escaping () -> Void
    ) -> CacheItemRow {
        CacheItemRow(
            title: cache.displayName,
            subtitle: description,
            size: cache.size,
            sizeBytes: sizeBytes,
            maxSizeBytes: maxSizeBytes,
            accentColor: accentColor,
            isMultiSelectMode: isMultiSelectMode,
            isSelected: isSelected,
            onToggleSelection: onToggleSelection,
            isDisabled: isDisabled,
            onDelete: onDelete
        )
    }
    
    /// Create from DerivedDataProjectInfo
    static func fromProject(
        _ project: DerivedDataProjectInfo,
        sizeBytes: Double = 0,
        maxSizeBytes: Double = 0,
        accentColor: Color = .orange,
        isMultiSelectMode: Bool = false,
        isSelected: Bool = false,
        isDisabled: Bool = false,
        onToggleSelection: (() -> Void)? = nil,
        onDelete: @escaping () -> Void
    ) -> CacheItemRow {
        CacheItemRow(
            title: project.displayName,
            subtitle: project.detailedDescription,
            size: project.size,
            sizeBytes: sizeBytes,
            maxSizeBytes: maxSizeBytes,
            accentColor: accentColor,
            isMultiSelectMode: isMultiSelectMode,
            isSelected: isSelected,
            onToggleSelection: onToggleSelection,
            isDisabled: isDisabled,
            onDelete: onDelete
        )
    }
    
    /// Create from iOSDeviceInfo
    static func fromDevice(
        _ device: iOSDeviceInfo,
        sizeBytes: Double = 0,
        maxSizeBytes: Double = 0,
        accentColor: Color = .orange,
        isMultiSelectMode: Bool = false,
        isSelected: Bool = false,
        isDisabled: Bool = false,
        onToggleSelection: (() -> Void)? = nil,
        onDelete: @escaping () -> Void
    ) -> CacheItemRow {
        CacheItemRow(
            title: device.displayName,
            subtitle: device.detailedDescription,
            size: device.size,
            sizeBytes: sizeBytes,
            maxSizeBytes: maxSizeBytes,
            accentColor: accentColor,
            isMultiSelectMode: isMultiSelectMode,
            isSelected: isSelected,
            onToggleSelection: onToggleSelection,
            isDisabled: isDisabled,
            onDelete: onDelete
        )
    }
    
    /// Create from ArchiveInfo
    static func fromArchive(
        _ archive: ArchiveInfo,
        sizeBytes: Double = 0,
        maxSizeBytes: Double = 0,
        accentColor: Color = .orange,
        isMultiSelectMode: Bool = false,
        isSelected: Bool = false,
        isDisabled: Bool = false,
        onToggleSelection: (() -> Void)? = nil,
        onDelete: @escaping () -> Void
    ) -> CacheItemRow {
        CacheItemRow(
            title: archive.displayName,
            subtitle: archive.detailedDescription,
            size: archive.size,
            sizeBytes: sizeBytes,
            maxSizeBytes: maxSizeBytes,
            accentColor: accentColor,
            isMultiSelectMode: isMultiSelectMode,
            isSelected: isSelected,
            onToggleSelection: onToggleSelection,
            isDisabled: isDisabled,
            onDelete: onDelete
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        CacheItemRow(
            title: "org.swift.swiftpm",
            subtitle: nil,
            size: "3.1G",
            sizeBytes: 3.1,
            maxSizeBytes: 3.1,
            accentColor: .blue,
            onDelete: {}
        )
        CacheItemRow(
            title: "CocoaPods",
            subtitle: nil,
            size: "316M",
            sizeBytes: 0.316,
            maxSizeBytes: 3.1,
            accentColor: .blue,
            isMultiSelectMode: true,
            isSelected: true,
            onToggleSelection: {},
            onDelete: {}
        )
    }
    .padding()
    .frame(width: 500)
}
