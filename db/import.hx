// ===== CREATE KNOWLEDGE COMPONENT NODES =====


N::KnowledgeComponent {
    KCName: "'v-N+N=N",
    KCCategory: "Transformation",
    Description: "KC pattern for Transformation steps",
    Difficulty: "Hard",
}

N::KnowledgeComponent {
    KCName: "'v-N+N=N[add N]",
    KCCategory: "Typein",
    Description: "KC pattern for Typein steps",
    Difficulty: "Hard",
}

N::KnowledgeComponent {
    KCName: "'v-N=N",
    KCCategory: "Transformation",
    Description: "KC pattern for Transformation steps",
    Difficulty: "Hard",
}

N::KnowledgeComponent {
    KCName: "'v-N=N[add N]",
    KCCategory: "Typein",
    Description: "KC pattern for Typein steps",
    Difficulty: "Hard",
}

N::KnowledgeComponent {
    KCName: "'v=N",
    KCCategory: "Transformation",
    Description: "KC pattern for Transformation steps",
    Difficulty: "Hard",
}

N::KnowledgeComponent {
    KCName: "'What should / do nov?",
    KCCategory: "Transformation",
    Description: "KC pattern for Transformation steps",
    Difficulty: "Hard",
}

N::KnowledgeComponent {
    KCName: "'Nv=N[add N]",
    KCCategory: "Typein",
    Description: "KC pattern for Typein steps",
    Difficulty: "Hard",
}

N::KnowledgeComponent {
    KCName: "'N=Nv",
    KCCategory: "Transformation",
    Description: "KC pattern for Transformation steps",
    Difficulty: "Hard",
}

N::KnowledgeComponent {
    KCName: "'N=Nv[add N]",
    KCCategory: "Typein",
    Description: "KC pattern for Typein steps",
    Difficulty: "Hard",
}

N::KnowledgeComponent {
    KCName: "'N=Nv+N",
    KCCategory: "Transformation",
    Description: "KC pattern for Transformation steps",
    Difficulty: "Hard",
}

N::KnowledgeComponent {
    KCName: "'N=Nv+N[add N]",
    KCCategory: "Typein",
    Description: "KC pattern for Typein steps",
    Difficulty: "Hard",
}


// ... (1008 more KCs)



// ===== CREATE FEEDBACK NODES AND EDGES =====


N::Feedback {
    FeedbackText: "batman: Let's see... Bear with me while I think.",
    FeedbackType: "HINT",
    HintLevel: 1,
}

E::HasFeedback {
    From: (KCName == "'v-N+N=N"),
    To: Feedback,
    Properties: {
        Condition: "ungraded",
        Order: 1,
    }
}

N::Feedback {
    FeedbackText: "batman: Is it alright to enter subtract 7 in the transformation now?",
    FeedbackType: "HINT",
    HintLevel: 1,
}

E::HasFeedback {
    From: (KCName == "'v-N+N=N"),
    To: Feedback,
    Properties: {
        Condition: "ungraded",
        Order: 1,
    }
}

N::Feedback {
    FeedbackText: "batman: Hmm, let me think... Bear with me.",
    FeedbackType: "HINT",
    HintLevel: 1,
}

E::HasFeedback {
    From: (KCName == "'v-N+N=N[add N]"),
    To: Feedback,
    Properties: {
        Condition: "ungraded",
        Order: 1,
    }
}

N::Feedback {
    FeedbackText: "batman: Is it okay to enter x-11 in the left-hand side now?",
    FeedbackType: "HINT",
    HintLevel: 1,
}

E::HasFeedback {
    From: (KCName == "'v-N+N=N[add N]"),
    To: Feedback,
    Properties: {
        Condition: "ungraded",
        Order: 1,
    }
}

N::Feedback {
    FeedbackText: "batman: Well, let me think... Bear with me.",
    FeedbackType: "HINT",
    HintLevel: 1,
}

E::HasFeedback {
    From: (KCName == "'v-N=N"),
    To: Feedback,
    Properties: {
        Condition: "ungraded",
        Order: 1,
    }
}

N::Feedback {
    FeedbackText: "batman: Is it alright to say that the problem is solved here?",
    FeedbackType: "HINT",
    HintLevel: 1,
}

E::HasFeedback {
    From: (KCName == "'v-N=N"),
    To: Feedback,
    Properties: {
        Condition: "ungraded",
        Order: 1,
    }
}

N::Feedback {
    FeedbackText: "batman: Let's see... Bear with me while I think.",
    FeedbackType: "HINT",
    HintLevel: 1,
}

E::HasFeedback {
    From: (KCName == "'v-N=N[add N]"),
    To: Feedback,
    Properties: {
        Condition: "ungraded",
        Order: 1,
    }
}

