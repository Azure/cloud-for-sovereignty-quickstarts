// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
using Azure.Core;
using Azure.Identity;
using ContosoHR.Models;
using ContosoHR.Util;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Data.SqlClient;
using Microsoft.Data.SqlClient.AlwaysEncrypted.AzureKeyVaultProvider;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json.Nodes;
using System.Threading.Tasks;

/// <summary>
/// Startup app configurations.
/// </summary>
namespace ContosoHR
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            IsDevelopment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") == "Development";

            if (IsDevelopment)
            {
                // For dev-side debugging, ask dev to log in, and get config from appConfig file
                ClientCredential = new InteractiveBrowserCredential();
                ConnectionString = configuration.GetConnectionString("ContosoHRDatabase");
                ConfidentialLedgerName = configuration.GetValue<string>("ConfidentialLedgerName");
            }
            else
            {
                // Production credential picked up from VM environment and config from IMDS
                ClientCredential = new DefaultAzureCredential();
                string imdsUserObject = GetUserObjectFromImdsAsync().Result;
                JsonNode configurationFromImds = JsonNode.Parse(imdsUserObject)!;
                ConnectionString = (string)configurationFromImds["ContosoHRDatabase"];
                ConfidentialLedgerName = (string)configurationFromImds["ConfidentialLedgerName"];
            }

            InitializeAzureKeyVaultProvider();
        }

        private bool IsDevelopment { get; set; }
        private TokenCredential ClientCredential { get; set; }
        private string ConnectionString { get; set; }
        private string ConfidentialLedgerName { get; set; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddSingleton(new ConfidentialLedgerLogger(ConfidentialLedgerName, "ContosoHrSqlLogs", ClientCredential));
            services.AddDbContext<ContosoHRContext>(options =>
                options.UseSqlServer(ConnectionString));
            services.AddControllers();
            services.AddRazorPages();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseStaticFiles();

            app.UseRouting();

            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
                endpoints.MapRazorPages();
            });
        }

        private static async Task<string> GetUserObjectFromImdsAsync()
        {
            string connectionString = string.Empty;
            using (var httpClient = new HttpClient())
            {
                // IMDS requires bypassing proxies.
                WebProxy proxy = new WebProxy();
                HttpClient.DefaultProxy = proxy;
                httpClient.DefaultRequestHeaders.Add("Metadata", "True");
                try
                {
                    var b64connString = await httpClient.GetStringAsync("http://169.254.169.254/metadata/instance/compute/userData?api-version=2021-01-01&format=text");
                    var b64Bytes = Convert.FromBase64String(b64connString);
                    return Encoding.UTF8.GetString(b64Bytes);
                }
                catch (AggregateException ex)
                {
                    // Handle response failures
                    Console.WriteLine("Request failed: " + ex.GetBaseException());
                }
            }
            return connectionString;
        }

        private void InitializeAzureKeyVaultProvider()
        {
            // Initialize the Azure Key Vault provider
            SqlColumnEncryptionAzureKeyVaultProvider sqlColumnEncryptionAzureKeyVaultProvider = new SqlColumnEncryptionAzureKeyVaultProvider(ClientCredential);
            // Register the Azure Key Vault provider
            SqlConnection.RegisterColumnEncryptionKeyStoreProviders(
                customProviders: new Dictionary<string, SqlColumnEncryptionKeyStoreProvider>(
                    capacity: 1, comparer: StringComparer.OrdinalIgnoreCase)
                {
                    {
                        SqlColumnEncryptionAzureKeyVaultProvider.ProviderName, sqlColumnEncryptionAzureKeyVaultProvider
                    }
                }
            );
        }
    }
}
