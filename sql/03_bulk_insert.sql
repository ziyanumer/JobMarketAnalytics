-- DBMS Lab Project, Iqra University
-- Project: Job Postings Market Analytics
-- File: 03_bulk_insert.sql
-- Description: Loads the cleaned CSVs into SQL Server with BULK INSERT
--
-- NOTE: BULK INSERT needs absolute paths that the SQL Server service can read.
-- Change C:\JobMarketAnalytics in the paths below to the folder where you cloned this repo.

USE JobMarketAnalytics;
GO

PRINT 'Starting data load...';
GO

-- Step 0: Empty the tables first (children before parents to avoid FK conflicts)
DELETE FROM benefit;
DELETE FROM salary;
DELETE FROM job_skill;
DELETE FROM skill;
DELETE FROM job_posting;
DELETE FROM employee_count;
DELETE FROM company_industry;
DELETE FROM industry;
DELETE FROM company;
GO

-- Step 1: Load the company table (parent table)
PRINT 'Loading company table...';
BULK INSERT company
FROM 'C:\JobMarketAnalytics\data\cleaned\clean_company.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2, -- Row 1 is the header, so start at row 2
    TABLOCK
);
GO

-- Step 2: Load the industry lookup table
-- Note: KEEPIDENTITY keeps the industry_id values from the CSV
PRINT 'Loading industry table...';
BULK INSERT industry
FROM 'C:\JobMarketAnalytics\data\cleaned\clean_industry.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    KEEPIDENTITY,
    TABLOCK
);
GO

-- Step 3: Load the company_industry junction table
PRINT 'Loading company_industry junction table...';
BULK INSERT company_industry
FROM 'C:\JobMarketAnalytics\data\cleaned\clean_company_industry.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    TABLOCK
);
GO

-- Step 4: Load the employee_count table
PRINT 'Loading employee_count table...';
BULK INSERT employee_count
FROM 'C:\JobMarketAnalytics\data\cleaned\clean_employee_count.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    KEEPIDENTITY,
    TABLOCK
);
GO

-- Step 5: Load the main job_posting table
PRINT 'Loading job_posting table...';
BULK INSERT job_posting
FROM 'C:\JobMarketAnalytics\data\cleaned\clean_job_posting.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    TABLOCK
);
GO

-- Step 6: Load the skill lookup table
PRINT 'Loading skill table...';
BULK INSERT skill
FROM 'C:\JobMarketAnalytics\data\cleaned\clean_skill.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    KEEPIDENTITY,
    TABLOCK
);
GO

-- Step 7: Load the job_skill junction table
PRINT 'Loading job_skill junction table...';
BULK INSERT job_skill
FROM 'C:\JobMarketAnalytics\data\cleaned\clean_job_skill.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    TABLOCK
);
GO

-- Step 8: Load the salary table
PRINT 'Loading salary table...';
BULK INSERT salary
FROM 'C:\JobMarketAnalytics\data\cleaned\clean_salary.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    KEEPIDENTITY,
    TABLOCK
);
GO

-- Step 9: Load the benefit table
PRINT 'Loading benefit table...';
BULK INSERT benefit
FROM 'C:\JobMarketAnalytics\data\cleaned\clean_benefit.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    KEEPIDENTITY,
    TABLOCK
);
GO

PRINT 'Data load complete.';
GO

-- Verification: row count for each table
SELECT 'company' AS [Table_Name], COUNT(*) AS [Total_Rows] FROM company
UNION ALL
SELECT 'industry', COUNT(*) FROM industry
UNION ALL
SELECT 'company_industry', COUNT(*) FROM company_industry
UNION ALL
SELECT 'employee_count', COUNT(*) FROM employee_count
UNION ALL
SELECT 'job_posting', COUNT(*) FROM job_posting
UNION ALL
SELECT 'skill', COUNT(*) FROM skill
UNION ALL
SELECT 'job_skill', COUNT(*) FROM job_skill
UNION ALL
SELECT 'salary', COUNT(*) FROM salary
UNION ALL
SELECT 'benefit', COUNT(*) FROM benefit;
GO
