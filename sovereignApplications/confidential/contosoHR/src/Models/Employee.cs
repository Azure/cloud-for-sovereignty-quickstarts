// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

/// <summary>
/// This is the employees data schema.
/// </summary>

#nullable disable

namespace ContosoHR.Models
{
    [Table("Employees", Schema = "HR")]
    public partial class Employee
    {
        public int EmployeeId { get; set; }
        [RegularExpression(@"^\d{3}-\d{2}-\d{4}$", ErrorMessage = "Invalid SSN format.")]
        [Column(TypeName = "char(11)")]
        public string Ssn { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        [Column(TypeName = "decimal(19,4)")]
        public decimal Salary { get; set; }
    }
}
