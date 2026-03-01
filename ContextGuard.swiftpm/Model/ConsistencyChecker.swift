//
//  ConsistencyChecker.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import Foundation
import Observation
import PDFKit

#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
@MainActor
@Observable
class ConsistencyChecker {

    /// Hard limit — keeps total text within Foundation Models' 4096-token context window.
    /// 3 docs × ~700 words each ≈ 2100 words ≈ 3000 tokens, leaving room for prompt + output.
    static let maxDocuments = 3

    var documents: [Document] = []
    var issues: [ConsistencyIssue] = []
    var state: CheckingState = .idle

    var canAddMore: Bool { remainingSlots > 0 }
    var remainingSlots: Int { Self.maxDocuments - documents.count }

    // MARK: - Document Management

    func addDocument(_ document: Document) {
        guard canAddMore else { return }
        documents.append(document)
    }

    func removeDocument(id: UUID) {
        documents.removeAll { $0.id == id }
    }

    func clear() {
        documents.removeAll()
        issues.removeAll()
        state = .idle
    }

    // MARK: - File Import

    func importFiles(from urls: [URL]) {
        for url in urls.prefix(remainingSlots) {
            if let document = loadDocument(from: url) {
                addDocument(document)
            }
        }
    }

    private func loadDocument(from url: URL) -> Document? {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }

        let title = url.lastPathComponent
        let text: String?

        if url.pathExtension.lowercased() == "pdf" {
            text = extractTextFromPDF(url: url)
        } else {
            text = try? String(contentsOf: url, encoding: .utf8)
        }

        guard let content = text, !content.isEmpty else { return nil }
        return Document(id: UUID(), title: title, content: content)
    }

    private func extractTextFromPDF(url: URL) -> String? {
        guard let pdf = PDFDocument(url: url) else { return nil }
        var fullText = ""
        for index in 0..<pdf.pageCount {
            if let page = pdf.page(at: index), let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        return fullText.isEmpty ? nil : fullText
    }

    // MARK: - Chunking

    /// Builds labeled chunks for the LLM prompt.
    /// Format: `[filename.txt §N] paragraph text`
    /// Compact tag saves ~120 tokens vs the old verbose format.
    func buildChunkedText() -> String {
        var chunks: [String] = []
        for doc in documents {
            let paragraphs = doc.content
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            for (i, paragraph) in paragraphs.enumerated() {
                chunks.append("[\(doc.title) §\(i + 1)] \(paragraph)")
            }
        }
        return chunks.joined(separator: "\n")
    }

    /// Locates which paragraph a quoted text belongs to in a document.
    /// Used in export only — the LLM returns quotes, we resolve locations.
    func locateParagraph(quote: String, inDocument title: String) -> Int {
        guard let doc = documents.first(where: { $0.title == title }) else { return 0 }
        let paragraphs = doc.content
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        for (i, paragraph) in paragraphs.enumerated() {
            if paragraph.localizedCaseInsensitiveContains(quote.prefix(30)) {
                return i + 1
            }
        }
        return 0
    }

    // MARK: - Run Check

    func runCheck() async {
        guard !documents.isEmpty else { return }
        state = .analyzing
        issues.removeAll()

        #if canImport(FoundationModels)
        await runCheckWithFoundationModels()
        #else
        await runCheckMock()
        #endif
    }

    #if canImport(FoundationModels)
    private func runCheckWithFoundationModels() async {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(.appleIntelligenceNotEnabled):
            state = .failed("Please enable Apple Intelligence in Settings → Apple Intelligence & Siri.")
            return
        case .unavailable(.deviceNotEligible):
            state = .failed("This device does not support Apple Intelligence.")
            return
        case .unavailable(.modelNotReady):
            state = .failed("The AI model is still downloading. Please try again later.")
            return
        case .unavailable:
            state = .failed("Apple Intelligence is not available.")
            return
        }

        let session = LanguageModelSession(instructions: """
            You find factual contradictions in text chunks. Each chunk is tagged \
            [filename §N] where N is the paragraph number.

            A contradiction: the SAME entity with CONFLICTING facts across chunks.

            Flag: different destinations, dates, prices, rules, or facts about the same thing.

            Do NOT flag:
            - Different wording saying the same thing
            - One document having more detail than another
            - Opinions or subjective descriptions
            - Information present in one document but absent in another

            sourceDocument/targetDocument: use ONLY the filename (e.g. "File.txt").
            sourceText/targetText: quote the key conflicting phrase, under 15 words, verbatim.
            If no contradictions exist, return an empty array.
            """)

        do {
            let response = try await session.respond(
                to: buildChunkedText(),
                generating: [ConsistencyIssue].self
            )
            issues = response.content
            state = .completed
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize:
                state = .failed("Documents are too long. Try shorter documents or fewer files.")
            case .guardrailViolation:
                state = .failed("Content triggered a safety filter. Try different documents.")
            default:
                state = .failed("Analysis failed: \(error.localizedDescription)")
            }
        } catch {
            state = .failed("Unexpected error: \(error.localizedDescription)")
        }
    }
    #endif

    // MARK: - Mock Fallback

    private func runCheckMock() async {
        try? await Task.sleep(for: .seconds(2))

        let titles = documents.map(\.title)
        let allContent = documents.map(\.content).joined(separator: " ")

        if titles.contains("DemoScienceMuseumTrip.txt") && titles.contains("Teacher_Trip_Update.txt") {
            issues = DemoData.twoDocIssues
        } else if allContent.contains("sun hat") && allContent.contains("Hats are not allowed") {
            issues = DemoData.singleDocIssues
        } else {
            state = .failed(
                "On-device AI (Apple Intelligence) is not available in this environment. " +
                "To run a real consistency check, open this project in Xcode 26 and deploy " +
                "to a physical device with Apple Intelligence enabled.\n\n" +
                "Tap \"Interactive Demo\" on the home screen to see how the app works."
            )
            return
        }

        state = .completed
    }

    // MARK: - Export

    func exportAsText() -> String {
        var report = "Context Guard — Consistency Report\n"
        report += "Checked \(documents.count) document(s)\n"
        report += "Found \(issues.count) issue(s)\n"
        report += String(repeating: "=", count: 40) + "\n\n"

        for (index, issue) in issues.enumerated() {
            let srcP = locateParagraph(quote: issue.sourceText, inDocument: issue.sourceDocument)
            let tgtP = locateParagraph(quote: issue.targetText, inDocument: issue.targetDocument)

            report += "Issue #\(index + 1) [\(issue.severity.uppercased())]\n"
            report += issue.rationale + "\n\n"
            report += "  \(issue.sourceDocument)"
            if srcP > 0 { report += " (Paragraph \(srcP))" }
            report += ":\n  \"\(issue.sourceText)\"\n\n"
            report += "  \(issue.targetDocument)"
            if tgtP > 0 { report += " (Paragraph \(tgtP))" }
            report += ":\n  \"\(issue.targetText)\"\n\n"
            report += "  Suggested Fix: \(issue.suggestedFix)\n"
            report += String(repeating: "-", count: 40) + "\n\n"
        }

        return report
    }

    func exportToFile() -> URL? {
        let text = exportAsText()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ContextGuard_Report.txt")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
