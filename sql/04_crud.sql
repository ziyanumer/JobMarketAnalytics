-- DBMS Lab Project, Iqra University
-- Project: Job Postings Market Analytics
-- File: 04_crud.sql
-- Description: Basic INSERT, SELECT, UPDATE and DELETE operations (Lab 7)

USE JobMarketAnalytics;
GO

PRINT '==================================================';
PRINT 'LAB 7: BASIC CRUD OPERATIONS DEMO';
PRINT '==================================================';
GO

-- ============================================================================
-- 1. CREATE (INSERT OPERATIONS)
-- ============================================================================

-- 1.1: Insert a new company
INSERT INTO company (company_id, name, company_size, description, url)
VALUES (
    99999901,
    'Apex Cloud Systems',
    '4',
    'A cloud computing and data engineering company.',
    'https://www.linkedin.com/company/apex-cloud-systems'
);
PRINT '1.1 Inserted new company: Apex Cloud Systems';
GO

-- 1.2: Insert a job posting for this company
INSERT INTO job_posting (job_id, company_id, title, work_type, location, experience_level, views, applies)
VALUES (
    9999990101,
    99999901,
    'Senior Data Engineer',
    'Full-time',
    'Austin, TX',
    'Mid-Senior level',
    120,
    15
);
PRINT '1.2 Inserted new job posting: Senior Data Engineer';
GO

-- 1.3: Add salary details for the job
INSERT INTO salary (job_id, max_salary, med_salary, min_salary, pay_period, currency)
VALUES (
    9999990101,
    155000.00,
    140000.00,
    125000.00,
    'YEARLY',
    'USD'
);
PRINT '1.3 Inserted job salary';
GO

-- 1.4: Insert several benefits at once (multi-row insert)
INSERT INTO benefit (job_id, type)
VALUES
    (9999990101, 'Medical insurance'),
    (9999990101, '401(k)'),
    (9999990101, 'Tuition assistance');
PRINT '1.4 Inserted multiple benefits for the job';
GO

-- 1.5: Link the job to skills in the junction table (24 = IT, 11 = Analyst)
INSERT INTO job_skill (job_id, skill_id)
VALUES
    (9999990101, 24),
    (9999990101, 11);
PRINT '1.5 Inserted job skills into the junction table';
GO


-- ============================================================================
-- 2. READ (SELECT OPERATIONS)
-- ============================================================================

-- 2.1: View the record we just inserted, using a join
PRINT '--- Query 2.1: View the inserted record ---';
SELECT
    c.company_id,
    c.name AS CompanyName,
    jp.job_id,
    jp.title AS JobTitle,
    jp.location,
    jp.views,
    jp.applies
FROM company c
JOIN job_posting jp ON c.company_id = jp.company_id
WHERE c.company_id = 99999901;
GO

-- 2.2: Search for titles containing Data or Analyst with LIKE
PRINT '--- Query 2.2: Search jobs with LIKE ---';
SELECT TOP 5
    job_id,
    title,
    location,
    work_type,
    experience_level
FROM job_posting
WHERE title LIKE '%Data%' OR title LIKE '%Analyst%'
ORDER BY views DESC;
GO

-- 2.3: Jobs with 100 to 500 views, using BETWEEN
PRINT '--- Query 2.3: Filter views with BETWEEN ---';
SELECT TOP 5
    job_id,
    title,
    views,
    applies
FROM job_posting
WHERE views BETWEEN 100 AND 500
ORDER BY applies DESC;
GO


-- ============================================================================
-- 3. UPDATE OPERATIONS
-- ============================================================================

-- 3.1: Increase views and applies for a specific job
UPDATE job_posting
SET views = views + 25,
    applies = applies + 5
WHERE job_id = 9999990101;
PRINT '3.1 Updated views and applies';
GO

-- 3.2: Change the max salary in the salary table
UPDATE salary
SET max_salary = 165000.00,
    med_salary = 145000.00
WHERE job_id = 9999990101;
PRINT '3.2 Updated salary range';
GO

-- 3.3: Check that the update worked
PRINT '--- Query 3.3: Check updated values ---';
SELECT
    jp.job_id,
    jp.title,
    jp.views,
    jp.applies,
    s.min_salary,
    s.med_salary,
    s.max_salary
FROM job_posting jp
JOIN salary s ON jp.job_id = s.job_id
WHERE jp.job_id = 9999990101;
GO


-- ============================================================================
-- 4. DELETE OPERATIONS
-- ============================================================================

-- 4.1: Delete one benefit record
DELETE FROM benefit
WHERE job_id = 9999990101 AND type = 'Tuition assistance';
PRINT '4.1 Deleted Tuition assistance benefit';
GO

-- 4.2: Delete the company
-- Note: job_posting uses ON DELETE SET NULL, so the job is kept and its company_id becomes NULL
DELETE FROM company
WHERE company_id = 99999901;
PRINT '4.2 Deleted company (company_id in job_posting is now NULL)';
GO

-- 4.3: Verify that company_id is now NULL
PRINT '--- Query 4.3: Check the SET NULL result ---';
SELECT
    job_id,
    company_id,
    title,
    location
FROM job_posting
WHERE job_id = 9999990101;
GO

-- 4.4: Delete the test job (CASCADE removes its salary, benefit and job_skill rows)
DELETE FROM job_posting
WHERE job_id = 9999990101;
PRINT '4.4 Deleted test job (child records removed by cascade)';
GO

PRINT 'CRUD script finished.';
GO
