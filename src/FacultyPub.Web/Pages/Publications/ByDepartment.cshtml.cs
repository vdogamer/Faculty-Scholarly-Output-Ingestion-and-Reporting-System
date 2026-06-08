using FacultyPub.Web.Models;
using FacultyPub.Web.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace FacultyPub.Web.Pages.Publications;

public class ByDepartmentModel : PageModel
{
    private readonly FacultyRepository _repository;
    public ByDepartmentModel(FacultyRepository repository) => _repository = repository;
    public IReadOnlyList<DepartmentPublicationSummary> Rows { get; private set; } = Array.Empty<DepartmentPublicationSummary>();
    public async Task OnGetAsync() => Rows = await _repository.ListPublicationsByDepartmentAsync();
}
