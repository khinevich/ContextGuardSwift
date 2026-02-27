//
//  File.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import Foundation

enum CheckingState {
    case idle
    case analyzing
    case completed
    case failed(String)
}

@available(iOS 26.0, *)
@Observable
class ConsistencyChecker {
    var documents: [Document] = []
    var issues: [ConsistencyIssue] = []
    var state: CheckingState = .idle
    
    func addDocument(_ document: Document) {
        documents.append(document)
    }
    
    func clear() {
        documents.removeAll()
        issues.removeAll()
        state = .idle
    }
    
//    func loadDemo() {
//        clear()
//        
//        if let pathA = Bundle.main.url(forResource: "DocA_Penguins", withExtension: "txt"),
//           let textA = try? String(contentsOf: pathA, encoding: .utf8) {
//            addDocument(Document(id: UUID(), title: "DocA_Penguins.txt", content: textA))
//        }
//        
//        if let pathB = Bundle.main.url(forResource: "DocB_Penguins", withExtension: "txt"),
//           let textB = try? String(contentsOf: pathB, encoding: .utf8) {
//            addDocument(Document(id: UUID(), title: "DocB_Penguins.txt", content: textB))
//        }
//    }
        
    func runCheck() async {
        state = .analyzing
        issues.removeAll()
        
        //TODO LanguageModelSession call
        
        state = .completed
    }
}
