import SwiftUI

// MARK: - Scan Result Model
struct ScanResult: Identifiable, Equatable {
    let id = UUID()
    let barcodeData: String
    let symbologyName: String
    let scannedAt: Date

    init(barcodeData: String, symbologyName: String, scannedAt: Date = Date()) {
        self.barcodeData = barcodeData
        self.symbologyName = symbologyName
        self.scannedAt = scannedAt
    }

    static func == (lhs: ScanResult, rhs: ScanResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Scan Result Row View
struct ScanResultRow: View {
    let result: ScanResult
    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: symbologyIcon)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                Text(result.symbologyName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)

                Spacer()

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(result.barcodeData)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(3)

            HStack {
                Button(action: copyToClipboard) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "コピー完了" : "コピー")
                    }
                    .font(.caption)
                    .foregroundColor(isCopied ? .green : .blue)
                }
                .buttonStyle(.plain)

                Spacer()

                if let url = URL(string: result.barcodeData), UIApplication.shared.canOpenURL(url) {
                    Button(action: { openURL(url) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "safari")
                            Text("開く")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }

    private var symbologyIcon: String {
        switch result.symbologyName.lowercased() {
        case let s where s.contains("qr"):
            return "qrcode"
        case let s where s.contains("datamatrix"):
            return "square.grid.3x3"
        case let s where s.contains("aztec"):
            return "square.grid.3x3.topleft.filled"
        case let s where s.contains("pdf417"):
            return "rectangle.split.3x3"
        default:
            return "barcode"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: result.scannedAt)
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = result.barcodeData
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }

    private func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview
#Preview {
    List {
        ScanResultRow(result: ScanResult(
            barcodeData: "4901234567890",
            symbologyName: "EAN-13"
        ))

        ScanResultRow(result: ScanResult(
            barcodeData: "https://www.example.com",
            symbologyName: "QR Code"
        ))

        ScanResultRow(result: ScanResult(
            barcodeData: "ABC-123456-XYZ",
            symbologyName: "Code 128"
        ))
    }
}
