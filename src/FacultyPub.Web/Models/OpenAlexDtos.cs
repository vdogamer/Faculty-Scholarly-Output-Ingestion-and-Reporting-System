using System.Text.Json;
using System.Text.Json.Serialization;

namespace FacultyPub.Web.Models;

public sealed class OpenAlexPagedResponse<T>
{
    [JsonPropertyName("meta")]
    public OpenAlexMeta? Meta { get; set; }

    [JsonPropertyName("results")]
    public List<T> Results { get; set; } = new();
}

public sealed class OpenAlexMeta
{
    [JsonPropertyName("count")]
    public int? Count { get; set; }

    [JsonPropertyName("db_response_time_ms")]
    public int? DbResponseTimeMs { get; set; }

    [JsonPropertyName("page")]
    public int? Page { get; set; }

    [JsonPropertyName("per_page")]
    public int? PerPage { get; set; }

    [JsonPropertyName("next_cursor")]
    public string? NextCursor { get; set; }

    [JsonPropertyName("cost_usd")]
    public decimal? CostUsd { get; set; }
}

public sealed class OpenAlexAuthorDto
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("display_name")]
    public string? DisplayName { get; set; }

    [JsonPropertyName("orcid")]
    public string? Orcid { get; set; }

    [JsonPropertyName("works_count")]
    public int? WorksCount { get; set; }

    [JsonPropertyName("cited_by_count")]
    public int? CitedByCount { get; set; }

    [JsonPropertyName("last_known_institutions")]
    public JsonElement LastKnownInstitutions { get; set; }
}

public sealed class OpenAlexWorkDto
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("doi")]
    public string? Doi { get; set; }

    [JsonPropertyName("title")]
    public string? Title { get; set; }

    [JsonPropertyName("display_name")]
    public string? DisplayName { get; set; }

    [JsonPropertyName("publication_year")]
    public int? PublicationYear { get; set; }

    [JsonPropertyName("publication_date")]
    public string? PublicationDate { get; set; }

    [JsonPropertyName("type")]
    public string? Type { get; set; }

    [JsonPropertyName("language")]
    public string? Language { get; set; }

    [JsonPropertyName("cited_by_count")]
    public int? CitedByCount { get; set; }

    [JsonPropertyName("is_retracted")]
    public bool? IsRetracted { get; set; }

    [JsonPropertyName("is_paratext")]
    public bool? IsParatext { get; set; }

    [JsonPropertyName("primary_location")]
    public OpenAlexLocationDto? PrimaryLocation { get; set; }

    [JsonPropertyName("best_oa_location")]
    public OpenAlexLocationDto? BestOaLocation { get; set; }

    [JsonPropertyName("open_access")]
    public OpenAlexOpenAccessDto? OpenAccess { get; set; }

    [JsonPropertyName("authorships")]
    public List<OpenAlexAuthorshipDto> Authorships { get; set; } = new();

    [JsonPropertyName("topics")]
    public List<OpenAlexTopicDto> Topics { get; set; } = new();

    [JsonPropertyName("mesh")]
    public JsonElement Mesh { get; set; }

    [JsonPropertyName("indexed_in")]
    public JsonElement IndexedIn { get; set; }

    [JsonPropertyName("referenced_works")]
    public List<string>? ReferencedWorks { get; set; }

    [JsonPropertyName("related_works")]
    public List<string>? RelatedWorks { get; set; }

    [JsonPropertyName("ids")]
    public OpenAlexWorkIdsDto? Ids { get; set; }

    [JsonPropertyName("created_date")]
    public string? CreatedDate { get; set; }

    [JsonPropertyName("updated_date")]
    public string? UpdatedDate { get; set; }
}

public sealed class OpenAlexWorkIdsDto
{
    [JsonPropertyName("openalex")]
    public string? OpenAlex { get; set; }

    [JsonPropertyName("doi")]
    public string? Doi { get; set; }

    [JsonPropertyName("pmid")]
    public string? Pmid { get; set; }

    [JsonPropertyName("pmcid")]
    public string? Pmcid { get; set; }
}

public sealed class OpenAlexLocationDto
{
    [JsonPropertyName("is_oa")]
    public bool? IsOa { get; set; }

    [JsonPropertyName("landing_page_url")]
    public string? LandingPageUrl { get; set; }

    [JsonPropertyName("pdf_url")]
    public string? PdfUrl { get; set; }

    [JsonPropertyName("source")]
    public OpenAlexSourceDto? Source { get; set; }
}

public sealed class OpenAlexSourceDto
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("display_name")]
    public string? DisplayName { get; set; }

    [JsonPropertyName("issn_l")]
    public string? IssnL { get; set; }

    [JsonPropertyName("issn")]
    public List<string>? Issn { get; set; }

    [JsonPropertyName("is_oa")]
    public bool? IsOa { get; set; }

    [JsonPropertyName("is_in_doaj")]
    public bool? IsInDoaj { get; set; }

    [JsonPropertyName("host_organization")]
    public string? HostOrganization { get; set; }

    [JsonPropertyName("host_organization_name")]
    public string? HostOrganizationName { get; set; }

    [JsonPropertyName("type")]
    public string? Type { get; set; }
}

public sealed class OpenAlexOpenAccessDto
{
    [JsonPropertyName("is_oa")]
    public bool? IsOa { get; set; }

    [JsonPropertyName("oa_status")]
    public string? OaStatus { get; set; }

    [JsonPropertyName("oa_url")]
    public string? OaUrl { get; set; }
}

public sealed class OpenAlexAuthorshipDto
{
    [JsonPropertyName("author_position")]
    public string? AuthorPosition { get; set; }

    [JsonPropertyName("is_corresponding")]
    public bool? IsCorresponding { get; set; }

    [JsonPropertyName("author")]
    public OpenAlexAuthorshipAuthorDto? Author { get; set; }

    [JsonPropertyName("institutions")]
    public JsonElement Institutions { get; set; }

    [JsonPropertyName("affiliations")]
    public JsonElement Affiliations { get; set; }

    [JsonPropertyName("raw_affiliation_strings")]
    public JsonElement RawAffiliationStrings { get; set; }

    [JsonPropertyName("countries")]
    public JsonElement Countries { get; set; }
}

public sealed class OpenAlexAuthorshipAuthorDto
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("display_name")]
    public string? DisplayName { get; set; }

    [JsonPropertyName("orcid")]
    public string? Orcid { get; set; }
}

public sealed class OpenAlexTopicDto
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("display_name")]
    public string? DisplayName { get; set; }

    [JsonPropertyName("score")]
    public decimal? Score { get; set; }
}
