# JobMarketAnalytics

A normalized SQL Server database built from 123,849 real LinkedIn job postings, used to answer practical questions about the job market: which skills are in demand, which industries hire the most, how pay changes with seniority, and how many employers actually publish salaries.

Built as the final project for the Database Management Systems lab at Iqra University, Karachi.

**Live dashboard:** [claude.ai/artifact/2tG4BAGHFTyAUV75cUmA6B](https://claude.ai/artifact/2tG4BAGHFTyAUV75cUmA6B)

## At a glance

| | |
|---|---|
| Rows loaded | 515,718 across 9 tables |
| Job postings | 123,849 |
| Companies | 24,472 |
| Schema | 9 tables in Third Normal Form (3NF) |
| Stack | Microsoft SQL Server, T-SQL, Python (pandas) |

## What the data shows

- **Only 29% of postings disclose salary.** 35,887 of 123,849 jobs list any pay information.
- **Median advertised yearly salary is $103K** (20,220 postings paid yearly in USD; salary figures use the midpoint of each posting's range).
- **Median yearly pay by experience level:** Internship $65K, Entry level $76.5K, Associate $82.5K, Mid-Senior $115K, Director $168K, Executive $200K.
- **Most in-demand skill category:** Information Technology (25,256 postings), followed by Sales and Management.
- **Top hiring industry:** Staffing and Recruiting (18,886 postings), then Hospitals and Health Care.
- **Most common benefit:** 401(k), listed in 23,109 of the 28,735 postings that mention benefits.

## Schema

```
company ──< company_industry >── industry
   │
   ├──< employee_count
   │
   └──< job_posting ──< job_skill >── skill
            │
            ├──< salary
            └──< benefit
```

| Table | Purpose |
|---|---|
| `company` | Company profile: name, size band, description, LinkedIn URL |
| `industry` | Lookup table of 144 industries |
| `company_industry` | Junction table for the many-to-many company ↔ industry relationship |
| `employee_count` | Employee and follower counts recorded over time |
| `job_posting` | The main fact table: title, work type, location, experience level, views, applies |
| `skill` | Lookup table of 35 skill categories |
| `job_skill` | Junction table for the many-to-many job ↔ skill relationship |
| `salary` | Min / median / max pay, pay period and currency per job |
| `benefit` | Benefits attached to each job |

Design choices worth noting:

- `job_id` and `company_id` are `BIGINT` because LinkedIn IDs exceed the `INT` range.
- `CHECK` constraints keep counts and salaries non-negative and restrict `pay_period` to `HOURLY`, `MONTHLY` or `YEARLY`.
- Deleting a company sets `job_posting.company_id` to `NULL` (the posting survives), while child rows of a job (skills, salary, benefits) cascade.

## Project structure

```
python/
  02_data_cleaning.py         Cleans the raw Kaggle CSVs into 9 table-ready CSVs
sql/
  01_schema.sql               Creates the database and all 9 tables with keys and constraints
  03_bulk_insert.sql          Loads the cleaned CSVs with BULK INSERT
  04_crud.sql                 INSERT / SELECT / UPDATE / DELETE examples
  05_aggregates.sql           GROUP BY and HAVING: salaries by level, top skills, top benefits
  06_joins.sql                Multi-table joins, LEFT JOIN, salary transparency audit
  07_subqueries.sql           Scalar, IN, NOT IN, EXISTS, NOT EXISTS, correlated and derived-table queries
  08_view.sql                 vw_JobMarketOverview, vw_IndustryHiringSummary
  09_stored_procedure.sql     sp_GetIndustryJobAnalytics, sp_SafeInsertJobPosting (TRY/CATCH + rollback)
  10_trigger.sql              trg_JobPostingAudit: logs every INSERT, UPDATE and DELETE on job_posting
  RUN_ALL_PROJECT_DEMO.sql    One script that runs through every feature end to end
run_verification.bat          Runs the demo script through sqlcmd on Windows
```

## How to run it

**Requirements:** SQL Server (Express or Developer edition works), `sqlcmd`, Python 3 with `pandas` and `numpy`.

1. **Get the data.** Download the [LinkedIn Job Postings dataset from Kaggle](https://www.kaggle.com/datasets/arshkon/linkedin-job-postings) and place these files directly in a `data/` folder at the repo root: `companies.csv`, `company_industries.csv`, `employee_counts.csv`, `job_postings.csv`, `skills.csv`, `job_skills.csv`, `salaries.csv`, `benefits.csv`. The data is not included in this repo because of its size.
2. **Clean it.**
   ```
   pip install pandas numpy
   python python/02_data_cleaning.py
   ```
   This writes 9 cleaned CSVs to `data/cleaned/`. It removes duplicates, drops orphan records so every foreign key is valid, strips broken line breaks from text fields, and converts Unix timestamps to `DATETIME`.
3. **Create the schema.** Run `sql/01_schema.sql` in SQL Server Management Studio or with `sqlcmd`.
4. **Load the data.** Open `sql/03_bulk_insert.sql`, change `C:\JobMarketAnalytics` to the folder where you cloned this repo (BULK INSERT needs absolute paths), then run it.
5. **Run the rest.** Execute `sql/04_crud.sql` through `sql/10_trigger.sql` in order.
6. **Check everything.** Run `run_verification.bat` (Windows) or `sql/RUN_ALL_PROJECT_DEMO.sql` directly.

## Authors

- **Ziyan Umer** · [LinkedIn](https://www.linkedin.com/in/ziyanumer)
- **Muhammad Arham**

DBMS Lab, BS Computer Science, Iqra University, 2026.
