USE FacultyPublicationIngestion;
GO

IF OBJECT_ID(N'dbo.usp_DashboardSummary', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_DashboardSummary;
GO
CREATE PROCEDURE dbo.usp_DashboardSummary
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        FacultyCount = (SELECT COUNT(*) FROM dbo.Faculty),
        ActiveFacultyCount = (SELECT COUNT(*) FROM dbo.Faculty WHERE IsActive = 1),
        VerifiedAuthorCount = (SELECT COUNT(*) FROM dbo.FacultyOpenAlexAuthor WHERE IsVerified = 1),
        CandidateCount = (SELECT COUNT(*) FROM dbo.OpenAlexMatchCandidate WHERE ReviewStatus IN ('Pending','NeedsMoreEvidence')),
        WorkCount = (SELECT COUNT(*) FROM dbo.OpenAlexWork),
        FacultyWorkCount = (SELECT COUNT(*) FROM dbo.FacultyWork WHERE IsActive = 1),
        PmidWithoutPmcidCount = (SELECT COUNT(*) FROM dbo.OpenAlexWork WHERE Pmid IS NOT NULL AND Pmcid IS NULL),
        RetractedWorkCount = (SELECT COUNT(*) FROM dbo.OpenAlexWork WHERE IsRetracted = 1),
        ErrorCount = (SELECT COUNT(*) FROM dbo.OpenAlexApiErrorLog);
END
GO

IF OBJECT_ID(N'dbo.usp_Faculty_List', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Faculty_List;
GO
CREATE PROCEDURE dbo.usp_Faculty_List
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        f.FacultyId,
        f.SourceFacultyId,
        f.DisplayName,
        f.Email,
        f.DepartmentCode,
        f.DepartmentName,
        f.AppointmentTitle,
        f.IsActive,
        f.IsPubliclyDisplayable,
        HasVerifiedOpenAlex = CAST(CASE WHEN EXISTS (SELECT 1 FROM dbo.FacultyOpenAlexAuthor a WHERE a.FacultyId = f.FacultyId AND a.IsVerified = 1) THEN 1 ELSE 0 END AS BIT),
        VerifiedOpenAlexAuthorId = (SELECT TOP (1) a.OpenAlexAuthorId FROM dbo.FacultyOpenAlexAuthor a WHERE a.FacultyId = f.FacultyId AND a.IsVerified = 1 ORDER BY a.IsPrimary DESC, a.VerifiedUtc DESC),
        CandidateCount = (SELECT COUNT(*) FROM dbo.OpenAlexMatchCandidate c WHERE c.FacultyId = f.FacultyId AND c.ReviewStatus IN ('Pending','NeedsMoreEvidence')),
        PublicationCount = (SELECT COUNT(*) FROM dbo.FacultyWork fw WHERE fw.FacultyId = f.FacultyId AND fw.IsActive = 1)
    FROM dbo.Faculty f
    ORDER BY f.DepartmentName, f.DisplayName;
END
GO

IF OBJECT_ID(N'dbo.usp_Faculty_Get', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Faculty_Get;
GO
CREATE PROCEDURE dbo.usp_Faculty_Get
    @FacultyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (1)
        f.FacultyId,
        f.SourceFacultyId,
        f.DisplayName,
        f.Email,
        f.DepartmentCode,
        f.DepartmentName,
        f.AppointmentTitle,
        f.IsActive,
        f.IsPubliclyDisplayable,
        VerifiedOpenAlexAuthorId = (SELECT TOP (1) a.OpenAlexAuthorId FROM dbo.FacultyOpenAlexAuthor a WHERE a.FacultyId = f.FacultyId AND a.IsVerified = 1 ORDER BY a.IsPrimary DESC, a.VerifiedUtc DESC),
        VerifiedOrcid = (SELECT TOP (1) a.Orcid FROM dbo.FacultyOpenAlexAuthor a WHERE a.FacultyId = f.FacultyId AND a.IsVerified = 1 ORDER BY a.IsPrimary DESC, a.VerifiedUtc DESC),
        PublicationCount = (SELECT COUNT(*) FROM dbo.FacultyWork fw WHERE fw.FacultyId = f.FacultyId AND fw.IsActive = 1)
    FROM dbo.Faculty f
    WHERE f.FacultyId = @FacultyId;
END
GO

IF OBJECT_ID(N'dbo.usp_FacultyOpenAlexAuthor_Verify', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FacultyOpenAlexAuthor_Verify;
GO
CREATE PROCEDURE dbo.usp_FacultyOpenAlexAuthor_Verify
    @FacultyId INT,
    @OpenAlexAuthorId NVARCHAR(100),
    @Orcid NVARCHAR(100) = NULL,
    @OpenAlexDisplayName NVARCHAR(300) = NULL,
    @LastKnownInstitution NVARCHAR(500) = NULL,
    @WorksCount INT = NULL,
    @CitedByCount INT = NULL,
    @MatchMethod NVARCHAR(50),
    @ConfidenceScore DECIMAL(5,2),
    @VerifiedBy NVARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    UPDATE dbo.FacultyOpenAlexAuthor
       SET Orcid = @Orcid,
           OpenAlexDisplayName = @OpenAlexDisplayName,
           LastKnownInstitution = @LastKnownInstitution,
           WorksCount = @WorksCount,
           CitedByCount = @CitedByCount,
           MatchMethod = @MatchMethod,
           ConfidenceScore = @ConfidenceScore,
           IsVerified = 1,
           IsPrimary = 1,
           VerifiedBy = @VerifiedBy,
           VerifiedUtc = SYSUTCDATETIME(),
           UpdatedUtc = SYSUTCDATETIME()
     WHERE FacultyId = @FacultyId
       AND OpenAlexAuthorId = @OpenAlexAuthorId;

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT dbo.FacultyOpenAlexAuthor
        (
            FacultyId, OpenAlexAuthorId, Orcid, OpenAlexDisplayName, LastKnownInstitution,
            WorksCount, CitedByCount, MatchMethod, ConfidenceScore, IsVerified, IsPrimary,
            VerifiedBy, VerifiedUtc
        )
        VALUES
        (
            @FacultyId, @OpenAlexAuthorId, @Orcid, @OpenAlexDisplayName, @LastKnownInstitution,
            @WorksCount, @CitedByCount, @MatchMethod, @ConfidenceScore, 1, 1,
            @VerifiedBy, SYSUTCDATETIME()
        );
    END

    UPDATE dbo.OpenAlexMatchCandidate
       SET ReviewStatus = 'Approved', ReviewedBy = @VerifiedBy, ReviewedUtc = SYSUTCDATETIME()
     WHERE FacultyId = @FacultyId AND OpenAlexAuthorId = @OpenAlexAuthorId;

    COMMIT;
END
GO

IF OBJECT_ID(N'dbo.usp_OpenAlexMatchCandidate_Upsert', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OpenAlexMatchCandidate_Upsert;
GO
CREATE PROCEDURE dbo.usp_OpenAlexMatchCandidate_Upsert
    @FacultyId INT,
    @OpenAlexAuthorId NVARCHAR(100),
    @OpenAlexDisplayName NVARCHAR(300) = NULL,
    @Orcid NVARCHAR(100) = NULL,
    @LastKnownInstitution NVARCHAR(500) = NULL,
    @WorksCount INT = NULL,
    @CitedByCount INT = NULL,
    @MatchMethod NVARCHAR(50),
    @ConfidenceScore DECIMAL(5,2),
    @EvidenceJson NVARCHAR(MAX) = NULL,
    @ReviewStatus NVARCHAR(50) = 'Pending'
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.OpenAlexMatchCandidate
       SET OpenAlexDisplayName = @OpenAlexDisplayName,
           Orcid = @Orcid,
           LastKnownInstitution = @LastKnownInstitution,
           WorksCount = @WorksCount,
           CitedByCount = @CitedByCount,
           MatchMethod = @MatchMethod,
           ConfidenceScore = @ConfidenceScore,
           EvidenceJson = @EvidenceJson,
           ReviewStatus = @ReviewStatus
     WHERE FacultyId = @FacultyId
       AND OpenAlexAuthorId = @OpenAlexAuthorId
       AND ReviewStatus IN ('Pending','NeedsMoreEvidence');

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT dbo.OpenAlexMatchCandidate
        (FacultyId, OpenAlexAuthorId, OpenAlexDisplayName, Orcid, LastKnownInstitution, WorksCount, CitedByCount, MatchMethod, ConfidenceScore, EvidenceJson, ReviewStatus)
        VALUES
        (@FacultyId, @OpenAlexAuthorId, @OpenAlexDisplayName, @Orcid, @LastKnownInstitution, @WorksCount, @CitedByCount, @MatchMethod, @ConfidenceScore, @EvidenceJson, @ReviewStatus);
    END
END
GO

IF OBJECT_ID(N'dbo.usp_MatchCandidates_List', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_MatchCandidates_List;
GO
CREATE PROCEDURE dbo.usp_MatchCandidates_List
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.MatchCandidateId, c.FacultyId, f.DisplayName AS FacultyDisplayName, f.DepartmentName,
           c.OpenAlexAuthorId, c.OpenAlexDisplayName, c.Orcid, c.LastKnownInstitution,
           c.WorksCount, c.CitedByCount, c.MatchMethod, c.ConfidenceScore,
           c.ReviewStatus, c.EvidenceJson, c.CreatedUtc
    FROM dbo.OpenAlexMatchCandidate c
    INNER JOIN dbo.Faculty f ON f.FacultyId = c.FacultyId
    ORDER BY CASE c.ReviewStatus WHEN 'Pending' THEN 1 WHEN 'NeedsMoreEvidence' THEN 2 ELSE 3 END, c.CreatedUtc DESC;
END
GO

IF OBJECT_ID(N'dbo.usp_MatchCandidate_Reject', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_MatchCandidate_Reject;
GO
CREATE PROCEDURE dbo.usp_MatchCandidate_Reject
    @MatchCandidateId INT,
    @ReviewedBy NVARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.OpenAlexMatchCandidate
       SET ReviewStatus = 'Rejected', ReviewedBy = @ReviewedBy, ReviewedUtc = SYSUTCDATETIME()
     WHERE MatchCandidateId = @MatchCandidateId;
END
GO

IF OBJECT_ID(N'dbo.usp_VerifiedAuthorsForSync_List', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_VerifiedAuthorsForSync_List;
GO
CREATE PROCEDURE dbo.usp_VerifiedAuthorsForSync_List
    @FacultyId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT f.FacultyId, f.DisplayName AS FacultyDisplayName, f.DepartmentCode, f.DepartmentName,
           a.OpenAlexAuthorId, a.Orcid, a.OpenAlexDisplayName
    FROM dbo.FacultyOpenAlexAuthor a
    INNER JOIN dbo.Faculty f ON f.FacultyId = a.FacultyId
    WHERE a.IsVerified = 1
      AND f.IsActive = 1
      AND (@FacultyId IS NULL OR f.FacultyId = @FacultyId)
    ORDER BY f.DepartmentName, f.DisplayName;
END
GO

IF OBJECT_ID(N'dbo.usp_OpenAlexSyncRun_Start', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OpenAlexSyncRun_Start;
GO
CREATE PROCEDURE dbo.usp_OpenAlexSyncRun_Start
    @SyncType NVARCHAR(50),
    @ScopeType NVARCHAR(50) = NULL,
    @ScopeValue NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.OpenAlexSyncRun (SyncType, ScopeType, ScopeValue)
    VALUES (@SyncType, @ScopeType, @ScopeValue);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS SyncRunId;
END
GO

IF OBJECT_ID(N'dbo.usp_OpenAlexSyncRun_Finish', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OpenAlexSyncRun_Finish;
GO
CREATE PROCEDURE dbo.usp_OpenAlexSyncRun_Finish
    @SyncRunId BIGINT,
    @Status NVARCHAR(50),
    @FacultyCount INT,
    @AuthorsChecked INT,
    @WorksInserted INT,
    @WorksUpdated INT,
    @WorksUnchanged INT,
    @ErrorsCount INT,
    @Message NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.OpenAlexSyncRun
       SET FinishedUtc = SYSUTCDATETIME(),
           Status = @Status,
           FacultyCount = @FacultyCount,
           AuthorsChecked = @AuthorsChecked,
           WorksInserted = @WorksInserted,
           WorksUpdated = @WorksUpdated,
           WorksUnchanged = @WorksUnchanged,
           ErrorsCount = @ErrorsCount,
           Message = @Message
     WHERE SyncRunId = @SyncRunId;
END
GO

IF OBJECT_ID(N'dbo.usp_OpenAlexApiErrorLog_Insert', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OpenAlexApiErrorLog_Insert;
GO
CREATE PROCEDURE dbo.usp_OpenAlexApiErrorLog_Insert
    @SyncRunId BIGINT = NULL,
    @Endpoint NVARCHAR(500) = NULL,
    @QueryStringRedacted NVARCHAR(MAX) = NULL,
    @HttpStatusCode INT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL,
    @ResponseBody NVARCHAR(MAX) = NULL,
    @RetryCount INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.OpenAlexApiErrorLog
    (SyncRunId, Endpoint, QueryStringRedacted, HttpStatusCode, ErrorMessage, ResponseBody, RetryCount)
    VALUES
    (@SyncRunId, @Endpoint, @QueryStringRedacted, @HttpStatusCode, @ErrorMessage, @ResponseBody, @RetryCount);
END
GO

IF OBJECT_ID(N'dbo.usp_OpenAlexSource_Upsert', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OpenAlexSource_Upsert;
GO
CREATE PROCEDURE dbo.usp_OpenAlexSource_Upsert
    @OpenAlexSourceId NVARCHAR(100),
    @DisplayName NVARCHAR(500) = NULL,
    @IssnL NVARCHAR(50) = NULL,
    @IssnJson NVARCHAR(MAX) = NULL,
    @SourceType NVARCHAR(100) = NULL,
    @IsOpenAccess BIT = NULL,
    @IsInDoaj BIT = NULL,
    @HostOrganization NVARCHAR(200) = NULL,
    @HostOrganizationName NVARCHAR(500) = NULL,
    @RawJson NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.OpenAlexSource
       SET DisplayName = @DisplayName,
           IssnL = @IssnL,
           IssnJson = @IssnJson,
           SourceType = @SourceType,
           IsOpenAccess = @IsOpenAccess,
           IsInDoaj = @IsInDoaj,
           HostOrganization = @HostOrganization,
           HostOrganizationName = @HostOrganizationName,
           RawJson = @RawJson,
           UpdatedUtc = SYSUTCDATETIME()
     WHERE OpenAlexSourceId = @OpenAlexSourceId;

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT dbo.OpenAlexSource
        (OpenAlexSourceId, DisplayName, IssnL, IssnJson, SourceType, IsOpenAccess, IsInDoaj, HostOrganization, HostOrganizationName, RawJson)
        VALUES
        (@OpenAlexSourceId, @DisplayName, @IssnL, @IssnJson, @SourceType, @IsOpenAccess, @IsInDoaj, @HostOrganization, @HostOrganizationName, @RawJson);
    END
END
GO

IF OBJECT_ID(N'dbo.usp_OpenAlexWork_Upsert', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OpenAlexWork_Upsert;
GO
CREATE PROCEDURE dbo.usp_OpenAlexWork_Upsert
    @OpenAlexWorkId NVARCHAR(100),
    @Doi NVARCHAR(500) = NULL,
    @Pmid NVARCHAR(100) = NULL,
    @Pmcid NVARCHAR(100) = NULL,
    @Title NVARCHAR(MAX) = NULL,
    @DisplayName NVARCHAR(MAX) = NULL,
    @PublicationYear INT = NULL,
    @PublicationDate DATE = NULL,
    @WorkType NVARCHAR(100) = NULL,
    @LanguageCode NVARCHAR(20) = NULL,
    @CitedByCount INT = NULL,
    @IsRetracted BIT = 0,
    @IsParatext BIT = 0,
    @PrimarySourceId NVARCHAR(100) = NULL,
    @PrimarySourceName NVARCHAR(500) = NULL,
    @OpenAccessStatus NVARCHAR(100) = NULL,
    @IsOpenAccess BIT = NULL,
    @BestOpenAccessUrl NVARCHAR(1000) = NULL,
    @LandingPageUrl NVARCHAR(1000) = NULL,
    @PdfUrl NVARCHAR(1000) = NULL,
    @ReferencedWorksJson NVARCHAR(MAX) = NULL,
    @RelatedWorksJson NVARCHAR(MAX) = NULL,
    @IndexedInJson NVARCHAR(MAX) = NULL,
    @MeshJson NVARCHAR(MAX) = NULL,
    @OpenAlexCreatedDate DATE = NULL,
    @OpenAlexUpdatedDateUtc DATETIME2 = NULL,
    @RawJson NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IncomingHash VARBINARY(32) = CASE WHEN @RawJson IS NULL THEN NULL ELSE HASHBYTES('SHA2_256', CONVERT(NVARCHAR(MAX), @RawJson)) END;
    DECLARE @ExistingHash VARBINARY(32);
    DECLARE @Action NVARCHAR(20) = 'Unchanged';

    SELECT @ExistingHash = RawJsonHash FROM dbo.OpenAlexWork WHERE OpenAlexWorkId = @OpenAlexWorkId;

    IF @ExistingHash IS NULL AND NOT EXISTS (SELECT 1 FROM dbo.OpenAlexWork WHERE OpenAlexWorkId = @OpenAlexWorkId)
    BEGIN
        INSERT dbo.OpenAlexWork
        (
            OpenAlexWorkId, Doi, Pmid, Pmcid, Title, DisplayName, PublicationYear, PublicationDate,
            WorkType, LanguageCode, CitedByCount, IsRetracted, IsParatext, PrimarySourceId,
            PrimarySourceName, OpenAccessStatus, IsOpenAccess, BestOpenAccessUrl, LandingPageUrl,
            PdfUrl, ReferencedWorksJson, RelatedWorksJson, IndexedInJson, MeshJson,
            OpenAlexCreatedDate, OpenAlexUpdatedDateUtc, RawJsonHash, RawJson
        )
        VALUES
        (
            @OpenAlexWorkId, @Doi, @Pmid, @Pmcid, @Title, @DisplayName, @PublicationYear, @PublicationDate,
            @WorkType, @LanguageCode, @CitedByCount, @IsRetracted, @IsParatext, @PrimarySourceId,
            @PrimarySourceName, @OpenAccessStatus, @IsOpenAccess, @BestOpenAccessUrl, @LandingPageUrl,
            @PdfUrl, @ReferencedWorksJson, @RelatedWorksJson, @IndexedInJson, @MeshJson,
            @OpenAlexCreatedDate, @OpenAlexUpdatedDateUtc, @IncomingHash, @RawJson
        );
        SET @Action = 'Inserted';
    END
    ELSE
    BEGIN
        UPDATE dbo.OpenAlexWork
           SET Doi = @Doi,
               Pmid = @Pmid,
               Pmcid = @Pmcid,
               Title = @Title,
               DisplayName = @DisplayName,
               PublicationYear = @PublicationYear,
               PublicationDate = @PublicationDate,
               WorkType = @WorkType,
               LanguageCode = @LanguageCode,
               CitedByCount = @CitedByCount,
               IsRetracted = @IsRetracted,
               IsParatext = @IsParatext,
               PrimarySourceId = @PrimarySourceId,
               PrimarySourceName = @PrimarySourceName,
               OpenAccessStatus = @OpenAccessStatus,
               IsOpenAccess = @IsOpenAccess,
               BestOpenAccessUrl = @BestOpenAccessUrl,
               LandingPageUrl = @LandingPageUrl,
               PdfUrl = @PdfUrl,
               ReferencedWorksJson = @ReferencedWorksJson,
               RelatedWorksJson = @RelatedWorksJson,
               IndexedInJson = @IndexedInJson,
               MeshJson = @MeshJson,
               OpenAlexCreatedDate = @OpenAlexCreatedDate,
               OpenAlexUpdatedDateUtc = @OpenAlexUpdatedDateUtc,
               RawJsonHash = @IncomingHash,
               RawJson = @RawJson,
               LastSeenUtc = SYSUTCDATETIME(),
               UpdatedUtc = SYSUTCDATETIME()
         WHERE OpenAlexWorkId = @OpenAlexWorkId;

        IF ISNULL(CONVERT(VARCHAR(64), @ExistingHash, 2), '') <> ISNULL(CONVERT(VARCHAR(64), @IncomingHash, 2), '')
            SET @Action = 'Updated';
    END

    SELECT @Action AS UpsertAction;
END
GO

IF OBJECT_ID(N'dbo.usp_OpenAlexWorkAuthorship_DeleteForWork', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OpenAlexWorkAuthorship_DeleteForWork;
GO
CREATE PROCEDURE dbo.usp_OpenAlexWorkAuthorship_DeleteForWork
    @OpenAlexWorkId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.OpenAlexWorkAuthorship WHERE OpenAlexWorkId = @OpenAlexWorkId;
END
GO

IF OBJECT_ID(N'dbo.usp_OpenAlexWorkAuthorship_Insert', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OpenAlexWorkAuthorship_Insert;
GO
CREATE PROCEDURE dbo.usp_OpenAlexWorkAuthorship_Insert
    @OpenAlexWorkId NVARCHAR(100),
    @OpenAlexAuthorId NVARCHAR(100) = NULL,
    @AuthorDisplayName NVARCHAR(300) = NULL,
    @Orcid NVARCHAR(100) = NULL,
    @AuthorPosition NVARCHAR(50) = NULL,
    @IsCorresponding BIT = NULL,
    @InstitutionJson NVARCHAR(MAX) = NULL,
    @AffiliationJson NVARCHAR(MAX) = NULL,
    @RawAffiliationStringsJson NVARCHAR(MAX) = NULL,
    @CountriesJson NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.OpenAlexWorkAuthorship
    (OpenAlexWorkId, OpenAlexAuthorId, AuthorDisplayName, Orcid, AuthorPosition, IsCorresponding, InstitutionJson, AffiliationJson, RawAffiliationStringsJson, CountriesJson)
    VALUES
    (@OpenAlexWorkId, @OpenAlexAuthorId, @AuthorDisplayName, @Orcid, @AuthorPosition, @IsCorresponding, @InstitutionJson, @AffiliationJson, @RawAffiliationStringsJson, @CountriesJson);
END
GO

IF OBJECT_ID(N'dbo.usp_FacultyWork_Upsert', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FacultyWork_Upsert;
GO
CREATE PROCEDURE dbo.usp_FacultyWork_Upsert
    @FacultyId INT,
    @OpenAlexWorkId NVARCHAR(100),
    @OpenAlexAuthorId NVARCHAR(100),
    @AuthorPosition NVARCHAR(50) = NULL,
    @IsCorresponding BIT = NULL,
    @MatchSource NVARCHAR(50) = 'OpenAlexAuthorship'
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.FacultyWork
       SET OpenAlexAuthorId = @OpenAlexAuthorId,
           AuthorPosition = @AuthorPosition,
           IsCorresponding = @IsCorresponding,
           MatchSource = @MatchSource,
           IsActive = 1,
           LastSeenUtc = SYSUTCDATETIME()
     WHERE FacultyId = @FacultyId
       AND OpenAlexWorkId = @OpenAlexWorkId;

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT dbo.FacultyWork
        (FacultyId, OpenAlexWorkId, OpenAlexAuthorId, AuthorPosition, IsCorresponding, MatchSource)
        VALUES
        (@FacultyId, @OpenAlexWorkId, @OpenAlexAuthorId, @AuthorPosition, @IsCorresponding, @MatchSource);
    END
END
GO

IF OBJECT_ID(N'dbo.usp_Publications_List', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Publications_List;
GO
CREATE PROCEDURE dbo.usp_Publications_List
    @FacultyId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        fw.FacultyWorkId,
        f.DisplayName AS FacultyDisplayName,
        f.DepartmentName,
        w.OpenAlexWorkId,
        w.DisplayName,
        w.Title,
        w.Doi,
        w.Pmid,
        w.Pmcid,
        w.PublicationYear,
        w.PublicationDate,
        w.WorkType,
        w.PrimarySourceName,
        w.CitedByCount,
        w.OpenAccessStatus,
        w.IsOpenAccess,
        w.IsRetracted,
        fw.AuthorPosition,
        fw.IsCorresponding
    FROM dbo.FacultyWork fw
    INNER JOIN dbo.Faculty f ON f.FacultyId = fw.FacultyId
    INNER JOIN dbo.OpenAlexWork w ON w.OpenAlexWorkId = fw.OpenAlexWorkId
    WHERE (@FacultyId IS NULL OR fw.FacultyId = @FacultyId)
    ORDER BY w.PublicationYear DESC, w.PublicationDate DESC, w.DisplayName;
END
GO

IF OBJECT_ID(N'dbo.usp_Publications_ByDepartment', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Publications_ByDepartment;
GO
CREATE PROCEDURE dbo.usp_Publications_ByDepartment
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        DepartmentName = ISNULL(f.DepartmentName, '(No Department)'),
        PublicationCount = COUNT(DISTINCT fw.OpenAlexWorkId),
        FacultyCount = COUNT(DISTINCT f.FacultyId),
        WithDoiCount = COUNT(DISTINCT CASE WHEN w.Doi IS NOT NULL THEN fw.OpenAlexWorkId END),
        WithPmidCount = COUNT(DISTINCT CASE WHEN w.Pmid IS NOT NULL THEN fw.OpenAlexWorkId END),
        WithPmcidCount = COUNT(DISTINCT CASE WHEN w.Pmcid IS NOT NULL THEN fw.OpenAlexWorkId END),
        PmidWithoutPmcidCount = COUNT(DISTINCT CASE WHEN w.Pmid IS NOT NULL AND w.Pmcid IS NULL THEN fw.OpenAlexWorkId END),
        OpenAccessCount = COUNT(DISTINCT CASE WHEN w.IsOpenAccess = 1 THEN fw.OpenAlexWorkId END),
        RetractedCount = COUNT(DISTINCT CASE WHEN w.IsRetracted = 1 THEN fw.OpenAlexWorkId END)
    FROM dbo.FacultyWork fw
    INNER JOIN dbo.Faculty f ON f.FacultyId = fw.FacultyId
    INNER JOIN dbo.OpenAlexWork w ON w.OpenAlexWorkId = fw.OpenAlexWorkId
    GROUP BY ISNULL(f.DepartmentName, '(No Department)')
    ORDER BY PublicationCount DESC, DepartmentName;
END
GO

IF OBJECT_ID(N'dbo.usp_SyncRuns_List', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_SyncRuns_List;
GO
CREATE PROCEDURE dbo.usp_SyncRuns_List
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (50) SyncRunId, SyncType, ScopeType, ScopeValue, StartedUtc, FinishedUtc, Status,
           FacultyCount, AuthorsChecked, WorksInserted, WorksUpdated, WorksUnchanged, ErrorsCount, Message
    FROM dbo.OpenAlexSyncRun
    ORDER BY SyncRunId DESC;
END
GO

IF OBJECT_ID(N'dbo.usp_Errors_List', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Errors_List;
GO
CREATE PROCEDURE dbo.usp_Errors_List
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (100) ApiErrorLogId, SyncRunId, Endpoint, QueryStringRedacted, HttpStatusCode,
           ErrorMessage, ResponseBody, RetryCount, CreatedUtc
    FROM dbo.OpenAlexApiErrorLog
    ORDER BY ApiErrorLogId DESC;
END
GO

IF OBJECT_ID(N'dbo.usp_OpenAlexTopic_Upsert', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OpenAlexTopic_Upsert;
GO
CREATE PROCEDURE dbo.usp_OpenAlexTopic_Upsert
    @OpenAlexTopicId NVARCHAR(100),
    @DisplayName NVARCHAR(500) = NULL,
    @RawJson NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.OpenAlexTopic
       SET DisplayName = @DisplayName,
           RawJson = @RawJson,
           UpdatedUtc = SYSUTCDATETIME()
     WHERE OpenAlexTopicId = @OpenAlexTopicId;

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT dbo.OpenAlexTopic (OpenAlexTopicId, DisplayName, RawJson)
        VALUES (@OpenAlexTopicId, @DisplayName, @RawJson);
    END
END
GO

IF OBJECT_ID(N'dbo.usp_OpenAlexWorkTopic_DeleteForWork', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OpenAlexWorkTopic_DeleteForWork;
GO
CREATE PROCEDURE dbo.usp_OpenAlexWorkTopic_DeleteForWork
    @OpenAlexWorkId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.OpenAlexWorkTopic WHERE OpenAlexWorkId = @OpenAlexWorkId;
END
GO

IF OBJECT_ID(N'dbo.usp_OpenAlexWorkTopic_Insert', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OpenAlexWorkTopic_Insert;
GO
CREATE PROCEDURE dbo.usp_OpenAlexWorkTopic_Insert
    @OpenAlexWorkId NVARCHAR(100),
    @OpenAlexTopicId NVARCHAR(100),
    @Score DECIMAL(10,6) = NULL,
    @IsPrimary BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.OpenAlexWorkTopic WHERE OpenAlexWorkId = @OpenAlexWorkId AND OpenAlexTopicId = @OpenAlexTopicId)
    BEGIN
        INSERT dbo.OpenAlexWorkTopic (OpenAlexWorkId, OpenAlexTopicId, Score, IsPrimary)
        VALUES (@OpenAlexWorkId, @OpenAlexTopicId, @Score, @IsPrimary);
    END
END
GO


/*
    Faculty Admin CRUD procedures
    SQL Server 2016-compatible pattern: IF OBJECT_ID + DROP + CREATE.
    The delete action is intentionally implemented as a soft delete/deactivate
    for prototype safety and auditability.
*/
IF OBJECT_ID(N'dbo.usp_FacultyAdmin_List', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FacultyAdmin_List;
GO
CREATE PROCEDURE dbo.usp_FacultyAdmin_List
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        f.FacultyId,
        f.SourceFacultyId,
        f.EmployeeId,
        f.ComputingId,
        f.FirstName,
        f.MiddleName,
        f.LastName,
        f.DisplayName,
        f.Email,
        f.DepartmentCode,
        f.DepartmentName,
        f.AppointmentTitle,
        f.IsActive,
        f.IsPubliclyDisplayable,
        f.SourceLastModifiedUtc,
        f.CreatedUtc,
        f.UpdatedUtc
    FROM dbo.Faculty f
    ORDER BY f.LastName, f.FirstName;
END;
GO

IF OBJECT_ID(N'dbo.usp_FacultyAdmin_Create', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FacultyAdmin_Create;
GO
CREATE PROCEDURE dbo.usp_FacultyAdmin_Create
    @SourceFacultyId NVARCHAR(100) = NULL,
    @EmployeeId NVARCHAR(100) = NULL,
    @ComputingId NVARCHAR(100) = NULL,
    @FirstName NVARCHAR(150),
    @MiddleName NVARCHAR(150) = NULL,
    @LastName NVARCHAR(150),
    @DisplayName NVARCHAR(300) = NULL,
    @Email NVARCHAR(320) = NULL,
    @DepartmentCode NVARCHAR(50) = NULL,
    @DepartmentName NVARCHAR(250) = NULL,
    @AppointmentTitle NVARCHAR(250) = NULL,
    @IsActive BIT = 1,
    @IsPubliclyDisplayable BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF NULLIF(LTRIM(RTRIM(@SourceFacultyId)), N'') IS NULL
    BEGIN
        SET @SourceFacultyId = N'LOCAL-' + LEFT(CONVERT(NVARCHAR(36), NEWID()), 8);
    END;

    IF NULLIF(LTRIM(RTRIM(@DisplayName)), N'') IS NULL
    BEGIN
        SET @DisplayName = LTRIM(RTRIM(CONCAT(@FirstName, N' ', ISNULL(@MiddleName + N' ', N''), @LastName)));
    END;

    INSERT dbo.Faculty
    (
        SourceFacultyId,
        EmployeeId,
        ComputingId,
        FirstName,
        MiddleName,
        LastName,
        DisplayName,
        Email,
        DepartmentCode,
        DepartmentName,
        AppointmentTitle,
        IsActive,
        IsPubliclyDisplayable,
        SourceLastModifiedUtc
    )
    VALUES
    (
        @SourceFacultyId,
        NULLIF(LTRIM(RTRIM(@EmployeeId)), N''),
        NULLIF(LTRIM(RTRIM(@ComputingId)), N''),
        @FirstName,
        NULLIF(LTRIM(RTRIM(@MiddleName)), N''),
        @LastName,
        @DisplayName,
        NULLIF(LTRIM(RTRIM(@Email)), N''),
        NULLIF(LTRIM(RTRIM(@DepartmentCode)), N''),
        NULLIF(LTRIM(RTRIM(@DepartmentName)), N''),
        NULLIF(LTRIM(RTRIM(@AppointmentTitle)), N''),
        @IsActive,
        @IsPubliclyDisplayable,
        SYSUTCDATETIME()
    );

    SELECT CONVERT(INT, SCOPE_IDENTITY()) AS FacultyId;
END;
GO

IF OBJECT_ID(N'dbo.usp_FacultyAdmin_Update', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FacultyAdmin_Update;
GO
CREATE PROCEDURE dbo.usp_FacultyAdmin_Update
    @FacultyId INT,
    @SourceFacultyId NVARCHAR(100),
    @EmployeeId NVARCHAR(100) = NULL,
    @ComputingId NVARCHAR(100) = NULL,
    @FirstName NVARCHAR(150),
    @MiddleName NVARCHAR(150) = NULL,
    @LastName NVARCHAR(150),
    @DisplayName NVARCHAR(300) = NULL,
    @Email NVARCHAR(320) = NULL,
    @DepartmentCode NVARCHAR(50) = NULL,
    @DepartmentName NVARCHAR(250) = NULL,
    @AppointmentTitle NVARCHAR(250) = NULL,
    @IsActive BIT = 1,
    @IsPubliclyDisplayable BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF NULLIF(LTRIM(RTRIM(@DisplayName)), N'') IS NULL
    BEGIN
        SET @DisplayName = LTRIM(RTRIM(CONCAT(@FirstName, N' ', ISNULL(@MiddleName + N' ', N''), @LastName)));
    END;

    UPDATE dbo.Faculty
    SET
        SourceFacultyId = @SourceFacultyId,
        EmployeeId = NULLIF(LTRIM(RTRIM(@EmployeeId)), N''),
        ComputingId = NULLIF(LTRIM(RTRIM(@ComputingId)), N''),
        FirstName = @FirstName,
        MiddleName = NULLIF(LTRIM(RTRIM(@MiddleName)), N''),
        LastName = @LastName,
        DisplayName = @DisplayName,
        Email = NULLIF(LTRIM(RTRIM(@Email)), N''),
        DepartmentCode = NULLIF(LTRIM(RTRIM(@DepartmentCode)), N''),
        DepartmentName = NULLIF(LTRIM(RTRIM(@DepartmentName)), N''),
        AppointmentTitle = NULLIF(LTRIM(RTRIM(@AppointmentTitle)), N''),
        IsActive = @IsActive,
        IsPubliclyDisplayable = @IsPubliclyDisplayable,
        SourceLastModifiedUtc = SYSUTCDATETIME(),
        UpdatedUtc = SYSUTCDATETIME()
    WHERE FacultyId = @FacultyId;
END;
GO

IF OBJECT_ID(N'dbo.usp_FacultyAdmin_SetActive', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FacultyAdmin_SetActive;
GO
CREATE PROCEDURE dbo.usp_FacultyAdmin_SetActive
    @FacultyId INT,
    @IsActive BIT,
    @IsPubliclyDisplayable BIT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Faculty
    SET
        IsActive = @IsActive,
        IsPubliclyDisplayable = @IsPubliclyDisplayable,
        UpdatedUtc = SYSUTCDATETIME()
    WHERE FacultyId = @FacultyId;
END;
GO

IF OBJECT_ID(N'dbo.usp_FacultyAdmin_SoftDelete', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FacultyAdmin_SoftDelete;
GO
CREATE PROCEDURE dbo.usp_FacultyAdmin_SoftDelete
    @FacultyId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Faculty
    SET
        IsActive = 0,
        IsPubliclyDisplayable = 0,
        UpdatedUtc = SYSUTCDATETIME()
    WHERE FacultyId = @FacultyId;
END;
GO
