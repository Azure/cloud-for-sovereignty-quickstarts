// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
using ContosoHR.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.Threading.Tasks;

/// <summary>
/// Create a new employee entry
/// </summary>
namespace ContosoHR.Pages.Employees
{
    public class CreateModel : PageModel
    {
        private readonly ContosoHR.Models.ContosoHRContext _context;

        public CreateModel(ContosoHR.Models.ContosoHRContext context)
        {
            _context = context;
        }

        public IActionResult OnGet()
        {
            return Page();
        }

        [BindProperty]
        public Employee Employee { get; set; }

        // To protect from overposting attacks, see https://aka.ms/RazorPagesCRUD
        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            try
            {
                var validationContext = new ValidationContext(Employee);
                Validator.ValidateObject(Employee, validationContext, validateAllProperties: true);
                _context.Employees.Add(Employee);
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                throw;
            }

            return RedirectToPage("./Index");
        }
    }
}
