USE FacultyPublicationIngestion;
GO

CREATE TABLE dbo.Faculty
(
    FacultyId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Faculty PRIMARY KEY,
    SourceFacultyId NVARCHAR(100) NOT NULL,
    EmployeeId NVARCHAR(100) NULL,
    ComputingId NVARCHAR(100) NULL,
    FirstName NVARCHAR(150) NOT NULL,
    MiddleName NVARCHAR(150) NULL,
    LastName NVARCHAR(150) NOT NULL,
    DisplayName NVARCHAR(300) NOT NULL,
    Email NVARCHAR(320) NULL,
    DepartmentCode NVARCHAR(50) NULL,
    DepartmentName NVARCHAR(250) NULL,
    AppointmentTitle NVARCHAR(250) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Faculty_IsActive DEFAULT 1,
    IsPubliclyDisplayable BIT NOT NULL CONSTRAINT DF_Faculty_IsPubliclyDisplayable DEFAULT 1,
    SourceLastModifiedUtc DATETIME2 NULL,
    CreatedUtc DATETIME2 NOT NULL CONSTRAINT DF_Faculty_CreatedUtc DEFAULT SYSUTCDATETIME(),
    UpdatedUtc DATETIME2 NOT NULL CONSTRAINT DF_Faculty_UpdatedUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_Faculty_SourceFacultyId UNIQUE (SourceFacultyId)
);
GO
CREATE INDEX IX_Faculty_Email ON dbo.Faculty(Email);
CREATE INDEX IX_Faculty_DepartmentCode ON dbo.Faculty(DepartmentCode);
CREATE INDEX IX_Faculty_IsActive ON dbo.Faculty(IsActive);
GO

CREATE TABLE dbo.FacultyDepartment
(
    FacultyDepartmentId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FacultyDepartment PRIMARY KEY,
    FacultyId INT NOT NULL,
    DepartmentCode NVARCHAR(50) NOT NULL,
    DepartmentName NVARCHAR(250) NOT NULL,
    AppointmentTitle NVARCHAR(250) NULL,
    IsPrimary BIT NOT NULL CONSTRAINT DF_FacultyDepartment_IsPrimary DEFAULT 0,
    IsActive BIT NOT NULL CONSTRAINT DF_FacultyDepartment_IsActive DEFAULT 1,
    CreatedUtc DATETIME2 NOT NULL CONSTRAINT DF_FacultyDepartment_CreatedUtc DEFAULT SYSUTCDATETIME(),
    UpdatedUtc DATETIME2 NOT NULL CONSTRAINT DF_FacultyDepartment_UpdatedUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_FacultyDepartment_Faculty FOREIGN KEY (FacultyId) REFERENCES dbo.Faculty(FacultyId),
    CONSTRAINT UQ_FacultyDepartment_Faculty_Department UNIQUE (FacultyId, DepartmentCode)
);
GO

CREATE TABLE dbo.FacultyOpenAlexAuthor
(
    FacultyOpenAlexAuthorId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FacultyOpenAlexAuthor PRIMARY KEY,
    FacultyId INT NOT NULL,
    OpenAlexAuthorId NVARCHAR(100) NOT NULL,
    Orcid NVARCHAR(100) NULL,
    OpenAlexDisplayName NVARCHAR(300) NULL,
    LastKnownInstitution NVARCHAR(500) NULL,
    WorksCount INT NULL,
    CitedByCount INT NULL,
    MatchMethod NVARCHAR(50) NOT NULL,
    ConfidenceScore DECIMAL(5,2) NOT NULL CONSTRAINT DF_FacultyOpenAlexAuthor_ConfidenceScore DEFAULT 0,
    IsVerified BIT NOT NULL CONSTRAINT DF_FacultyOpenAlexAuthor_IsVerified DEFAULT 0,
    IsPrimary BIT NOT NULL CONSTRAINT DF_FacultyOpenAlexAuthor_IsPrimary DEFAULT 1,
    VerifiedBy NVARCHAR(150) NULL,
    VerifiedUtc DATETIME2 NULL,
    LastCheckedUtc DATETIME2 NULL,
    CreatedUtc DATETIME2 NOT NULL CONSTRAINT DF_FacultyOpenAlexAuthor_CreatedUtc DEFAULT SYSUTCDATETIME(),
    UpdatedUtc DATETIME2 NOT NULL CONSTRAINT DF_FacultyOpenAlexAuthor_UpdatedUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_FacultyOpenAlexAuthor_Faculty FOREIGN KEY (FacultyId) REFERENCES dbo.Faculty(FacultyId),
    CONSTRAINT UQ_FacultyOpenAlexAuthor_Faculty_OpenAlex UNIQUE (FacultyId, OpenAlexAuthorId)
);
GO
CREATE INDEX IX_FacultyOpenAlexAuthor_OpenAlexAuthorId ON dbo.FacultyOpenAlexAuthor(OpenAlexAuthorId);
CREATE INDEX IX_FacultyOpenAlexAuthor_IsVerified ON dbo.FacultyOpenAlexAuthor(IsVerified);
GO

