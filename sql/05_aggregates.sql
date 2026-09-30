-- DBMS Lab Project, Iqra University
-- Project: Job Postings Market Analytics
-- File: 05_aggregates.sql
-- Description: COUNT, AVG, MIN, MAX, GROUP BY and HAVING queries (Lab 8)

USE JobMarketAnalytics;
GO

PRINT '==================================================';
PRINT 'LAB 8: AGGREGATE FUNCTIONS AND GROUPING DEMO';
PRINT '==================================================';
GO

-- Query 1: Top 10 locations with the most job postings
PRINT '--- Query 1: Top 10 Job Locations ---';
SELECT TOP 10
    location AS JobLocation,
    COUNT(*) AS TotalJobPostings
FROM job_posting
WHERE location IS NOT NULL AND location <> ''
GROUP BY location
ORDER BY TotalJobPostings DESC;
GO


-- Query 2: Job count, average views and average applies by experience level
PRINT '--- Query 2: Experience Level Distribution ---';
SELECT
    experience_level,
    COUNT(*) AS TotalJobs,
    AVG(views) AS AvgViews,
    AVG(applies) AS AvgApplies
FROM job_posting
WHERE experience_level IS NOT NULL AND experience_level <> ''
GROUP BY experience_level
ORDER BY TotalJobs DESC;
GO


-- Query 3: Job count by work type (Full-time, Contract, etc.)
PRINT '--- Query 3: Work Type Distribution ---';
SELECT
    work_type,
    COUNT(*) AS TotalJobs
FROM job_posting
WHERE work_type IS NOT NULL AND work_type <> ''
GROUP BY work_type
ORDER BY TotalJobs DESC;
GO


-- Query 4: Min, average and max annual salary by experience level
PRINT '--- Query 4: Salary Metrics by Experience Level ---';
SELECT
    jp.experience_level,
    COUNT(*) AS JobsWithSalary,
    CAST(MIN(s.min_salary) AS DECIMAL(10,2)) AS LowestMinSalary,
    CAST(AVG(s.min_salary) AS DECIMAL(10,2)) AS AvgMinSalary,
    CAST(AVG(s.med_salary) AS DECIMAL(10,2)) AS AvgMedianSalary,
    CAST(AVG(s.max_salary) AS DECIMAL(10,2)) AS AvgMaxSalary,
    CAST(MAX(s.max_salary) AS DECIMAL(10,2)) AS HighestMaxSalary
FROM job_posting jp
JOIN salary s ON jp.job_id = s.job_id
WHERE s.pay_period = 'YEARLY'
  AND jp.experience_level IS NOT NULL
  AND jp.experience_level <> ''
GROUP BY jp.experience_level
ORDER BY AvgMaxSalary DESC;
GO


-- Query 5: Compare average annual salary across Full-time, Contract and Part-time
PRINT '--- Query 5: Salary Comparison Across Work Types ---';
SELECT
    jp.work_type,
    COUNT(*) AS ReportedSalaries,
    CAST(AVG(s.min_salary) AS DECIMAL(10,2)) AS AvgMinSalary,
    CAST(AVG(s.max_salary) AS DECIMAL(10,2)) AS AvgMaxSalary
FROM job_posting jp
JOIN salary s ON jp.job_id = s.job_id
WHERE s.pay_period = 'YEARLY'
  AND jp.work_type IS NOT NULL
  AND jp.work_type <> ''
GROUP BY jp.work_type
ORDER BY AvgMaxSalary DESC;
GO


-- Query 6: HAVING clause: only experience levels with an average max salary above 120,000
PRINT '--- Query 6: HAVING Clause: High Salary Experience Levels (>120k) ---';
SELECT
    jp.experience_level,
    COUNT(*) AS TotalPostings,
    CAST(AVG(s.max_salary) AS DECIMAL(10,2)) AS AvgMaxSalary
FROM job_posting jp
JOIN salary s ON jp.job_id = s.job_id
WHERE s.pay_period = 'YEARLY'
GROUP BY jp.experience_level
HAVING AVG(s.max_salary) > 120000.00
ORDER BY AvgMaxSalary DESC;
GO


-- Query 7: Top 10 most in-demand skills
PRINT '--- Query 7: Top 10 In-Demand Skills ---';
SELECT TOP 10
    sk.skill_name AS SkillName,
    sk.skill_category AS SkillCode,
    COUNT(js.job_id) AS JobDemandCount
FROM job_skill js
JOIN skill sk ON js.skill_id = sk.skill_id
GROUP BY sk.skill_name, sk.skill_category
ORDER BY JobDemandCount DESC;
GO


-- Query 8: HAVING clause: core skills required by 15,000 or more jobs
PRINT '--- Query 8: HAVING Clause: Core Skills (>= 15,000 Jobs) ---';
SELECT
    sk.skill_name AS SkillName,
    COUNT(js.job_id) AS JobDemandCount
FROM job_skill js
JOIN skill sk ON js.skill_id = sk.skill_id
GROUP BY sk.skill_name
HAVING COUNT(js.job_id) >= 15000
ORDER BY JobDemandCount DESC;
GO


-- Query 9: Most commonly offered benefits (401k, Medical, etc.)
PRINT '--- Query 9: Most Frequent Benefits ---';
SELECT
    type AS BenefitType,
    COUNT(*) AS TotalOffers
FROM benefit
GROUP BY type
ORDER BY TotalOffers DESC;
GO


-- Query 10: HAVING clause: companies with 50 or more active job postings
PRINT '--- Query 10: HAVING Clause: Companies Hiring at Scale (>= 50 Jobs) ---';
SELECT TOP 10
    c.company_id,
    c.name AS CompanyName,
    c.company_size AS SizeTier,
    COUNT(jp.job_id) AS TotalActiveJobs
FROM company c
JOIN job_posting jp ON c.company_id = jp.company_id
GROUP BY c.company_id, c.name, c.company_size
HAVING COUNT(jp.job_id) >= 50
ORDER BY TotalActiveJobs DESC;
GO

PRINT 'Aggregates script finished.';
GO
