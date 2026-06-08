USE FacultyPublicationIngestion;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Faculty WHERE SourceFacultyId = N'UVA-SOM-MEG-KEELEY')
BEGIN
    INSERT dbo.Faculty
    (SourceFacultyId, FirstName, MiddleName, LastName, DisplayName, Email, DepartmentCode, DepartmentName, AppointmentTitle)
    VALUES
    (N'UVA-SOM-MEG-KEELEY', N'Meg', N'G.', N'Keeley', N'Meg G. Keeley', N'meg.keeley@example.edu', N'PEDS', N'Pediatrics', N'Professor of Pediatrics');
END
GO

DECLARE @MegFacultyId INT = (SELECT FacultyId FROM dbo.Faculty WHERE SourceFacultyId = N'UVA-SOM-MEG-KEELEY');

IF @MegFacultyId IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM dbo.OpenAlexMatchCandidate WHERE FacultyId = @MegFacultyId AND OpenAlexAuthorId = N'W4292121792')
BEGIN
    INSERT dbo.OpenAlexMatchCandidate
    (FacultyId, OpenAlexAuthorId, OpenAlexDisplayName, LastKnownInstitution, WorksCount, CitedByCount, MatchMethod, ConfidenceScore, EvidenceJson, ReviewStatus)
    VALUES
    (
        @MegFacultyId,
        N'W4292121792',
        N'Supplied identifier appears to be a Work ID, not an Author ID',
        N'PMID supplied: 35976718; Department: Pediatrics',
        NULL,
        NULL,
        N'ProvidedWorkIdNotAuthorId',
        0,
        N'{"warning":"OpenAlex IDs beginning with W are works. Author IDs normally begin with A. Use PMID 35976718 to inspect the work authors and select the correct A... author ID."}',
        N'NeedsMoreEvidence'
    );
END
GO

DECLARE @SeedFaculty TABLE
(
    SourceFacultyId NVARCHAR(100), FirstName NVARCHAR(150), LastName NVARCHAR(150), DisplayName NVARCHAR(300),
    Email NVARCHAR(320), DepartmentCode NVARCHAR(50), DepartmentName NVARCHAR(250), AppointmentTitle NVARCHAR(250)
);

INSERT @SeedFaculty VALUES
(N'DEMO-001', N'Avery', N'Johnson', N'Avery Johnson', N'avery.johnson@example.edu', N'MED', N'Medicine', N'Associate Professor'),
(N'DEMO-002', N'Maya', N'Patel', N'Maya Patel', N'maya.patel@example.edu', N'SURG', N'Surgery', N'Assistant Professor'),
(N'DEMO-003', N'James', N'Wilson', N'James Wilson', N'james.wilson@example.edu', N'NEUR', N'Neurology', N'Professor'),
(N'DEMO-004', N'Lin', N'Chen', N'Lin Chen', N'lin.chen@example.edu', N'PEDS', N'Pediatrics', N'Assistant Professor'),
(N'DEMO-005', N'Fatima', N'Hassan', N'Fatima Hassan', N'fatima.hassan@example.edu', N'RAD', N'Radiology', N'Associate Professor'),
(N'DEMO-006', N'Noah', N'Brown', N'Noah Brown', N'noah.brown@example.edu', N'PSYC', N'Psychiatry', N'Professor'),
(N'DEMO-007', N'Sofia', N'Garcia', N'Sofia Garcia', N'sofia.garcia@example.edu', N'OBGYN', N'Obstetrics and Gynecology', N'Assistant Professor'),
(N'DEMO-008', N'Omar', N'Rahman', N'Omar Rahman', N'omar.rahman@example.edu', N'MED', N'Medicine', N'Assistant Professor'),
(N'DEMO-009', N'Grace', N'Miller', N'Grace Miller', N'grace.miller@example.edu', N'PEDS', N'Pediatrics', N'Associate Professor'),
(N'DEMO-010', N'Elijah', N'Davis', N'Elijah Davis', N'elijah.davis@example.edu', N'SURG', N'Surgery', N'Professor');

INSERT dbo.Faculty
(SourceFacultyId, FirstName, LastName, DisplayName, Email, DepartmentCode, DepartmentName, AppointmentTitle)
SELECT s.SourceFacultyId, s.FirstName, s.LastName, s.DisplayName, s.Email, s.DepartmentCode, s.DepartmentName, s.AppointmentTitle
FROM @SeedFaculty s
WHERE NOT EXISTS (SELECT 1 FROM dbo.Faculty f WHERE f.SourceFacultyId = s.SourceFacultyId);
GO

