using System.Data;
using Dapper;
using FacultyPub.Web.Models;

namespace FacultyPub.Web.Services;

public sealed class FacultyRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public FacultyRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<DashboardSummary> GetDashboardSummaryAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QuerySingleAsync<DashboardSummary>("dbo.usp_DashboardSummary", commandType: CommandType.StoredProcedure);
    }

    public async Task<IReadOnlyList<FacultyListItem>> ListFacultyAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var rows = await connection.QueryAsync<FacultyListItem>("dbo.usp_Faculty_List", commandType: CommandType.StoredProcedure);
        return rows.ToList();
    }

    public async Task<FacultyDetail?> GetFacultyAsync(int facultyId)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QuerySingleOrDefaultAsync<FacultyDetail>(
            "dbo.usp_Faculty_Get",
            new { FacultyId = facultyId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task VerifyAuthorAsync(int facultyId, string openAlexAuthorId, string? orcid, string? displayName, string? institution, int? worksCount, int? citedByCount, string matchMethod, decimal confidenceScore, string verifiedBy)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "dbo.usp_FacultyOpenAlexAuthor_Verify",
            new
            {
                FacultyId = facultyId,
                OpenAlexAuthorId = OpenAlexIdHelper.ToShortId(openAlexAuthorId),
                Orcid = orcid,
                OpenAlexDisplayName = displayName,
                LastKnownInstitution = institution,
                WorksCount = worksCount,
                CitedByCount = citedByCount,
                MatchMethod = matchMethod,
                ConfidenceScore = confidenceScore,
                VerifiedBy = verifiedBy
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IReadOnlyList<MatchCandidate>> ListMatchCandidatesAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var rows = await connection.QueryAsync<MatchCandidate>("dbo.usp_MatchCandidates_List", commandType: CommandType.StoredProcedure);
        return rows.ToList();
    }

    public async Task UpsertMatchCandidateAsync(int facultyId, string openAlexAuthorId, string? displayName, string? orcid, string? institution, int? worksCount, int? citedByCount, string matchMethod, decimal confidenceScore, string? evidenceJson, string reviewStatus)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "dbo.usp_OpenAlexMatchCandidate_Upsert",
            new
            {
                FacultyId = facultyId,
                OpenAlexAuthorId = OpenAlexIdHelper.ToShortId(openAlexAuthorId),
                OpenAlexDisplayName = displayName,
                Orcid = orcid,
                LastKnownInstitution = institution,
                WorksCount = worksCount,
                CitedByCount = citedByCount,
                MatchMethod = matchMethod,
                ConfidenceScore = confidenceScore,
                EvidenceJson = evidenceJson,
                ReviewStatus = reviewStatus
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task RejectMatchCandidateAsync(int matchCandidateId, string reviewedBy)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync("dbo.usp_MatchCandidate_Reject", new { MatchCandidateId = matchCandidateId, ReviewedBy = reviewedBy }, commandType: CommandType.StoredProcedure);
    }

    public async Task<IReadOnlyList<VerifiedAuthor>> ListVerifiedAuthorsForSyncAsync(int? facultyId = null)
    {
        using var connection = _connectionFactory.CreateConnection();
        var rows = await connection.QueryAsync<VerifiedAuthor>("dbo.usp_VerifiedAuthorsForSync_List", new { FacultyId = facultyId }, commandType: CommandType.StoredProcedure);
        return rows.ToList();
    }

    public async Task<long> StartSyncRunAsync(string syncType, string? scopeType, string? scopeValue)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QuerySingleAsync<long>("dbo.usp_OpenAlexSyncRun_Start", new { SyncType = syncType, ScopeType = scopeType, ScopeValue = scopeValue }, commandType: CommandType.StoredProcedure);
    }

    public async Task FinishSyncRunAsync(long syncRunId, string status, int facultyCount, int authorsChecked, int worksInserted, int worksUpdated, int worksUnchanged, int errorsCount, string? message)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync("dbo.usp_OpenAlexSyncRun_Finish", new
        {
            SyncRunId = syncRunId,
            Status = status,
            FacultyCount = facultyCount,
            AuthorsChecked = authorsChecked,
            WorksInserted = worksInserted,
            WorksUpdated = worksUpdated,
            WorksUnchanged = worksUnchanged,
            ErrorsCount = errorsCount,
            Message = message
        }, commandType: CommandType.StoredProcedure);
    }

    public async Task LogApiErrorAsync(long? syncRunId, string? endpoint, string? queryStringRedacted, int? httpStatusCode, string? errorMessage, string? responseBody, int retryCount)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync("dbo.usp_OpenAlexApiErrorLog_Insert", new
        {
            SyncRunId = syncRunId,
            Endpoint = endpoint,
            QueryStringRedacted = queryStringRedacted,
            HttpStatusCode = httpStatusCode,
            ErrorMessage = errorMessage,
            ResponseBody = responseBody,
            RetryCount = retryCount
        }, commandType: CommandType.StoredProcedure);
    }

    public async Task UpsertSourceAsync(object parameters)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync("dbo.usp_OpenAlexSource_Upsert", parameters, commandType: CommandType.StoredProcedure);
    }

    public async Task<string> UpsertWorkAsync(object parameters)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QuerySingleAsync<string>("dbo.usp_OpenAlexWork_Upsert", parameters, commandType: CommandType.StoredProcedure);
    }

    public async Task DeleteAuthorshipsForWorkAsync(string openAlexWorkId)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync("dbo.usp_OpenAlexWorkAuthorship_DeleteForWork", new { OpenAlexWorkId = openAlexWorkId }, commandType: CommandType.StoredProcedure);
    }

    public async Task InsertAuthorshipAsync(object parameters)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync("dbo.usp_OpenAlexWorkAuthorship_Insert", parameters, commandType: CommandType.StoredProcedure);
    }

    public async Task UpsertFacultyWorkAsync(object parameters)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync("dbo.usp_FacultyWork_Upsert", parameters, commandType: CommandType.StoredProcedure);
    }

    public async Task UpsertTopicAsync(object parameters)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync("dbo.usp_OpenAlexTopic_Upsert", parameters, commandType: CommandType.StoredProcedure);
    }

    public async Task DeleteTopicsForWorkAsync(string openAlexWorkId)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync("dbo.usp_OpenAlexWorkTopic_DeleteForWork", new { OpenAlexWorkId = openAlexWorkId }, commandType: CommandType.StoredProcedure);
    }

    public async Task InsertWorkTopicAsync(object parameters)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync("dbo.usp_OpenAlexWorkTopic_Insert", parameters, commandType: CommandType.StoredProcedure);
    }

    public async Task<IReadOnlyList<PublicationListItem>> ListPublicationsAsync(int? facultyId = null)
    {
        using var connection = _connectionFactory.CreateConnection();
        var rows = await connection.QueryAsync<PublicationListItem>("dbo.usp_Publications_List", new { FacultyId = facultyId }, commandType: CommandType.StoredProcedure);
        return rows.ToList();
    }

    public async Task<IReadOnlyList<DepartmentPublicationSummary>> ListPublicationsByDepartmentAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var rows = await connection.QueryAsync<DepartmentPublicationSummary>("dbo.usp_Publications_ByDepartment", commandType: CommandType.StoredProcedure);
        return rows.ToList();
    }

    public async Task<IReadOnlyList<SyncRunListItem>> ListSyncRunsAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var rows = await connection.QueryAsync<SyncRunListItem>("dbo.usp_SyncRuns_List", commandType: CommandType.StoredProcedure);
        return rows.ToList();
    }

    public async Task<IReadOnlyList<ApiErrorListItem>> ListErrorsAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var rows = await connection.QueryAsync<ApiErrorListItem>("dbo.usp_Errors_List", commandType: CommandType.StoredProcedure);
        return rows.ToList();
    }
}
