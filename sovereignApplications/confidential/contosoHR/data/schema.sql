-- Copyright (c) Microsoft Corporation.
-- Licensed under the MIT License.
--- SUMMARY: Create employee table ---
CREATE TABLE [HR].[Employees]
(
    [EmployeeID] [int] IDENTITY(1,1) NOT NULL,
    [SSN] [char](11) NOT NULL,
    [FirstName] [nvarchar](50) NOT NULL,
    [LastName] [nvarchar](50) NOT NULL,
    [Salary] [decimal](19,4) NOT NULL
) ON [PRIMARY];
