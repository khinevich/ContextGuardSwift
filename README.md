# Context Guard

**Swift Student Challenge 2026 Submission — An On-Device Document Consistency Checker**

## Problem

In educational settings, legal research, and technical documentation, information is spread across multiple documents — PDFs, scanned handouts, typed notes. When these documents contradict each other, it creates what educational psychology calls **Extraneous Cognitive Load** (Mayer's Coherence Principle). Users waste mental energy reconciling contradictions instead of focusing on actual content.

Example: Document A says "Emperor penguins are native to Antarctica" while Document B says "Emperor penguins are commonly found in the Arctic." A human reader may not notice this contradiction across files, but it undermines the reliability of the entire knowledge base.

**Context Guard** is an on-device AI tool that acts as a quality assurance layer. It checks a small set of documents (1–3 pages) for factual, semantic, and logical contradictions — entirely on-device, with zero data leaving the iPhone or iPad.

## What is an Inconsistency?

An **inconsistency** is defined as: an unintentional violation of coherence that creates extraneous cognitive load by presenting contradictory information about the same entity or concept.

For natural language documents, Context Guard focuses on two adapted categories:

1. **Semantic/Factual Inconsistencies**: The same entity is described contradictorily across documents or within a single document. Example: Doc A says "The meeting is on Tuesday" while Doc B says "The meeting is scheduled for Thursday."

2. **Structural/Scope Inconsistencies**: A summary, heading, or table of contents does not match the actual body text. Example: A syllabus lists 5 modules in the overview, but only 4 modules are described in the body.

## Theoretical Foundation

Grounded in:

- **Mayer's Coherence Principle**: Extraneous information and contradictions increase cognitive load and reduce learning effectiveness.
- **Biggs' Constructive Alignment**: Educational materials must be internally consistent to support intended learning outcomes.

This definition and approach come from the research paper **"LLM-Based Multi-Artifact Consistency Verification for Programming Exercise Quality Assurance"** [(Dietrich et al., Koli Calling 2025)](https://www.sciencedirect.com/science/article/pii/S2666920X25001778) and my Bachelor thesis implementation of this research. This project adapts it from programming exercise artifacts to general natural language documents.

## Sustainability & Social Impact

Context Guard contributes to sustainability and reduced waste in several concrete ways:

**Preventing Material Waste.** Inconsistent documents that get printed, distributed, or published often need to be recalled and reprinted once contradictions are discovered. By catching contradictions *before* distribution, Context Guard prevents wasted paper, ink, and shipping resources. In educational settings alone, millions of pages of handouts, syllabi, and policy documents are distributed each semester — catching errors early has a direct environmental benefit.

**Zero Network Energy.** Unlike cloud-based AI tools (ChatGPT, Gemini, etc.) that require data center processing, network transmission, and server cooling, Context Guard runs **100% on-device** using Apple Intelligence. There is no network traffic, no cloud compute, and no server energy consumed per query. For a tool that might be used hundreds of times across a school or organization, this adds up to meaningful energy savings.

**Reducing Cognitive Waste.** Research shows that inconsistent materials force readers to spend extra time and mental effort reconciling contradictions (Mayer's Coherence Principle). This is especially harmful for students with learning disabilities who may struggle more with conflicting information. By eliminating contradictions at the source, Context Guard reduces wasted study time and improves learning efficiency — a form of sustainability for human cognitive resources.

## Accessibility

Contradictions in educational materials create what can be called **cognitive mapping barriers** — points where the reader must hold conflicting information in working memory and decide which version is correct. For neurotypical readers this is annoying; for learners with dyslexia, ADHD, or working memory difficulties, it can be genuinely disabling, causing confusion, frustration, and disengagement.

Context Guard addresses this by surfacing inconsistencies automatically, so that educators and content creators can fix them *before* materials reach learners. The result is more **coherent, accessible content** that works for everyone — not just those who can easily reconcile conflicting information on their own.

The app itself is built entirely in SwiftUI with native support for Dynamic Type, VoiceOver, and Apple Pencil navigation.

## How It Works

Context Guard uses Apple's **Foundation Models** framework (`LanguageModelSession`) to perform on-device AI analysis. The app:

1. **Ingests** text from imported files (.txt, .pdf) or scanned paper documents (via VisionKit OCR)
2. **Chunks** text into labeled paragraphs and builds a single prompt-ready string
3. **Analyzes** using guided generation (`@Generable` structs) to produce structured results — severity level, exact contradicting quotes, paragraph locations, and suggested fixes

### Key Constraint: 4096 Token Context Window

Apple's on-device model has a **4096-token limit** per session (~3,000 words). This means:

- The app targets short documents (1–3 pages each)
- Maximum **3 documents** can be checked simultaneously
- The prompt itself (system instructions + persona definition) consumes tokens, so the user's text budget is smaller than 4096
- For longer inputs, text is chunked into overlapping paragraph windows

This constraint is why the app limits imports to 3 documents — it ensures the full text plus prompt fit within the on-device model's context window while leaving room for structured output.

## Requirements

- iPhone 15 Pro / iPad with M-series chip or newer
- iOS/iPadOS 26 or later
- Apple Intelligence enabled in Settings → Apple Intelligence & Siri

Built with Xcode 26 as an App Playground (.swiftpm). Runs entirely offline.
