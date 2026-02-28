//
//  SwiftUIView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 28.02.26.
//

import SwiftUI

/// Full-text preview of a loaded document, presented as a sheet.
///
/// Why a sheet and not QuickLook?
/// Our Documents hold in-memory text strings, not file URLs.
/// QLPreviewController requires a URL on disk. We'd have to write
/// to a temp file just to show it — wasteful and fragile.
/// A sheet is instant, works in simulator, and we control the styling.
struct DocumentPreviewSheet: View {
    let document: Document
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(document.content)
                    .font(.body)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview("Document Preview") {
    DocumentPreviewSheet(
        document: Document(
            id: UUID(),
            title: "DocA_Penguins.txt",
            content: """
            Emperor penguins are the tallest of all penguin species, reaching nearly 4 feet \
            in height. They are native to Antarctica, where they endure harsh winters with \
            temperatures dropping to minus 60 degrees Celsius.
            
            Emperor penguins breed during the Antarctic winter, with males incubating eggs \
            on their feet for over two months. Their diet consists primarily of fish, squid, \
            and krill found in the Southern Ocean.
            """
        )
    )
}
