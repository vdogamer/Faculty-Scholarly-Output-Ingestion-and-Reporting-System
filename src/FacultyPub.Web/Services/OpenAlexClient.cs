using System.Net;
using System.Text.Json;
using FacultyPub.Web.Models;
using Microsoft.Extensions.Options;

namespace FacultyPub.Web.Services;

public interface IOpenAlexClient
{
    bool IsConfigured { get; }
    Task<OpenAlexAuthorDto?> GetAuthorAsync(string openAlexAuthorId, CancellationToken cancellationToken);
    Task<OpenAlexPagedResponse<OpenAlexAuthorDto>> SearchAuthorsAsync(string searchText, CancellationToken cancellationToken);
    Task<OpenAlexWorkDto?> GetWorkByPmidAsync(string pmid, CancellationToken cancellationToken);
    Task<OpenAlexWorkDto?> GetWorkAsync(string openAlexWorkId, CancellationToken cancellationToken);
    Task<OpenAlexPagedResponse<OpenAlexWorkDto>> GetWorksByAuthorAsync(string openAlexAuthorId, string cursor, DateTimeOffset? fromUpdatedDate, CancellationToken cancellationToken);
}

public sealed class OpenAlexClient : IOpenAlexClient
{
    private readonly HttpClient _httpClient;
    private readonly OpenAlexOptions _options;
    private readonly ILogger<OpenAlexClient> _logger;
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private const string WorkSelectFields = "id,doi,title,display_name,publication_year,publication_date,type,language,cited_by_count,is_retracted,is_paratext,primary_location,best_oa_location,open_access,authorships,topics,mesh,indexed_in,referenced_works,related_works,ids,created_date,updated_date";

    public OpenAlexClient(HttpClient httpClient, IOptions<OpenAlexOptions> options, ILogger<OpenAlexClient> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
        _httpClient.BaseAddress = new Uri(_options.BaseUrl.TrimEnd('/') + "/");
    }

    public bool IsConfigured => !string.IsNullOrWhiteSpace(_options.ApiKey);

    public async Task<OpenAlexAuthorDto?> GetAuthorAsync(string openAlexAuthorId, CancellationToken cancellationToken)
    {
        var id = OpenAlexIdHelper.ToShortId(openAlexAuthorId);
        return await GetAsync<OpenAlexAuthorDto>($"authors/{Uri.EscapeDataString(id)}", cancellationToken);
    }

    public async Task<OpenAlexPagedResponse<OpenAlexAuthorDto>> SearchAuthorsAsync(string searchText, CancellationToken cancellationToken)
    {
        var query = new Dictionary<string, string?>
        {
            ["search"] = searchText,
            ["per_page"] = "10",
            ["select"] = "id,display_name,orcid,works_count,cited_by_count,last_known_institutions"
        };
        return await GetAsync<OpenAlexPagedResponse<OpenAlexAuthorDto>>($"authors{ToQueryString(query)}", cancellationToken)
               ?? new OpenAlexPagedResponse<OpenAlexAuthorDto>();
    }

    public async Task<OpenAlexWorkDto?> GetWorkByPmidAsync(string pmid, CancellationToken cancellationToken)
    {
        return await GetAsync<OpenAlexWorkDto>($"works/pmid:{Uri.EscapeDataString(pmid)}", cancellationToken);
    }

    public async Task<OpenAlexWorkDto?> GetWorkAsync(string openAlexWorkId, CancellationToken cancellationToken)
    {
        var id = OpenAlexIdHelper.ToShortId(openAlexWorkId);
        return await GetAsync<OpenAlexWorkDto>($"works/{Uri.EscapeDataString(id)}", cancellationToken);
    }

    public async Task<OpenAlexPagedResponse<OpenAlexWorkDto>> GetWorksByAuthorAsync(string openAlexAuthorId, string cursor, DateTimeOffset? fromUpdatedDate, CancellationToken cancellationToken)
    {
        var authorId = OpenAlexIdHelper.ToShortId(openAlexAuthorId);
        var filter = $"authorships.author.id:{authorId}";
        if (_options.UseFromUpdatedDate && fromUpdatedDate.HasValue)
        {
            filter += $",from_updated_date:{fromUpdatedDate.Value.UtcDateTime:yyyy-MM-ddTHH:mm:ss}";
        }

        var query = new Dictionary<string, string?>
        {
            ["filter"] = filter,
            ["per_page"] = Math.Clamp(_options.PerPage, 1, 100).ToString(),
            ["cursor"] = string.IsNullOrWhiteSpace(cursor) ? "*" : cursor,
            ["select"] = WorkSelectFields
        };

        return await GetAsync<OpenAlexPagedResponse<OpenAlexWorkDto>>($"works{ToQueryString(query)}", cancellationToken)
               ?? new OpenAlexPagedResponse<OpenAlexWorkDto>();
    }

    private async Task<T?> GetAsync<T>(string relativeUrl, CancellationToken cancellationToken)
    {
        if (!IsConfigured)
        {
            throw new InvalidOperationException("OpenAlex API key is not configured. Use dotnet user-secrets or an environment variable named OpenAlex__ApiKey.");
        }

        var url = AddApiKey(relativeUrl);
        const int maxAttempts = 3;
        for (var attempt = 1; attempt <= maxAttempts; attempt++)
        {
            using var response = await _httpClient.GetAsync(url, cancellationToken);
            var body = await response.Content.ReadAsStringAsync(cancellationToken);

            if (response.IsSuccessStatusCode)
            {
                return JsonSerializer.Deserialize<T>(body, JsonOptions);
            }

            if (response.StatusCode == HttpStatusCode.BadRequest || response.StatusCode == HttpStatusCode.Forbidden)
            {
                throw new OpenAlexApiException((int)response.StatusCode, url, body);
            }

            if (attempt == maxAttempts)
            {
                throw new OpenAlexApiException((int)response.StatusCode, url, body);
            }

            _logger.LogWarning("OpenAlex request failed with {StatusCode}; retrying attempt {Attempt}/{MaxAttempts}.", response.StatusCode, attempt, maxAttempts);
            await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, attempt)), cancellationToken);
        }

        return default;
    }

    private string AddApiKey(string relativeUrl)
    {
        var separator = relativeUrl.Contains('?') ? '&' : '?';
        return $"{relativeUrl}{separator}api_key={Uri.EscapeDataString(_options.ApiKey!)}";
    }

    private static string ToQueryString(Dictionary<string, string?> query)
    {
        var parts = query
            .Where(kvp => !string.IsNullOrWhiteSpace(kvp.Value))
            .Select(kvp => $"{Uri.EscapeDataString(kvp.Key)}={Uri.EscapeDataString(kvp.Value!)}");
        return "?" + string.Join("&", parts);
    }
}

public sealed class OpenAlexApiException : Exception
{
    public OpenAlexApiException(int statusCode, string endpoint, string responseBody)
        : base($"OpenAlex API request failed with HTTP {statusCode}.")
    {
        StatusCode = statusCode;
        Endpoint = endpoint;
        ResponseBody = responseBody;
    }

    public int StatusCode { get; }
    public string Endpoint { get; }
    public string ResponseBody { get; }
}
