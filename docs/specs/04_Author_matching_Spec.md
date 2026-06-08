Rules:
    - OpenAlex Author IDs must begin with A.
    - OpenAlex Work IDs begin with W and must not be accepted as Author IDs.
    - Name-only matching must never auto-approve.
    - ORCID match is strongest, but current internal faculty data does not store ORCID.
    - Known PMID/DOI authorship can support a match but should still require review if no ORCID exists.
    - Manual verification must be stored.

Statuses:
    PendingReview
    Verified
    Rejected
    Superseded
    NeedsMoreEvidence

Acceptance criteria:
    - The system rejects W... IDs as author IDs.
    - The system accepts only A... IDs for verified faculty-author links.
    - The system records who verified the author match.
    - Ambiguous matches remain pending.