-- DBMS Lab Project, Iqra University
-- Project: Job Postings Market Analytics
-- File: 09_stored_procedure.sql
-- Description: Stored procedures with input/OUTPUT parameters and TRY...CATCH transactions (Lab 11)

USE JobMarketAnalytics;
GO

PRINT '==================================================';
PRINT 'STORED PROCEDURES DEMO (LAB 11)';
PRINT '==================================================';
GO

-- Procedure 1: sp_GetIndustryJobAnalytics
-- Purpose: takes an industry name and returns total jobs and average salary as OUTPUT parameters.
-- Also returns a result set with the top 5 highest-paying jobs.
IF OBJECT_ID('sp_GetIndustryJobAnalytics', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetIndustryJobAnalytics;
GO

CREATE PROCEDURE sp_GetIndustryJobAnalytics
    @IndustryName   VARCHAR(150),
    @TotalJobs      INT            OUTPUT,   -- Output parameter 1: total jobs
    @AvgMaxSalary   DECIMAL(12,2)  OUTPUT    -- Output parameter 2: average salary
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate total jobs and average salary into the OUTPUT parameters
    SELECT
        @TotalJobs = COUNT(jp.job_id),
        @AvgMaxSalary = CAST(AVG(s.max_salary) AS DECIMAL(12,2))
    FROM industry ind
    INNER JOIN company_industry ci ON ind.industry_id = ci.industry_id
    INNER JOIN company c           ON ci.company_id = c.company_id
    INNER JOIN job_posting jp      ON c.company_id = jp.company_id
    LEFT JOIN salary s             ON jp.job_id = s.job_id AND s.pay_period = 'YEARLY'
    WHERE ind.industry_name = @IndustryName;

    -- Return the top 5 highest-paying jobs in this industry
    SELECT TOP 5
        jp.job_id,
        jp.title AS JobTitle,
        c.name AS CompanyName,
        jp.location AS Location,
        s.max_salary AS MaxSalary
    FROM industry ind
    INNER JOIN company_industry ci ON ind.industry_id = ci.industry_id
    INNER JOIN company c           ON ci.company_id = c.company_id
    INNER JOIN job_posting jp      ON c.company_id = jp.company_id
    INNER JOIN salary s            ON jp.job_id = s.job_id
    WHERE ind.industry_name = @IndustryName AND s.pay_period = 'YEARLY'
    ORDER BY s.max_salary DESC;
END;
GO

PRINT 'Created procedure: sp_GetIndustryJobAnalytics';
GO


-- Procedure 2: sp_SafeInsertJobPosting
-- Purpose: insert a job posting and its salary together in one transaction.
-- On any error, TRY...CATCH rolls back so no partial data is saved.
IF OBJECT_ID('sp_SafeInsertJobPosting', 'P') IS NOT NULL
    DROP PROCEDURE sp_SafeInsertJobPosting;
GO

CREATE PROCEDURE sp_SafeInsertJobPosting
    @JobID          BIGINT,
    @CompanyID      BIGINT,
    @Title          VARCHAR(255),
    @Location       VARCHAR(255),
    @WorkType       VARCHAR(50),
    @ExpLevel       VARCHAR(50),
    @MinSalary      DECIMAL(12,2) = NULL,
    @MaxSalary      DECIMAL(12,2) = NULL,
    @PayPeriod      VARCHAR(20)   = 'YEARLY'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Check that the company exists (foreign key integrity)
        IF @CompanyID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM company WHERE company_id = @CompanyID)
        BEGIN
            RAISERROR('Error: This CompanyID does not exist in the company table!', 16, 1);
            RETURN;
        END

        -- Start the transaction: insert into both tables or neither
        BEGIN TRANSACTION;

            -- 1. Insert the job posting
            INSERT INTO job_posting (job_id, company_id, title, location, work_type, experience_level, views, applies)
            VALUES (@JobID, @CompanyID, @Title, @Location, @WorkType, @ExpLevel, 0, 0);

            -- 2. If a salary was given, insert it into the salary table too
            IF @MinSalary IS NOT NULL OR @MaxSalary IS NOT NULL
            BEGIN
                INSERT INTO salary (job_id, min_salary, med_salary, max_salary, pay_period, currency)
                VALUES (
                    @JobID,
                    @MinSalary,
                    CAST((@MinSalary + @MaxSalary) / 2.0 AS DECIMAL(12,2)),
                    @MaxSalary,
                    @PayPeriod,
                    'USD'
                );
            END

        -- Everything succeeded, so commit
        COMMIT TRANSACTION;
        PRINT 'Success: job posting and salary transaction committed.';

    END TRY
    BEGIN CATCH
        -- On error, roll back
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'Error, transaction rolled back: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

PRINT 'Created procedure: sp_SafeInsertJobPosting';
GO


-- Demo 1: Call the procedure with OUTPUT parameters
PRINT '--- Test 1: Calling sp_GetIndustryJobAnalytics ---';

DECLARE @TotalFoundJobs INT;
DECLARE @AverageSalary  DECIMAL(12,2);

EXEC sp_GetIndustryJobAnalytics
    @IndustryName   = 'IT Services and IT Consulting',
    @TotalJobs      = @TotalFoundJobs OUTPUT,
    @AvgMaxSalary   = @AverageSalary  OUTPUT;

-- Print the OUTPUT parameter values
PRINT '>> Result for industry [IT Services and IT Consulting]:';
PRINT '   Total Active Jobs : ' + CAST(@TotalFoundJobs AS VARCHAR);
PRINT '   Average Max Salary: $' + CAST(@AverageSalary AS VARCHAR);
GO


-- Demo 2: Test the safe job insert procedure
PRINT '--- Test 2: Testing sp_SafeInsertJobPosting ---';

-- Remove leftover test data from earlier runs
DELETE FROM salary WHERE job_id = 9999990202;
DELETE FROM job_posting WHERE job_id = 9999990202;

-- Pick a real company ID
DECLARE @SampleCompanyID BIGINT;
SELECT TOP 1 @SampleCompanyID = company_id FROM company WHERE name LIKE '%Microsoft%';

-- Call the procedure to insert the new job and salary
EXEC sp_SafeInsertJobPosting
    @JobID      = 9999990202,
    @CompanyID  = @SampleCompanyID,
    @Title      = 'Lead AI Architect',
    @Location   = 'Redmond, WA',
    @WorkType   = 'Full-time',
    @ExpLevel   = 'Executive',
    @MinSalary  = 180000.00,
    @MaxSalary  = 240000.00,
    @PayPeriod  = 'YEARLY';

-- Check that the insert worked
SELECT jp.job_id, jp.title, c.name, s.min_salary, s.max_salary
FROM job_posting jp
JOIN company c ON jp.company_id = c.company_id
JOIN salary s  ON jp.job_id = s.job_id
WHERE jp.job_id = 9999990202;

-- Clean up the test data
DELETE FROM salary WHERE job_id = 9999990202;
DELETE FROM job_posting WHERE job_id = 9999990202;
PRINT 'Test job cleaned up.';
GO

PRINT 'Stored procedures script finished.';
GO
