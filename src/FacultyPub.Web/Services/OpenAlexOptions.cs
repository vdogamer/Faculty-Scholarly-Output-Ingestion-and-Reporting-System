namespace FacultyPub.Web.Services;

public sealed class OpenAlexOptions
{
    public string BaseUrl { get; set; } = "https://api.openalex.org";
    public string? ApiKey { get; set; }
    public int PerPage { get; set; } = 100;
    public int MaxPagesPerAuthor { get; set; } = 25;
    public bool UseFromUpdatedDate { get; set; }
}
