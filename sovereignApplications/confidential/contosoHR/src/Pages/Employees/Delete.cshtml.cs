// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
using ContosoHR.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;

/// <summary>
/// Delete the employee entry
/// </summary>
namespace ContosoHR.Pages.Employees
{
    public class DeleteModel : PageModel
    {
        private readonly ContosoHR.Models.ContosoHRContext _context;

        public DeleteModel(ContosoHR.Models.ContosoHRContext context)
        {
            _context = context;
        }

        [BindProperty]
        public Employee Employee { get; set; }

        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            Employee = await _context.Employees.FirstOrDefaultAsync(m => m.EmployeeId == id);

            if (Employee == null)
            {
                return NotFound();
            }
            return Page();
        }

        public async Task<IActionResult> OnPostAsync(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            Employee = await _context.Employees.FindAsync(id);

            if (Employee != null)
            {
                _context.Employees.Remove(Employee);
                await _context.SaveChangesAsync();
            }

            return RedirectToPage("./Index");
        }
    }
}
