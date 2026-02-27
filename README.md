# Context Guard

**Swift Student Challenge 2026 Submission — An On-Device Document Consistency Checker**

## Problem

In educational settings, legal research, and technical documentation, information is spread across multiple documents — PDFs, scanned handouts, typed notes. When these documents contradict each other, it creates what educational psychology calls **Extraneous Cognitive Load** (Mayer's Coherence Principle). Users waste mental energy reconciling contradictions instead of focusing on actual content.

Example: Document A says "Emperor penguins are native to Antarctica" while Document B says "Emperor penguins are commonly found in the Arctic." A human reader may not notice this contradiction across files, but it undermines the reliability of the entire knowledge base.

**Context Guard** is an on-device AI agent that acts as a quality assurance layer. It checks a small set of documents (1–2 pages) for factual, semantic, and logical contradictions — entirely on-device, with zero data leaving the iPad or iPhone.

## Sustainability Angle

Context Guard reduces the cognitive and material waste caused by inconsistent documents. By catching contradictions before printing, publishing, or distributing materials, it prevents wasted paper, wasted revision cycles, and wasted energy from repeated cloud-based processing. The app runs 100% on-device using Apple Intelligence, consuming no network bandwidth and minimal energy compared to cloud LLM solutions.

## Theoretical Foundation

Grounded in:

- **Mayer's Coherence Principle**: Extraneous information and contradictions increase cognitive load and reduce learning effectiveness.
- **Biggs' Constructive Alignment**: Educational materials must be internally consistent to support intended learning outcomes.

An **inconsistency** is defined as: an unintentional violation of coherence that creates extraneous cognitive load by presenting contradictory information about the same entity or concept.

This definition comes from the research paper "LLM-Based Multi-Artifact Consistency Verification for Programming Exercise Quality Assurance" [(Dietrich et al., Koli Calling 2025)](https://www.sciencedirect.com/science/article/pii/S2666920X25001778) and my Bachelor-Thesis implementation of this research papaer. This project adapts it from programming exercise artifacts to general natural language documents.

## Inconsistency Types (Adapted for Natural Language)

The original paper defines five categories (Structural, Semantic, Assessment, Temporal, Scope) for programming exercises. For natural language documents, Context Guard focuses on two adapted categories:

1. **Semantic/Factual Inconsistencies**: The same entity is described contradictorily across documents or within a single document. Example: Doc A says "The meeting is on Tuesday" while Doc B says "The meeting is scheduled for Thursday."

2. **Structural/Scope Inconsistencies**: A summary, heading, or table of contents does not match the actual body text. Example: A syllabus lists 5 modules in the overview, but only 4 modules are described in the body.

## Core Features

1. **Files Integration**: Select files from the iPad Files app. The app reads plain text (.txt) and PDF documents to build a unified text context.

2. **Paper-to-Text Scan**: Use the iPad camera to scan physical handouts or whiteboard notes. Uses VisionKit for OCR to digitize scanned text.

3. **On-Device LLM Agent**: Powered by Apple's Foundation Models framework (`LanguageModelSession`). The on-device large language model analyzes text for contradictions. No network connection required. All processing is local.

4. **Precision Localization**: The AI returns structured results showing which documents and which text segments contradict each other, along with a severity level, a pedagogical rationale explaining the cognitive impact, and a suggested fix.

5. **Demo Mode**: Bundled sample documents with a known contradiction (the penguin example) so judges can see the app work immediately without preparing their own files.

## Technical Architecture

### Data Models

```swift
@Generable(description: "A consistency issue found between documents")
struct ConsistencyIssue {
    @Guide(description: "HIGH, MEDIUM, or LOW severity")
    var severity: String

    @Guide(description: "What the contradiction is, in one sentence")
    var description: String

    @Guide(description: "The text from the first source that contradicts")
    var sourceText: String

    @Guide(description: "The document name of the first source")
    var sourceDocument: String

    @Guide(description: "The text from the second source that contradicts")
    var targetText: String

    @Guide(description: "The document name of the second source")
    var targetDocument: String

    @Guide(description: "A short suggested fix for the contradiction")
    var suggestedFix: String
}
```

The `@Generable` macro from the Foundation Models framework guarantees the on-device model returns a valid Swift struct via constrained sampling — no manual JSON parsing needed.

### Pipeline (3 Steps)

1. **Text Ingestion and Normalization**: Extract text from all sources (PDF, TXT, OCR scans). Assign paragraph numbers to create a unified, referenceable text block. Combine into a single prompt-ready string.

2. **Prompt Construction**: Initialize a `LanguageModelSession` with a system prompt that defines the "Semantic Consistency Validator" persona. The prompt instructs the model to identify core entities, cross-reference their attributes across text chunks, and flag contradictions — while filtering out intentional variations.

3. **Guided Generation**: Call `session.respond(to:generating:)` with the user's text and `[ConsistencyIssue].self` as the output type. The Foundation Models framework handles constrained output. Results render directly into SwiftUI.

### Key Constraint: 4096 Token Context Window

Apple's on-device model has a 4096-token limit per session (~3,000 words). This means:

- The app targets short documents (1–2 pages).
- For longer inputs, text must be chunked and checked across multiple sessions.
- The prompt itself (instructions + persona) consumes tokens, so the user's text budget is smaller than 4096.
- Chunking strategy: split text into overlapping paragraph windows, run consistency checks per window, then deduplicate results.

### Frameworks Used

- **Foundation Models** (`LanguageModelSession`, `@Generable`): On-device LLM for consistency analysis
- **VisionKit** (`DataScannerViewController`): Camera-based document scanning with Live Text OCR
- **SwiftUI**: Entire UI layer, with Dynamic Type, VoiceOver, and Apple Pencil support
- **UniformTypeIdentifiers**: File type handling for the file importer

## Accessibility

The app supports inclusive learning by identifying "cognitive mapping barriers" — contradictions that disproportionately affect users with learning disabilities who may struggle to reconcile conflicting information across documents. The UI is built entirely in SwiftUI with native support for Dynamic Type, VoiceOver, and Apple Pencil navigation.

## Build Target

Built with Swift Playgrounds 4.6 or Xcode 26 for iPadOS. Runs entirely offline.
