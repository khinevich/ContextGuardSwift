//
//  DemoFlowView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 28.02.26.
//

import SwiftUI

@available(iOS 26.0, *)
struct DemoFlowView: View {
    var checker: ConsistencyChecker
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var step: DemoStep = .welcome
    @State private var previewDocument: Document? = nil
    @State private var goingForward: Bool = true

    private var isCompact: Bool { sizeClass == .compact }
    private var progress: Double {
        Double(step.rawValue) / Double(DemoStep.allCases.count - 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color.blue.opacity(0.03)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    ProgressView(value: progress)
                        .tint(.blue)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    Text("Step \(step.rawValue + 1) of \(DemoStep.allCases.count)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 6)

                    ScrollView {
                        VStack(spacing: 24) {
                            stepContent
                                .id(step)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: goingForward ? .trailing : .leading)
                                            .combined(with: .opacity),
                                        removal: .move(edge: goingForward ? .leading : .trailing)
                                            .combined(with: .opacity)
                                    )
                                )
                        }
                        .animation(.easeInOut(duration: 0.3), value: step)
                        .padding(.horizontal, isCompact ? 20 : 40)
                        .padding(.vertical, 24)
                    }

                    Divider()
                    navigationBar
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }
            }
            .navigationTitle(step.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(item: $previewDocument) { doc in
            DocumentPreviewSheet(document: doc)
        }
    }

    // MARK: - Step Router

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            IntroductionWelcomeView()

        case .twoDocs:
            IntroductionDocumentStepView(
                title: "Two contradictory documents",
                icon: "doc.on.doc.fill",
                iconColor: .blue,
                description: "Imagine a school sends these two communications about a field trip. Can you spot the contradictions?",
                docs: [DemoData.tripDoc, DemoData.teacherDoc],
                nextHint: "Tap **Next** to run the AI check.",
                onPreview: { previewDocument = $0 }
            )

        case .twoDocsAnalyzing:
            IntroductionAnalyzingView(docs: [DemoData.tripDoc, DemoData.teacherDoc]) {
                goingForward = true
                if let next = step.nextStep { step = next }
            }

        case .twoDocsResults:
            IntroductionResultsView(
                issueCount: DemoData.twoDocIssues.count,
                docCount: 2,
                description: "The AI found these contradictions between the two school trip documents:",
                issues: DemoData.twoDocIssues,
                allTitles: [DemoData.tripDoc.title, DemoData.teacherDoc.title],
                footerIcon: "lightbulb.fill",
                footerColor: .orange,
                footerContent: "Each issue shows **which documents** conflict, **what text** contradicts, and a **suggested fix**. Colors are consistent per document."
            )

        case .singleDoc:
            IntroductionDocumentStepView(
                title: "Contradictions within one document",
                icon: "doc.text.fill",
                iconColor: .purple,
                description: "Context Guard also catches contradictions **inside a single document**. This camp guide has several rules that contradict each other:",
                docs: [DemoData.campDoc],
                nextHint: "Tap **Next** to find the internal contradictions.",
                onPreview: { previewDocument = $0 }
            )

        case .singleDocAnalyzing:
            IntroductionAnalyzingView(docs: [DemoData.campDoc]) {
                goingForward = true
                if let next = step.nextStep { step = next }
            }

        case .singleDocResults:
            IntroductionResultsView(
                issueCount: DemoData.singleDocIssues.count,
                docCount: 1,
                description: "The AI found contradictions **within the same document** — the camp guide contradicts its own rules:",
                issues: DemoData.singleDocIssues,
                allTitles: [DemoData.campDoc.title],
                footerIcon: nil, footerColor: nil, footerContent: nil
            )

        case .libraryDoc:
            IntroductionDocumentStepView(
                title: "A well-written document",
                icon: "checkmark.seal.fill",
                iconColor: .green,
                description: "Not every document has contradictions. Here's a well-written library guide — let's see if the AI finds any issues:",
                docs: [DemoData.libraryDoc],
                nextHint: "Tap **Next** to run the check.",
                onPreview: { previewDocument = $0 }
            )

        case .libraryDocAnalyzing:
            IntroductionAnalyzingView(docs: [DemoData.libraryDoc]) {
                goingForward = true
                if let next = step.nextStep { step = next }
            }

        case .libraryDocResults:
            IntroductionResultsView(
                issueCount: 0,
                docCount: 1,
                description: "",
                issues: [],
                allTitles: [DemoData.libraryDoc.title],
                footerIcon: "info.circle.fill",
                footerColor: .blue,
                footerContent: "When no contradictions are found, Context Guard confirms your document is consistent. This is the result you **want** to see for your own documents."
            )

        case .tips:
            IntroductionTipsView { dismiss() }
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            // Back button — skips analyzing steps
            if let prev = step.previousStep, !step.isAnalyzing {
                Button {
                    goingForward = false
                    step = prev
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .tint(.secondary)
            }

            Spacer()

            if step == .tips {
                // "Get Started" button is in the content
            } else if step.isAnalyzing {
                Text("Please wait...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    goingForward = true
                    if let next = step.nextStep {
                        step = next
                    }
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
    }
}

// MARK: - Previews

@available(iOS 26.0, *)
#Preview("Demo Flow") {
    DemoFlowView(checker: ConsistencyChecker())
}
