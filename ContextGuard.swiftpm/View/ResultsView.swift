//
//  SwiftUIView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import SwiftUI

@available(iOS 26.0, *)
struct ResultsView: View {
    var checker: ConsistencyChecker
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    private var layout: AppLayout {
        AppLayout.current(for: sizeClass)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                summaryBanner
                
                if checker.issues.isEmpty {
                    allClearView
                } else {
                    issuesList
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, layout.horizontalPadding)
        }
    }
    
    // MARK: - Summary
    
    private var summaryBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: checker.issues.isEmpty
                  ? "checkmark.shield.fill"
                  : "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(checker.issues.isEmpty ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(checker.issues.isEmpty
                     ? "No Contradictions Found"
                     : "\(checker.issues.count) Issue\(checker.issues.count == 1 ? "" : "s") Found")
                    .font(.title2.bold())
                
                Text("Checked \(checker.documents.count) document\(checker.documents.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - All Clear
    
    private var allClearView: some View {
        VStack(spacing: 16) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            
            Text("All Clear")
                .font(.title3.weight(.medium))
            
            Text("No contradictions were detected between your documents.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Issues List
    
    private var issuesList: some View {
        let allTitles = checker.documents.map { $0.title }
        return VStack(spacing: 16) {
            ForEach(Array(checker.issues.enumerated()), id: \.offset) { index, issue in
                IssueCard(issue: issue, index: index + 1, allDocumentTitles: allTitles)
            }
        }
    }
}

@available(iOS 26.0, *)
#Preview("Results — Issues Found") {
    let checker = ConsistencyChecker()
    
    NavigationStack {
        ResultsView(checker: checker)
            .navigationTitle("Context Guard")
            .onAppear {
                checker.addDocument(Document(id: UUID(), title: "DocA_Penguins.txt", content: "..."))
                checker.addDocument(Document(id: UUID(), title: "DocB_Penguins.txt", content: "..."))
                checker.issues = [
                    ConsistencyIssue(
                        severity: "HIGH",
                        rationale: "The habitat of Emperor penguins is described contradictorily.",
                        sourceText: "They are native to Antarctica",
                        sourceDocument: "DocA_Penguins.txt",
                        targetText: "Emperor penguins are commonly found in the Arctic region",
                        targetDocument: "DocB_Penguins.txt",
                        suggestedFix: "Emperor penguins are native to Antarctica, not the Arctic.",
                        sourceParagraph: 1,
                        targetParagraph: 2
                    ),
                    ConsistencyIssue(
                        severity: "LOW",
                        rationale: "Diet sources differ between documents.",
                        sourceText: "fish, squid, and krill found in the Southern Ocean",
                        sourceDocument: "DocA_Penguins.txt",
                        targetText: "freshwater fish from Arctic rivers and lakes",
                        targetDocument: "DocB_Penguins.txt",
                        suggestedFix: "Emperor penguins feed in the Southern Ocean.",
                        sourceParagraph: 3,
                        targetParagraph: 4
                    )
                ]
            }
    }
}

@available(iOS 26.0, *)
#Preview("Results — All Clear") {
    let checker = ConsistencyChecker()
    
    NavigationStack {
        ResultsView(checker: checker)
            .navigationTitle("Context Guard")
            .onAppear {
                checker.addDocument(Document(id: UUID(), title: "Notes.txt", content: "..."))
            }
    }
}
