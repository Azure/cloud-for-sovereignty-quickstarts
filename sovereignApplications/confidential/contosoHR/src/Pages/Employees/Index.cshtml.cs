// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
using ContosoHR.Models;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading.Tasks;

/// <summary>
/// Employee Index model
/// </summary>
namespace ContosoHR.Pages.Employees
{
    public class IndexModel : PageModel
    {
        private readonly ContosoHR.Models.ContosoHRContext _context;

        public IndexModel(ContosoHR.Models.ContosoHRContext context)
        {
            _context = context;
        }

        public IList<Employee> Employee { get;set; }

        public async Task OnGetAsync()
        {
            Employee = await _context.Employees.ToListAsync();
        }
    }
}
