import SwiftUI

@available(iOS 26.0, *)
struct ContentView: View {
    @State private var checker = ConsistencyChecker()
    @State private var showFileImporter = false
    @State private var showScanner = false
    
    var body: some View {
        NavigationStack {
            Group {
                switch checker.state {
                case .idle:
                    HomeView(
                        checker: checker,
                        showFileImporter: $showFileImporter,
                        showScanner: $showScanner
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
                            ShareLink(item: fileURL, preview: SharePreview("Context Guard Report", image: Image(systemName: "doc.text")))
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.plainText, .pdf],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                checker.importFiles(from: urls)
            }
        }
    }
    
    private var startOverButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Start Over") {
                withAnimation { checker.clear() }
            }
            .tint(.blue)
        }
    }
}

@available(iOS 26.0, *)
#Preview("Content View — Idle") {
    ContentView()
}
