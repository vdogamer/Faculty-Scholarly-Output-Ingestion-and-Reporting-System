# Business Rules Spec

## Status
Draft v0.2

## Purpose
Defines the business rules for faculty identity, OpenAlex author matching, publication ingestion, source reporting, topic/keyword reporting, sync behavior, and data display.

## Core Principle
The internal faculty database is the source of truth for faculty identity, department, title, and active/inactive status. OpenAlex is the source of scholarly metadata.

## Rule Placement
- Documentation explains the rule.
- C# services apply the rule.
- SQL Server enforces data integrity.
- Razor Pages display the result.

## Author Matching Rules
- OpenAlex Author IDs must begin with A.
- OpenAlex Work IDs beginning with W must not be accepted as author IDs.
- Name-only matches must never auto-approve.
- ORCID exact match is strongest evidence.
- Known PMID/DOI authorship supports a match but does not replace manual review when ORCID is missing.

## Publication Rules
- Works should be upserted by OpenAlexWorkId.
- Duplicate faculty-work links are not allowed.
- Retracted works should be stored and flagged.
- PMID without PMCID should be reportable.
- Raw JSON should be preserved for traceability.

## Source Rules
- primary_location.source is used as the official publication venue.
- best_oa_location is used for open-access access reporting.
- locations may be stored for full availability reporting.
- Source priority scoring is optional and configurable.
- Source priority must not prove author identity.

## Topic and Keyword Rules
- Topics and keywords must be normalized.
- Work-topic and work-keyword relationships are many-to-many.
- Topics and keywords should support department-level reporting.

## CRUD Rules
- Faculty records are soft-deleted, not hard-deleted.
- Soft delete sets IsActive = 0 and IsPubliclyDisplayable = 0.
- CRUD changes must be auditable in a later production version.

## Sync Rules
- Prototype uses manual sync.
- Production may use scheduled sync.
- One failed author sync must not stop the entire sync run.
- Full author refresh is acceptable for prototype.
- from_updated_date must be tested before relying on incremental sync.

## Open Questions
- Should preprints be included?
- Should works before appointment date be included?
- Should retracted works appear in public reports?
- Should SourcePriorityScore be manager-editable?
- Should keywords be used in search filters?

Business rules should be handled like this:
    Docs explain the rule.
    C# applies the rule.
    SQL protects data integrity.
    Razor Pages display the result.

Rule categories:
    Author matching rules
    Publication inclusion rules
    Source reporting rules
    Topic/keyword rules
    PMCID/compliance rules
    Sync/watermark rules
    CRUD rules
    Soft-delete rules

Example rules:
    - Never hard-delete faculty records in the prototype.
    - Soft delete sets IsActive = 0 and IsPubliclyDisplayable = 0.
    - Retracted works should be ingested but clearly flagged.
    - PMID without PMCID should be reportable.
    - Name-only OpenAlex author matches require manual review.
    - OpenAlex Source priority score is optional and must be configurable.