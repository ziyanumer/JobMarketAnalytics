-- DBMS Lab Project, Iqra University
-- Project: Job Postings Market Analytics
-- File: 07_subqueries.sql
-- Description: Subqueries: scalar, IN, NOT IN, EXISTS, correlated (Lab 10)

USE JobMarketAnalytics;
GO

PRINT '==================================================';
PRINT 'LAB 10: SUBQUERIES AND NESTED QUERIES DEMO';
PRINT '==================================================';
GO

-- Query 1: Scalar subquery: jobs whose max salary is above the overall market average
PRINT '--- Query 1: Above-Average Salary Jobs (Scalar Subquery) ---';
SELECT TOP 10
    jp.job_id,
    jp.title AS JobTitle,
    jp.experience_level,
    s.max_salary,
    (SELECT CAST(AVG(max_salary) AS DECIMAL(10,2)) FROM salary WHERE pay_period = 'YEARLY') AS MarketAvgMaxSalary
FROM job_posting jp
JOIN salary s ON jp.job_id = s.job_id
WHERE s.pay_period = 'YEARLY'
  AND s.max_salary > (
      -- Inner query calculates the market-wide average salary
      SELECT AVG(max_salary)
      FROM salary
      WHERE pay_period = 'YEARLY'
  )
ORDER BY s.max_salary DESC;
GO


-- Query 2: Multi-row subquery with IN: companies hiring in San Francisco or Seattle
PRINT '--- Query 2: Tech Hub Hiring Companies (IN Operator) ---';
SELECT TOP 10
    c.company_id,
    c.name AS CompanyName,
    c.company_size AS SizeTier,
    c.url
FROM company c
WHERE c.company_id IN (
    -- Inner query returns the companies with jobs in these tech hubs
    SELECT DISTINCT jp.company_id
    FROM job_posting jp
    WHERE jp.location LIKE '%San Francisco%'
       OR jp.location LIKE '%Seattle%'
)
ORDER BY c.name ASC;
GO


-- Query 3: Multi-row subquery with NOT IN: companies with no active jobs
PRINT '--- Query 3: Companies with No Jobs (NOT IN Operator) ---';
SELECT TOP 10
    c.company_id,
    c.name AS CompanyName,
    c.company_size AS SizeTier
FROM company c
WHERE c.company_id NOT IN (
    SELECT DISTINCT company_id
    FROM job_posting
    WHERE company_id IS NOT NULL
)
ORDER BY c.name ASC;
GO


-- Query 4: EXISTS operator: companies that offer a 401(k) benefit
PRINT '--- Query 4: Companies Offering 401(k) (EXISTS Operator) ---';
SELECT TOP 10
    c.company_id,
    c.name AS CompanyName,
    c.company_size AS SizeTier
FROM company c
WHERE EXISTS (
    -- Stops searching at the first match, so it is fast
    SELECT 1
    FROM job_posting jp
    JOIN benefit b ON jp.job_id = b.job_id
    WHERE jp.company_id = c.company_id
      AND b.type = '401(k)'
)
ORDER BY c.name ASC;
GO


-- Query 5: NOT EXISTS operator: jobs with no linked skills
PRINT '--- Query 5: Jobs with No Skill Tags (NOT EXISTS Operator) ---';
SELECT TOP 10
    jp.job_id,
    jp.title,
    jp.location,
    jp.work_type
FROM job_posting jp
WHERE NOT EXISTS (
    SELECT 1
    FROM job_skill js
    WHERE js.job_id = jp.job_id
)
ORDER BY jp.job_id DESC;
GO


-- Query 6: Correlated subquery: compare each job's salary with the average for its experience level
PRINT '--- Query 6: Correlated Subquery (Salary vs Level Average) ---';
SELECT TOP 10
    jp.job_id,
    jp.title AS JobTitle,
    jp.experience_level,
    s.max_salary AS JobSalary
FROM job_posting jp
JOIN salary s ON jp.job_id = s.job_id
WHERE s.pay_period = 'YEARLY'
  AND jp.experience_level IS NOT NULL
  AND s.max_salary > (
      -- Inner query uses the experience level of the outer row
      SELECT AVG(s2.max_salary)
      FROM job_posting jp2
      JOIN salary s2 ON jp2.job_id = s2.job_id
      WHERE jp2.experience_level = jp.experience_level
        AND s2.pay_period = 'YEARLY'
  )
ORDER BY s.max_salary DESC;
GO


-- Query 7: Derived table (subquery in FROM): companies posting more jobs than average
PRINT '--- Query 7: Derived Table: High-Volume Companies ---';
SELECT TOP 10
    CompanyHiringStats.company_id,
    c.name AS CompanyName,
    CompanyHiringStats.JobCount
FROM (
    -- Derived table: total jobs per company
    SELECT company_id, COUNT(*) AS JobCount
    FROM job_posting
    WHERE company_id IS NOT NULL
    GROUP BY company_id
) AS CompanyHiringStats
JOIN company c ON CompanyHiringStats.company_id = c.company_id
WHERE CompanyHiringStats.JobCount > (
    -- Subquery: average jobs per company
    SELECT AVG(CAST(JobCount AS FLOAT))
    FROM (
        SELECT COUNT(*) AS JobCount
        FROM job_posting
        WHERE company_id IS NOT NULL
        GROUP BY company_id
    ) AS OverallAverage
)
ORDER BY CompanyHiringStats.JobCount DESC;
GO

PRINT 'Subqueries script finished.';
GO
