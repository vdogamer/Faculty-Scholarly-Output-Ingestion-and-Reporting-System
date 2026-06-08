using FacultyPub.Web.Models;
using FacultyPub.Web.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace FacultyPub.Web.Pages.Errors;

public class IndexModel : PageModel
{
    private readonly FacultyRepository _repository;
    public IndexModel(FacultyRepository repository) => _repository = repository;
    public IReadOnlyList<ApiErrorListItem> Errors { get; private set; } = Array.Empty<ApiErrorListItem>();
    public async Task OnGetAsync() => Errors = await _repository.ListErrorsAsync();
}
