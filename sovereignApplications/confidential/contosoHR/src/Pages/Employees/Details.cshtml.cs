// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
using ContosoHR.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;

/// <summary>
/// Get the detail of employee info
/// </summary>
namespace ContosoHR.Pages.Employees
{
    public class DetailsModel : PageModel
    {
        private readonly ContosoHR.Models.ContosoHRContext _context;

        public DetailsModel(ContosoHR.Models.ContosoHRContext context)
        {
            _context = context;
        }

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
    }
}
