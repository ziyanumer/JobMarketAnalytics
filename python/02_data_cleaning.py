# DBMS Lab Project, Iqra University
# Project: Job Postings Market Analytics
# File: 02_data_cleaning.py
# Description: Cleans the raw Kaggle CSV files and writes 9 normalized CSVs (one per table)

import os
import time
import pandas as pd
import numpy as np

def clean_data():
    start_time = time.time()
    print('Starting data cleaning...')

    # Paths are relative to the repo root (this script lives in python/).
    # Put the raw Kaggle CSVs in data/; cleaned output goes to data/cleaned/.
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    raw_dir = os.path.join(base_dir, 'data')
    clean_dir = os.path.join(raw_dir, 'cleaned')
    os.makedirs(clean_dir, exist_ok=True)

    # ------------------------------------------------------------------------
    # STEP 1: Clean companies.csv into the company table
    # ------------------------------------------------------------------------
    print('\n[1/7] Cleaning companies.csv...')
    comp = pd.read_csv(os.path.join(raw_dir, 'companies.csv'))

    # Drop duplicate companies and rows missing an ID or name
    comp = comp.drop_duplicates(subset=['company_id'])
    comp = comp.dropna(subset=['company_id', 'name'])
    comp['company_id'] = comp['company_id'].astype(np.int64)

    # Remove line breaks and extra spaces from text columns so the CSV stays valid
    comp['name'] = comp['name'].astype(str).str.replace(r'[\r\n\t]+', ' ', regex=True).str.strip()
    comp['company_size'] = comp['company_size'].fillna('').astype(str).str.replace('.0', '', regex=False)
    comp['description'] = comp['description'].fillna('').astype(str).str.replace(r'[\r\n\t]+', ' ', regex=True).str.strip()
    comp['url'] = comp['url'].fillna('').astype(str).str.replace(r'[\r\n\t]+', ' ', regex=True).str.strip()

    comp_clean = comp[['company_id', 'name', 'company_size', 'description', 'url']]
    comp_clean.to_csv(os.path.join(clean_dir, 'clean_company.csv'), index=False, encoding='utf-8')

    # Keep the valid company IDs to avoid foreign key errors later
    valid_companies = set(comp_clean['company_id'])
    print(f'   -> Saved clean_company.csv ({len(comp_clean):,} rows)')

    # ------------------------------------------------------------------------
    # STEP 2: Build industry and company_industry from company_industries.csv (3NF)
    # ------------------------------------------------------------------------
    print('\n[2/7] Cleaning company_industries.csv...')
    ci = pd.read_csv(os.path.join(raw_dir, 'company_industries.csv'))
    ci = ci.dropna(subset=['company_id', 'industry'])
    ci['company_id'] = ci['company_id'].astype(np.int64)

    # Keep only companies that exist in the company table
    ci = ci[ci['company_id'].isin(valid_companies)]
    ci['industry'] = ci['industry'].astype(str).str.strip()

    # Assign a numeric ID to each unique industry (3NF)
    unique_industries = sorted(ci['industry'].unique())
    ind_df = pd.DataFrame({
        'industry_id': range(1, len(unique_industries) + 1),
        'industry_name': unique_industries
    })
    ind_df.to_csv(os.path.join(clean_dir, 'clean_industry.csv'), index=False, encoding='utf-8')
    print(f'   -> Saved clean_industry.csv ({len(ind_df):,} distinct industries)')

    # Junction table: replace the industry text with its industry_id
    ci = ci.merge(ind_df, left_on='industry', right_on='industry_name')
    ci_clean = ci[['company_id', 'industry_id']].drop_duplicates()
    ci_clean.to_csv(os.path.join(clean_dir, 'clean_company_industry.csv'), index=False, encoding='utf-8')
    print(f'   -> Saved clean_company_industry.csv ({len(ci_clean):,} rows)')

    # ------------------------------------------------------------------------
    # STEP 3: Clean employee_counts.csv into employee_count
    # ------------------------------------------------------------------------
    print('\n[3/7] Cleaning employee_counts.csv...')
    ec = pd.read_csv(os.path.join(raw_dir, 'employee_counts.csv'))
    ec = ec.dropna(subset=['company_id'])
    ec['company_id'] = ec['company_id'].astype(np.int64)
    ec = ec[ec['company_id'].isin(valid_companies)]
    ec = ec.drop_duplicates()

    # Convert Unix epoch seconds to a readable DATETIME (YYYY-MM-DD HH:MM:SS)
    ec['time_recorded'] = pd.to_datetime(ec['time_recorded'], unit='s', errors='coerce').dt.strftime('%Y-%m-%d %H:%M:%S')
    ec['employee_count'] = ec['employee_count'].fillna('').apply(lambda x: '' if x == '' else str(int(float(x))))
    ec['follower_count'] = ec['follower_count'].fillna('').apply(lambda x: '' if x == '' else str(int(float(x))))

    ec['employee_count_id'] = range(1, len(ec) + 1)
    ec_clean = ec[['employee_count_id', 'company_id', 'employee_count', 'follower_count', 'time_recorded']]
    ec_clean.to_csv(os.path.join(clean_dir, 'clean_employee_count.csv'), index=False, encoding='utf-8')
    print(f'   -> Saved clean_employee_count.csv ({len(ec_clean):,} rows)')

    # ------------------------------------------------------------------------
    # STEP 4: Clean job_postings.csv into job_posting
    # ------------------------------------------------------------------------
    print('\n[4/7] Cleaning job_postings.csv...')
    jp_cols = ['job_id', 'company_id', 'title', 'location', 'formatted_work_type', 'formatted_experience_level', 'views', 'applies']
    jp = pd.read_csv(os.path.join(raw_dir, 'job_postings.csv'), usecols=jp_cols)

    jp = jp.dropna(subset=['job_id', 'title'])
    jp = jp.drop_duplicates(subset=['job_id'])
    jp['job_id'] = jp['job_id'].astype(np.int64)

    # If the company doesn't exist, leave company_id empty (NULL)
    jp['company_id'] = jp['company_id'].apply(lambda x: str(int(x)) if pd.notna(x) and int(x) in valid_companies else '')

    # Clean the text columns
    jp['title'] = jp['title'].astype(str).str.replace(r'[\r\n\t]+', ' ', regex=True).str.strip().str.slice(0, 255)
    jp['location'] = jp['location'].fillna('').astype(str).str.replace(r'[\r\n\t]+', ' ', regex=True).str.strip().str.slice(0, 255)
    jp['work_type'] = jp['formatted_work_type'].fillna('').astype(str).str.strip()
    jp['experience_level'] = jp['formatted_experience_level'].fillna('').astype(str).str.strip()

    # Fill missing views and applies with 0 (matches DEFAULT 0)
    jp['views'] = jp['views'].fillna(0).astype(int)
    jp['applies'] = jp['applies'].fillna(0).astype(int)

    jp_clean = jp[['job_id', 'company_id', 'title', 'work_type', 'location', 'experience_level', 'views', 'applies']]
    jp_clean.to_csv(os.path.join(clean_dir, 'clean_job_posting.csv'), index=False, encoding='utf-8')

    # Keep the valid job IDs for the child tables
    valid_jobs = set(jp_clean['job_id'])
    print(f'   -> Saved clean_job_posting.csv ({len(jp_clean):,} rows)')

    # ------------------------------------------------------------------------
    # STEP 5: Clean skills.csv and job_skills.csv (3NF)
    # ------------------------------------------------------------------------
    print('\n[5/7] Cleaning skills.csv and job_skills.csv...')
    sk = pd.read_csv(os.path.join(raw_dir, 'skills.csv'))
    sk['skill_id'] = range(1, len(sk) + 1)
    sk['skill_name'] = sk['skill_name'].astype(str).str.strip()
    sk['skill_category'] = sk['skill_abr'].astype(str).str.strip()
    sk_clean = sk[['skill_id', 'skill_name', 'skill_category']]
    sk_clean.to_csv(os.path.join(clean_dir, 'clean_skill.csv'), index=False, encoding='utf-8')
    print(f'   -> Saved clean_skill.csv ({len(sk_clean):,} skills)')

    js = pd.read_csv(os.path.join(raw_dir, 'job_skills.csv'))
    js = js.dropna(subset=['job_id', 'skill_abr'])
    js['job_id'] = js['job_id'].astype(np.int64)
    # Keep only valid jobs
    js = js[js['job_id'].isin(valid_jobs)]

    # Map each skill abbreviation to its integer skill_id
    js = js.merge(sk[['skill_abr', 'skill_id']], on='skill_abr')
    js_clean = js[['job_id', 'skill_id']].drop_duplicates()
    js_clean.to_csv(os.path.join(clean_dir, 'clean_job_skill.csv'), index=False, encoding='utf-8')
    print(f'   -> Saved clean_job_skill.csv ({len(js_clean):,} rows)')

    # ------------------------------------------------------------------------
    # STEP 6: Clean salaries.csv into salary
    # ------------------------------------------------------------------------
    print('\n[6/7] Cleaning salaries.csv...')
    sal = pd.read_csv(os.path.join(raw_dir, 'salaries.csv'))
    sal = sal.dropna(subset=['job_id'])
    sal['job_id'] = sal['job_id'].astype(np.int64)
    # Remove orphan salary rows with no matching job_posting
    sal = sal[sal['job_id'].isin(valid_jobs)]

    # Keep only valid pay periods (HOURLY, MONTHLY, YEARLY)
    sal['pay_period'] = sal['pay_period'].astype(str).str.strip().str.upper()
    sal = sal[sal['pay_period'].isin(['HOURLY', 'MONTHLY', 'YEARLY'])]
    sal['currency'] = 'USD'

    # Format salary values to 2 decimal places
    sal['max_salary'] = sal['max_salary'].fillna('').apply(lambda x: '' if x == '' else f'{float(x):.2f}')
    sal['med_salary'] = sal['med_salary'].fillna('').apply(lambda x: '' if x == '' else f'{float(x):.2f}')
    sal['min_salary'] = sal['min_salary'].fillna('').apply(lambda x: '' if x == '' else f'{float(x):.2f}')

    sal['salary_id'] = range(1, len(sal) + 1)
    sal_clean = sal[['salary_id', 'job_id', 'max_salary', 'med_salary', 'min_salary', 'pay_period', 'currency']]
    sal_clean.to_csv(os.path.join(clean_dir, 'clean_salary.csv'), index=False, encoding='utf-8')
    print(f'   -> Saved clean_salary.csv ({len(sal_clean):,} rows)')

    # ------------------------------------------------------------------------
    # STEP 7: Clean benefits.csv into benefit
    # ------------------------------------------------------------------------
    print('\n[7/7] Cleaning benefits.csv...')
    ben = pd.read_csv(os.path.join(raw_dir, 'benefits.csv'))
    ben = ben.dropna(subset=['job_id', 'type'])
    ben['job_id'] = ben['job_id'].astype(np.int64)
    ben = ben[ben['job_id'].isin(valid_jobs)]

    ben['type'] = ben['type'].astype(str).str.replace(r'[\r\n\t]+', ' ', regex=True).str.strip()
    ben = ben.drop_duplicates(subset=['job_id', 'type'])

    ben['benefit_id'] = range(1, len(ben) + 1)
    ben_clean = ben[['benefit_id', 'job_id', 'type']]
    ben_clean.to_csv(os.path.join(clean_dir, 'clean_benefit.csv'), index=False, encoding='utf-8')
    print(f'   -> Saved clean_benefit.csv ({len(ben_clean):,} rows)')

    print(f'\nCleaned data for all 9 tables in {time.time()-start_time:.2f} seconds.')
    print(f'Cleaned files saved to: {clean_dir}')

if __name__ == '__main__':
    clean_data()