CREATE TABLE dbo.OpenAlexMatchCandidate
(
    MatchCandidateId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OpenAlexMatchCandidate PRIMARY KEY,
    FacultyId INT NOT NULL,
    OpenAlexAuthorId NVARCHAR(100) NOT NULL,
    OpenAlexDisplayName NVARCHAR(300) NULL,
    Orcid NVARCHAR(100) NULL,
    LastKnownInstitution NVARCHAR(500) NULL,
    WorksCount INT NULL,
    CitedByCount INT NULL,
    MatchMethod NVARCHAR(50) NOT NULL,
    ConfidenceScore DECIMAL(5,2) NOT NULL,
    EvidenceJson NVARCHAR(MAX) NULL,
    ReviewStatus NVARCHAR(50) NOT NULL CONSTRAINT DF_OpenAlexMatchCandidate_ReviewStatus DEFAULT 'Pending',
    ReviewedBy NVARCHAR(150) NULL,
    ReviewedUtc DATETIME2 NULL,
    CreatedUtc DATETIME2 NOT NULL CONSTRAINT DF_OpenAlexMatchCandidate_CreatedUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_OpenAlexMatchCandidate_Faculty FOREIGN KEY (FacultyId) REFERENCES dbo.Faculty(FacultyId)
);
GO
CREATE INDEX IX_OpenAlexMatchCandidate_FacultyId ON dbo.OpenAlexMatchCandidate(FacultyId);
CREATE INDEX IX_OpenAlexMatchCandidate_ReviewStatus ON dbo.OpenAlexMatchCandidate(ReviewStatus);
GO

