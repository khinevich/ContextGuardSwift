//
//  IntroductionViews.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 28.02.26.
//

import SwiftUI

// MARK: - Welcome Step

@available(iOS 26.0, *)
struct IntroductionWelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .padding(.top, 20)

            Text("What is Context Guard?")
                .font(.title2.bold())

            InfoCard(icon: "brain.head.profile", color: .purple) {
                Text("Context Guard uses **on-device AI** to find factual contradictions in your documents — completely offline, fully private.")
            }

            InfoCard(icon: "doc.on.doc", color: .blue) {
                Text("It works across **multiple documents** (e.g. a permission slip vs. a teacher's note) and **within a single document** (e.g. a guide that contradicts itself).")
            }

            InfoCard(icon: "shield.checkered", color: .green) {
                Text("All processing happens on your iPad using Apple Intelligence. **No data ever leaves your device.**")
            }

            Text("Let's walk through three examples.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }
}

// MARK: - Document Step

@available(iOS 26.0, *)
struct IntroductionDocumentStepView: View {
    let title: String
    let icon: String
    let iconColor: Color
    let description: String
    let docs: [Document]
    let nextHint: String
    let onPreview: (Document) -> Void

    var body: some View {
        let titles = docs.map(\.title)

        return VStack(spacing: 20) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(iconColor)

            Text(.init(description))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(docs, id: \.id) { doc in
                    DemoDocumentRow(doc: doc, allTitles: titles) {
                        onPreview(doc)
                    }
                }
            }

            Text(.init(nextHint))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Analyzing Step

@available(iOS 26.0, *)
struct IntroductionAnalyzingView: View {
    let docs: [Document]
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            ProgressView()
                .controlSize(.large)

            Text("Analyzing \(docs.count) document\(docs.count == 1 ? "" : "s")...")
                .font(.title3.weight(.medium))

            Text("The on-device AI is cross-referencing text for factual contradictions.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 6) {
                ForEach(docs, id: \.id) { doc in
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text(doc.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer().frame(height: 40)
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                onFinish()
            }
        }
    }
}

// MARK: - Results Step

@available(iOS 26.0, *)
struct IntroductionResultsView: View {
    let issueCount: Int
    let docCount: Int
    let description: String
    let issues: [ConsistencyIssue]
    let allTitles: [String]
    let footerIcon: String?
    let footerColor: Color?
    let footerContent: String?

    var body: some View {
        VStack(spacing: 20) {
            ResultBanner(count: issueCount, docCount: docCount, hasIssues: issueCount > 0)

            Text(.init(description))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if issueCount > 0 {
                ForEach(Array(issues.enumerated()), id: \.offset) { index, issue in
                    IssueCard(issue: issue, index: index + 1, allDocumentTitles: allTitles)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("All Clear!")
                        .font(.title3.weight(.medium))

                    Text("No contradictions were detected. The library guide is internally consistent — all its facts align.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            }

            if let footerIcon = footerIcon, let footerColor = footerColor, let footerContent = footerContent {
                InfoCard(icon: footerIcon, color: footerColor) {
                    Text(.init(footerContent))
                }
            }
        }
    }
}

// MARK: - Tips Step

@available(iOS 26.0, *)
struct IntroductionTipsView: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .padding(.top, 12)

            Text("You're all set!")
                .font(.title2.bold())

            Text("Here's how to check your own documents:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TipRow(icon: "folder.badge.plus", color: .blue,
                   title: "Import Files",
                   detail: "Tap **Import Files** to load .txt or .pdf documents from the Files app.")

            TipRow(icon: "document.viewfinder", color: .green,
                   title: "Scan Files",
                   detail: "Use your iPhone or Pad camera to **scan printed handouts**, whiteboards, or notes. The built-in OCR converts them to text automatically.")

            TipRow(icon: "sparkle.magnifyingglass", color: .purple,
                   title: "Run the Check",
                   detail: "Load up to **3 documents**, then tap **Check for Contradictions**. Results appear in seconds.")

            TipRow(icon: "square.and.arrow.up", color: .orange,
                   title: "Export & Share",
                   detail: "Share your report via AirDrop, Messages, or save it to Files.")

            InfoCard(icon: "lock.shield.fill", color: .blue) {
                Text("Everything runs **100% on-device** using Apple Intelligence. No internet connection needed. Your documents never leave your iPhone or iPad.")
            }

            Button {
                onFinish()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.top, 8)
        }
    }
}
