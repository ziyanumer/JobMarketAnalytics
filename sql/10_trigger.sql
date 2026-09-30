-- DBMS Lab Project, Iqra University
-- Project: Job Postings Market Analytics
-- File: 10_trigger.sql
-- Description: Triggers and audit logging to track INSERT, UPDATE and DELETE (Lab 11)

USE JobMarketAnalytics;
GO

PRINT '==================================================';
PRINT 'DATABASE TRIGGERS & AUDITING DEMO (LAB 11)';
PRINT '==================================================';
GO

-- Step 1: Create the audit log table
-- Purpose: keeps a history of every change to the job_posting table
IF OBJECT_ID('JobPostingAuditLog', 'U') IS NOT NULL
    DROP TABLE JobPostingAuditLog;
GO

CREATE TABLE JobPostingAuditLog (
    log_id          INT             IDENTITY(1,1) PRIMARY KEY,
    job_id          BIGINT          NOT NULL,
    action_type     VARCHAR(20)     NOT NULL, -- 'INSERT', 'UPDATE', or 'DELETE'
    job_title       VARCHAR(255)    NULL,
    company_id      BIGINT          NULL,
    action_time     DATETIME        DEFAULT GETDATE(),
    action_user     VARCHAR(100)    DEFAULT SYSTEM_USER
);
GO

PRINT 'Created audit table: JobPostingAuditLog';
GO


-- Step 2: Create the AFTER INSERT, UPDATE, DELETE trigger
-- Purpose: fires automatically on every insert, update or delete on job_posting
-- inserted: virtual table holding the new or updated rows
-- deleted: virtual table holding the old or deleted rows
IF OBJECT_ID('trg_JobPostingAudit', 'TR') IS NOT NULL
    DROP TRIGGER trg_JobPostingAudit;
GO

CREATE TRIGGER trg_JobPostingAudit
ON job_posting
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Case 1: UPDATE (rows in both inserted and deleted)
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO JobPostingAuditLog (job_id, action_type, job_title, company_id)
        SELECT
            i.job_id,
            'UPDATE',
            i.title,
            i.company_id
        FROM inserted i;
    END

    -- Case 2: INSERT (rows only in inserted)
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO JobPostingAuditLog (job_id, action_type, job_title, company_id)
        SELECT
            i.job_id,
            'INSERT',
            i.title,
            i.company_id
        FROM inserted i;
    END

    -- Case 3: DELETE (rows only in deleted)
    ELSE IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO JobPostingAuditLog (job_id, action_type, job_title, company_id)
        SELECT
            d.job_id,
            'DELETE',
            d.title,
            d.company_id
        FROM deleted d;
    END
END;
GO

PRINT 'Created AFTER trigger: trg_JobPostingAudit';
GO


-- Step 3: Live trigger test (run an INSERT, UPDATE and DELETE)
PRINT '--- Trigger Test: running INSERT, UPDATE and DELETE ---';

-- Remove leftover test data from earlier runs
DELETE FROM JobPostingAuditLog WHERE job_id = 9999990303;
DELETE FROM job_posting WHERE job_id = 9999990303;

-- 1. INSERT test (trigger logs action_type = 'INSERT')
INSERT INTO job_posting (job_id, company_id, title, location, work_type, experience_level, views, applies)
VALUES (9999990303, 1009, 'Cybersecurity Architect', 'Armonk, NY', 'Full-time', 'Mid-Senior level', 10, 2);
PRINT '1. Inserted test job: 9999990303';

-- 2. UPDATE test (trigger logs action_type = 'UPDATE')
UPDATE job_posting
SET title = 'Principal Cybersecurity Architect',
    views = 50
WHERE job_id = 9999990303;
PRINT '2. Updated test job: 9999990303';

-- 3. DELETE test (trigger logs action_type = 'DELETE')
DELETE FROM job_posting
WHERE job_id = 9999990303;
PRINT '3. Deleted test job: 9999990303';
GO

-- Step 4: Check that the audit log entries were written
PRINT '--- Query: Inspecting JobPostingAuditLog ---';
SELECT
    log_id,
    job_id,
    action_type,
    job_title,
    company_id,
    action_time,
    action_user
FROM JobPostingAuditLog
WHERE job_id = 9999990303
ORDER BY log_id ASC;
GO

PRINT 'Triggers script finished.';
GO
