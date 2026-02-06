import Foundation

/// Shared size parsing helpers used across views and models.
enum SizeHelper {
    static func parseSizeToBytes(_ sizeString: String) -> Double {
        let s = sizeString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Single-letter suffixes: "3.1G", "424M", "0B"
        if s.hasSuffix("T") && !s.hasSuffix("TB") {
            return (Double(String(s.dropLast())) ?? 0) * 1024 * 1024 * 1024 * 1024
        } else if s.hasSuffix("G") && !s.hasSuffix("GB") {
            return (Double(String(s.dropLast())) ?? 0) * 1024 * 1024 * 1024
        } else if s.hasSuffix("M") && !s.hasSuffix("MB") {
            return (Double(String(s.dropLast())) ?? 0) * 1024 * 1024
        } else if s.hasSuffix("K") && !s.hasSuffix("KB") {
            return (Double(String(s.dropLast())) ?? 0) * 1024
        } else if s.hasSuffix("B") && !s.hasSuffix("KB") && !s.hasSuffix("MB") && !s.hasSuffix("GB") && !s.hasSuffix("TB") {
            return Double(String(s.dropLast())) ?? 0
        }
        
        // Two-part formats: "18 GB", "462 MB", "13,16 GB" (localized)
        let parts = s.components(separatedBy: " ")
        if parts.count == 2 {
            // Handle comma as decimal separator (e.g. "13,16")
            let numStr = parts[0].replacingOccurrences(of: ",", with: ".")
            let num = Double(numStr) ?? 0
            switch parts[1].uppercased() {
            case "TB": return num * 1024 * 1024 * 1024 * 1024
            case "GB": return num * 1024 * 1024 * 1024
            case "MB": return num * 1024 * 1024
            case "KB": return num * 1024
            case "BYTES", "B": return num
            default: return 0
            }
        }
        return 0
    }
    
    static func maxSizeBytes(_ sizes: [String]) -> Double {
        sizes.map { parseSizeToBytes($0) }.max() ?? 0
    }
}
