//
//  IntroductionComponents.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 28.02.26.
//

import SwiftUI

@available(iOS 26.0, *)
struct InfoCard<Content: View>: View {
    let icon: String
    let color: Color
    let content: Content

    init(icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.color = color
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 28)
                .padding(.top, 2)

            content
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

@available(iOS 26.0, *)
struct ResultBanner: View {
    let count: Int
    let docCount: Int
    let hasIssues: Bool

    var body: some View {
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
}

@available(iOS 26.0, *)
struct TipRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
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

@available(iOS 26.0, *)
struct DemoDocumentRow: View {
    let doc: Document
    let allTitles: [String]
    let action: () -> Void

    var body: some View {
        let color = DocumentColorRegistry.color(for: doc.title, among: allTitles)

        return Button(action: action) {
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
}
