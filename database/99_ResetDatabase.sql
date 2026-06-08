USE master;
GO

IF DB_ID(N'FacultyPublicationIngestion') IS NOT NULL
BEGIN
    ALTER DATABASE FacultyPublicationIngestion SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FacultyPublicationIngestion;
END
GO
