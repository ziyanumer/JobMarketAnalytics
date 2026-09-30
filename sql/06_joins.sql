-- DBMS Lab Project, Iqra University
-- Project: Job Postings Market Analytics
-- File: 06_joins.sql
-- Description: INNER JOIN and LEFT JOIN queries (Lab 9)

USE JobMarketAnalytics;
GO

PRINT '==================================================';
PRINT 'LAB 9: RELATIONAL JOINS DEMO';
PRINT '==================================================';
GO

-- Query 1: Two-table INNER JOIN: job postings with their company details
PRINT '--- Query 1: Jobs with Company Profiles (Two-Table INNER JOIN) ---';
SELECT TOP 10
    jp.job_id,
    jp.title AS JobTitle,
    c.name AS CompanyName,
    c.company_size AS CompanySizeTier,
    jp.location,
    jp.work_type
FROM job_posting jp
INNER JOIN company c ON jp.company_id = c.company_id
ORDER BY jp.job_id DESC;
GO


-- Query 2: Three-table junction JOIN: company to industry through company_industry
PRINT '--- Query 2: Companies and Mapped Industries (Junction Table JOIN) ---';
SELECT TOP 10
    c.name AS CompanyName,
    ind.industry_name AS IndustrySector
FROM company c
INNER JOIN company_industry ci ON c.company_id = ci.company_id
INNER JOIN industry ind        ON ci.industry_id = ind.industry_id
ORDER BY c.name ASC;
GO


-- Query 3: Multi-table join: Company + Job + Salary + Skill (via job_skill)
PRINT '--- Query 3: Multi-Table Profile (Company + Job + Salary + Skill) ---';
SELECT TOP 10
    c.name AS CompanyName,
    jp.title AS JobTitle,
    s.min_salary,
    s.max_salary,
    s.pay_period,
    sk.skill_name AS RequiredSkill
FROM company c
INNER JOIN job_posting jp ON c.company_id = jp.company_id
INNER JOIN salary s       ON jp.job_id = s.job_id
INNER JOIN job_skill js   ON jp.job_id = js.job_id
INNER JOIN skill sk       ON js.skill_id = sk.skill_id
WHERE s.pay_period = 'YEARLY' AND s.min_salary IS NOT NULL
ORDER BY s.max_salary DESC;
GO


-- Query 4: Top 10 industries by job count (4-table join + GROUP BY)
PRINT '--- Query 4: Top 10 Industries by Total Job Postings ---';
SELECT TOP 10
    ind.industry_name AS IndustrySector,
    COUNT(jp.job_id) AS TotalJobPostings
FROM industry ind
INNER JOIN company_industry ci ON ind.industry_id = ci.industry_id
INNER JOIN company c           ON ci.company_id = c.company_id
INNER JOIN job_posting jp      ON c.company_id = jp.company_id
GROUP BY ind.industry_name
ORDER BY TotalJobPostings DESC;
GO


-- Query 5: LEFT JOIN: companies with no job postings in the database (IS NULL)
PRINT '--- Query 5: Inactive Companies with Zero Jobs (LEFT JOIN) ---';
SELECT TOP 10
    c.company_id,
    c.name AS CompanyName,
    c.company_size AS SizeTier,
    jp.job_id AS PostingStatus
FROM company c
LEFT JOIN job_posting jp ON c.company_id = jp.company_id
WHERE jp.job_id IS NULL
ORDER BY c.name ASC;
GO


-- Query 6: Followers vs job postings: do companies with more followers post more jobs?
PRINT '--- Query 6: Company Follower Count vs Total Postings ---';
SELECT TOP 10
    c.name AS CompanyName,
    c.company_size AS SizeTier,
    MAX(ec.employee_count) AS LatestEmployeeCount,
    MAX(ec.follower_count) AS LatestFollowerCount,
    COUNT(DISTINCT jp.job_id) AS ActiveJobCount
FROM company c
INNER JOIN employee_count ec ON c.company_id = ec.company_id
INNER JOIN job_posting jp    ON c.company_id = jp.company_id
GROUP BY c.company_id, c.name, c.company_size
HAVING COUNT(DISTINCT jp.job_id) >= 20
ORDER BY LatestFollowerCount DESC;
GO


-- Query 7: Benefits by company size tier (Small = 1, Medium = 4, Enterprise = 7)
PRINT '--- Query 7: Top Benefits by Company Size Tier ---';
SELECT
    c.company_size AS CompanySizeTier,
    b.type AS BenefitType,
    COUNT(*) AS OfferCount
FROM company c
INNER JOIN job_posting jp ON c.company_id = jp.company_id
INNER JOIN benefit b      ON jp.job_id = b.job_id
WHERE c.company_size IN ('1', '4', '7')
GROUP BY c.company_size, b.type
HAVING COUNT(*) >= 50
ORDER BY c.company_size ASC, OfferCount DESC;
GO


-- Query 8: LEFT JOIN: salary transparency (how many jobs disclose a salary and how many don't)
PRINT '--- Query 8: Salary Transparency Audit ---';
SELECT
    CASE
        WHEN s.salary_id IS NULL THEN 'Salary Not Disclosed'
        ELSE 'Salary Disclosed'
    END AS DisclosureStatus,
    COUNT(jp.job_id) AS TotalPostings
FROM job_posting jp
LEFT JOIN salary s ON jp.job_id = s.job_id
GROUP BY
    CASE
        WHEN s.salary_id IS NULL THEN 'Salary Not Disclosed'
        ELSE 'Salary Disclosed'
    END;
GO

PRINT 'Joins script finished.';
GO
