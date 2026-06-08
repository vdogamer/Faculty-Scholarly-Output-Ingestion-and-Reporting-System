Target normalized model:
    Faculty
    FacultyDepartment
    FacultyOpenAlexAuthor
    OpenAlexMatchCandidate
    OpenAlexMatchEvidence

    OpenAlexWork
    OpenAlexSource
    OpenAlexWorkLocation
    OpenAlexWorkAuthorship
    FacultyWork

    OpenAlexTopic
    OpenAlexWorkTopic

    OpenAlexKeyword
    OpenAlexWorkKeyword

    OpenAlexFunder
    OpenAlexAward

    OpenAlexSyncRun
    OpenAlexSyncWatermark
    OpenAlexApiErrorLog
    OpenAlexRawJsonArchive
    BusinessRuleSetting

Normalization rule:
    One table per durable entity.
    Bridge tables for many-to-many relationships.
    Raw JSON preserved for traceability.
    Common reporting fields may remain denormalized when useful.

Do not over-normalize away useful report fields like:
    PublicationYear
    PrimarySourceName
    Doi
    Pmid
    Pmcid
    OpenAccessStatus
    CitedByCount