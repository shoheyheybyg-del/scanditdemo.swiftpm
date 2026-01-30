import Foundation

struct ScannedItem: Identifiable, Hashable {
    let id = UUID()
    let barcode: String
    let name: String
    let recognizedTexts: [String]
    let scannedAt: Date

    init(barcode: String, name: String = "", recognizedTexts: [String] = []) {
        self.barcode = barcode
        self.name = name.isEmpty ? "商品: \(barcode)" : name
        self.recognizedTexts = recognizedTexts
        self.scannedAt = Date()
    }

    // Extract potential expiration dates from recognized text
    var expirationDate: String? {
        let patterns = [
            "賞味期限", "消費期限", "期限", "EXP", "exp", "BB", "BEST BEFORE"
        ]

        for text in recognizedTexts {
            for pattern in patterns {
                if text.contains(pattern) {
                    return text
                }
            }
            // Check for date-like patterns (e.g., 2024.01.15, 2024/01/15, 24.01.15)
            let datePattern = #"\d{2,4}[./\-]\d{1,2}[./\-]\d{1,2}"#
            if let _ = text.range(of: datePattern, options: .regularExpression) {
                return text
            }
        }
        return nil
    }
}
