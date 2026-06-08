
Purpose: 
    Normalize and report OpenAlex Source metadata such as journals, repositories, conferences, and preprint servers.

Source Priority fields:
    OpenAlexSourceId
    DisplayName
    SourceType
    ISSN-L
    ISSNs
    IsCore
    IsOpenAccess
    IsInDoaj
    HostOrganization
    WorksCount
    CitedByCount
    HIndex
    I10Index
    TwoYearMeanCitedness
    CountryCode
    Continent
    RawJson

Business Rule:
    For publication venue reporting, use primary_location.source.

    For open-access access reporting, use best_oa_location.

    For full availability reporting, store all locations when possible.

    Source ranking must not be used as proof of faculty-author identity.