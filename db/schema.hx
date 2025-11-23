// Schema for real-time math tutoring knowledge base
// LLM queries this database by Knowledge Component to provide hints/feedback
// Based on CTI Lab Study 2024 Summer dataset structure

// Node Types

// Knowledge Component: Core skill/concept (1,018 step-level KCs)
N::KnowledgeComponent {
    KCName: String,        // e.g., "'v-N+N=N", unique identifier
    KCCategory: String,    // e.g., "Transformation"
    Description: String,   // Human-readable description of the skill
    Difficulty: String,   // Optional: "Easy", "Medium", "Hard"
}

// Step: Mathematical step/operation that can be performed
N::Step {
    StepName: String,      // e.g., "x + 5 = 10"
    StepType: String,      // "Transformation" or "Typein"
    StepPattern: String,   // Pattern/regex for matching similar steps
}

// Feedback/Hint: Guidance to provide students
N::Feedback {
    FeedbackText: String,
    FeedbackType: String,  // "HINT", "ERROR", "ENCOURAGEMENT", "EXPLANATION"
    HintLevel: I64,       // 1 = subtle, 2 = moderate, 3 = explicit
}

// Common Mistake: Frequent errors students make
N::Mistake {
    MistakePattern: String,  // Pattern of the mistake (e.g., "wrong sign")
    Description: String,     // Description of the mistake
    StudentInput: String,    // Example of what student might enter incorrectly
    CorrectApproach: String, // How to do it correctly
}

// Problem Type: Categories of problems (optional, for organization)
N::ProblemType {
    TypeName: String,      // e.g., "Linear Equation", "Ratio Problem"
    Description: String,
}

// Edge Types

// Step requires a Knowledge Component (many-to-many)
E::RequiresKC {
    From: Step,
    To: KnowledgeComponent,
    Properties: {
        IsPrimary: Boolean,  // Is this the primary KC for this step?
    }
}

// Knowledge Component has associated Feedback/Hints
E::HasFeedback {
    From: KnowledgeComponent,
    To: Feedback,
    Properties: {
        Condition: String,      // When to use: "on_incorrect", "on_hint_request", "on_stuck"
        Order: I64,             // Order for hint levels (1, 2, 3...)
    }
}

// Knowledge Component has common Mistakes
E::HasMistake {
    From: KnowledgeComponent,
    To: Mistake,
    Properties: {
        Frequency: I64,         // Relative frequency of this mistake
    }
}

// Problem Type uses Knowledge Components
E::UsesKC {
    From: ProblemType,
    To: KnowledgeComponent,
    Properties: {}
}

// Knowledge Components can be prerequisites for other KCs
E::Prerequisite {
    From: KnowledgeComponent,
    To: KnowledgeComponent,
    Properties: {}
}

// Similar Knowledge Components (for finding related hints)
E::SimilarTo {
    From: KnowledgeComponent,
    To: KnowledgeComponent,
    Properties: {
        Similarity: F64,  // Similarity score 0.0-1.0
    }
}
