//
//  SwiftUIView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import SwiftUI

struct DocumentRowView: View {
    let document: Document
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .font(.subheadline.weight(.medium))
                
                Text("\(document.content.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview("Document Row") {
    VStack(spacing: 8) {
        DocumentRowView(document: Document(id: UUID(), title: "DocA_Penguins.txt", content: String(repeating: "x", count: 847)))
        DocumentRowView(document: Document(id: UUID(), title: "Lecture_Notes_Week3.pdf", content: String(repeating: "x", count: 3201)))
    }
    .padding(40)
}
