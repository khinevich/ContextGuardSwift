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

            // --- What is an inconsistency? ---
            InfoCard(icon: "questionmark.circle.fill", color: .indigo) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("**What is an inconsistency?**")
                        .font(.subheadline.weight(.semibold))

                    Text("An inconsistency is an unintentional contradiction where the **same entity or concept is described with conflicting facts** — across multiple documents or within a single one. For example, one letter says the school trip goes to a Science Museum, while another says it goes to a Water Park.")

                    Text("Research shows that contradictions create **Extraneous Cognitive Load** (Mayer's Coherence Principle) — readers waste mental energy reconciling conflicting information instead of focusing on actual content.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Link(destination: URL(string: "https://www.sciencedirect.com/science/article/pii/S2666920X25001778")!) {
                        Label("Based on: Dietrich et al., Koli Calling 2025", systemImage: "doc.text.fill")
                            .font(.caption)
                    }
                    .tint(.indigo)
                }
            }

            // --- Core capability ---
            InfoCard(icon: "brain.head.profile", color: .purple) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Context Guard uses **on-device AI** to find factual contradictions in your documents — completely offline, fully private.")

                    Text("**Requirement:** Enable Apple Intelligence in your iPhone or iPad Settings (Settings → Apple Intelligence & Siri) to use the AI check.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }

            InfoCard(icon: "doc.on.doc", color: .blue) {
                Text("It works across **multiple documents** (e.g. a permission slip vs. a teacher's note) and **within a single document** (e.g. a guide that contradicts itself).")
            }

            InfoCard(icon: "shield.checkered", color: .green) {
                Text("All processing happens on your iPhone or iPad using Apple Intelligence. **No data ever leaves your device.** No internet connection needed.")
            }

            // --- Sustainability & Accessibility ---
            InfoCard(icon: "leaf.fill", color: Color(red: 0.2, green: 0.65, blue: 0.35)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("**Sustainability & Accessibility**")
                        .font(.subheadline.weight(.semibold))

                    Text("Context Guard helps reduce **material waste** — catching contradictions before documents are printed, distributed, or published prevents recall and reprinting of flawed materials.")

                    Text("Unlike cloud AI tools, this app uses **zero network energy**: no servers, no data centers, no transmission costs. Every check runs locally on your device.")

                    Text("Contradictions in educational materials create **cognitive barriers** that disproportionately affect learners with disabilities, who may struggle more to reconcile conflicting information. By surfacing inconsistencies automatically, Context Guard helps educators create more **accessible, inclusive materials** for all learners.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

            if !description.isEmpty {
                Text(.init(description))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Explanation card — shown BEFORE the issue cards so users
            // understand what they're looking at before scrolling through results.
            if let footerIcon = footerIcon, let footerColor = footerColor, let footerContent = footerContent {
                InfoCard(icon: footerIcon, color: footerColor) {
                    Text(.init(footerContent))
                }
            }

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
                   detail: "Tap **Import Files** to load **.txt** or **.pdf** documents from the Files app. You can import up to **3 documents** at a time.")

            TipRow(icon: "document.viewfinder", color: .green,
                   title: "Scan Paper Documents",
                   detail: "Use your iPhone or iPad camera to **scan printed handouts**, whiteboards, or notes. Built-in OCR converts the scanned image to text automatically.")

            TipRow(icon: "sparkle.magnifyingglass", color: .purple,
                   title: "Run the AI Check",
                   detail: "Tap **Check for Contradictions** and the on-device AI will cross-reference all your documents. Results show **severity**, **exact quotes**, **paragraph locations**, and a **suggested fix**.")

            TipRow(icon: "square.and.arrow.up", color: .orange,
                   title: "Export & Share",
                   detail: "Share your consistency report via **AirDrop**, **Messages**, or save it to **Files**.")

            TipRow(icon: "hand.tap", color: .teal,
                   title: "Manage Documents",
                   detail: "Tap any document to **preview** it. **Swipe left** to delete or preview. Use the **trash icon** to clear all documents at once.")

            InfoCard(icon: "wand.and.stars", color: .purple) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("**Apple Intelligence Required**")
                        .font(.subheadline.weight(.semibold))
                    Text("To run the AI consistency check, enable Apple Intelligence in your device settings: **Settings → Apple Intelligence & Siri**. The app requires an iPhone 15 Pro / iPad with M-series chip or newer.")
                        .font(.caption)
                }
            }

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
