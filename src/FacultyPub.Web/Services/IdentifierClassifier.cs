using System.Text.RegularExpressions;

namespace FacultyPub.Web.Services;

public enum OpenAlexIdentifierKind
{
    Empty,
    Author,
    Work,
    Source,
    Institution,
    Topic,
    Pmid,
    Pmcid,
    Orcid,
    Unknown
}

public sealed record IdentifierClassification(OpenAlexIdentifierKind Kind, string NormalizedValue, string Message);

public sealed class IdentifierClassifier
{
    private static readonly Regex OrcidRegex = new(@"^(https://orcid\.org/)?\d{4}-\d{4}-\d{4}-\d{3}[\dX]$", RegexOptions.IgnoreCase | RegexOptions.Compiled);

    public IdentifierClassification Classify(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return new IdentifierClassification(OpenAlexIdentifierKind.Empty, string.Empty, "No identifier supplied.");
        }

        var trimmed = value.Trim();
        var shortId = trimmed.Replace("https://openalex.org/", string.Empty, StringComparison.OrdinalIgnoreCase);

        if (shortId.StartsWith("A", StringComparison.OrdinalIgnoreCase))
        {
            return new IdentifierClassification(OpenAlexIdentifierKind.Author, shortId, "Looks like an OpenAlex Author ID.");
        }

        if (shortId.StartsWith("W", StringComparison.OrdinalIgnoreCase))
        {
            return new IdentifierClassification(OpenAlexIdentifierKind.Work, shortId, "Looks like an OpenAlex Work ID, not an Author ID.");
        }

        if (shortId.StartsWith("S", StringComparison.OrdinalIgnoreCase))
        {
            return new IdentifierClassification(OpenAlexIdentifierKind.Source, shortId, "Looks like an OpenAlex Source ID.");
        }

        if (shortId.StartsWith("I", StringComparison.OrdinalIgnoreCase))
        {
            return new IdentifierClassification(OpenAlexIdentifierKind.Institution, shortId, "Looks like an OpenAlex Institution ID.");
        }

        if (shortId.StartsWith("T", StringComparison.OrdinalIgnoreCase))
        {
            return new IdentifierClassification(OpenAlexIdentifierKind.Topic, shortId, "Looks like an OpenAlex Topic ID.");
        }

        if (shortId.StartsWith("pmid:", StringComparison.OrdinalIgnoreCase) || Regex.IsMatch(shortId, @"^\d{6,10}$"))
        {
            return new IdentifierClassification(OpenAlexIdentifierKind.Pmid, shortId.Replace("pmid:", string.Empty, StringComparison.OrdinalIgnoreCase), "Looks like a PMID.");
        }

        if (shortId.StartsWith("pmcid:", StringComparison.OrdinalIgnoreCase) || shortId.StartsWith("PMC", StringComparison.OrdinalIgnoreCase))
        {
            return new IdentifierClassification(OpenAlexIdentifierKind.Pmcid, shortId.Replace("pmcid:", string.Empty, StringComparison.OrdinalIgnoreCase), "Looks like a PMCID.");
        }

        if (OrcidRegex.IsMatch(trimmed))
        {
            return new IdentifierClassification(OpenAlexIdentifierKind.Orcid, trimmed.Replace("https://orcid.org/", string.Empty, StringComparison.OrdinalIgnoreCase), "Looks like an ORCID.");
        }

        return new IdentifierClassification(OpenAlexIdentifierKind.Unknown, trimmed, "Could not classify this identifier.");
    }
}
