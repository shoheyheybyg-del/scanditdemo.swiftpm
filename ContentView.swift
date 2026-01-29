import SwiftUI

struct ContentView: View {
    @State private var scannedResults: [ScannedItem] = []
    @State private var showScanner = false
    @State private var scannedCode: String?

    var body: some View {
        NavigationView {
            VStack {
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

                Button(action: {
                    showScanner = true
                }) {
                    Label("スキャン", systemImage: "barcode.viewfinder")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Scandit Demo")
            .sheet(isPresented: $showScanner) {
                ScannerView(scannedCode: $scannedCode, isPresented: $showScanner)
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
            .onChange(of: scannedCode) { newValue in
                if let code = newValue {
                    let item = ScannedItem(barcode: code)
                    scannedResults.append(item)
                    scannedCode = nil
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func deleteItems(at offsets: IndexSet) {
        scannedResults.remove(atOffsets: offsets)
    }
}