N::Feedback {
    FeedbackText: "batman: I think I've finished the problem so I clicked the problem is solved button. Is that right?",
    FeedbackType: "HINT",
    HintLevel: 1,
}

E::HasFeedback {
    From: (KCName == "'v-N=N[add N]"),
    To: Feedback,
    Properties: {
        Condition: "ungraded",
        Order: 1,
    }
}

N::Feedback {
    FeedbackText: "batman: Well, let me think... Bear with me.",
    FeedbackType: "HINT",
    HintLevel: 1,
}

E::HasFeedback {
    From: (KCName == "'v=N"),
    To: Feedback,
    Properties: {
        Condition: "ungraded",
        Order: 1,
    }
}

N::Feedback {
    FeedbackText: "batman: Is it alright to say that the problem is solved here?",
    FeedbackType: "HINT",
    HintLevel: 1,
}

E::HasFeedback {
    From: (KCName == "'v=N"),
    To: Feedback,
    Properties: {
        Condition: "ungraded",
        Order: 1,
    }
}


// ... (490 more feedbacks)



// ===== CREATE MISTAKE NODES AND EDGES =====


N::Mistake {
    MistakePattern: "incorrect_input",
    Description: "Student entered ''-1'",
    StudentInput: "'-1",
    CorrectApproach: "See tutor guidance",
}

E::HasMistake {
    From: (KCName == "'v-N+N=N"),
    To: Mistake,
    Properties: {
        Frequency: 1,
    }
}

N::Mistake {
    MistakePattern: "incorrect_input",
    Description: "Student entered ''subtract 3'",
    StudentInput: "'subtract 3",
    CorrectApproach: "See tutor guidance",
}

E::HasMistake {
    From: (KCName == "'v-N+N=N"),
    To: Mistake,
    Properties: {
        Frequency: 1,
    }
}

N::Mistake {
    MistakePattern: "incorrect_input",
    Description: "Student entered ''-1'",
    StudentInput: "'-1",
    CorrectApproach: "See tutor guidance",
}

E::HasMistake {
    From: (KCName == "'v-N+N=N[add N]"),
    To: Mistake,
    Properties: {
        Frequency: 1,
    }
}

N::Mistake {
    MistakePattern: "incorrect_input",
    Description: "Student entered ''5'",
    StudentInput: "'5",
    CorrectApproach: "See tutor guidance",
}

E::HasMistake {
    From: (KCName == "'v-N+N=N[add N]"),
    To: Mistake,
    Properties: {
        Frequency: 1,
    }
}

N::Mistake {
    MistakePattern: "incorrect_input",
    Description: "Student entered ''-1'",
    StudentInput: "'-1",
    CorrectApproach: "See tutor guidance",
}

E::HasMistake {
    From: (KCName == "'v-N=N"),
    To: Mistake,
    Properties: {
        Frequency: 1,
    }
}

N::Mistake {
    MistakePattern: "incorrect_input",
    Description: "Student entered ''add 7'",
    StudentInput: "'add 7",
    CorrectApproach: "See tutor guidance",
}

E::HasMistake {
    From: (KCName == "'v-N=N"),
    To: Mistake,
    Properties: {
        Frequency: 1,
    }
}

N::Mistake {
    MistakePattern: "incorrect_input",
    Description: "Student entered ''-1'",
    StudentInput: "'-1",
    CorrectApproach: "See tutor guidance",
}

E::HasMistake {
    From: (KCName == "'v-N=N[add N]"),
    To: Mistake,
    Properties: {
        Frequency: 1,
    }
}

N::Mistake {
    MistakePattern: "incorrect_input",
    Description: "Student entered ''x'",
    StudentInput: "'x",
    CorrectApproach: "See tutor guidance",
}

E::HasMistake {
    From: (KCName == "'v-N=N[add N]"),
    To: Mistake,
    Properties: {
        Frequency: 1,
    }
}

N::Mistake {
    MistakePattern: "incorrect_input",
    Description: "Student entered ''-1'",
    StudentInput: "'-1",
    CorrectApproach: "See tutor guidance",
}

E::HasMistake {
    From: (KCName == "'v=N"),
    To: Mistake,
    Properties: {
        Frequency: 1,
    }
}

N::Mistake {
    MistakePattern: "incorrect_input",
    Description: "Student entered ''correct'",
    StudentInput: "'correct",
    CorrectApproach: "See tutor guidance",
}

E::HasMistake {
    From: (KCName == "'v=N"),
    To: Mistake,
    Properties: {
        Frequency: 1,
    }
}


// ... (274 more mistakes)



// ===== IMPORT SUMMARY =====
// Total KnowledgeComponents: 1018
// Total Feedback: 500
// Total Mistakes: 284
//
// To complete import, run full script with all nodes
// Use JSON files for batch import if preferred
