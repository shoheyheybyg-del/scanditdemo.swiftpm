import SwiftUI

struct ContentView: View {
    @State private var scannedResults: [ScannedItem] = []
    @State private var showScanner = false
    @State private var scannedCodes: [String] = []
    @State private var selectedMode: ScanMode = .single

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode selector
                VStack(spacing: 8) {
                    Picker("スキャンモード", selection: $selectedMode) {
                        ForEach(ScanMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    Text(selectedMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                Text("バーコード: \(item.barcode)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(item.scannedAt, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }

                // Scan button
                Button(action: {
                    scannedCodes = []
                    showScanner = true
                }) {
                    HStack {
                        Image(systemName: selectedMode.iconName)
                        Text(selectedMode == .single ? "スキャン" : "複数スキャン開始")
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
            .sheet(isPresented: $showScanner, onDismiss: processScannedCodes) {
                ScannerView(
                    scanMode: selectedMode,
                    scannedCodes: $scannedCodes,
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

    private func processScannedCodes() {
        for code in scannedCodes {
            let item = ScannedItem(barcode: code)
            scannedResults.append(item)
        }
        scannedCodes = []
    }

    private func deleteItems(at offsets: IndexSet) {
        scannedResults.remove(atOffsets: offsets)
    }
}
