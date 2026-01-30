import Foundation

enum ScanMode: String, CaseIterable {
    case single = "シングル"
    case multiple = "複数"

    var description: String {
        switch self {
        case .single:
            return "1つのバーコードをスキャンして自動的に閉じます"
        case .multiple:
            return "複数のバーコードを連続でスキャンできます"
        }
    }

    var iconName: String {
        switch self {
        case .single:
            return "barcode"
        case .multiple:
            return "barcode.viewfinder"
        }
    }
}
