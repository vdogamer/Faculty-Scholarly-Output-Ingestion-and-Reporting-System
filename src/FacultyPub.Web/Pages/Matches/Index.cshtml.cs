using FacultyPub.Web.Models;
using FacultyPub.Web.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace FacultyPub.Web.Pages.Matches;

public class IndexModel : PageModel
{
    private readonly FacultyRepository _repository;
    public IndexModel(FacultyRepository repository) => _repository = repository;

    public IReadOnlyList<MatchCandidate> Candidates { get; private set; } = Array.Empty<MatchCandidate>();

    public async Task OnGetAsync() => Candidates = await _repository.ListMatchCandidatesAsync();

    public async Task<IActionResult> OnPostRejectAsync(int id)
    {
        await _repository.RejectMatchCandidateAsync(id, "prototype-user");
        return RedirectToPage();
    }
}
