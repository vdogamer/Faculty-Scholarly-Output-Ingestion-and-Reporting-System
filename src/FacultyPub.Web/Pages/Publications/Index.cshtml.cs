using FacultyPub.Web.Models;
using FacultyPub.Web.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace FacultyPub.Web.Pages.Publications;

public class IndexModel : PageModel
{
    private readonly FacultyRepository _repository;
    public IndexModel(FacultyRepository repository) => _repository = repository;
    public IReadOnlyList<PublicationListItem> Publications { get; private set; } = Array.Empty<PublicationListItem>();
    public async Task OnGetAsync() => Publications = await _repository.ListPublicationsAsync();
}
