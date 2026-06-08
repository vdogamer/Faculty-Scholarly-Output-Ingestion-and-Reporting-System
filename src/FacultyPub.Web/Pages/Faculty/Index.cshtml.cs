using FacultyPub.Web.Models;
using FacultyPub.Web.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace FacultyPub.Web.Pages.Faculty;

public class IndexModel : PageModel
{
    private readonly FacultyRepository _repository;
    public IndexModel(FacultyRepository repository) => _repository = repository;
    public IReadOnlyList<FacultyListItem> Faculty { get; private set; } = Array.Empty<FacultyListItem>();
    public async Task OnGetAsync() => Faculty = await _repository.ListFacultyAsync();
}
