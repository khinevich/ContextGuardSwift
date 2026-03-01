//
//  ConsistencyIssue.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable(description: "A factual contradiction between two text passages")
struct ConsistencyIssue {
    @Guide(description: "Exactly one of: HIGH, MEDIUM, LOW. HIGH = direct factual conflict (place A vs place B). MEDIUM = numerical or temporal mismatch (date, price, time). LOW = minor or implicit conflict.")
    var severity: String

    @Guide(description: "One short sentence: what exactly contradicts. Example: 'The trip destination differs between the two documents.'")
    var rationale: String

    @Guide(description: "The exact short phrase from the FIRST document that contradicts. Under 15 words. Copy verbatim from the input text.")
    var sourceText: String

    @Guide(description: "The filename (e.g. 'Report.txt') of the first document. Must match a filename from the input chunk tags.")
    var sourceDocument: String

    @Guide(description: "The exact short phrase from the SECOND document that contradicts. Under 15 words. Copy verbatim from the input text.")
    var targetText: String

    @Guide(description: "The filename (e.g. 'Notes.txt') of the second document. Must match a filename from the input chunk tags. Can be the same as sourceDocument for internal contradictions.")
    var targetDocument: String

    @Guide(description: "One concrete action to resolve the contradiction. Example: 'Confirm whether the trip is to the museum or water park and update both documents.'")
    var suggestedFix: String
}

#else

// Fallback when FoundationModels is not available (Swift Playgrounds, older Xcode)
struct ConsistencyIssue {
    var severity: String
    var rationale: String
    var sourceText: String
    var sourceDocument: String
    var targetText: String
    var targetDocument: String
    var suggestedFix: String
}

#endif
