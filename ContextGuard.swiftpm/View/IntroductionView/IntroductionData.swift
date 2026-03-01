//
//  IntroductionData.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 28.02.26.
//

import SwiftUI

// MARK: - Demo Steps

@available(iOS 26.0, *)
enum DemoStep: Int, CaseIterable {
    case welcome
    case twoDocs
    case twoDocsAnalyzing
    case twoDocsResults
    case singleDoc
    case singleDocAnalyzing
    case singleDocResults
    case libraryDoc
    case libraryDocAnalyzing
    case libraryDocResults
    case tips

    var title: String {
        switch self {
        case .welcome:              return "Welcome"
        case .twoDocs:              return "Multi-Document Check"
        case .twoDocsAnalyzing:     return "Analyzing..."
        case .twoDocsResults:       return "Contradictions Found"
        case .singleDoc:            return "Single-Document Check"
        case .singleDocAnalyzing:   return "Analyzing..."
        case .singleDocResults:     return "Internal Contradictions"
        case .libraryDoc:           return "Clean Document"
        case .libraryDocAnalyzing:  return "Analyzing..."
        case .libraryDocResults:    return "All Clear"
        case .tips:                 return "You're Ready"
        }
    }

    var isAnalyzing: Bool {
        self == .twoDocsAnalyzing || self == .singleDocAnalyzing || self == .libraryDocAnalyzing
    }

    var previousStep: DemoStep? {
        switch self {
        case .welcome:              return nil
        case .twoDocs:              return .welcome
        case .twoDocsAnalyzing:     return .twoDocs
        case .twoDocsResults:       return .twoDocs
        case .singleDoc:            return .twoDocsResults
        case .singleDocAnalyzing:   return .singleDoc
        case .singleDocResults:     return .singleDoc
        case .libraryDoc:           return .singleDocResults
        case .libraryDocAnalyzing:  return .libraryDoc
        case .libraryDocResults:    return .libraryDoc
        case .tips:                 return .libraryDocResults
        }
    }

    var nextStep: DemoStep? {
        DemoStep(rawValue: rawValue + 1)
    }
}

// MARK: - Demo Data

@available(iOS 26.0, *)
enum DemoData {

    static func loadTextResource(_ name: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return text
    }

    // MARK: - Two-Document Demo

    static let tripDoc = Document(
        id: UUID(),
        title: "DemoScienceMuseumTrip.txt",
        content: loadTextResource("DemoScienceMuseumTrip") ?? tripFallback
    )

    static let teacherDoc = Document(
        id: UUID(),
        title: "DemoTeacherTripUpdate.txt",
        content: loadTextResource("DemoTeacherTripUpdate") ?? teacherFallback
    )

    static let twoDocIssues: [ConsistencyIssue] = [
        ConsistencyIssue(
            severity: "HIGH",
            rationale: "The trip destination is completely different across the two documents.",
            sourceText: "trip to the Science Museum in the city center",
            sourceDocument: "DemoScienceMuseumTrip.txt",
            targetText: "trip to the Water Park at the beach",
            targetDocument: "DemoTeacherTripUpdate.txt",
            suggestedFix: "Confirm the actual destination — Science Museum or Water Park — and update both documents."
        ),
        ConsistencyIssue(
            severity: "MEDIUM",
            rationale: "The trip date and departure time are contradictory.",
            sourceText: "Monday, June 1st at 8:00 AM",
            sourceDocument: "DemoScienceMuseumTrip.txt",
            targetText: "Wednesday, June 3rd at 10:00 AM",
            targetDocument: "DemoTeacherTripUpdate.txt",
            suggestedFix: "Align the trip date — parents need one consistent date and time."
        ),
        ConsistencyIssue(
            severity: "MEDIUM",
            rationale: "The food instructions directly contradict each other.",
            sourceText: "bring a packed lunch from home",
            sourceDocument: "DemoScienceMuseumTrip.txt",
            targetText: "You do not need to bring food",
            targetDocument: "DemoTeacherTripUpdate.txt",
            suggestedFix: "Clarify whether students should pack lunch or if food is provided."
        ),
        ConsistencyIssue(
            severity: "MEDIUM",
            rationale: "The dress code contradicts across documents.",
            sourceText: "must wear their blue school uniform",
            sourceDocument: "DemoScienceMuseumTrip.txt",
            targetText: "Do not wear your school uniform",
            targetDocument: "DemoTeacherTripUpdate.txt",
            suggestedFix: "Specify one dress code — school uniform or swimming clothes."
        ),
    ]

