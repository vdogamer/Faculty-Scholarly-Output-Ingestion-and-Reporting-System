using FacultyPub.Web.Models;
using FacultyPub.Web.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace FacultyPub.Web.Pages.Sync;

public class IndexModel : PageModel
{
    private readonly FacultyRepository _repository;
    private readonly OpenAlexSyncService _syncService;
    private readonly IOpenAlexClient _openAlexClient;

    public IndexModel(FacultyRepository repository, OpenAlexSyncService syncService, IOpenAlexClient openAlexClient)
    {
        _repository = repository;
        _syncService = syncService;
        _openAlexClient = openAlexClient;
    }

    public IReadOnlyList<SyncRunListItem> Runs { get; private set; } = Array.Empty<SyncRunListItem>();
    public bool IsOpenAlexConfigured => _openAlexClient.IsConfigured;
    public string? Message { get; private set; }

    public async Task OnGetAsync()
    {
        Runs = await _repository.ListSyncRunsAsync();
    }

    public async Task<IActionResult> OnPostRunAsync(CancellationToken cancellationToken)
    {
        if (!_openAlexClient.IsConfigured)
        {
            TempData["Message"] = "OpenAlex API key is not configured.";
            return RedirectToPage();
        }

        var syncRunId = await _syncService.RunVerifiedAuthorSyncAsync(cancellationToken);
        TempData["Message"] = $"Sync run {syncRunId} completed. Review results below.";
        return RedirectToPage();
    }
}
