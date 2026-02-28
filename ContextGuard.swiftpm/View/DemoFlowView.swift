//
//  SwiftUIView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 28.02.26.
//

import SwiftUI

// MARK: - Demo Steps

@available(iOS 26.0, *)
enum DemoStep: Int, CaseIterable {
    case welcome
    case twoDocs
    case twoDocsAnalyzing
    case twoDocsResults
    case singleDoc
    case singleDocAnalyzing
    case singleDocResults
    case libraryDoc
    case libraryDocAnalyzing
    case libraryDocResults
    case tips

    var title: String {
        switch self {
        case .welcome:              return "Welcome"
        case .twoDocs:              return "Multi-Document Check"
        case .twoDocsAnalyzing:     return "Analyzing..."
        case .twoDocsResults:       return "Contradictions Found"
        case .singleDoc:            return "Single-Document Check"
        case .singleDocAnalyzing:   return "Analyzing..."
        case .singleDocResults:     return "Internal Contradictions"
        case .libraryDoc:           return "Clean Document"
        case .libraryDocAnalyzing:  return "Analyzing..."
        case .libraryDocResults:    return "All Clear"
        case .tips:                 return "You're Ready"
        }
    }

    var isAnalyzing: Bool {
        self == .twoDocsAnalyzing || self == .singleDocAnalyzing || self == .libraryDocAnalyzing
    }

    /// Back navigation skips analyzing steps so user doesn't land on a spinner.
    var previousStep: DemoStep? {
        switch self {
        case .welcome:              return nil
        case .twoDocs:              return .welcome
        case .twoDocsAnalyzing:     return .twoDocs
        case .twoDocsResults:       return .twoDocs
        case .singleDoc:            return .twoDocsResults
        case .singleDocAnalyzing:   return .singleDoc
        case .singleDocResults:     return .singleDoc
        case .libraryDoc:           return .singleDocResults
        case .libraryDocAnalyzing:  return .libraryDoc
        case .libraryDocResults:    return .libraryDoc
        case .tips:                 return .libraryDocResults
        }
    }

    var nextStep: DemoStep? {
        DemoStep(rawValue: rawValue + 1)
    }
}

// MARK: - Demo Flow View

@available(iOS 26.0, *)
struct DemoFlowView: View {
    var checker: ConsistencyChecker
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var step: DemoStep = .welcome
    @State private var previewDocument: Document? = nil

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
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
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
        case .welcome:              welcomeStep
        case .twoDocs:              twoDocsStep
        case .twoDocsAnalyzing:     analyzingStep(docs: [DemoData.tripDoc, DemoData.teacherDoc])
        case .twoDocsResults:       twoDocsResultsStep
        case .singleDoc:            singleDocStep
        case .singleDocAnalyzing:   analyzingStep(docs: [DemoData.campDoc])
        case .singleDocResults:     singleDocResultsStep
        case .libraryDoc:           libraryDocStep
        case .libraryDocAnalyzing:  analyzingStep(docs: [DemoData.libraryDoc])
        case .libraryDocResults:    libraryDocResultsStep
        case .tips:                 tipsStep
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .padding(.top, 20)

            Text("What is Context Guard?")
                .font(.title2.bold())

            infoCard(icon: "brain.head.profile", color: .purple) {
                Text("Context Guard uses **on-device AI** to find factual contradictions in your documents — completely offline, fully private.")
            }

            infoCard(icon: "doc.on.doc", color: .blue) {
                Text("It works across **multiple documents** (e.g. a permission slip vs. a teacher's note) and **within a single document** (e.g. a guide that contradicts itself).")
            }

            infoCard(icon: "shield.checkered", color: .green) {
                Text("All processing happens on your iPad using Apple Intelligence. **No data ever leaves your device.**")
            }

