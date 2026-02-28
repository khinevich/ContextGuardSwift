//
//  File.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import Foundation
import Observation
import PDFKit
import FoundationModels

@available(iOS 26.0, *)

@MainActor
@Observable
class ConsistencyChecker {

    var documents: [Document] = []
    var issues: [ConsistencyIssue] = []
    var state: CheckingState = .idle
    
    /// Hard limit — keeps total text within Foundation Models' 4096-token context window.
    /// 3 docs × ~700 words each ≈ 2100 words ≈ 3000 tokens, leaving room for prompt + output.
    static let maxDocuments = 3
    
    /// True when we haven't hit the document cap yet.
    var canAddMore: Bool {
        remainingSlots > 0
    }
    /// How many slots remain — useful for UI labels like "2 of 3 slots used".
    var remainingSlots: Int {
        Self.maxDocuments - documents.count
    }
    
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

        let accepted = urls.prefix(available)
        for url in accepted {
            if let document = loadDocument(from: url) {
                addDocument(document)
            }
        }
    }
    
    private func loadDocument(from url: URL) -> Document? {
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let title = url.lastPathComponent
        let text: String?
        
        if url.pathExtension.lowercased() == "pdf" {
            text = extractTextFromPDF(url: url)
        } else {
            text = try? String(contentsOf: url, encoding: .utf8)
        }
        
        guard let content = text, !content.isEmpty else {
            return nil
        }
        
        return Document(id: UUID(), title: title, content: content)
    }
    
    private func extractTextFromPDF(url: URL) -> String? {
        guard let pdf = PDFDocument(url: url) else { return nil }
        
        var fullText = ""
        for index in 0..<pdf.pageCount {
            if let page = pdf.page(at: index),
               let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        return fullText.isEmpty ? nil : fullText
    }
    
    // MARK: - Demo
    
    func loadDemo() {
        clear()
        
        // Bundled sample files — create these in Resources/ folder
        if let pathA = Bundle.main.url(forResource: "DocA_Penguins", withExtension: "txt"),
           let textA = try? String(contentsOf: pathA, encoding: .utf8) {
            addDocument(Document(id: UUID(), title: "DocA_Penguins.txt", content: textA))
        }
        
        if let pathB = Bundle.main.url(forResource: "DocB_Penguins", withExtension: "txt"),
           let textB = try? String(contentsOf: pathB, encoding: .utf8) {
            addDocument(Document(id: UUID(), title: "DocB_Penguins.txt", content: textB))
        }
        
        // Fallback: if resource files are not yet created, use inline text
        if documents.isEmpty {
            // DOCUMENT 1: The Permission Slip
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

            // DOCUMENT 2: The Teacher's Note (CONTRADICTORY)
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
            
//            // DOCUMENT 3: Summer_Camp_Rules.txt
//            addDocument(Document(
//                id: UUID(),
//                title: "Summer_Camp_Guide.txt",
//                content: """
//                WELCOME TO THE 5-DAY ART CAMP
//                
//                CAMP OVERVIEW:
//                This camp is designed to help you be creative. Our camp lasts for five full days, \
//                from Monday until Friday. We have a lot of fun activities planned for you!
//                
//                WEEKLY SCHEDULE:
//                Day 1: Painting with water colors in the garden.
//                Day 2: Making bowls out of wet clay.
//                Day 3: Drawing animals with colored pencils.
//                (This is the end of our activity list for the week).
//                
//                CAMP RULES:
//                - You must always wear a sun hat when you are outside.
//                - No candy, soda, or sugary snacks are allowed in the camp building.
//                - You do not need to bring any extra money with you.
//                
//                THE CAMP SHOP:
//                - The shop is open every afternoon for students to buy snacks.
//                - Please bring $5 every day so you can buy candy and soda for your friends.
//                - Hats are not allowed at camp. Do not bring a hat inside or outside.
//                
//                GRADING AND PRIZES:
//                At the end of the week, everyone gets a "Gold Star" for finishing. \
//                Please note: There are no tests at this camp. We just want you to have fun.
//                
//                FINAL TEST DETAILS:
//                - The final exam is on Friday afternoon in the main hall. 
//                - You must pass this test to get your "Gold Star." 
//                - Bring a pen and paper for the writing part of the exam.
//                """
//            ))
        }
    }
    
    // MARK: - Consistency Check
    
    func buildChunkedText() -> String {
        var chunks: [String] = []
        for doc in documents {
            let paragraphs = doc.content
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines)}
                .filter { !$0.isEmpty }
            for (i, paragraph) in paragraphs.enumerated() {
                chunks.append("[Doc: \(doc.title), Paragraph \(i+1)]: \(paragraph)")
            }
        }
        return chunks.joined(separator: "\n\n")
    }
    
    func runCheck() async {
        guard !documents.isEmpty else { return }

        state = .analyzing
        issues.removeAll()

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

        // 3. Create session with system prompt in instructions
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
//    func runCheck() async {
//        state = .analyzing
//        issues.removeAll()
//        
//        // TODO: Phase 3 — Replace with real LanguageModelSession call
//        // simulate a delay and return mock results for UI development
//        
//        try? await Task.sleep(for: .seconds(2))
//        
//        issues = [
//            ConsistencyIssue(
//                severity: "HIGH",
//                rationale: "The habitat of Emperor penguins is described contradictorily across documents.",
//                sourceText: "They are native to Antarctica",
//                sourceDocument: "DocA_Penguins.txt",
//                targetText: "Emperor penguins are commonly found in the Arctic region",
//                targetDocument: "DocB_Penguins.txt",
//                suggestedFix: "Verify the correct habitat. Emperor penguins are native to Antarctica, not the Arctic."
//            ),
//            ConsistencyIssue(
//                severity: "MEDIUM",
//                rationale: "Temperature preferences are contradictory between documents.",
//                sourceText: "temperatures dropping to minus 60 degrees Celsius",
//                sourceDocument: "DocA_Penguins.txt",
//                targetText: "They prefer moderate temperatures around 5 degrees Celsius",
//                targetDocument: "DocB_Penguins.txt",
//                suggestedFix: "Reconcile temperature claims. Emperor penguins survive extreme cold, not moderate temperatures."
//            ),
//            ConsistencyIssue(
//                severity: "MEDIUM",
//                rationale: "Breeding season is described differently across documents.",
//                sourceText: "breed during the Antarctic winter",
//                sourceDocument: "DocA_Penguins.txt",
//                targetText: "typically breed in the summer months",
//                targetDocument: "DocB_Penguins.txt",
//                suggestedFix: "Confirm breeding season. Emperor penguins breed during the Antarctic winter."
//            ),
//            ConsistencyIssue(
//                severity: "LOW",
//                rationale: "Diet sources differ between documents.",
//                sourceText: "fish, squid, and krill found in the Southern Ocean",
//                sourceDocument: "DocA_Penguins.txt",
//                targetText: "freshwater fish from Arctic rivers and lakes",
//                targetDocument: "DocB_Penguins.txt",
//                suggestedFix: "Align diet descriptions. Emperor penguins feed in the Southern Ocean, not Arctic freshwater."
//            )
//        ]
//        
//        state = .completed
//    }
    
    // MARK: - Export
    func exportAsText() -> String {
        var report = "Context Guard — Consistency Report\n"
        report += "Checked \(documents.count) document(s)\n"
        report += "Found \(issues.count) issue(s)\n"
        report += String(repeating: "=", count: 40) + "\n\n"
        
        for (index, issue) in issues.enumerated() {
            report += "Issue #\(index + 1) [\(issue.severity.uppercased())]\n"
            report += issue.rationale + "\n\n"
            report += "  Source: \(issue.sourceDocument)\n"
            report += "  \"\(issue.sourceText)\"\n\n"
            report += "  Target: \(issue.targetDocument)\n"
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
