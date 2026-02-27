//
//  SwiftUIView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            
            Text("Something went wrong")
                .font(.title2.weight(.medium))
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Try Again", action: onRetry)
                .buttonStyle(.bordered)
            
            Spacer()
        }
    }
}

#Preview("Error") {
    NavigationStack {
        ErrorView(message: "Apple Intelligence is not available on this device. Please enable it in Settings.") {}
            .navigationTitle("Context Guard")
    }
}
