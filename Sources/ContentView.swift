import SwiftUI

struct ContentView: View {
    @State private var scannedResults: [ScanResult] = []
    @State private var isShowingScanner = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if scannedResults.isEmpty {
                    emptyStateView
                } else {
                    resultListView
                }

                scanButton
            }
            .navigationTitle("バーコードスキャナー")
            .sheet(isPresented: $isShowingScanner) {
                BarcodeScannerView { result in
                    scannedResults.insert(result, at: 0)
                    isShowingScanner = false
                }
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
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.6))

            Text("スキャン結果がありません")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("下のボタンをタップしてバーコードをスキャンしてください")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    private var resultListView: some View {
        List {
            ForEach(scannedResults) { result in
                ScanResultRow(result: result)
            }
            .onDelete { indexSet in
                scannedResults.remove(atOffsets: indexSet)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var scanButton: some View {
        Button(action: {
            isShowingScanner = true
        }) {
            HStack {
                Image(systemName: "barcode.viewfinder")
                Text("スキャン開始")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
