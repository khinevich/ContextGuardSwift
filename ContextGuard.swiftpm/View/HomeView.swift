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
    
    private var layout: AppLayout {
        AppLayout.current(for: sizeClass)
    }
    
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
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        Group {
            if sizeClass == .compact {
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
            subtitle: "Import .txt or .pdf",
            color: .blue
        ) {
            showFileImporter = true
        }
        
        ActionCard(
            icon: "camera.viewfinder",
            title: "Scan Paper",
            subtitle: "Use iPad camera",
            color: .green
        ) {
            showScanner = true
        }
    }
    
    // MARK: - Loaded Documents
    
    private var loadedDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Loaded Documents")
                    .font(.headline)
                
                Spacer()
                
                Text("\(checker.documents.count) file\(checker.documents.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(checker.documents, id: \.id) { doc in
                DocumentRowView(document: doc)
            }
        }
        .padding(.horizontal, layout.horizontalPadding)
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
                checker.addDocument(Document(id: UUID(), title: "DocA_Penguins.txt", content: "Emperor penguins are native to Antarctica..."))
                checker.addDocument(Document(id: UUID(), title: "DocB_Penguins.txt", content: "Emperor penguins are found in the Arctic..."))
            }
    }
}
