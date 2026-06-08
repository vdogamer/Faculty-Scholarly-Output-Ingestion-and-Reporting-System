USE FacultyPublicationIngestion;
GO

-- Optional demo data only. This is not authoritative OpenAlex metadata.
-- Use this when you want the UI to show sample publications before entering a real OpenAlex Author ID.

DECLARE @FacultyId INT = (SELECT FacultyId FROM dbo.Faculty WHERE SourceFacultyId = N'UVA-SOM-MEG-KEELEY');

IF @FacultyId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.OpenAlexSource WHERE OpenAlexSourceId = N'DEMO-S-PEDIATRICS')
    BEGIN
        INSERT dbo.OpenAlexSource (OpenAlexSourceId, DisplayName, IssnL, SourceType, RawJson)
        VALUES (N'DEMO-S-PEDIATRICS', N'Pediatrics - Demo Source', N'0031-4005', N'journal', N'{"demo":true}');
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.OpenAlexWork WHERE OpenAlexWorkId = N'DEMO-W-001')
    BEGIN
        INSERT dbo.OpenAlexWork
        (OpenAlexWorkId, Pmid, Title, DisplayName, PublicationYear, WorkType, PrimarySourceId, PrimarySourceName, CitedByCount, IsOpenAccess, OpenAccessStatus, RawJson)
        VALUES
        (N'DEMO-W-001', N'35976718', N'Demo placeholder publication for UI review', N'Demo placeholder publication for UI review', 2022, N'article', N'DEMO-S-PEDIATRICS', N'Pediatrics - Demo Source', 0, 0, N'unknown', N'{"demo":true,"warning":"Replace with real OpenAlex sync data."}');
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.FacultyWork WHERE FacultyId = @FacultyId AND OpenAlexWorkId = N'DEMO-W-001')
    BEGIN
        INSERT dbo.FacultyWork (FacultyId, OpenAlexWorkId, OpenAlexAuthorId, AuthorPosition, IsCorresponding, MatchSource)
        VALUES (@FacultyId, N'DEMO-W-001', N'DEMO-A-UNKNOWN', N'middle', 0, N'DemoData');
    END
END
GO
