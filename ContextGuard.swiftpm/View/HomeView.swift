//
//  HomeView.swift
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
    @Binding var showDemo: Bool

    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var previewDocument: Document? = nil
    @State private var useGridView: Bool = false
    @State private var showClearConfirmation = false

    private var layout: AppLayout { AppLayout.current(for: sizeClass) }
    private var isCompact: Bool { sizeClass == .compact }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: layout.sectionSpacing) {
                headerSection

                if !checker.documents.isEmpty {
                    loadedDocumentsSection
                }

                // Token limit disclaimer — shown when documents are loaded
                if !checker.documents.isEmpty {
                    tokenLimitDisclaimer
                }

                actionButtonsSection

                if !checker.documents.isEmpty {
                    runCheckButton
                }

                Divider()
                    .padding(.horizontal, layout.horizontalPadding)

                demoSection
                footerSection
            }
            .padding(.vertical, layout.sectionSpacing)
        }
        .sheet(item: $previewDocument) { doc in
            DocumentPreviewSheet(document: doc)
        }
        .alert("Clear All Documents?", isPresented: $showClearConfirmation) {
            Button("Clear All", role: .destructive) {
                withAnimation { checker.clear() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all \(checker.documents.count) loaded documents.")
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

    // MARK: - Loaded Documents

    private var loadedDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Loaded Documents")
                    .font(.headline)

                Spacer()

                Text("\(checker.documents.count) of \(ConsistencyChecker.maxDocuments)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !isCompact {
                    Picker("View", selection: $useGridView) {
                        Image(systemName: "list.bullet").tag(false)
                        Image(systemName: "square.grid.2x2").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }

                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                }
                .tint(.red)
            }

            if useGridView && !isCompact {
                gridDocumentsView
            } else {
                listDocumentsView
            }
        }
        .padding(.horizontal, layout.horizontalPadding)
    }

    // MARK: - List View

    /// Row height: DocumentRowView uses padding(12/16) + minHeight(44/80) + listRowInsets(4+4).
    /// Compact: ~86pt. Regular: ~105pt (includes preview text line).
    private var listDocumentsView: some View {
        let rowHeight: CGFloat = isCompact ? 86 : 105
        let listHeight = CGFloat(checker.documents.count) * rowHeight + 8

        return List {
            ForEach(checker.documents, id: \.id) { doc in
                Button { previewDocument = doc } label: {
                    DocumentRowView(document: doc)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        withAnimation { checker.removeDocument(id: doc.id) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button { previewDocument = doc } label: {
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
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        //.contentMargins(.vertical, 0, for: .scrollContent)
        .frame(height: listHeight)
    }

    // MARK: - Grid View (iPad)

    private var gridDocumentsView: some View {
        let columns = [GridItem(.adaptive(minimum: 140, maximum: 160), spacing: 20)]

        return LazyVGrid(columns: columns, spacing: 20) {
            ForEach(checker.documents, id: \.id) { doc in
                DocumentGridItemView(document: doc)
                    .onTapGesture { previewDocument = doc }
                    .contextMenu {
                        Button { previewDocument = doc } label: {
                            Label("Preview", systemImage: "eye")
                        }
                        Button(role: .destructive) {
                            withAnimation { checker.removeDocument(id: doc.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Token Limit Disclaimer

    private var tokenLimitDisclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.blue)
                .padding(.top, 1)

            Text("The on-device AI has a **4,096-token context window** (~3,000 words). To deliver the most accurate results, document imports are limited to **\(ConsistencyChecker.maxDocuments) files** of 1–3 pages each. Larger documents may not be fully analyzed.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, layout.horizontalPadding)
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        Group {
            if isCompact {
                VStack(spacing: layout.cardSpacing) { actionCards }
            } else {
                HStack(spacing: layout.cardSpacing) { actionCards }
            }
        }
        .padding(.horizontal, layout.horizontalPadding)
    }

    @ViewBuilder
    private var actionCards: some View {
        ActionCard(
            icon: "folder.badge.plus",
            title: "Import Files",
            subtitle: checker.canAddMore
                ? "Select .txt or .pdf"
                : "Limit reached (\(ConsistencyChecker.maxDocuments) docs)",
            color: checker.canAddMore ? .blue : .gray
        ) {
            if checker.canAddMore { showFileImporter = true }
        }
        .disabled(!checker.canAddMore)

        ActionCard(
            icon: "document.viewfinder",
            title: "Scan Files",
            subtitle: checker.canAddMore
                ? "Use iPhone/iPad camera"
                : "Limit reached (\(ConsistencyChecker.maxDocuments) docs)",
            color: checker.canAddMore ? .green : .gray
        ) {
            if checker.canAddMore { showScanner = true }
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
                showDemo = true
            } label: {
                Label("Interactive Demo", systemImage: "play.fill")
                    .font(.subheadline.weight(.medium))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal, layout.horizontalPadding)

            VStack(spacing: 6) {
                Text("Created by Mikhail Khinevich")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    Link(destination: URL(string: "https://www.linkedin.com/in/mikhail-khinevich-a56399219/")!) {
                        Label("LinkedIn", systemImage: "person.crop.circle")
                            .font(.footnote)
                    }
                    Link(destination: URL(string: "https://github.com/khinevich")!) {
                        Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                            .font(.footnote)
                    }
                }
                .tint(.blue)
            }

            Divider()
                .padding(.horizontal, layout.horizontalPadding)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)

                Text(
                    "**AI Disclaimer.** Results are generated by an on-device Large Language Model and may contain inaccuracies or hallucinations. Always verify findings independently before acting on them. This tool is intended as a verification aid only and does not constitute legal, editorial, or factual authority. In accordance with the EU AI Act (Regulation (EU) 2024/1689), users are informed that AI-assisted output requires human oversight."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, layout.horizontalPadding)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Previews

@available(iOS 26.0, *)
#Preview("Home — Empty") {
    @Previewable @State var showFiles = false
    @Previewable @State var showScanner = false
    @Previewable @State var showDemo = false
    let checker = ConsistencyChecker()

    NavigationStack {
        HomeView(checker: checker, showFileImporter: $showFiles, showScanner: $showScanner, showDemo: $showDemo)
    }
}

@available(iOS 26.0, *)
#Preview("Home — With Documents") {
    @Previewable @State var showFiles = false
    @Previewable @State var showScanner = false
    @Previewable @State var showDemo = false
    let checker = ConsistencyChecker()

    NavigationStack {
        HomeView(checker: checker, showFileImporter: $showFiles, showScanner: $showScanner, showDemo: $showDemo)
            .onAppear {
                checker.addDocument(Document(id: UUID(), title: "DocA_Penguins.txt", content: "Emperor penguins are native to Antarctica..."))
                checker.addDocument(Document(id: UUID(), title: "DocB_Penguins.txt", content: "Emperor penguins are found in the Arctic..."))
            }
    }
}
