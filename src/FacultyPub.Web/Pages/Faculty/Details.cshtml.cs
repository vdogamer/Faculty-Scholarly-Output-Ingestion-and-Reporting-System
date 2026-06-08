using FacultyPub.Web.Models;
using FacultyPub.Web.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace FacultyPub.Web.Pages.Faculty;

public class DetailsModel : PageModel
{
    private readonly FacultyRepository _repository;
    private readonly IdentifierClassifier _identifierClassifier;

    public DetailsModel(FacultyRepository repository, IdentifierClassifier identifierClassifier)
    {
        _repository = repository;
        _identifierClassifier = identifierClassifier;
    }

    public FacultyDetail? Faculty { get; private set; }
    public string? IdentifierMessage { get; private set; }

    [BindProperty]
    public string OpenAlexAuthorId { get; set; } = string.Empty;

    [BindProperty]
    public string? Orcid { get; set; }

    [BindProperty]
    public string? DisplayName { get; set; }

    public async Task<IActionResult> OnGetAsync(int id)
    {
        Faculty = await _repository.GetFacultyAsync(id);
        if (Faculty is null) return NotFound();
        return Page();
    }

    public async Task<IActionResult> OnPostVerifyAsync(int id)
    {
        Faculty = await _repository.GetFacultyAsync(id);
        if (Faculty is null) return NotFound();

        var classification = _identifierClassifier.Classify(OpenAlexAuthorId);
        IdentifierMessage = classification.Message;

        if (classification.Kind != OpenAlexIdentifierKind.Author)
        {
            ModelState.AddModelError(nameof(OpenAlexAuthorId), $"This cannot be approved as an author match. {classification.Message}");
            return Page();
        }

        await _repository.VerifyAuthorAsync(
            id,
            classification.NormalizedValue,
            Orcid,
            string.IsNullOrWhiteSpace(DisplayName) ? Faculty.DisplayName : DisplayName,
            Faculty.DepartmentName,
            null,
            null,
            "Manual",
            95,
            "prototype-user");

        return RedirectToPage(new { id });
    }
}
