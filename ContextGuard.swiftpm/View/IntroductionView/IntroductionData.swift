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

    /// Back navigation skips analyzing steps so user doesn't land on a spinner.
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

// MARK: - Demo Data (all mocked — no LLM calls)

@available(iOS 26.0, *)
enum DemoData {

    // --- Two-document demo: school trip ---

    static let tripDoc = Document(
        id: UUID(),
        title: "Science_Museum_Trip.txt",
        content: """
        SUMMER SCHOOL TRIP: SCIENCE MUSEUM

        Dear Parents,
        We are excited to go on a trip to the Science Museum in the city center. 
        The bus will leave from the school gate on Monday, June 1st at 8:00 AM. 
        We will return to the school by 3:30 PM on the same day.

        WHAT TO BRING:
        - The cost of the trip is $15 per student.
        - Please bring a packed lunch from home. The museum cafe is currently closed.
        - Students must wear their blue school uniform so we can stay together.

        GOAL:
        The goal is to learn about space and the planets. This trip is part of our 
        science class. We hope every student can join us for this fun day of learning!
        """
    )

    static let teacherDoc = Document(
        id: UUID(),
        title: "Teacher_Trip_Update.txt",
        content: """
        TRIP UPDATE: WATER PARK ADVENTURE

        Hi Class,
        Here is the final plan for our big trip to the Water Park at the beach! 
        The train leaves from the station on Wednesday, June 3rd at 10:00 AM. 
        We will get back to the school very late, around 7:00 PM.

        COST AND FOOD:
        - The price is $30 for each person. This includes your ticket and a locker.
        - You do not need to bring food. We will all eat lunch together at the 
        park restaurant. The meal is included in the price.

        CLOTHING:
        - Please wear your favorite swimming clothes and a bright t-shirt.
        - Do not wear your school uniform because it will get wet and messy.
        """
    )

    static let twoDocIssues: [ConsistencyIssue] = [
        ConsistencyIssue(
            severity: "HIGH",
            rationale: "The trip destination is completely different across the two documents.",
            sourceText: "trip to the Science Museum in the city center",
            sourceDocument: "Science_Museum_Trip.txt",
            targetText: "trip to the Water Park at the beach",
            targetDocument: "Teacher_Trip_Update.txt",
            suggestedFix: "Confirm the actual destination — Science Museum or Water Park — and update both documents.",
            sourceParagraph: 2,
            targetParagraph: 2
        ),
        ConsistencyIssue(
            severity: "MEDIUM",
            rationale: "The trip date and departure time are contradictory.",
            sourceText: "Monday, June 1st at 8:00 AM",
            sourceDocument: "Science_Museum_Trip.txt",
            targetText: "Wednesday, June 3rd at 10:00 AM",
            targetDocument: "Teacher_Trip_Update.txt",
            suggestedFix: "Align the trip date — parents need one consistent date and time.",
            sourceParagraph: 2,
            targetParagraph: 2
        ),
        ConsistencyIssue(
            severity: "MEDIUM",
            rationale: "The food instructions directly contradict each other.",
            sourceText: "bring a packed lunch from home. The museum cafe is currently closed",
            sourceDocument: "Science_Museum_Trip.txt",
            targetText: "You do not need to bring food. We will all eat lunch together",
            targetDocument: "Teacher_Trip_Update.txt",
            suggestedFix: "Clarify whether students should pack lunch or if food is provided.",
            sourceParagraph: 4,
            targetParagraph: 4
        ),
        ConsistencyIssue(
            severity: "MEDIUM",
            rationale: "The dress code contradicts across documents.",
            sourceText: "Students must wear their blue school uniform",
            sourceDocument: "Science_Museum_Trip.txt",
            targetText: "Do not wear your school uniform because it will get wet",
            targetDocument: "Teacher_Trip_Update.txt",
            suggestedFix: "Specify one dress code — school uniform or swimming clothes.",
            sourceParagraph: 5,
            targetParagraph: 7
        ),
    ]

    // --- Single-document demo: camp guide ---

