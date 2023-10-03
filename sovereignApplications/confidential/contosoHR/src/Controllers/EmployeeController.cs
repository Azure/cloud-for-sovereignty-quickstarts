// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
using ContosoHR.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using System;
using System.Data;
using System.Linq;
using System.Linq.Dynamic.Core;

/// <summary>
/// This is ContosoHR API controller to retrieve the employee entries from database.
/// </summary>
namespace ContosoHR.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EmployeeController : ControllerBase
    {
        private readonly ContosoHRContext context;
        private readonly IConfiguration configuration;
        public EmployeeController(ContosoHRContext context, IConfiguration configuration)
        {
            this.context = context;
            this.configuration = configuration;
        }
        [HttpPost]
        public IActionResult GetEmployees()
        {
            var draw = Request.Form["draw"].FirstOrDefault();
            var start = Request.Form["start"].FirstOrDefault();
            var length = Request.Form["length"].FirstOrDefault();
            var sortColumn = Request.Form["columns[" + Request.Form["order[0][column]"].FirstOrDefault() + "][name]"].FirstOrDefault();
            var sortColumnDirection = Request.Form["order[0][dir]"].FirstOrDefault();
            var searchValue = Request.Form["search[value]"].FirstOrDefault();
            int pageSize = length != null ? Convert.ToInt32(length) : 0;
            int skip = start != null ? Convert.ToInt32(start) : 0;
            int recordsTotal = 0;

            string salaryRange = Request.Form["columns[4][search][value]"]; // NOTE: it must match .column(8) in Index.cshtml


            int from = 0, to = 100000;

            if (!string.IsNullOrEmpty(salaryRange))
            {
                from = Convert.ToInt32(salaryRange.Split(':')[0]);
                to = Convert.ToInt32(salaryRange.Split(':')[1]);
            }

            var ssnSearchPattern = new SqlParameter();
            ssnSearchPattern.ParameterName = @"@SSNSearchPattern";
            ssnSearchPattern.DbType = DbType.AnsiStringFixedLength;
            ssnSearchPattern.Direction = ParameterDirection.Input;
            ssnSearchPattern.Value = "%" + searchValue + "%";
            ssnSearchPattern.Size = ssnSearchPattern.Value.ToString().Length;

            var nameSearchPattern = new SqlParameter();
            nameSearchPattern.ParameterName = @"@NameSearchPattern";
            nameSearchPattern.DbType = DbType.String;
            nameSearchPattern.Direction = ParameterDirection.Input;
            nameSearchPattern.Value = "%" + searchValue + "%";
            nameSearchPattern.Size = nameSearchPattern.Value.ToString().Length;

            var minSalary = new SqlParameter();
            minSalary.ParameterName = @"@MinSalary";
            minSalary.DbType = DbType.Decimal;
            minSalary.Precision = 19;
            minSalary.Scale = 4;
            minSalary.Direction = ParameterDirection.Input;
            minSalary.Value = from;

            var maxSalary = new SqlParameter();
            maxSalary.ParameterName = @"@MaxSalary";
            maxSalary.DbType = DbType.Decimal;
            maxSalary.Precision = 19;
            maxSalary.Scale = 4;
            maxSalary.Direction = ParameterDirection.Input;
            maxSalary.Value = to;

            var employeeData = context.Employees.FromSqlRaw(
                @"SELECT [EmployeeID], [SSN], [FirstName], [LastName], [Salary] FROM [HR].[Employees] WHERE ([SSN] LIKE @SSNSearchPattern OR [LastName] LIKE @NameSearchPattern) AND [Salary] BETWEEN @MinSalary AND @MaxSalary"
                , ssnSearchPattern
                , nameSearchPattern
                , minSalary
                , maxSalary);

            if (!(string.IsNullOrEmpty(sortColumn) && string.IsNullOrEmpty(sortColumnDirection)))
            {
                employeeData = employeeData.OrderBy(sortColumn + " " + sortColumnDirection);
            }

            recordsTotal = employeeData.Count();
            var data = employeeData.Skip(skip).Take(pageSize).ToList();
            var jsonData = new { draw = draw, recordsFiltered = recordsTotal, recordsTotal = recordsTotal, data = data };
            return Ok(jsonData);
        }
    }
}
