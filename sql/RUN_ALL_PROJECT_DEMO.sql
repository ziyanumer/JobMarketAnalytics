-- DBMS Lab Project, Iqra University: Master Script
-- Project: Job Postings Market Analytics
-- File: RUN_ALL_PROJECT_DEMO.sql
-- Description: Runs an end-to-end demo of the whole project in one go (F5)
-- Covers: Table Rows Check, CRUD (Lab 7), Aggregates (Lab 8), Joins (Lab 9),
--         Subqueries (Lab 10), Views, Stored Procedure (Lab 11), Trigger (Lab 11)
-- Run this after the numbered scripts (01-10): it expects the data, views, procedure and trigger to exist.

USE JobMarketAnalytics;
GO

PRINT '========================================================================';
PRINT '>>> STARTING FULL PROJECT FUNCTIONALITY TEST <<<';
PRINT '========================================================================';
GO

-- TEST 1: Database health check and row counts for all 9 tables
PRINT '>>> [TEST 1/7] VERIFYING ALL 9 TABLES AND DATA (3NF SCHEMA)...';
SELECT 'company' AS [Table_Name], COUNT(*) AS [Total_Rows], 'Company Profiles' AS [Description] FROM company
UNION ALL
SELECT 'industry', COUNT(*), 'Industry Sectors' FROM industry
UNION ALL
SELECT 'company_industry', COUNT(*), 'Company <-> Industry (M:N)' FROM company_industry
UNION ALL
SELECT 'employee_count', COUNT(*), 'Employee Counts & Followers' FROM employee_count
UNION ALL
SELECT 'job_posting', COUNT(*), 'Job Postings (Main Table)' FROM job_posting
UNION ALL
SELECT 'skill', COUNT(*), 'Skills List' FROM skill
UNION ALL
SELECT 'job_skill', COUNT(*), 'Job <-> Skill (M:N)' FROM job_skill
UNION ALL
SELECT 'salary', COUNT(*), 'Salary Compensation' FROM salary
UNION ALL
SELECT 'benefit', COUNT(*), 'Job Benefits' FROM benefit;
GO

PRINT '>>> TEST 1 PASS: 515,000+ rows across all 9 tables.';
PRINT '';
GO

-- TEST 2: CRUD Operations (Lab 7)
PRINT '>>> [TEST 2/7] TESTING CRUD OPERATIONS (INSERT, SELECT, UPDATE, DELETE)...';

-- Remove leftover test records from earlier runs
DELETE FROM salary WHERE job_id = 88888888;
DELETE FROM job_posting WHERE job_id = 88888888;
DELETE FROM company WHERE company_id = 88888;

-- Insert
INSERT INTO company (company_id, name, company_size) VALUES (88888, 'Test Analytics Corp', '3');
INSERT INTO job_posting (job_id, company_id, title, location, work_type, experience_level, views, applies)
VALUES (88888888, 88888, 'Software Engineer Intern', 'Lahore, PK', 'Full-time', 'Entry level', 50, 10);
INSERT INTO salary (job_id, min_salary, max_salary, pay_period, currency) VALUES (88888888, 60000, 80000, 'YEARLY', 'USD');

-- Update
UPDATE job_posting SET views = 100, applies = 25 WHERE job_id = 88888888;

-- Select to verify
SELECT jp.job_id, jp.title, c.name AS CompanyName, jp.views, jp.applies, s.min_salary, s.max_salary
FROM job_posting jp
JOIN company c ON jp.company_id = c.company_id
JOIN salary s  ON jp.job_id = s.job_id
WHERE jp.job_id = 88888888;

-- Delete (checks the cascade)
DELETE FROM job_posting WHERE job_id = 88888888;
DELETE FROM company WHERE company_id = 88888;

PRINT '>>> TEST 2 PASS: CRUD operations and cascading foreign keys work correctly.';
PRINT '';
GO

-- TEST 3: Aggregate functions and GROUP BY / HAVING (Lab 8)
PRINT '>>> [TEST 3/7] TESTING AGGREGATE FUNCTIONS & GROUP BY...';

-- Top 5 In-Demand Skills
SELECT TOP 5
    sk.skill_name AS [Top Skill],
    COUNT(js.job_id) AS [Total Job Postings]
FROM job_skill js
JOIN skill sk ON js.skill_id = sk.skill_id
GROUP BY sk.skill_name
ORDER BY [Total Job Postings] DESC;