    static let campDoc = Document(
        id: UUID(),
        title: "Summer_Camp_Guide.txt",
        content: """
        WELCOME TO THE 5-DAY ART CAMP

        CAMP OVERVIEW:
        This camp lasts for five full days, from Monday until Friday. 
        We have a lot of fun activities planned for you!

        WEEKLY SCHEDULE:
        Day 1: Painting with water colors in the garden.
        Day 2: Making bowls out of wet clay.
        Day 3: Drawing animals with colored pencils.
        (This is the end of our activity list for the week).

        CAMP RULES:
        - You must always wear a sun hat when you are outside.
        - No candy, soda, or sugary snacks are allowed in the camp building.

        THE CAMP SHOP:
        - The shop is open every afternoon for students to buy snacks.
        - Please bring $5 every day so you can buy candy and soda.
        - Hats are not allowed at camp.

        GRADING AND PRIZES:
        At the end of the week, everyone gets a "Gold Star" for finishing. 
        There are no tests at this camp. We just want you to have fun.

        FINAL TEST DETAILS:
        - The final exam is on Friday afternoon in the main hall.
        - You must pass this test to get your "Gold Star."
        """
    )

    static let singleDocIssues: [ConsistencyIssue] = [
        ConsistencyIssue(
            severity: "HIGH",
            rationale: "The snack policy directly contradicts the camp shop description.",
            sourceText: "No candy, soda, or sugary snacks are allowed in the camp building",
            sourceDocument: "Summer_Camp_Guide.txt",
            targetText: "bring $5 every day so you can buy candy and soda",
            targetDocument: "Summer_Camp_Guide.txt",
            suggestedFix: "Decide whether candy and soda are banned or sold — remove one of the conflicting statements.",
            sourceParagraph: 5,
            targetParagraph: 8
        ),
        ConsistencyIssue(
            severity: "HIGH",
            rationale: "The hat policy contradicts itself within the same document.",
            sourceText: "You must always wear a sun hat when you are outside",
            sourceDocument: "Summer_Camp_Guide.txt",
            targetText: "Hats are not allowed at camp",
            targetDocument: "Summer_Camp_Guide.txt",
            suggestedFix: "Clarify whether hats are required outside or banned entirely.",
            sourceParagraph: 4,
            targetParagraph: 9
        ),
        ConsistencyIssue(
            severity: "HIGH",
            rationale: "The grading section says there are no tests, but then describes a final exam.",
            sourceText: "There are no tests at this camp",
            sourceDocument: "Summer_Camp_Guide.txt",
            targetText: "The final exam is on Friday afternoon",
            targetDocument: "Summer_Camp_Guide.txt",
            suggestedFix: "Remove either the 'no tests' claim or the final exam details.",
            sourceParagraph: 11,
            targetParagraph: 13
        ),
    ]

    // --- Clean document demo: library guide (no contradictions) ---

    static let libraryDoc = Document(
        id: UUID(),
        title: "City_Library_Guide.txt",
        content: """
        WELCOME TO THE CENTRAL CITY LIBRARY

        GENERAL INFORMATION:
        The Central City Library is a place for everyone to read, study, and learn. 
        We are open 6 days a week, from Monday to Saturday. Please note that the 
        library is always closed on Sundays to allow for deep cleaning and shelf organizing.

        OPERATING HOURS:
        - Monday to Friday: 9:00 AM to 8:00 PM
        - Saturday: 10:00 AM to 4:00 PM
        - Sunday: Closed

        BORROWING RULES:
        Every member can borrow up to 10 books at one time. Books must be returned 
        within 14 days. If you need more time, you can renew your books once through 
        our website or by visiting the front desk.

        FACILITY RULES:
        1. Keep your voice at a whisper to respect other readers.
        2. Cell phones must be set to silent mode at all times.
        3. No food or drinks are allowed near the computers or the rare book section.
        4. Bottled water is permitted only in the main seating area.

        THE CHILDREN'S CORNER:
        The Children's Corner is located on the first floor. It is a special area 
        designed for kids aged 3 to 12. We have over 5,000 picture books and 
        educational games available.

        WEEKLY CHILDREN'S EVENTS:
        - Story Time: Tuesday mornings at 10:30 AM.
        - Puppet Show: Thursday afternoons at 2:00 PM.
        - Lego Club: Saturday mornings at 11:00 AM.

        STUDY ROOMS:
        We offer 8 private study rooms for group work. You can book a study room 
        for a maximum of 2 hours per day. Reservations can be made up to one week 
        in advance at the information desk.

        MEMBERSHIP FEES:
        Membership is completely free for all city residents. You just need to show 
        a valid ID and proof of address to get your library card. Non-residents can 
        join for a small fee of $20 per year.
        """
    )
}
