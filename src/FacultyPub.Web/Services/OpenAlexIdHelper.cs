namespace FacultyPub.Web.Services;

public static class OpenAlexIdHelper
{
    public static string ToShortId(string? id)
    {
        if (string.IsNullOrWhiteSpace(id)) return string.Empty;
        return id.Trim().Replace("https://openalex.org/", string.Empty, StringComparison.OrdinalIgnoreCase);
    }

    public static bool IsSameOpenAlexId(string? left, string? right)
    {
        return string.Equals(ToShortId(left), ToShortId(right), StringComparison.OrdinalIgnoreCase);
    }
}
