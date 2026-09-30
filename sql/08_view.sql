-- DBMS Lab Project, Iqra University
-- Project: Job Postings Market Analytics
-- File: 08_view.sql
-- Description: Creates reporting views (Lab 10/11)

USE JobMarketAnalytics;
GO

PRINT '==================================================';
PRINT 'DATABASE VIEWS: REPORTING DEMO';
PRINT '==================================================';
GO

-- View 1: vw_JobMarketOverview
-- Purpose: one ready-made view that combines job, company and salary
-- Benefit: no need to join the 3 tables every time, just query the view
IF OBJECT_ID('vw_JobMarketOverview', 'V') IS NOT NULL
    DROP VIEW vw_JobMarketOverview;
GO

CREATE VIEW vw_JobMarketOverview AS
SELECT
    jp.job_id,
    jp.title AS JobTitle,
    c.name AS CompanyName,
    c.company_size AS CompanySizeTier,
    jp.location AS JobLocation,
    jp.work_type AS WorkType,
    jp.experience_level AS ExperienceLevel,
    s.min_salary AS MinSalary,
    s.med_salary AS MedianSalary,
    s.max_salary AS MaxSalary,
    s.pay_period AS PayPeriod,
    jp.views AS TotalViews,
    jp.applies AS TotalApplies,
    -- Midpoint salary (falls back to median salary)
    CASE
        WHEN s.min_salary IS NOT NULL AND s.max_salary IS NOT NULL
        THEN CAST((s.min_salary + s.max_salary) / 2.0 AS DECIMAL(12,2))
        ELSE s.med_salary
    END AS EstimatedMidSalary
FROM job_posting jp
LEFT JOIN company c ON jp.company_id = c.company_id
LEFT JOIN salary s  ON jp.job_id = s.job_id;
GO

PRINT 'Created view: vw_JobMarketOverview';
GO


-- View 2: vw_IndustryHiringSummary
-- Purpose: pre-computed company and job counts for each industry
IF OBJECT_ID('vw_IndustryHiringSummary', 'V') IS NOT NULL
    DROP VIEW vw_IndustryHiringSummary;
GO

CREATE VIEW vw_IndustryHiringSummary AS
SELECT
    ind.industry_id,
    ind.industry_name AS IndustryName,
    COUNT(DISTINCT c.company_id) AS TotalHiringCompanies,
    COUNT(jp.job_id) AS TotalJobPostings
FROM industry ind
INNER JOIN company_industry ci ON ind.industry_id = ci.industry_id
INNER JOIN company c           ON ci.company_id = c.company_id
LEFT JOIN job_posting jp       ON c.company_id = jp.company_id
GROUP BY ind.industry_id, ind.industry_name;
GO

PRINT 'Created view: vw_IndustryHiringSummary';
GO


-- Querying the views (works just like a regular table)

-- Demo 1: High-paying jobs straight from the view
PRINT '--- Query 1: High-Paying Jobs via View ---';
SELECT TOP 10
    job_id,
    JobTitle,
    CompanyName,
    JobLocation,
    ExperienceLevel,
    MaxSalary,
    PayPeriod
FROM vw_JobMarketOverview
WHERE WorkType = 'Full-time'
  AND PayPeriod = 'YEARLY'
  AND MaxSalary >= 150000.00
ORDER BY MaxSalary DESC;
GO

-- Demo 2: GROUP BY and AVG on top of the view
PRINT '--- Query 2: Salary by Experience Level via View ---';
SELECT
    ExperienceLevel,
    COUNT(*) AS TotalPostings,
    CAST(AVG(MaxSalary) AS DECIMAL(10,2)) AS AvgMaxSalary
FROM vw_JobMarketOverview
WHERE PayPeriod = 'YEARLY' AND ExperienceLevel IS NOT NULL
GROUP BY ExperienceLevel
ORDER BY AvgMaxSalary DESC;
GO

-- Demo 3: Top 10 industries from the summary view
PRINT '--- Query 3: Top 10 Industries via View ---';
SELECT TOP 10
    IndustryName,
    TotalHiringCompanies,
    TotalJobPostings
FROM vw_IndustryHiringSummary
ORDER BY TotalJobPostings DESC;
GO

PRINT 'Views script finished.';
GO
