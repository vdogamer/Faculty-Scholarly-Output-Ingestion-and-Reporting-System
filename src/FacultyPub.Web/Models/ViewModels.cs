namespace FacultyPub.Web.Models;

public sealed class DashboardSummary
{
    public int FacultyCount { get; set; }
    public int ActiveFacultyCount { get; set; }
    public int VerifiedAuthorCount { get; set; }
    public int CandidateCount { get; set; }
    public int WorkCount { get; set; }
    public int FacultyWorkCount { get; set; }
    public int PmidWithoutPmcidCount { get; set; }
    public int RetractedWorkCount { get; set; }
    public int ErrorCount { get; set; }
}

public sealed class FacultyListItem
{
    public int FacultyId { get; set; }
    public string SourceFacultyId { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? DepartmentCode { get; set; }
    public string? DepartmentName { get; set; }
    public string? AppointmentTitle { get; set; }
    public bool IsActive { get; set; }
    public bool IsPubliclyDisplayable { get; set; }
    public bool HasVerifiedOpenAlex { get; set; }
    public string? VerifiedOpenAlexAuthorId { get; set; }
    public int CandidateCount { get; set; }
    public int PublicationCount { get; set; }
}

public sealed class FacultyDetail
{
    public int FacultyId { get; set; }
    public string SourceFacultyId { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? DepartmentCode { get; set; }
    public string? DepartmentName { get; set; }
    public string? AppointmentTitle { get; set; }
    public bool IsActive { get; set; }
    public bool IsPubliclyDisplayable { get; set; }
    public string? VerifiedOpenAlexAuthorId { get; set; }
    public string? VerifiedOrcid { get; set; }
    public int PublicationCount { get; set; }
}

public sealed class MatchCandidate
{
    public int MatchCandidateId { get; set; }
    public int FacultyId { get; set; }
    public string FacultyDisplayName { get; set; } = string.Empty;
    public string? DepartmentName { get; set; }
    public string OpenAlexAuthorId { get; set; } = string.Empty;
    public string? OpenAlexDisplayName { get; set; }
    public string? Orcid { get; set; }
    public string? LastKnownInstitution { get; set; }
    public int? WorksCount { get; set; }
    public int? CitedByCount { get; set; }
    public string MatchMethod { get; set; } = string.Empty;
    public decimal ConfidenceScore { get; set; }
    public string ReviewStatus { get; set; } = string.Empty;
    public string? EvidenceJson { get; set; }
    public DateTime CreatedUtc { get; set; }
}

public sealed class VerifiedAuthor
{
    public int FacultyId { get; set; }
    public string FacultyDisplayName { get; set; } = string.Empty;
    public string? DepartmentCode { get; set; }
    public string? DepartmentName { get; set; }
    public string OpenAlexAuthorId { get; set; } = string.Empty;
    public string? Orcid { get; set; }
    public string? OpenAlexDisplayName { get; set; }
}

public sealed class PublicationListItem
{
    public int FacultyWorkId { get; set; }
    public string FacultyDisplayName { get; set; } = string.Empty;
    public string? DepartmentName { get; set; }
    public string OpenAlexWorkId { get; set; } = string.Empty;
    public string? DisplayName { get; set; }
    public string? Title { get; set; }
    public string? Doi { get; set; }
    public string? Pmid { get; set; }
    public string? Pmcid { get; set; }
    public int? PublicationYear { get; set; }
    public DateTime? PublicationDate { get; set; }
    public string? WorkType { get; set; }
    public string? PrimarySourceName { get; set; }
    public int? CitedByCount { get; set; }
    public string? OpenAccessStatus { get; set; }
    public bool? IsOpenAccess { get; set; }
    public bool IsRetracted { get; set; }
    public string? AuthorPosition { get; set; }
    public bool? IsCorresponding { get; set; }
}

public sealed class DepartmentPublicationSummary
{
    public string DepartmentName { get; set; } = string.Empty;
    public int PublicationCount { get; set; }
    public int FacultyCount { get; set; }
    public int WithDoiCount { get; set; }
    public int WithPmidCount { get; set; }
    public int WithPmcidCount { get; set; }
    public int PmidWithoutPmcidCount { get; set; }
    public int OpenAccessCount { get; set; }
    public int RetractedCount { get; set; }
}

public sealed class SyncRunListItem
{
    public long SyncRunId { get; set; }
    public string SyncType { get; set; } = string.Empty;
    public string? ScopeType { get; set; }
    public string? ScopeValue { get; set; }
    public DateTime StartedUtc { get; set; }
    public DateTime? FinishedUtc { get; set; }
    public string Status { get; set; } = string.Empty;
    public int FacultyCount { get; set; }
    public int AuthorsChecked { get; set; }
    public int WorksInserted { get; set; }
    public int WorksUpdated { get; set; }
    public int WorksUnchanged { get; set; }
    public int ErrorsCount { get; set; }
    public string? Message { get; set; }
}

public sealed class ApiErrorListItem
{
    public long ApiErrorLogId { get; set; }
    public long? SyncRunId { get; set; }
    public string? Endpoint { get; set; }
    public string? QueryStringRedacted { get; set; }
    public int? HttpStatusCode { get; set; }
    public string? ErrorMessage { get; set; }
    public string? ResponseBody { get; set; }
    public int RetryCount { get; set; }
    public DateTime CreatedUtc { get; set; }
}
