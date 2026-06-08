# Implementation Notes

## Identifier safety

OpenAlex IDs are entity-specific. Work IDs begin with `W`; Author IDs begin with `A`. The app blocks manual verification when an entered value is classified as a Work ID.

## First local limitation

The app cannot pull works until at least one faculty member has a verified OpenAlex Author ID. The supplied identifier `W4292121792` is stored as a match candidate with `NeedsMoreEvidence` so the manager can see the review workflow.

## OpenAlex API usage

The client uses:

- `https://api.openalex.org` base URL
- `api_key` query parameter from configuration
- `/works?filter=authorships.author.id:A...`
- `cursor=*` paging
- `per_page=100` from configuration
- `select=` to reduce payload size

## SQL strategy

The prototype uses SQL scripts and stored procedures, not EF migrations. C# calls stored procedures through Dapper.

## What to improve next

1. Add search/resolve page for candidate author matching.
2. Add PMID work inspection to retrieve a work and display its authors.
3. Add a true review screen with approve buttons for candidate authors.
4. Add SQL Server Agent or hosted background worker scheduling.
5. Add Windows Authentication or UVA authentication later.
