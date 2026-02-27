//
//  File.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
@Generable(description: "A contradiction found between documents")
struct ConsistencyIssue {
    @Guide(description: "HIGH, MEDIUM, or LOW")
    var severity: String
    
    @Guide(description: "One sentence explaining the contradiction")
    var rationale: String
    
    @Guide(description: "The contradicting text from the first source")
    var sourceText: String
    
    @Guide(description: "Document name of the first source")
    var sourceDocument: String
    
    @Guide(description: "The contradicting text from the second source")
    var targetText: String
    
    @Guide(description: "Document name of the second source")
    var targetDocument: String
    
    @Guide(description: "How to fix this contradiction")
    var suggestedFix: String
}
