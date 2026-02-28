//
//  SwiftUIView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import SwiftUI

/// A single document row in the loaded documents list.
///
/// Adapts to size class:
/// - iPhone (compact): icon + title + char count — same compact style
/// - iPad (regular): taller row with a mini page thumbnail on the left
///   showing real document text, plus a first-line preview
struct DocumentRowView: View {
    let document: Document
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    private var isCompact: Bool { sizeClass == .compact }
    
    var body: some View {
        HStack(spacing: isCompact ? 12 : 16) {
            if isCompact {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(.blue)
            } else {
                miniPagePreview
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .font(isCompact ? .subheadline.weight(.medium) : .body.weight(.medium))
                
                Text("\(document.content.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // iPad only: show first line of content
                if !isCompact {
                    Text(document.content.prefix(80).replacingOccurrences(of: "\n", with: " "))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Chevron hints that tapping opens a preview
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(isCompact ? 12 : 16)
        .frame(minHeight: isCompact ? 44 : 80)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    /// Mini page thumbnail for iPad — renders real document text at tiny size.
    private var miniPagePreview: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            
            Text(String(document.content.prefix(100)))
                .font(.system(size: 4, design: .monospaced))
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(4)
        }
        .frame(width: 44, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}

#Preview("Document Row — iPhone") {
    VStack(spacing: 8) {
        DocumentRowView(document: Document(id: UUID(), title: "DocA_Penguins.txt", content: "Emperor penguins are native to Antarctica..."))
        DocumentRowView(document: Document(id: UUID(), title: "Lecture_Notes.pdf", content: String(repeating: "x", count: 3201)))
    }
    .padding(20)
    .environment(\.horizontalSizeClass, .compact)
}

#Preview("Document Row — iPad") {
    VStack(spacing: 8) {
        DocumentRowView(document: Document(id: UUID(), title: "DocA_Penguins.txt", content: "Emperor penguins are the tallest of all penguin species, reaching nearly 4 feet in height. They are native to Antarctica."))
        DocumentRowView(document: Document(id: UUID(), title: "Lecture_Notes.pdf", content: "Business Analytics and Machine Learning. Tutorial sheet 11. Solutions and worked examples."))
    }
    .padding(40)
    .environment(\.horizontalSizeClass, .regular)
}