    // MARK: - Single-Document Demo

    static let campDoc = Document(
        id: UUID(),
        title: "DemoSummerCampGuide.txt",
        content: loadTextResource("DemoSummerCampGuide") ?? campFallback
    )

    static let singleDocIssues: [ConsistencyIssue] = [
        ConsistencyIssue(
            severity: "HIGH",
            rationale: "The snack policy directly contradicts the camp shop description.",
            sourceText: "No candy, soda, or sugary snacks are allowed",
            sourceDocument: "DemoSummerCampGuide.txt",
            targetText: "buy candy and soda",
            targetDocument: "DemoSummerCampGuide.txt",
            suggestedFix: "Decide whether candy and soda are banned or sold — remove one of the conflicting statements."
        ),
        ConsistencyIssue(
            severity: "HIGH",
            rationale: "The hat policy contradicts itself within the same document.",
            sourceText: "must always wear a sun hat",
            sourceDocument: "DemoSummerCampGuide.txt",
            targetText: "Hats are not allowed at camp",
            targetDocument: "DemoSummerCampGuide.txt",
            suggestedFix: "Clarify whether hats are required outside or banned entirely."
        ),
        ConsistencyIssue(
            severity: "HIGH",
            rationale: "The grading section says there are no tests, but then describes a final exam.",
            sourceText: "There are no tests at this camp",
            sourceDocument: "DemoSummerCampGuide.txt",
            targetText: "The final exam is on Friday afternoon",
            targetDocument: "DemoSummerCampGuide.txt",
            suggestedFix: "Remove either the 'no tests' claim or the final exam details."
        ),
    ]

    // MARK: - Clean Document Demo

    static let libraryDoc = Document(
        id: UUID(),
        title: "DemoCityLibraryGuide.txt",
        content: loadTextResource("DemoCityLibraryGuide") ?? libraryFallback
    )

    // MARK: - Fallbacks

    private static let tripFallback = """
        SUMMER SCHOOL TRIP: SCIENCE MUSEUM

        Dear Parents,
        We are excited to go on a trip to the Science Museum in the city center. \
        The bus will leave from the school gate on Monday, June 1st at 8:00 AM. \
        We will return to the school by 3:30 PM on the same day.

        WHAT TO BRING:
        - The cost of the trip is $15 per student.
        - Please bring a packed lunch from home. The museum cafe is currently closed.
        - Students must wear their blue school uniform so we can stay together.
        """

    private static let teacherFallback = """
        TRIP UPDATE: WATER PARK ADVENTURE

        Hi Class,
        Here is the final plan for our big trip to the Water Park at the beach! \
        The train leaves from the station on Wednesday, June 3rd at 10:00 AM. \
        We will get back to the school very late, around 7:00 PM.

        COST AND FOOD:
        - The price is $30 for each person. This includes your ticket and a locker.
        - You do not need to bring food. We will all eat lunch together at the \
        park restaurant. The meal is included in the price.

        CLOTHING:
        - Please wear your favorite swimming clothes and a bright t-shirt.
        - Do not wear your school uniform because it will get wet and messy.
        """

    private static let campFallback = """
        WELCOME TO THE 5-DAY ART CAMP

        CAMP RULES:
        - You must always wear a sun hat when you are outside.
        - No candy, soda, or sugary snacks are allowed in the camp building.

        THE CAMP SHOP:
        - Please bring $5 every day so you can buy candy and soda.
        - Hats are not allowed at camp.

        GRADING AND PRIZES:
        There are no tests at this camp. We just want you to have fun.

        FINAL TEST DETAILS:
        - The final exam is on Friday afternoon in the main hall.
        """

    private static let libraryFallback = """
        WELCOME TO THE CENTRAL CITY LIBRARY

        OPERATING HOURS:
        - Monday to Friday: 9:00 AM to 8:00 PM
        - Saturday: 10:00 AM to 4:00 PM
        - Sunday: Closed

        BORROWING RULES:
        Every member can borrow up to 10 books at one time. Books must be returned \
        within 14 days.

        MEMBERSHIP FEES:
        Membership is completely free for all city residents. Non-residents can \
        join for a small fee of $20 per year.
        """
}
