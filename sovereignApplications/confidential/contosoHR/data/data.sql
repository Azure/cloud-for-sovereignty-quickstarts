-- Copyright (c) Microsoft Corporation.
-- Licensed under the MIT License.
--- SUMMARY: Insert employee data ---
INSERT INTO [HR].[Employees]
        ([SSN]
        ,[FirstName]
        ,[LastName]
        ,[Salary])
    VALUES
        ('795-73-9838'
        , N'Catherine'
        , N'Abel'
        , $31692);

INSERT INTO [HR].[Employees]
        ([SSN]
        ,[FirstName]
        ,[LastName]
        ,[Salary])
    VALUES
        ('990-00-6818'
        , N'Kim'
        , N'Abercrombie'
        , $55415);
