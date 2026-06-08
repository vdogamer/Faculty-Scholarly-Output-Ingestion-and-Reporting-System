# Faculty Publication Ingestion Prototype

ASP.NET Core 8 Razor Pages prototype for importing local faculty, verifying OpenAlex Author IDs, pulling OpenAlex works/publications, and storing results in SQL Server 2019.

## Important correction for the supplied test identifier

The supplied value `W4292121792` appears to be an OpenAlex **Work** ID because it starts with `W`.
OpenAlex **Author** IDs normally start with `A`.

This prototype includes identifier validation so a Work ID cannot be silently approved as an Author ID. The supplied PMID `35976718` can be used later to retrieve the work and inspect its authors in OpenAlex.

## Prerequisites

- .NET 8 SDK
- SQL Server 2019 or newer
- VS Code
- OpenAlex API key

## 1. Create the database

Open SQL Server Management Studio or Azure Data Studio and run these scripts in order:

```sql
:r database/00_CreateDatabase.sql
:r database/01_Schema.sql
:r database/02_StoredProcedures.sql
:r database/03_SeedData.sql
```

If your tool does not support SQLCMD `:r`, open and execute each file manually in this order.

Optional: run `database/04_DemoPublicationData.sql` if you want visible demo publication rows before connecting to OpenAlex. These rows are clearly marked as demo data.

## 2. Configure the app

From the repository root:

```bash
cd src/FacultyPub.Web
dotnet restore
dotnet user-secrets init
dotnet user-secrets set "OpenAlex:ApiKey" "YOUR_OPENALEX_API_KEY"
```

Do not commit the API key.

The local SQL Server connection string is in `appsettings.Development.json`:

```json
"Server=localhost;Database=FacultyPublicationIngestion;Trusted_Connection=True;TrustServerCertificate=True;"
```

## 3. Run

```bash
dotnet run
```

Then open the URL printed by Kestrel, usually:

```text
https://localhost:5001
http://localhost:5000
```

## 4. First demo flow

1. Open **Faculty**.
2. Open **Meg G. Keeley**.
3. Notice the seeded candidate warning: `W4292121792` looks like a Work ID, not an Author ID.
4. Enter a verified OpenAlex Author ID that starts with `A` when available.
5. Open **Sync**.
6. Run the manual OpenAlex sync.
7. Open **Publications** and **By Department**.
8. Review **Sync Runs** and **API Errors**.

## 5. Environment variable alternative

For deployment, use an environment variable instead of user-secrets:

```powershell
setx OpenAlex__ApiKey "YOUR_OPENALEX_API_KEY"
```

ASP.NET Core maps `OpenAlex__ApiKey` to `OpenAlex:ApiKey`.

## Prototype scope

This version intentionally does not include login/authentication. It is a local prototype to show the manager the workflow and screen layout.

## What this prototype proves

- SQL Server schema can store faculty, OpenAlex authors, works, sources, authorships, sync runs, and errors.
- Name-only author matching is blocked from auto-approval.
- A supplied Work ID cannot be mistakenly approved as an Author ID.
- Verified Author IDs can be used to pull works from OpenAlex.
- Re-running sync uses upserts to avoid duplicates.
- Department-level publication reporting is available.
