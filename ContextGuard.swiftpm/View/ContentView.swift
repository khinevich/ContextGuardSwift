import SwiftUI

@available(iOS 26.0, *)
struct ContentView: View {
    @State private var checker = ConsistencyChecker()
    @State private var showFileImporter = false
    @State private var showScanner = false
    @State private var showDemo = false

    /// Shown when user picks more files than remaining slots
    @State private var droppedFilesCount = 0
    @State private var showDroppedAlert = false

    var body: some View {
        NavigationStack {
            Group {
                switch checker.state {
                case .idle:
                    HomeView(
                        checker: checker,
                        showFileImporter: $showFileImporter,
                        showScanner: $showScanner,
                        showDemo: $showDemo
                    )
                case .analyzing:
                    AnalyzingView(documents: checker.documents)
                case .completed:
                    ResultsView(checker: checker)
                case .failed(let message):
                    ErrorView(message: message) {
                        withAnimation { checker.clear() }
                    }
                }
            }
            .navigationTitle(checker.state == .idle ? "" : "Context Guard")
            .toolbar(checker.state == .idle ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                if checker.state != .idle && checker.state != .analyzing {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Start Over") {
                            withAnimation { checker.clear() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if let fileURL = checker.exportToFile() {
                            ShareLink(
                                item: fileURL,
                                preview: SharePreview("Context Guard Report", image: Image(systemName: "doc.text"))
                            )
                        }
                    }
                }
            }
        }
        // MARK: - File Importer
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.plainText, .pdf],
            allowsMultipleSelection: checker.remainingSlots > 1
        ) { result in
            switch result {
            case .success(let urls):
                let slots = checker.remainingSlots
                let accepted = Array(urls.prefix(slots))
                checker.importFiles(from: accepted)

                let dropped = urls.count - accepted.count
                if dropped > 0 {
                    droppedFilesCount = dropped
                    showDroppedAlert = true
                }
            case .failure:
                break
            }
        }
        // MARK: - Scanner
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView(
                onScan: { scannedText in
                    let doc = Document(
                        id: UUID(),
                        title: "Scanned Document",
                        content: scannedText
                    )
                    checker.addDocument(doc)
                    showScanner = false
                },
                onCancel: {
                    showScanner = false
                }
            )
        }
        // MARK: - Demo
        .fullScreenCover(isPresented: $showDemo) {
            DemoFlowView(checker: checker)
        }
        // MARK: - Dropped Files Alert
        .alert("File Limit", isPresented: $showDroppedAlert) {
            Button("OK") {}
        } message: {
            Text("\(droppedFilesCount) file\(droppedFilesCount == 1 ? " was" : "s were") not imported. The maximum is \(ConsistencyChecker.maxDocuments) documents total.")
        }
    }
}

@available(iOS 26.0, *)
#Preview("Content View") {
    ContentView()
}
