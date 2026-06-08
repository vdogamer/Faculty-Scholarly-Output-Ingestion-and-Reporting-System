using System.Text.Json;
using FacultyPub.Web.Models;
using FacultyPub.Web.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace FacultyPub.Web.Pages.Lookup;

public class IndexModel : PageModel
{
    private readonly IOpenAlexClient _client;
    private readonly IdentifierClassifier _classifier;

    public IndexModel(IOpenAlexClient client, IdentifierClassifier classifier)
    {
        _client = client;
        _classifier = classifier;
    }

    [BindProperty(SupportsGet = true)]
    public string? Identifier { get; set; }

    public IdentifierClassification? Classification { get; private set; }
    public OpenAlexWorkDto? Work { get; private set; }
    public OpenAlexAuthorDto? Author { get; private set; }
    public string? ErrorMessage { get; private set; }
    public bool IsOpenAlexConfigured => _client.IsConfigured;

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(Identifier)) return;

        Classification = _classifier.Classify(Identifier);

        if (!_client.IsConfigured)
        {
            ErrorMessage = "OpenAlex API key is not configured.";
            return;
        }

        try
        {
            if (Classification.Kind == OpenAlexIdentifierKind.Pmid)
            {
                Work = await _client.GetWorkByPmidAsync(Classification.NormalizedValue, cancellationToken);
            }
            else if (Classification.Kind == OpenAlexIdentifierKind.Work)
            {
                Work = await _client.GetWorkAsync(Classification.NormalizedValue, cancellationToken);
            }
            else if (Classification.Kind == OpenAlexIdentifierKind.Author)
            {
                Author = await _client.GetAuthorAsync(Classification.NormalizedValue, cancellationToken);
            }
            else
            {
                ErrorMessage = "This lookup page currently supports PMID, OpenAlex Work ID, and OpenAlex Author ID.";
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }

    public static string ShortId(string? value) => OpenAlexIdHelper.ToShortId(value);
}
