//
//  SwiftUIView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import SwiftUI

// MARK: - Action Card (Home Screen Buttons)

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

// MARK: - Issue Card (Results Screen)

struct IssueCard: View {
    let issue: ConsistencyIssue
    let index: Int
    
    @State private var isExpanded = true
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    private var isCompact: Bool { sizeClass == .compact }
    
    var severityColor: Color {
        switch issue.severity.uppercased() {
        case "HIGH": return .red
        case "MEDIUM": return .orange
        case "LOW": return Color(red: 0.82, green: 0.68, blue: 0.15)
        default: return .gray
        }
    }
    
    var severityIcon: String {
        switch issue.severity.uppercased() {
        case "HIGH": return "exclamationmark"
        case "MEDIUM": return "exclamationmark"
        case "LOW": return "exclamationmark"
        default: return "questionmark"
        }
    }
    
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
    
    // MARK: - Header
    
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
    
    // MARK: - Expanded Content
    
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
            // iPhone: stack vertically
            VStack(spacing: 12) {
                contradictionBlock(
                    label: "Source",
                    document: issue.sourceDocument,
                    text: issue.sourceText,
                    color: .red
                )
                
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                
                contradictionBlock(
                    label: "Target",
                    document: issue.targetDocument,
                    text: issue.targetText,
                    color: .blue
                )
            }
        } else {
            // iPad: side by side
            HStack(alignment: .top, spacing: 12) {
                contradictionBlock(
                    label: "Source",
                    document: issue.sourceDocument,
                    text: issue.sourceText,
                    color: .red
                )
                
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 24)
                
                contradictionBlock(
                    label: "Target",
                    document: issue.targetDocument,
                    text: issue.targetText,
                    color: .blue
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
    
    private func contradictionBlock(label: String, document: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(color)
            
            Text(document)
                .font(.caption)
                .foregroundStyle(.secondary)
            
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

#Preview("Action Cards — iPad") {
    HStack(spacing: 20) {
        ActionCard(icon: "folder.badge.plus", title: "Select Files", subtitle: "Import .txt or .pdf", color: .blue) {}
        ActionCard(icon: "camera.viewfinder", title: "Scan Paper", subtitle: "Use iPad camera", color: .green) {}
    }
    .padding(40)
}

#Preview("Issue Card — HIGH") {
    IssueCard(
        issue: ConsistencyIssue(
            severity: "HIGH",
            rationale: "The habitat of Emperor penguins is described contradictorily across documents.",
            sourceText: "They are native to Antarctica",
            sourceDocument: "DocA_Penguins.txt",
            targetText: "Emperor penguins are commonly found in the Arctic region",
            targetDocument: "DocB_Penguins.txt",
            suggestedFix: "Verify the correct habitat. Emperor penguins are native to Antarctica, not the Arctic."
        ),
        index: 1
    )
    .padding(40)
}

#Preview("Issue Card — LOW") {
    IssueCard(
        issue: ConsistencyIssue(
            severity: "LOW",
            rationale: "Diet sources differ between documents.",
            sourceText: "fish, squid, and krill found in the Southern Ocean",
            sourceDocument: "DocA_Penguins.txt",
            targetText: "freshwater fish from Arctic rivers and lakes",
            targetDocument: "DocB_Penguins.txt",
            suggestedFix: "Align diet descriptions. Emperor penguins feed in the Southern Ocean, not Arctic freshwater."
        ),
        index: 3
    )
    .padding(40)
}

#Preview("Same Document Issue - MEDIUM") {
    IssueCard(
        issue: ConsistencyIssue(
            severity: "MEDIUM",
            rationale: "Paragraph 2 contradicts paragraph 5 within the same document.",
            sourceText: "The project deadline is March 15th",
            sourceDocument: "Meeting_Notes.txt",
            targetText: "Final submission is due by April 1st",
            targetDocument: "Meeting_Notes.txt",
            suggestedFix: "Clarify the actual deadline — March 15th and April 1st cannot both be correct."
        ),
        index: 2
    )
    .padding(40)
}
