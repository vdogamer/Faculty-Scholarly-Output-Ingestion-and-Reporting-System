using System.Text.Json;
using FacultyPub.Web.Models;
using Microsoft.Extensions.Options;

namespace FacultyPub.Web.Services;

public sealed class OpenAlexSyncService
{
    private readonly FacultyRepository _repository;
    private readonly IOpenAlexClient _client;
    private readonly OpenAlexOptions _options;
    private readonly ILogger<OpenAlexSyncService> _logger;

    public OpenAlexSyncService(FacultyRepository repository, IOpenAlexClient client, IOptions<OpenAlexOptions> options, ILogger<OpenAlexSyncService> logger)
    {
        _repository = repository;
        _client = client;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<long> RunVerifiedAuthorSyncAsync(CancellationToken cancellationToken)
    {
        var syncRunId = await _repository.StartSyncRunAsync("AuthorWorksFullRefresh", "AllVerifiedAuthors", null);
        var facultyCount = 0;
        var authorsChecked = 0;
        var worksInserted = 0;
        var worksUpdated = 0;
        var worksUnchanged = 0;
        var errors = 0;

        try
        {
            var authors = await _repository.ListVerifiedAuthorsForSyncAsync();
            facultyCount = authors.Select(a => a.FacultyId).Distinct().Count();

            foreach (var author in authors)
            {
                authorsChecked++;
                try
                {
                    var cursor = "*";
                    for (var pageNumber = 1; pageNumber <= Math.Max(_options.MaxPagesPerAuthor, 1); pageNumber++)
                    {
                        var page = await _client.GetWorksByAuthorAsync(author.OpenAlexAuthorId, cursor, null, cancellationToken);
                        if (page.Results.Count == 0)
                        {
                            break;
                        }

                        foreach (var work in page.Results)
                        {
                            var action = await UpsertWorkGraphAsync(author, work);
                            switch (action)
                            {
                                case "Inserted": worksInserted++; break;
                                case "Updated": worksUpdated++; break;
                                default: worksUnchanged++; break;
                            }
                        }

                        if (string.IsNullOrWhiteSpace(page.Meta?.NextCursor))
                        {
                            break;
                        }

                        cursor = page.Meta.NextCursor;
                    }
                }
                catch (OpenAlexApiException apiEx)
                {
                    errors++;
                    var redactedEndpoint = RedactApiKey(apiEx.Endpoint);
                    await _repository.LogApiErrorAsync(syncRunId, redactedEndpoint, redactedEndpoint, apiEx.StatusCode, apiEx.Message, apiEx.ResponseBody, 0);
                }
                catch (Exception ex)
                {
                    errors++;
                    _logger.LogError(ex, "Failed syncing author {AuthorId}.", author.OpenAlexAuthorId);
                    await _repository.LogApiErrorAsync(syncRunId, "AuthorWorksSync", author.OpenAlexAuthorId, null, ex.Message, ex.ToString(), 0);
                }
            }

            var status = errors > 0 ? "CompletedWithErrors" : "Completed";
            await _repository.FinishSyncRunAsync(syncRunId, status, facultyCount, authorsChecked, worksInserted, worksUpdated, worksUnchanged, errors, null);
            return syncRunId;
        }
        catch (Exception ex)
        {
            await _repository.FinishSyncRunAsync(syncRunId, "Failed", facultyCount, authorsChecked, worksInserted, worksUpdated, worksUnchanged, errors + 1, ex.Message);
            throw;
        }
    }

    private async Task<string> UpsertWorkGraphAsync(VerifiedAuthor author, OpenAlexWorkDto work)
    {
        if (string.IsNullOrWhiteSpace(work.Id))
        {
            return "Unchanged";
        }

        var source = work.PrimaryLocation?.Source ?? work.BestOaLocation?.Source;
        if (!string.IsNullOrWhiteSpace(source?.Id))
        {
            await _repository.UpsertSourceAsync(new
            {
                OpenAlexSourceId = source.Id,
                DisplayName = source.DisplayName,
                IssnL = source.IssnL,
                IssnJson = ToJson(source.Issn),
                SourceType = source.Type,
                IsOpenAccess = source.IsOa,
                IsInDoaj = source.IsInDoaj,
                HostOrganization = source.HostOrganization,
                HostOrganizationName = source.HostOrganizationName,
                RawJson = ToJson(source)
            });
        }

        var publicationDate = ParseDate(work.PublicationDate);
        var createdDate = ParseDate(work.CreatedDate);
        var updatedDate = ParseDateTime(work.UpdatedDate);
        var rawJson = ToJson(work);

        var action = await _repository.UpsertWorkAsync(new
        {
            OpenAlexWorkId = work.Id,
            Doi = work.Doi ?? work.Ids?.Doi,
            Pmid = work.Ids?.Pmid,
            Pmcid = work.Ids?.Pmcid,
            Title = work.Title,
            DisplayName = work.DisplayName,
            PublicationYear = work.PublicationYear,
            PublicationDate = publicationDate,
            WorkType = work.Type,
            LanguageCode = work.Language,
            CitedByCount = work.CitedByCount,
            IsRetracted = work.IsRetracted ?? false,
            IsParatext = work.IsParatext ?? false,
            PrimarySourceId = source?.Id,
            PrimarySourceName = source?.DisplayName,
            OpenAccessStatus = work.OpenAccess?.OaStatus,
            IsOpenAccess = work.OpenAccess?.IsOa,
            BestOpenAccessUrl = work.OpenAccess?.OaUrl ?? work.BestOaLocation?.LandingPageUrl,
            LandingPageUrl = work.PrimaryLocation?.LandingPageUrl ?? work.BestOaLocation?.LandingPageUrl,
            PdfUrl = work.PrimaryLocation?.PdfUrl ?? work.BestOaLocation?.PdfUrl,
            ReferencedWorksJson = ToJson(work.ReferencedWorks),
            RelatedWorksJson = ToJson(work.RelatedWorks),
            IndexedInJson = ToJson(work.IndexedIn),
            MeshJson = ToJson(work.Mesh),
            OpenAlexCreatedDate = createdDate,
            OpenAlexUpdatedDateUtc = updatedDate,
            RawJson = rawJson
        });

        await _repository.DeleteTopicsForWorkAsync(work.Id);
        for (var topicIndex = 0; topicIndex < work.Topics.Count; topicIndex++)
        {
            var topic = work.Topics[topicIndex];
            if (string.IsNullOrWhiteSpace(topic.Id)) continue;
            await _repository.UpsertTopicAsync(new
            {
                OpenAlexTopicId = topic.Id,
                DisplayName = topic.DisplayName,
                RawJson = ToJson(topic)
            });
            await _repository.InsertWorkTopicAsync(new
            {
                OpenAlexWorkId = work.Id,
                OpenAlexTopicId = topic.Id,
                Score = topic.Score,
                IsPrimary = topicIndex == 0
            });
        }

        await _repository.DeleteAuthorshipsForWorkAsync(work.Id);

        foreach (var authorship in work.Authorships)
        {
            await _repository.InsertAuthorshipAsync(new
            {
                OpenAlexWorkId = work.Id,
                OpenAlexAuthorId = authorship.Author?.Id,
                AuthorDisplayName = authorship.Author?.DisplayName,
                Orcid = authorship.Author?.Orcid,
                AuthorPosition = authorship.AuthorPosition,
                IsCorresponding = authorship.IsCorresponding,
                InstitutionJson = ToJson(authorship.Institutions),
                AffiliationJson = ToJson(authorship.Affiliations),
                RawAffiliationStringsJson = ToJson(authorship.RawAffiliationStrings),
                CountriesJson = ToJson(authorship.Countries)
            });

            if (OpenAlexIdHelper.IsSameOpenAlexId(authorship.Author?.Id, author.OpenAlexAuthorId))
            {
                await _repository.UpsertFacultyWorkAsync(new
                {
                    FacultyId = author.FacultyId,
                    OpenAlexWorkId = work.Id,
                    OpenAlexAuthorId = OpenAlexIdHelper.ToShortId(author.OpenAlexAuthorId),
                    AuthorPosition = authorship.AuthorPosition,
                    IsCorresponding = authorship.IsCorresponding,
                    MatchSource = "OpenAlexAuthorship"
                });
            }
        }

        return action;
    }

    private static string RedactApiKey(string value)
    {
        var index = value.IndexOf("api_key=", StringComparison.OrdinalIgnoreCase);
        if (index < 0) return value;
        return value[..index] + "api_key=REDACTED";
    }

    private static string? ToJson<T>(T value)
    {
        if (value is null) return null;
        return JsonSerializer.Serialize(value, new JsonSerializerOptions(JsonSerializerDefaults.Web));
    }

    private static string? ToJson(System.Text.Json.JsonElement element)
    {
        if (element.ValueKind is System.Text.Json.JsonValueKind.Undefined or System.Text.Json.JsonValueKind.Null)
        {
            return null;
        }
        return element.GetRawText();
    }

    private static DateTime? ParseDate(string? value)
    {
        return DateTime.TryParse(value, out var parsed) ? parsed.Date : null;
    }

    private static DateTime? ParseDateTime(string? value)
    {
        return DateTime.TryParse(value, out var parsed) ? parsed.ToUniversalTime() : null;
    }
}