CREATE TABLE dbo.OpenAlexSource
(
    OpenAlexSourceId NVARCHAR(100) NOT NULL CONSTRAINT PK_OpenAlexSource PRIMARY KEY,
    DisplayName NVARCHAR(500) NULL,
    IssnL NVARCHAR(50) NULL,
    IssnJson NVARCHAR(MAX) NULL,
    SourceType NVARCHAR(100) NULL,
    IsOpenAccess BIT NULL,
    IsInDoaj BIT NULL,
    HostOrganization NVARCHAR(200) NULL,
    HostOrganizationName NVARCHAR(500) NULL,
    RawJson NVARCHAR(MAX) NULL,
    CreatedUtc DATETIME2 NOT NULL CONSTRAINT DF_OpenAlexSource_CreatedUtc DEFAULT SYSUTCDATETIME(),
    UpdatedUtc DATETIME2 NOT NULL CONSTRAINT DF_OpenAlexSource_UpdatedUtc DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE dbo.OpenAlexWork
(
    OpenAlexWorkId NVARCHAR(100) NOT NULL CONSTRAINT PK_OpenAlexWork PRIMARY KEY,
    Doi NVARCHAR(500) NULL,
    Pmid NVARCHAR(100) NULL,
    Pmcid NVARCHAR(100) NULL,
    Title NVARCHAR(MAX) NULL,
    DisplayName NVARCHAR(MAX) NULL,
    PublicationYear INT NULL,
    PublicationDate DATE NULL,
    WorkType NVARCHAR(100) NULL,
    LanguageCode NVARCHAR(20) NULL,
    CitedByCount INT NULL,
    IsRetracted BIT NOT NULL CONSTRAINT DF_OpenAlexWork_IsRetracted DEFAULT 0,
    IsParatext BIT NOT NULL CONSTRAINT DF_OpenAlexWork_IsParatext DEFAULT 0,
    PrimarySourceId NVARCHAR(100) NULL,
    PrimarySourceName NVARCHAR(500) NULL,
    OpenAccessStatus NVARCHAR(100) NULL,
    IsOpenAccess BIT NULL,
    BestOpenAccessUrl NVARCHAR(1000) NULL,
    LandingPageUrl NVARCHAR(1000) NULL,
    PdfUrl NVARCHAR(1000) NULL,
    ReferencedWorksJson NVARCHAR(MAX) NULL,
    RelatedWorksJson NVARCHAR(MAX) NULL,
    IndexedInJson NVARCHAR(MAX) NULL,
    MeshJson NVARCHAR(MAX) NULL,
    OpenAlexCreatedDate DATE NULL,
    OpenAlexUpdatedDateUtc DATETIME2 NULL,
    RawJsonHash VARBINARY(32) NULL,
    RawJson NVARCHAR(MAX) NULL,
    FirstSeenUtc DATETIME2 NOT NULL CONSTRAINT DF_OpenAlexWork_FirstSeenUtc DEFAULT SYSUTCDATETIME(),
    LastSeenUtc DATETIME2 NOT NULL CONSTRAINT DF_OpenAlexWork_LastSeenUtc DEFAULT SYSUTCDATETIME(),
    UpdatedUtc DATETIME2 NOT NULL CONSTRAINT DF_OpenAlexWork_UpdatedUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_OpenAlexWork_Source FOREIGN KEY (PrimarySourceId) REFERENCES dbo.OpenAlexSource(OpenAlexSourceId)
);
GO
CREATE UNIQUE INDEX UX_OpenAlexWork_Doi ON dbo.OpenAlexWork(Doi) WHERE Doi IS NOT NULL;
CREATE INDEX IX_OpenAlexWork_Pmid ON dbo.OpenAlexWork(Pmid) WHERE Pmid IS NOT NULL;
CREATE INDEX IX_OpenAlexWork_Pmcid ON dbo.OpenAlexWork(Pmcid) WHERE Pmcid IS NOT NULL;
CREATE INDEX IX_OpenAlexWork_PublicationYear ON dbo.OpenAlexWork(PublicationYear);
CREATE INDEX IX_OpenAlexWork_OpenAlexUpdatedDateUtc ON dbo.OpenAlexWork(OpenAlexUpdatedDateUtc);
GO

CREATE TABLE dbo.FacultyWork
(
    FacultyWorkId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FacultyWork PRIMARY KEY,
    FacultyId INT NOT NULL,
    OpenAlexWorkId NVARCHAR(100) NOT NULL,
    OpenAlexAuthorId NVARCHAR(100) NOT NULL,
    AuthorPosition NVARCHAR(50) NULL,
    IsCorresponding BIT NULL,
    MatchSource NVARCHAR(50) NOT NULL CONSTRAINT DF_FacultyWork_MatchSource DEFAULT 'OpenAlexAuthorship',
    IsActive BIT NOT NULL CONSTRAINT DF_FacultyWork_IsActive DEFAULT 1,
    FirstSeenUtc DATETIME2 NOT NULL CONSTRAINT DF_FacultyWork_FirstSeenUtc DEFAULT SYSUTCDATETIME(),
    LastSeenUtc DATETIME2 NOT NULL CONSTRAINT DF_FacultyWork_LastSeenUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_FacultyWork_Faculty FOREIGN KEY (FacultyId) REFERENCES dbo.Faculty(FacultyId),
    CONSTRAINT FK_FacultyWork_Work FOREIGN KEY (OpenAlexWorkId) REFERENCES dbo.OpenAlexWork(OpenAlexWorkId),
    CONSTRAINT UQ_FacultyWork_Faculty_Work UNIQUE (FacultyId, OpenAlexWorkId)
);
GO
CREATE INDEX IX_FacultyWork_OpenAlexWorkId ON dbo.FacultyWork(OpenAlexWorkId);
CREATE INDEX IX_FacultyWork_FacultyId ON dbo.FacultyWork(FacultyId);
GO

CREATE TABLE dbo.OpenAlexWorkAuthorship
(
    OpenAlexWorkAuthorshipId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OpenAlexWorkAuthorship PRIMARY KEY,
    OpenAlexWorkId NVARCHAR(100) NOT NULL,
    OpenAlexAuthorId NVARCHAR(100) NULL,
    AuthorDisplayName NVARCHAR(300) NULL,
    Orcid NVARCHAR(100) NULL,
    AuthorPosition NVARCHAR(50) NULL,
    IsCorresponding BIT NULL,
    InstitutionJson NVARCHAR(MAX) NULL,
    AffiliationJson NVARCHAR(MAX) NULL,
    RawAffiliationStringsJson NVARCHAR(MAX) NULL,
    CountriesJson NVARCHAR(MAX) NULL,
    CreatedUtc DATETIME2 NOT NULL CONSTRAINT DF_OpenAlexWorkAuthorship_CreatedUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_OpenAlexWorkAuthorship_Work FOREIGN KEY (OpenAlexWorkId) REFERENCES dbo.OpenAlexWork(OpenAlexWorkId)
);
GO
CREATE INDEX IX_OpenAlexWorkAuthorship_Work ON dbo.OpenAlexWorkAuthorship(OpenAlexWorkId);
CREATE INDEX IX_OpenAlexWorkAuthorship_Author ON dbo.OpenAlexWorkAuthorship(OpenAlexAuthorId);
GO

CREATE TABLE dbo.OpenAlexTopic
(
    OpenAlexTopicId NVARCHAR(100) NOT NULL CONSTRAINT PK_OpenAlexTopic PRIMARY KEY,
    DisplayName NVARCHAR(500) NULL,
    Description NVARCHAR(MAX) NULL,
    DomainId NVARCHAR(100) NULL,
    DomainName NVARCHAR(300) NULL,
    FieldId NVARCHAR(100) NULL,
    FieldName NVARCHAR(300) NULL,
    SubfieldId NVARCHAR(100) NULL,
    SubfieldName NVARCHAR(300) NULL,
    RawJson NVARCHAR(MAX) NULL,
    UpdatedUtc DATETIME2 NOT NULL CONSTRAINT DF_OpenAlexTopic_UpdatedUtc DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE dbo.OpenAlexWorkTopic
(
    OpenAlexWorkId NVARCHAR(100) NOT NULL,
    OpenAlexTopicId NVARCHAR(100) NOT NULL,
    Score DECIMAL(10,6) NULL,
    IsPrimary BIT NULL,
    CONSTRAINT PK_OpenAlexWorkTopic PRIMARY KEY (OpenAlexWorkId, OpenAlexTopicId),
    CONSTRAINT FK_OpenAlexWorkTopic_Work FOREIGN KEY (OpenAlexWorkId) REFERENCES dbo.OpenAlexWork(OpenAlexWorkId),
    CONSTRAINT FK_OpenAlexWorkTopic_Topic FOREIGN KEY (OpenAlexTopicId) REFERENCES dbo.OpenAlexTopic(OpenAlexTopicId)
);
GO

CREATE TABLE dbo.OpenAlexSyncRun
(
    SyncRunId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OpenAlexSyncRun PRIMARY KEY,
    SyncType NVARCHAR(50) NOT NULL,
    ScopeType NVARCHAR(50) NULL,
    ScopeValue NVARCHAR(200) NULL,
    StartedUtc DATETIME2 NOT NULL CONSTRAINT DF_OpenAlexSyncRun_StartedUtc DEFAULT SYSUTCDATETIME(),
    FinishedUtc DATETIME2 NULL,
    Status NVARCHAR(50) NOT NULL CONSTRAINT DF_OpenAlexSyncRun_Status DEFAULT 'Running',
    FacultyCount INT NOT NULL CONSTRAINT DF_OpenAlexSyncRun_FacultyCount DEFAULT 0,
    AuthorsChecked INT NOT NULL CONSTRAINT DF_OpenAlexSyncRun_AuthorsChecked DEFAULT 0,
    WorksInserted INT NOT NULL CONSTRAINT DF_OpenAlexSyncRun_WorksInserted DEFAULT 0,
    WorksUpdated INT NOT NULL CONSTRAINT DF_OpenAlexSyncRun_WorksUpdated DEFAULT 0,
    WorksUnchanged INT NOT NULL CONSTRAINT DF_OpenAlexSyncRun_WorksUnchanged DEFAULT 0,
    ErrorsCount INT NOT NULL CONSTRAINT DF_OpenAlexSyncRun_ErrorsCount DEFAULT 0,
    Message NVARCHAR(MAX) NULL
);
GO

CREATE TABLE dbo.OpenAlexSyncWatermark
(
    WatermarkId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OpenAlexSyncWatermark PRIMARY KEY,
    ScopeType NVARCHAR(50) NOT NULL,
    ScopeValue NVARCHAR(200) NULL,
    LastSuccessfulOpenAlexUpdatedDateUtc DATETIME2 NULL,
    LastSuccessfulSyncUtc DATETIME2 NULL,
    LastCursor NVARCHAR(MAX) NULL,
    UpdatedUtc DATETIME2 NOT NULL CONSTRAINT DF_OpenAlexSyncWatermark_UpdatedUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_OpenAlexSyncWatermark_Scope UNIQUE (ScopeType, ScopeValue)
);
GO

CREATE TABLE dbo.OpenAlexApiErrorLog
(
    ApiErrorLogId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OpenAlexApiErrorLog PRIMARY KEY,
    SyncRunId BIGINT NULL,
    Endpoint NVARCHAR(500) NULL,
    QueryStringRedacted NVARCHAR(MAX) NULL,
    HttpStatusCode INT NULL,
    ErrorMessage NVARCHAR(MAX) NULL,
    ResponseBody NVARCHAR(MAX) NULL,
    RetryCount INT NOT NULL CONSTRAINT DF_OpenAlexApiErrorLog_RetryCount DEFAULT 0,
    CreatedUtc DATETIME2 NOT NULL CONSTRAINT DF_OpenAlexApiErrorLog_CreatedUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_OpenAlexApiErrorLog_SyncRun FOREIGN KEY (SyncRunId) REFERENCES dbo.OpenAlexSyncRun(SyncRunId)
);
GO
