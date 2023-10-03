// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
using ContosoHR.Util;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

/// <summary>
/// This is Contoso HR Context.
/// </summary>

#nullable disable
namespace ContosoHR.Models
{
    public partial class ContosoHRContext : DbContext
    {
        ConfidentialLedgerLogger _logger;

        public ContosoHRContext(DbContextOptions<ContosoHRContext> options, ConfidentialLedgerLogger logger)
            : base(options)
        {
            _logger = logger;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
            => optionsBuilder.LogTo(_logger.Log, new[] { DbLoggerCategory.Database.Command.Name }, LogLevel.Information);

        public virtual DbSet<Employee> Employees { get; set; }
    }
}
