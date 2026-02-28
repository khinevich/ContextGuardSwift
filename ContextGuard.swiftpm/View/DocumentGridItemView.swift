//
//  SwiftUIView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 28.02.26.
//

import SwiftUI

/// iPad-only grid card mimicking the Files app icon layout.
/// Shows a "page" with faded text lines as a visual preview,
/// with the filename and character count below.
///
/// The page thumbnail uses real document text rendered at tiny font size
/// so each card looks unique — just like Files app thumbnails show
/// actual document content.
struct DocumentGridItemView: View {
    let document: Document
    
    var body: some View {
        VStack(spacing: 8) {
            pageThumbnail
            
            Text(document.title)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Text("\(document.content.count) chars")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 140)
    }
    
    // MARK: - Page Thumbnail
    
    /// A white rectangle with clipped text that looks like a real document page.
    private var pageThumbnail: some View {
        ZStack(alignment: .topLeading) {
            // Page background
            RoundedRectangle(cornerRadius: 8)
                .fill(.background)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            
            // Actual document text at tiny size — gives each page a unique look
            Text(String(document.content.prefix(300)))
                .font(.system(size: 5, design: .monospaced))
                .foregroundStyle(.secondary.opacity(0.6))
                .lineSpacing(1)
                .padding(8)
            
            // Corner fold triangle (top-right)
            VStack {
                HStack {
                    Spacer()
                    Triangle()
                        .fill(.gray.opacity(0.15))
                        .frame(width: 16, height: 16)
                }
                Spacer()
            }
        }
        .frame(width: 120, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}

/// Small triangle for the page fold effect in the top-right corner.
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview("Grid Items") {
    HStack(spacing: 24) {
        DocumentGridItemView(document: Document(
            id: UUID(),
            title: "DocA_Penguins.txt",
            content: "Emperor penguins are the tallest of all penguin species, reaching nearly 4 feet in height. They are native to Antarctica."
        ))
        DocumentGridItemView(document: Document(
            id: UUID(),
            title: "DocB_Penguins.txt",
            content: "Emperor penguins are commonly found in the Arctic region, where they coexist with polar bears and other Arctic wildlife."
        ))
        DocumentGridItemView(document: Document(
            id: UUID(),
            title: "Lecture_Notes.pdf",
            content: "Business Analytics and Machine Learning. Tutorial sheet 11. Principal component analysis solutions."
        ))
    }
    .padding(40)
    .background(Color(.systemGroupedBackground))
}
