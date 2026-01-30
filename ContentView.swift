import SwiftUI

struct ContentView: View {
    @State private var scannedResults: [ScannedItem] = []
    @State private var showScanner = false
    @State private var scanResults: [ScanResult] = []
    @State private var selectedMode: ScanMode = .single
    @State private var textRecognitionEnabled = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Settings section
                VStack(spacing: 12) {
                    // Mode selector
                    Picker("スキャンモード", selection: $selectedMode) {
                        ForEach(ScanMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(selectedMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Text recognition toggle
                    Toggle(isOn: $textRecognitionEnabled) {
                        HStack {
                            Image(systemName: "text.viewfinder")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("テキスト認識")
                                    .font(.subheadline)
                                Text("賞味期限などを読み取り")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))

                // Results list
                if scannedResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("スキャン結果なし")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("下のボタンをタップしてバーコードをスキャンしてください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(scannedResults) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                // Barcode info
                                HStack {
                                    Image(systemName: "barcode")
                                        .foregroundColor(.blue)
                                    Text(item.barcode)
                                        .font(.headline)
                                        .fontDesign(.monospaced)
                                }

                                // Expiration date if found
                                if let expDate = item.expirationDate {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.orange)
                                        Text(expDate)
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                    }
                                }

                                // Other recognized texts
                                if !item.recognizedTexts.isEmpty {
                                    DisclosureGroup {
                                        ForEach(item.recognizedTexts, id: \.self) { text in
                                            Text(text)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "text.alignleft")
                                                .foregroundColor(.gray)
                                            Text("認識テキスト (\(item.recognizedTexts.count)件)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }

                                // Scan time
                                Text(item.scannedAt, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }

                // Scan button
                Button(action: {
                    scanResults = []
                    showScanner = true
                }) {
                    HStack {
                        Image(systemName: selectedMode.iconName)
                        Text(selectedMode == .single ? "スキャン" : "複数スキャン開始")
                        if textRecognitionEnabled {
                            Text("+ OCR")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.3))
                                .cornerRadius(4)
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedMode == .single ? Color.blue : Color.green)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Scandit Demo")
            .sheet(isPresented: $showScanner, onDismiss: processScanResults) {
                ScannerView(
                    scanMode: selectedMode,
                    textRecognitionEnabled: textRecognitionEnabled,
                    scannedResults: $scanResults,
                    isPresented: $showScanner
                )
                .ignoresSafeArea()
            }
            .toolbar {
                if !scannedResults.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("クリア") {
                            scannedResults.removeAll()
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func processScanResults() {
        for result in scanResults {
            let item = ScannedItem(
                barcode: result.barcode,
                recognizedTexts: result.recognizedTexts
            )
            scannedResults.append(item)
        }
        scanResults = []
    }

    private func deleteItems(at offsets: IndexSet) {
        scannedResults.remove(atOffsets: offsets)
    }
}
