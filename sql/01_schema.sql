-- DBMS Lab Project, Iqra University
-- Project: Job Postings Market Analytics
-- File: 01_schema.sql
-- Description: Creates the database and the 9 normalized tables (3NF)

-- Create the database if it doesn't already exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'JobMarketAnalytics')
BEGIN
    CREATE DATABASE JobMarketAnalytics;
END
GO

USE JobMarketAnalytics;
GO

-- Drop existing tables (children first) so the script can be re-run without foreign key errors
IF OBJECT_ID('benefit', 'U') IS NOT NULL DROP TABLE benefit;
IF OBJECT_ID('salary', 'U') IS NOT NULL DROP TABLE salary;
IF OBJECT_ID('job_skill', 'U') IS NOT NULL DROP TABLE job_skill;
IF OBJECT_ID('skill', 'U') IS NOT NULL DROP TABLE skill;
IF OBJECT_ID('job_posting', 'U') IS NOT NULL DROP TABLE job_posting;
IF OBJECT_ID('employee_count', 'U') IS NOT NULL DROP TABLE employee_count;
IF OBJECT_ID('company_industry', 'U') IS NOT NULL DROP TABLE company_industry;
IF OBJECT_ID('industry', 'U') IS NOT NULL DROP TABLE industry;
IF OBJECT_ID('company', 'U') IS NOT NULL DROP TABLE company;
GO

-- Table 1: company
-- Basic company details (name, size, URL)
CREATE TABLE company (
    company_id      BIGINT          PRIMARY KEY, -- Unique company ID
    name            VARCHAR(255)    NOT NULL,    -- Company name
    company_size    VARCHAR(50)     NULL,        -- Company size (1 to 7, or text)
    description     VARCHAR(MAX)    NULL,        -- Company description
    url             VARCHAR(500)    NULL         -- LinkedIn page URL
);
GO

-- Table 2: industry
-- Lookup table of industry categories, so names are not repeated (3NF)
CREATE TABLE industry (
    industry_id     INT             IDENTITY(1,1) PRIMARY KEY, -- Auto-increment ID
    industry_name   VARCHAR(150)    NOT NULL UNIQUE            -- Unique industry name
);
GO

-- Table 3: company_industry
-- Junction table: a company can belong to many industries and an industry can have many companies (M:N)
CREATE TABLE company_industry (
    company_id      BIGINT          NOT NULL,
    industry_id     INT             NOT NULL,
    PRIMARY KEY (company_id, industry_id), -- Composite primary key prevents duplicate pairs
    FOREIGN KEY (company_id) REFERENCES company(company_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (industry_id) REFERENCES industry(industry_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- Table 4: employee_count
-- History of employee and follower counts per company
CREATE TABLE employee_count (
    employee_count_id   INT         IDENTITY(1,1) PRIMARY KEY,
    company_id          BIGINT      NOT NULL,
    employee_count      INT         NULL CHECK (employee_count >= 0), -- Can't be negative
    follower_count      INT         NULL CHECK (follower_count >= 0),
    time_recorded       DATETIME    NULL, -- When the count was recorded
    FOREIGN KEY (company_id) REFERENCES company(company_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- Table 5: job_posting
-- Main job listings table (fact table)
-- Note: job_id is BIGINT because LinkedIn job IDs are larger than 2 billion
CREATE TABLE job_posting (
    job_id              BIGINT          PRIMARY KEY, -- Unique job ID
    company_id          BIGINT          NULL,        -- Posting company (set to NULL if the company is deleted)
    title               VARCHAR(255)    NOT NULL,    -- Job title
    work_type           VARCHAR(50)     NULL,        -- Full-time, Part-time, Contract, etc.
    location            VARCHAR(255)    NULL,        -- City/State location
    experience_level    VARCHAR(50)     NULL,        -- Entry level, Mid-Senior, etc.
    views               INT             NULL DEFAULT 0 CHECK (views >= 0),
    applies             INT             NULL DEFAULT 0 CHECK (applies >= 0),
    FOREIGN KEY (company_id) REFERENCES company(company_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);
GO

-- Table 6: skill
-- Lookup table of distinct skills
CREATE TABLE skill (
    skill_id        INT             IDENTITY(1,1) PRIMARY KEY,
    skill_name      VARCHAR(100)    NOT NULL UNIQUE, -- Full skill name (e.g. Information Technology)
    skill_category  VARCHAR(50)     NULL             -- Short code (e.g. IT, MRKT)
);
GO

-- Table 7: job_skill
-- Junction table: a job can require many skills and a skill can appear in many jobs (M:N)
CREATE TABLE job_skill (
    job_id          BIGINT          NOT NULL,
    skill_id        INT             NOT NULL,
    PRIMARY KEY (job_id, skill_id), -- Composite primary key
    FOREIGN KEY (job_id) REFERENCES job_posting(job_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skill(skill_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- Table 8: salary
-- Salary range, pay period and currency for each job
CREATE TABLE salary (
    salary_id       INT             IDENTITY(1,1) PRIMARY KEY,
    job_id          BIGINT          NOT NULL,
    max_salary      DECIMAL(12,2)   NULL CHECK (max_salary >= 0),
    med_salary      DECIMAL(12,2)   NULL CHECK (med_salary >= 0),
    min_salary      DECIMAL(12,2)   NULL CHECK (min_salary >= 0),
    pay_period      VARCHAR(20)     NULL CHECK (pay_period IN ('HOURLY', 'MONTHLY', 'YEARLY')),
    currency        VARCHAR(10)     NULL DEFAULT 'USD',
    FOREIGN KEY (job_id) REFERENCES job_posting(job_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- Table 9: benefit
-- Benefits offered with each job (Medical, 401k, etc.)
CREATE TABLE benefit (
    benefit_id      INT             IDENTITY(1,1) PRIMARY KEY,
    job_id          BIGINT          NOT NULL,
    type            VARCHAR(150)    NOT NULL, -- Benefit name
    FOREIGN KEY (job_id) REFERENCES job_posting(job_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
GO

PRINT 'All 9 tables created successfully.';
GO
