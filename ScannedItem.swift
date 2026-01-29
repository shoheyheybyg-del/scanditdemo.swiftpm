import Foundation

struct ScannedItem: Identifiable, Hashable {
    let id = UUID()
    let barcode: String
    let name: String
    let scannedAt: Date

    init(barcode: String, name: String = "") {
        self.barcode = barcode
        self.name = name.isEmpty ? "商品: \(barcode)" : name
        self.scannedAt = Date()
    }
}
