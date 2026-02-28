//
//  SwiftUIView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import SwiftUI

@available(iOS 26.0, *)
struct HomeView: View {
    var checker: ConsistencyChecker
    @Binding var showFileImporter: Bool
    @Binding var showScanner: Bool
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    // MARK: - Local State
    
    /// Which document to show in the preview sheet. nil = no sheet.
    @State private var previewDocument: Document? = nil
    
    /// iPad only: toggles between list and grid layout for loaded documents.
    /// false = list (default), true = grid (icon view like Files app).
    @State private var useGridView: Bool = false
    
    private var layout: AppLayout {
        AppLayout.current(for: sizeClass)
    }
    
    private var isCompact: Bool { sizeClass == .compact }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: layout.sectionSpacing) {
                headerSection
                
                if !checker.documents.isEmpty {
                    loadedDocumentsSection
                }
                
                actionButtonsSection
                
                if !checker.documents.isEmpty {
                    runCheckButton
                }
                
                Divider()
                    .padding(.horizontal, layout.horizontalPadding)
                
                demoSection
            }
            .padding(.vertical, layout.sectionSpacing)
        }
        // Preview sheet — presented when previewDocument is set
        .sheet(item: $previewDocument) { doc in
            DocumentPreviewSheet(document: doc)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: layout.iconSize))
                .foregroundStyle(.blue)
            
            Text("Context Guard")
                .font(.largeTitle.bold())
            
            Text("Check your documents for contradictions\nusing on-device AI — fully offline, fully private.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, layout.horizontalPadding)
        }
    }
    
    // MARK: - Loaded Documents Section
    
    /// The entire loaded documents area: header with count + view toggle,
    /// then either a list or grid of document cards.
    private var loadedDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row: title, count, and iPad view toggle
            HStack {
                Text("Loaded Documents")
                    .font(.headline)
                
                Spacer()
                
                // "2 of 3" capacity label
                Text("\(checker.documents.count) of \(ConsistencyChecker.maxDocuments)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // iPad only: list/grid toggle
                // Using a Picker with .segmented style — two SF Symbol buttons.
                if !isCompact {
                    Picker("View", selection: $useGridView) {
                        Image(systemName: "list.bullet")
                            .tag(false)
                        Image(systemName: "square.grid.2x2")
                            .tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }
            }
            
            // Content: list or grid
            if useGridView && !isCompact {
                gridDocumentsView
            } else {
                listDocumentsView
            }
        }
        .padding(.horizontal, layout.horizontalPadding)
    }
    
    // MARK: - List View (all devices)
    
    /// List with swipe actions. `.swipeActions` only works inside a `List`,
    /// not in a plain VStack > ForEach. We use `.scrollDisabled(true)` so
    /// the List doesn't conflict with the outer ScrollView, and calculate
    /// a fixed frame height based on document count.
    private var listDocumentsView: some View {
        // Row height: ~60 on iPhone, ~92 on iPad (taller rows with thumbnails)
        let rowHeight: CGFloat = isCompact ? 60 : 92
        let listHeight = CGFloat(checker.documents.count) * rowHeight
        
        return List {
            ForEach(checker.documents, id: \.id) { doc in
                // Tap anywhere on the row → open preview sheet
                Button {
                    previewDocument = doc
                } label: {
                    DocumentRowView(document: doc)
                }
                .buttonStyle(.plain)
                // Left-swipe reveals two actions: Preview and Delete
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Delete button (rightmost, shown first)
                    Button(role: .destructive) {
                        withAnimation {
                            checker.removeDocument(id: doc.id)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    // Preview button (second from right)
                    Button {
                        previewDocument = doc
                    } label: {
                        Label("Preview", systemImage: "eye")
                    }
                    .tint(.blue)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollDisabled(true)               // Outer ScrollView handles scrolling
        .scrollContentBackground(.hidden)   // Remove default List background
        .frame(height: listHeight)
    }
    
    // MARK: - Grid View (iPad only)
    
    /// LazyVGrid with document page cards — mimics the Files app icon view.
    /// Long-press (context menu) provides Preview and Delete actions since
    /// grid items don't support swipe gestures.
    private var gridDocumentsView: some View {
        let columns = [
            GridItem(.adaptive(minimum: 140, maximum: 160), spacing: 20)
        ]
        
        return LazyVGrid(columns: columns, spacing: 20) {
            ForEach(checker.documents, id: \.id) { doc in
                DocumentGridItemView(document: doc)
                    // Tap → preview
                    .onTapGesture {
                        previewDocument = doc
                    }
                    // Long-press → context menu with Preview and Delete
                    .contextMenu {
                        Button {
                            previewDocument = doc
                        } label: {
                            Label("Preview", systemImage: "eye")
                        }
                        
                        Button(role: .destructive) {
                            withAnimation {
                                checker.removeDocument(id: doc.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        Group {
            if isCompact {
                VStack(spacing: layout.cardSpacing) {
                    actionCards
                }
            } else {
                HStack(spacing: layout.cardSpacing) {
                    actionCards
                }
            }
        }
        .padding(.horizontal, layout.horizontalPadding)
    }
    
    @ViewBuilder
    private var actionCards: some View {
        ActionCard(
            icon: "folder.badge.plus",
            title: "Select Files",
            subtitle: checker.canAddMore
                ? "Import .txt or .pdf"
                : "Limit reached (\(ConsistencyChecker.maxDocuments) docs)",
            color: checker.canAddMore ? .blue : .gray
        ) {
            if checker.canAddMore {
                showFileImporter = true
            }
        }
        .disabled(!checker.canAddMore)
        
        ActionCard(
            icon: "camera.viewfinder",
            title: "Scan Paper",
            subtitle: checker.canAddMore
                ? "Use iPad camera"
                : "Limit reached (\(ConsistencyChecker.maxDocuments) docs)",
            color: checker.canAddMore ? .green : .gray
        ) {
            if checker.canAddMore {
                showScanner = true
            }
        }
        .disabled(!checker.canAddMore)
    }
    
    // MARK: - Run Check
    
    private var runCheckButton: some View {
        Button {
            Task { await checker.runCheck() }
        } label: {
            Label("Check for Contradictions", systemImage: "sparkle.magnifyingglass")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .padding(.horizontal, layout.horizontalPadding)
    }
    
    // MARK: - Demo
    
    private var demoSection: some View {
        VStack(spacing: 12) {
            Text("First time? Try it out:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                checker.loadDemo()
                Task { await checker.runCheck() }
            } label: {
                Label("Run Demo with Sample Documents", systemImage: "play.fill")
                    .font(.subheadline.weight(.medium))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
    }
}

// MARK: - Previews

@available(iOS 26.0, *)
#Preview("Home — Empty") {
    @Previewable @State var showFiles = false
    @Previewable @State var showScanner = false
    let checker = ConsistencyChecker()
    
    NavigationStack {
        HomeView(checker: checker, showFileImporter: $showFiles, showScanner: $showScanner)
            .navigationTitle("Context Guard")
    }
}

@available(iOS 26.0, *)
#Preview("Home — With Documents") {
    @Previewable @State var showFiles = false
    @Previewable @State var showScanner = false
    let checker = ConsistencyChecker()
    
    NavigationStack {
        HomeView(checker: checker, showFileImporter: $showFiles, showScanner: $showScanner)
            .navigationTitle("Context Guard")
            .onAppear {
                checker.addDocument(Document(id: UUID(), title: "DocA_Penguins.txt", content: "Emperor penguins are native to Antarctica, where they endure harsh winters with temperatures dropping to minus 60 degrees Celsius. They breed during the Antarctic winter."))
                checker.addDocument(Document(id: UUID(), title: "DocB_Penguins.txt", content: "Emperor penguins are found in the Arctic region, where they coexist with polar bears. They prefer moderate temperatures around 5 degrees Celsius."))
            }
    }
}

@available(iOS 26.0, *)
#Preview("Home — At Capacity") {
    @Previewable @State var showFiles = false
    @Previewable @State var showScanner = false
    let checker = ConsistencyChecker()
    
    NavigationStack {
        HomeView(checker: checker, showFileImporter: $showFiles, showScanner: $showScanner)
            .navigationTitle("Context Guard")
            .onAppear {
                checker.addDocument(Document(id: UUID(), title: "DocA.txt", content: "First document content..."))
                checker.addDocument(Document(id: UUID(), title: "DocB.txt", content: "Second document content..."))
                checker.addDocument(Document(id: UUID(), title: "DocC.txt", content: "Third document content..."))
            }
    }
}
