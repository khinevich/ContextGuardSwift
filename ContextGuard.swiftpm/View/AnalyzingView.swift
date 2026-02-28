//
//  SwiftUIView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import SwiftUI

struct AnalyzingView: View {
    let documents: [Document]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .controlSize(.large)
            
            Text("Analyzing documents...")
                .font(.title2.weight(.medium))
            
            Text("The on-device AI is cross-referencing\nyour documents for contradictions.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                ForEach(documents, id: \.id) { doc in
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
            .padding(.top, 16)
            
            Spacer()
        }
        .padding(40)
    }
}

#Preview("Analyzing") {
    NavigationStack {
        AnalyzingView(documents: [
            Document(id: UUID(), title: "DocA_Penguins.txt", content: ""),
            Document(id: UUID(), title: "DocB_Penguins.txt", content: "")
        ])
        .navigationTitle("Context Guard")
    }
}