            Text("Let's walk through three examples.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }

    // MARK: - Step 2: Two Documents

    private var twoDocsStep: some View {
        let docs = [DemoData.tripDoc, DemoData.teacherDoc]
        let titles = docs.map(\.title)

        return VStack(spacing: 20) {
            Label("Two contradictory documents", systemImage: "doc.on.doc.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            Text("Imagine a school sends these two communications about a field trip. Can you spot the contradictions?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(docs, id: \.id) { doc in
                    demoDocumentRow(doc: doc, allTitles: titles)
                }
            }

            Text("Tap **Next** to run the AI check.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Analyzing (reused for all 3 checks)

    private func analyzingStep(docs: [Document]) -> some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            ProgressView()
                .controlSize(.large)

            Text("Analyzing \(docs.count) document\(docs.count == 1 ? "" : "s")...")
                .font(.title3.weight(.medium))

            Text("The on-device AI is cross-referencing\ntext for factual contradictions.")
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
                withAnimation(.easeInOut(duration: 0.3)) {
                    if let next = step.nextStep {
                        step = next
                    }
                }
            }
        }
    }

    // MARK: - Step 4: Two-Doc Results

    private var twoDocsResultsStep: some View {
        let allTitles = [DemoData.tripDoc.title, DemoData.teacherDoc.title]

        return VStack(spacing: 20) {
            resultBanner(count: DemoData.twoDocIssues.count, docCount: 2, hasIssues: true)

            Text("The AI found these contradictions between the two school trip documents:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ForEach(Array(DemoData.twoDocIssues.enumerated()), id: \.offset) { index, issue in
                IssueCard(issue: issue, index: index + 1, allDocumentTitles: allTitles)
            }

            infoCard(icon: "lightbulb.fill", color: .orange) {
                Text("Each issue shows **which documents** conflict, **what text** contradicts, and a **suggested fix**. Colors are consistent per document.")
            }
        }
    }

    // MARK: - Step 5: Single Document

    private var singleDocStep: some View {
        let docs = [DemoData.campDoc]
        let titles = docs.map(\.title)

        return VStack(spacing: 20) {
            Label("Contradictions within one document", systemImage: "doc.text.fill")
                .font(.headline)
                .foregroundStyle(.purple)

            Text("Context Guard also catches contradictions **inside a single document**. This camp guide has several rules that contradict each other:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(docs, id: \.id) { doc in
                    demoDocumentRow(doc: doc, allTitles: titles)
                }
            }

            Text("Tap **Next** to find the internal contradictions.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Step 7: Single-Doc Results

    private var singleDocResultsStep: some View {
        let allTitles = [DemoData.campDoc.title]

        return VStack(spacing: 20) {
            resultBanner(count: DemoData.singleDocIssues.count, docCount: 1, hasIssues: true)

            Text("The AI found contradictions **within the same document** — the camp guide contradicts its own rules:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ForEach(Array(DemoData.singleDocIssues.enumerated()), id: \.offset) { index, issue in
                IssueCard(issue: issue, index: index + 1, allDocumentTitles: allTitles)
            }
        }
    }

    // MARK: - Step 8: Library Document (Clean)

    private var libraryDocStep: some View {
        let docs = [DemoData.libraryDoc]
        let titles = docs.map(\.title)

        return VStack(spacing: 20) {
            Label("A well-written document", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.green)

            Text("Not every document has contradictions. Here's a well-written library guide — let's see if the AI finds any issues:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(docs, id: \.id) { doc in
                    demoDocumentRow(doc: doc, allTitles: titles)
                }
            }

            Text("Tap **Next** to run the check.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Step 10: Library Results (All Clear)

    private var libraryDocResultsStep: some View {
        VStack(spacing: 20) {
            resultBanner(count: 0, docCount: 1, hasIssues: false)

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

            infoCard(icon: "info.circle.fill", color: .blue) {
                Text("When no contradictions are found, Context Guard confirms your document is consistent. This is the result you **want** to see for your own documents.")
            }
        }
    }

    // MARK: - Step 11: Tips

    private var tipsStep: some View {
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

            tipRow(icon: "folder.badge.plus", color: .blue,
                   title: "Import Files",
                   detail: "Tap **Select Files** to load .txt or .pdf documents from the Files app.")

            tipRow(icon: "camera.viewfinder", color: .green,
                   title: "Scan Paper",
                   detail: "Use your iPad camera to **scan printed handouts**, whiteboards, or notes. The built-in OCR converts them to text automatically.")

            tipRow(icon: "sparkle.magnifyingglass", color: .purple,
                   title: "Run the Check",
                   detail: "Load up to **3 documents**, then tap **Check for Contradictions**. Results appear in seconds.")

            tipRow(icon: "square.and.arrow.up", color: .orange,
                   title: "Export & Share",
                   detail: "Share your report via AirDrop, Messages, or save it to Files.")

            infoCard(icon: "lock.shield.fill", color: .blue) {
                Text("Everything runs **100% on-device** using Apple Intelligence. No internet connection needed. Your documents never leave your iPad.")
            }

            Button {
                dismiss()
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

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            // Back button — skips analyzing steps
            if let prev = step.previousStep, !step.isAnalyzing {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        step = prev
                    }
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
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if let next = step.nextStep {
                            step = next
                        }
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

    // MARK: - Reusable Components

    /// Tappable document row with mini page thumbnail. Opens preview sheet on tap.
    /// Color is consistent with what IssueCard will use for this filename.
    private func demoDocumentRow(doc: Document, allTitles: [String]) -> some View {
        let color = DocumentColorRegistry.color(for: doc.title, among: allTitles)

        return Button {
            previewDocument = doc
        } label: {
            HStack(spacing: 12) {
                // Mini page thumbnail
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.background)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                    Text(String(doc.content.prefix(100)))
                        .font(.system(size: 4, design: .monospaced))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .padding(4)
                }
                .frame(width: 40, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(color)

                    Text("\(doc.content.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func infoCard(icon: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 28)
                .padding(.top, 2)

            content()
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private func resultBanner(count: Int, docCount: Int, hasIssues: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: hasIssues ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                .font(.system(size: 32))
                .foregroundStyle(hasIssues ? .orange : .green)

            VStack(alignment: .leading, spacing: 2) {
                Text(hasIssues
                     ? "\(count) Issue\(count == 1 ? "" : "s") Found"
                     : "No Contradictions Found")
                    .font(.title3.bold())
                Text("Checked \(docCount) document\(docCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func tipRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(.init(detail))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - Demo Data (all mocked — no LLM calls)

@available(iOS 26.0, *)
enum DemoData {

    // --- Two-document demo: school trip ---

    static let tripDoc = Document(
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
    )

    static let teacherDoc = Document(
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
        """
    )

    static let twoDocIssues: [ConsistencyIssue] = [
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

    // --- Single-document demo: camp guide ---

    static let campDoc = Document(
        id: UUID(),
        title: "Summer_Camp_Guide.txt",
        content: """
        WELCOME TO THE 5-DAY ART CAMP

        CAMP OVERVIEW:
        This camp lasts for five full days, from Monday until Friday. \
        We have a lot of fun activities planned for you!

        WEEKLY SCHEDULE:
        Day 1: Painting with water colors in the garden.
        Day 2: Making bowls out of wet clay.
        Day 3: Drawing animals with colored pencils.
        (This is the end of our activity list for the week).

        CAMP RULES:
        - You must always wear a sun hat when you are outside.
        - No candy, soda, or sugary snacks are allowed in the camp building.

        THE CAMP SHOP:
        - The shop is open every afternoon for students to buy snacks.
        - Please bring $5 every day so you can buy candy and soda.
        - Hats are not allowed at camp.

        GRADING AND PRIZES:
        At the end of the week, everyone gets a "Gold Star" for finishing. \
        There are no tests at this camp. We just want you to have fun.

        FINAL TEST DETAILS:
        - The final exam is on Friday afternoon in the main hall.
        - You must pass this test to get your "Gold Star."
        """
    )

    static let singleDocIssues: [ConsistencyIssue] = [
        ConsistencyIssue(
            severity: "HIGH",
            rationale: "The snack policy directly contradicts the camp shop description.",
            sourceText: "No candy, soda, or sugary snacks are allowed in the camp building",
            sourceDocument: "Summer_Camp_Guide.txt",
            targetText: "bring $5 every day so you can buy candy and soda",
            targetDocument: "Summer_Camp_Guide.txt",
            suggestedFix: "Decide whether candy and soda are banned or sold — remove one of the conflicting statements."
        ),
        ConsistencyIssue(
            severity: "HIGH",
            rationale: "The hat policy contradicts itself within the same document.",
            sourceText: "You must always wear a sun hat when you are outside",
            sourceDocument: "Summer_Camp_Guide.txt",
            targetText: "Hats are not allowed at camp",
            targetDocument: "Summer_Camp_Guide.txt",
            suggestedFix: "Clarify whether hats are required outside or banned entirely."
        ),
        ConsistencyIssue(
            severity: "HIGH",
            rationale: "The grading section says there are no tests, but then describes a final exam.",
            sourceText: "There are no tests at this camp",
            sourceDocument: "Summer_Camp_Guide.txt",
            targetText: "The final exam is on Friday afternoon",
            targetDocument: "Summer_Camp_Guide.txt",
            suggestedFix: "Remove either the 'no tests' claim or the final exam details."
        ),
    ]

    // --- Clean document demo: library guide (no contradictions) ---

    static let libraryDoc = Document(
        id: UUID(),
        title: "City_Library_Guide.txt",
        content: """
        WELCOME TO THE CENTRAL CITY LIBRARY

        GENERAL INFORMATION:
        The Central City Library is a place for everyone to read, study, and learn. \
        We are open 6 days a week, from Monday to Saturday. Please note that the \
        library is always closed on Sundays to allow for deep cleaning and shelf organizing.

        OPERATING HOURS:
        - Monday to Friday: 9:00 AM to 8:00 PM
        - Saturday: 10:00 AM to 4:00 PM
        - Sunday: Closed

        BORROWING RULES:
        Every member can borrow up to 10 books at one time. Books must be returned \
        within 14 days. If you need more time, you can renew your books once through \
        our website or by visiting the front desk.

        FACILITY RULES:
        1. Keep your voice at a whisper to respect other readers.
        2. Cell phones must be set to silent mode at all times.
        3. No food or drinks are allowed near the computers or the rare book section.
        4. Bottled water is permitted only in the main seating area.

        THE CHILDREN'S CORNER:
        The Children's Corner is located on the first floor. It is a special area \
        designed for kids aged 3 to 12. We have over 5,000 picture books and \
        educational games available.

        WEEKLY CHILDREN'S EVENTS:
        - Story Time: Tuesday mornings at 10:30 AM.
        - Puppet Show: Thursday afternoons at 2:00 PM.
        - Lego Club: Saturday mornings at 11:00 AM.

        STUDY ROOMS:
        We offer 8 private study rooms for group work. You can book a study room \
        for a maximum of 2 hours per day. Reservations can be made up to one week \
        in advance at the information desk.

        MEMBERSHIP FEES:
        Membership is completely free for all city residents. You just need to show \
        a valid ID and proof of address to get your library card. Non-residents can \
        join for a small fee of $20 per year.
        """
    )
}

// MARK: - Previews

@available(iOS 26.0, *)
#Preview("Demo Flow") {
    DemoFlowView(checker: ConsistencyChecker())
}
