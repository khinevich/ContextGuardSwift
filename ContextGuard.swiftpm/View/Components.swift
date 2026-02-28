import SwiftUI

// MARK: - Document Color Registry

/// Assigns consistent neutral colors and labels (Document A, B, C...) to documents.
/// The same filename always gets the same color and letter across all issue cards.
struct DocumentColorRegistry {
    /// Neutral palette — avoids red/orange/yellow which are reserved for severity.
    static let palette: [Color] = [
        Color(red: 0.37, green: 0.55, blue: 0.85),  // Blue
        Color(red: 0.55, green: 0.40, blue: 0.80),  // Purple
        Color(red: 0.25, green: 0.65, blue: 0.65),  // Teal
        Color(red: 0.80, green: 0.50, blue: 0.25),  // Amber
        Color(red: 0.45, green: 0.65, blue: 0.40),  // Green
    ]

    private static func uniqueOrdered(_ titles: [String]) -> [String] {
        var seen = Set<String>()
        return titles.filter { seen.insert($0).inserted }
    }

    static func color(for title: String, among allTitles: [String]) -> Color {
        let ordered = uniqueOrdered(allTitles)
        let index = ordered.firstIndex(of: title) ?? 0
        return palette[index % palette.count]
    }
}

// MARK: - Action Card

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(subtitle)")
    }
}

// MARK: - Issue Card

@available(iOS 26.0, *)
struct IssueCard: View {
    let issue: ConsistencyIssue
    let index: Int
    let allDocumentTitles: [String]

    @State private var isExpanded = true
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isCompact: Bool { sizeClass == .compact }

    // Severity colors — red/orange/yellow only for the badge, never for documents
    private var severityColor: Color {
        switch issue.severity.uppercased() {
        case "HIGH":   return .red
        case "MEDIUM": return .orange
        case "LOW":    return Color(red: 0.82, green: 0.68, blue: 0.15)
        default:       return .gray
        }
    }

    private var severityIcon: String {
        switch issue.severity.uppercased() {
        case "HIGH", "MEDIUM", "LOW": return "exclamationmark"
        default: return "questionmark"
        }
    }

    // Document colors — neutral palette, consistent per filename
    private var sourceColor: Color {
        DocumentColorRegistry.color(for: issue.sourceDocument, among: allDocumentTitles)
    }
    private var targetColor: Color {
        DocumentColorRegistry.color(for: issue.targetDocument, among: allDocumentTitles)
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                header
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                expandedContent
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(severityColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: severityIcon)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(severityColor, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("Issue #\(index)")
                    .font(.subheadline.weight(.medium))

                Text(issue.rationale)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(isExpanded ? nil : 1)
            }

            Spacer()

            Text(issue.severity.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(severityColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(severityColor.opacity(0.12), in: Capsule())

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .padding(16)
    }

    // MARK: Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            contradictionComparison
            suggestedFixSection
        }
        .padding(16)
    }

    @ViewBuilder
    private var contradictionComparison: some View {
        if isCompact {
            VStack(spacing: 12) {
                contradictionBlock(
                    documentTitle: issue.sourceDocument,
                    paragraph: issue.sourceParagraph,
                    text: issue.sourceText,
                    color: sourceColor
                )
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                contradictionBlock(
                    documentTitle: issue.targetDocument,
                    paragraph: issue.targetParagraph,
                    text: issue.targetText,
                    color: targetColor
                )
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                contradictionBlock(
                    documentTitle: issue.sourceDocument,
                    paragraph: issue.sourceParagraph,
                    text: issue.sourceText,
                    color: sourceColor
                )
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 28)
                contradictionBlock(
                    documentTitle: issue.targetDocument,
                    paragraph: issue.targetParagraph,
                    text: issue.targetText,
                    color: targetColor
                )
            }
        }
    }

    private var suggestedFixSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Suggested Fix", systemImage: "lightbulb.fill")
                .font(.caption.bold())
                .foregroundStyle(.green)

            Text(issue.suggestedFix)
                .font(.callout)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    /// Each contradiction block shows:
    /// 1. **Filename** — big title, colored (the primary identifier)
    /// 2. **Paragraph N** — small subtitle showing chunk location
    /// 3. **Quoted text** — the contradicting passage
    private func contradictionBlock(
        documentTitle: String,
        paragraph: Int,
        text: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Filename only, colored to match this document everywhere
            Text(documentTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)

            // Paragraph location from chunk data
            Text("Paragraph \(paragraph)")
                .font(.caption2.bold())
                .foregroundStyle(color.opacity(0.7))

            // Quoted contradicting text
            Text("\"\(text)\"")
                .font(.callout)
                .italic()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

@available(iOS 26.0, *)
#Preview("Action Cards") {
    HStack(spacing: 20) {
        ActionCard(icon: "folder.badge.plus", title: "Import Files", subtitle: "Select .txt or .pdf", color: .blue) {}
        ActionCard(icon: "document.viewfinder", title: "Scan Files", subtitle: "Use device camera", color: .green) {}
    }
    .padding(40)
}

@available(iOS 26.0, *)
#Preview("Issue Card — HIGH") {
    IssueCard(
        issue: ConsistencyIssue(
            severity: "HIGH",
            rationale: "The habitat of Emperor penguins is described contradictorily across documents.",
            sourceText: "They are native to Antarctica",
            sourceDocument: "DocA_Penguins.txt",
            targetText: "Emperor penguins are commonly found in the Arctic region",
            targetDocument: "DocB_Penguins.txt",
            suggestedFix: "Verify the correct habitat. Emperor penguins are native to Antarctica, not the Arctic.",
            sourceParagraph: 1,
            targetParagraph: 2
        ),
        index: 1,
        allDocumentTitles: ["DocA_Penguins.txt", "DocB_Penguins.txt"]
    )
    .padding(40)
}

@available(iOS 26.0, *)
#Preview("Same Document — MEDIUM") {
    IssueCard(
        issue: ConsistencyIssue(
            severity: "MEDIUM",
            rationale: "Paragraph 2 contradicts paragraph 5 within the same document.",
            sourceText: "The project deadline is March 15th",
            sourceDocument: "Meeting_Notes.txt",
            targetText: "Final submission is due by April 1st",
            targetDocument: "Meeting_Notes.txt",
            suggestedFix: "Clarify the actual deadline.",
            sourceParagraph: 2,
            targetParagraph: 5
        ),
        index: 2,
        allDocumentTitles: ["Meeting_Notes.txt"]
    )
    .padding(40)
}
