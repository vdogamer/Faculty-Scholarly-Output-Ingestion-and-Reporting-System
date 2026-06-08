using FacultyPub.Web.Models;
using FacultyPub.Web.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace FacultyPub.Web.Pages;

public class IndexModel : PageModel
{
    private readonly FacultyRepository _repository;
    private readonly IOpenAlexClient _openAlexClient;

    public IndexModel(FacultyRepository repository, IOpenAlexClient openAlexClient)
    {
        _repository = repository;
        _openAlexClient = openAlexClient;
    }

    public DashboardSummary Summary { get; private set; } = new();
    public bool IsOpenAlexConfigured => _openAlexClient.IsConfigured;

    public async Task OnGetAsync()
    {
        Summary = await _repository.GetDashboardSummaryAsync();
    }
}
