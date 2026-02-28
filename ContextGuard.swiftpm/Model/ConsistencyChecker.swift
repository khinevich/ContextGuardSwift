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
        let available = Self.maxDocuments - documents.count
        guard available > 0 else { return }

        for url in urls.prefix(available) {
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

    // MARK: - Demo

    func loadDemo() {
        clear()

        // Try bundled resource files first
        if let pathA = Bundle.main.url(forResource: "DocA_Penguins", withExtension: "txt"),
           let textA = try? String(contentsOf: pathA, encoding: .utf8) {
            addDocument(Document(id: UUID(), title: "DocA_Penguins.txt", content: textA))
        }
        if let pathB = Bundle.main.url(forResource: "DocB_Penguins", withExtension: "txt"),
           let textB = try? String(contentsOf: pathB, encoding: .utf8) {
            addDocument(Document(id: UUID(), title: "DocB_Penguins.txt", content: textB))
        }

        // Fallback: inline demo documents (school trip scenario)
        if documents.isEmpty {
            addDocument(Document(
                id: UUID(),
                title: "Science_Museum_Trip.txt",
                content: """
                SUMMER SCHOOL TRIP: SCIENCE MUSEUM

                Dear Parents,
                We are excited to go on a trip to the Science Museum in the city center. \
                The bus will leave from the school gate on Monday, June 1st at 8:00 AM. \
                We will return to the school by 3:30 PM on the same day.

                WHAT TO BRING:
                - The cost of the trip is $15 per student.
                - Please bring a packed lunch from home. The museum cafe is currently closed.
                - Students must wear their blue school uniform so we can stay together.

                GOAL:
                The goal is to learn about space and the planets. This trip is part of our \
                science class. We hope every student can join us for this fun day of learning!
                """
            ))

            addDocument(Document(
                id: UUID(),
                title: "Teacher_Trip_Update.txt",
                content: """
                TRIP UPDATE: WATER PARK ADVENTURE

                Hi Class,
                Here is the final plan for our big trip to the Water Park at the beach! \
                The train leaves from the station on Wednesday, June 3rd at 10:00 AM. \
                We will get back to the school very late, around 7:00 PM.

                COST AND FOOD:
                - The price is $30 for each person. This includes your ticket and a locker.
                - You do not need to bring food. We will all eat lunch together at the \
                park restaurant. The meal is included in the price.

                CLOTHING:
                - Please wear your favorite swimming clothes and a bright t-shirt.
                - Do not wear your school uniform because it will get wet and messy.

                Wait for the final bell before you leave the school. See you at the train!
                """
            ))
        }
    }

    // MARK: - Consistency Check

    func buildChunkedText() -> String {
        var chunks: [String] = []
        for doc in documents {
            let paragraphs = doc.content
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            for (i, paragraph) in paragraphs.enumerated() {
                chunks.append("[Doc: \(doc.title), Paragraph \(i + 1)]: \(paragraph)")
            }
        }
        return chunks.joined(separator: "\n\n")
    }

    // MARK: - Run Check (with FoundationModels or mock fallback)

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

    // MARK: - Real AI Check (FoundationModels available)

    #if canImport(FoundationModels)
    private func runCheckWithFoundationModels() async {
        // 1. Availability check
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(.appleIntelligenceNotEnabled):
            state = .failed("Please enable Apple Intelligence in Settings > Apple Intelligence & Siri.")
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

        // 2. Build chunked text from loaded documents
        let chunkedText = buildChunkedText()

        // 3. Create session with system prompt
        let session = LanguageModelSession(instructions: """
            You are a Semantic Consistency Validator. Find factual contradictions \
            in the provided document chunks.

            A contradiction: the SAME entity described with CONFLICTING attributes \
            across different paragraphs or documents.

            Rules:
            - Only flag genuine factual contradictions, not stylistic differences
            - Use document names from [Doc: ...] tags for sourceDocument/targetDocument
            - sourceText/targetText: quote the relevant short phrases, not full paragraphs
            - Severity: HIGH = direct factual conflict, MEDIUM = numerical/temporal, LOW = minor
            - If no contradictions exist, return an empty array

            Do NOT flag: different wording saying the same thing, one document \
            having more detail, or subjective statements.
            """)

        // 4. Guided generation — response.content is [ConsistencyIssue]
        do {
            let response = try await session.respond(
                to: chunkedText,
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

    // MARK: - Mock Fallback (when FoundationModels is not available)

    /// Used when running in Swift Playgrounds or on devices without Apple Intelligence.
    /// Returns realistic mock results so the full UI flow can be demonstrated.
    private func runCheckMock() async {
        // Simulate processing delay
        try? await Task.sleep(for: .seconds(2))

        // Check if it's the demo documents (school trip)
        let titles = documents.map { $0.title }
        let allContent = documents.map { $0.content }.joined(separator: " ")

        if titles.contains("Science_Museum_Trip.txt") && titles.contains("Teacher_Trip_Update.txt") {
            // Two-document demo: school trip contradictions
            issues = [
                ConsistencyIssue(
                    severity: "HIGH",
                    rationale: "The trip destination is completely different across the two documents.",
                    sourceText: "trip to the Science Museum in the city center",
                    sourceDocument: "Science_Museum_Trip.txt",
                    targetText: "trip to the Water Park at the beach",
                    targetDocument: "Teacher_Trip_Update.txt",
                    suggestedFix: "Confirm the actual destination — Science Museum or Water Park — and update both documents."
                ),
                ConsistencyIssue(
                    severity: "MEDIUM",
                    rationale: "The trip date and departure time are contradictory.",
                    sourceText: "Monday, June 1st at 8:00 AM",
                    sourceDocument: "Science_Museum_Trip.txt",
                    targetText: "Wednesday, June 3rd at 10:00 AM",
                    targetDocument: "Teacher_Trip_Update.txt",
                    suggestedFix: "Align the trip date — parents need one consistent date and time."
                ),
                ConsistencyIssue(
                    severity: "MEDIUM",
                    rationale: "The food instructions directly contradict each other.",
                    sourceText: "bring a packed lunch from home. The museum cafe is currently closed",
                    sourceDocument: "Science_Museum_Trip.txt",
                    targetText: "You do not need to bring food. We will all eat lunch together",
                    targetDocument: "Teacher_Trip_Update.txt",
                    suggestedFix: "Clarify whether students should pack lunch or if food is provided."
                ),
                ConsistencyIssue(
                    severity: "MEDIUM",
                    rationale: "The dress code contradicts across documents.",
                    sourceText: "Students must wear their blue school uniform",
                    sourceDocument: "Science_Museum_Trip.txt",
                    targetText: "Do not wear your school uniform because it will get wet",
                    targetDocument: "Teacher_Trip_Update.txt",
                    suggestedFix: "Specify one dress code — school uniform or swimming clothes."
                ),
            ]
        } else if allContent.contains("sun hat") && allContent.contains("Hats are not allowed") {
            // Single-document demo: camp guide contradictions
            let docTitle = titles.first ?? "Document"
            issues = [
                ConsistencyIssue(
                    severity: "HIGH",
                    rationale: "The snack policy directly contradicts the camp shop description.",
                    sourceText: "No candy, soda, or sugary snacks are allowed",
                    sourceDocument: docTitle,
                    targetText: "bring $5 every day so you can buy candy and soda",
                    targetDocument: docTitle,
                    suggestedFix: "Decide whether candy and soda are banned or sold."
                ),
                ConsistencyIssue(
                    severity: "HIGH",
                    rationale: "The hat policy contradicts itself within the same document.",
                    sourceText: "You must always wear a sun hat when you are outside",
                    sourceDocument: docTitle,
                    targetText: "Hats are not allowed at camp",
                    targetDocument: docTitle,
                    suggestedFix: "Clarify whether hats are required or banned."
                ),
                ConsistencyIssue(
                    severity: "HIGH",
                    rationale: "The grading section says there are no tests, but then describes a final exam.",
                    sourceText: "There are no tests at this camp",
                    sourceDocument: docTitle,
                    targetText: "The final exam is on Friday afternoon",
                    targetDocument: docTitle,
                    suggestedFix: "Remove either the 'no tests' claim or the final exam details."
                ),
            ]
        } else {
            // Generic fallback for user-imported documents
            // Show a helpful message instead of fake results
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
            report += "Issue #\(index + 1) [\(issue.severity.uppercased())]\n"
            report += issue.rationale + "\n\n"
            report += "  \(issue.sourceDocument):\n"
            report += "  \"\(issue.sourceText)\"\n\n"
            report += "  \(issue.targetDocument):\n"
            report += "  \"\(issue.targetText)\"\n\n"
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
