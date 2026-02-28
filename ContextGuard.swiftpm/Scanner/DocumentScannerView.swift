//
//  SwiftUIView.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import SwiftUI

import VisionKit
import Vision

struct DocumentScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    var onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }
    
    @MainActor
    class Coordinator: NSObject, @MainActor VNDocumentCameraViewControllerDelegate {
        let onScan: (String) -> Void
        let onCancel: () -> Void
        
        init(onScan: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onScan = onScan
            self.onCancel = onCancel
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            
            var fullText = ""
            
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                
                guard let cgImage = image.cgImage else { continue }
                
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
                
                if let observations = request.results {
                    for observation in observations {
                        if let text = observation.topCandidates(1).first?.string {
                            fullText += text + "\n"
                        }
                    }
                }
                
                fullText += "\n"
            }
            
            onScan(fullText)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Scanner failed with error: \(error.localizedDescription)")
            onCancel()
        }
    }
}