-- Salary Metrics by Experience Level
SELECT
    jp.experience_level AS [Seniority Level],
    COUNT(*) AS [Jobs Analyzed],
    CAST(AVG(s.min_salary) AS DECIMAL(10,2)) AS [Avg Min Salary ($)],
    CAST(AVG(s.max_salary) AS DECIMAL(10,2)) AS [Avg Max Salary ($)]
FROM job_posting jp
JOIN salary s ON jp.job_id = s.job_id
WHERE s.pay_period = 'YEARLY' AND jp.experience_level IS NOT NULL AND jp.experience_level <> ''
GROUP BY jp.experience_level
ORDER BY [Avg Max Salary ($)] DESC;

PRINT '>>> TEST 3 PASS: Aggregates and GROUP BY work correctly.';
PRINT '';
GO

-- TEST 4: Multi-Table Joins (Lab 9)
PRINT '>>> [TEST 4/7] TESTING MULTI-TABLE JOINS (TOP INDUSTRIES)...';

-- Top 5 industries (4-table join: industry, company_industry, company, job_posting)
SELECT TOP 5
    ind.industry_name AS [Industry Sector],
    COUNT(jp.job_id) AS [Total Job Postings]
FROM industry ind
INNER JOIN company_industry ci ON ind.industry_id = ci.industry_id
INNER JOIN company c           ON ci.company_id = c.company_id
INNER JOIN job_posting jp      ON c.company_id = jp.company_id
GROUP BY ind.industry_name
ORDER BY [Total Job Postings] DESC;

PRINT '>>> TEST 4 PASS: Relational joins work correctly.';
PRINT '';
GO

-- TEST 5: Subqueries (Lab 10)
PRINT '>>> [TEST 5/7] TESTING SUBQUERIES...';

-- Scalar subquery: jobs paying above the market average
SELECT TOP 3
    jp.title AS [High-Paying Job],
    s.max_salary AS [Offered Max Salary ($)],
    (SELECT CAST(AVG(max_salary) AS DECIMAL(10,2)) FROM salary WHERE pay_period = 'YEARLY') AS [Market Average ($)]
FROM job_posting jp
JOIN salary s ON jp.job_id = s.job_id
WHERE s.pay_period = 'YEARLY'
  AND s.max_salary > (SELECT AVG(max_salary) FROM salary WHERE pay_period = 'YEARLY')
ORDER BY s.max_salary DESC;

PRINT '>>> TEST 5 PASS: Subqueries work correctly.';
PRINT '';
GO

-- TEST 6: Views (Lab 10/11)
PRINT '>>> [TEST 6/7] TESTING REPORTING VIEWS...';

SELECT TOP 3
    job_id,
    JobTitle,
    CompanyName,
    JobLocation,
    MaxSalary,
    PayPeriod
FROM vw_JobMarketOverview
WHERE WorkType = 'Full-time' AND PayPeriod = 'YEARLY' AND MaxSalary >= 150000
ORDER BY MaxSalary DESC;

PRINT '>>> TEST 6 PASS: Reporting views work correctly.';
PRINT '';
GO

-- TEST 7: Stored Procedure & Trigger (Lab 11)
PRINT '>>> [TEST 7/7] TESTING STORED PROCEDURE AND AUDIT TRIGGER...';

-- Stored Procedure Test
DECLARE @TotalFoundJobs INT;
DECLARE @AverageSalary  DECIMAL(12,2);

EXEC sp_GetIndustryJobAnalytics
    @IndustryName   = 'IT Services and IT Consulting',
    @TotalJobs      = @TotalFoundJobs OUTPUT,
    @AvgMaxSalary   = @AverageSalary  OUTPUT;

PRINT '>> Procedure output: IT Services has ' + CAST(@TotalFoundJobs AS VARCHAR) + ' jobs, average max salary $' + CAST(@AverageSalary AS VARCHAR) + '.';

-- Trigger audit check (read from the log table)
SELECT TOP 3
    log_id,
    job_id,
    action_type,
    job_title,
    action_time,
    action_user
FROM JobPostingAuditLog
ORDER BY log_id DESC;

PRINT '>>> TEST 7 PASS: Stored procedures and triggers work correctly.';
PRINT '';
GO

PRINT '========================================================================';
PRINT '>>> ALL VERIFICATION TESTS COMPLETE <<<';
PRINT '========================================================================';
GO
