import SwiftUI

struct ContentView: View {
    @State private var scannedResults: [String] = []
    @State private var isShowingScanner: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                if scannedResults.isEmpty {
                    ContentUnavailableView(
                        "スキャン結果なし",
                        systemImage: "barcode.viewfinder",
                        description: Text("下のボタンをタップしてバーコードをスキャンしてください")
                    )
                } else {
                    List {
                        ForEach(scannedResults, id: \.self) { result in
                            HStack {
                                Image(systemName: "barcode")
                                    .foregroundStyle(.blue)
                                Text(result)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        .onDelete(perform: deleteResults)
                    }
                }
            }
            .navigationTitle("Scandit Demo")
            .sheet(isPresented: $isShowingScanner) {
                BarcodeScannerView { barcode in
                    scannedResults.append(barcode)
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

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        isShowingScanner = true
                    } label: {
                        Label("スキャン", systemImage: "barcode.viewfinder")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func deleteResults(at offsets: IndexSet) {
        scannedResults.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}
