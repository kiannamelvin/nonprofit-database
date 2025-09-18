-- Ensure clean slate for development/testing
---DROP VIEWS
DROP VIEW IF EXISTS monthly_volunteer_summary;
DROP VIEW IF EXISTS volunteer_area_summary;
DROP VIEW IF EXISTS dashboard_monthly_detail;

-- DROP TABLES
DROP TABLE IF EXISTS volunteer_sessions;
DROP TABLE IF EXISTS volunteers; 
DROP TABLE IF EXISTS volunteer_areas;
DROP TABLE IF EXISTS raw_data1;
DROP TABLE IF EXISTS raw_data1_backup;

-- Drop the custom function if it exists
DROP FUNCTION IF EXISTS parse_date(TEXT);

-- NONPROFIT VOLUNTEER DATABASE PROJECT
-- Complete Data Cleaning and Normalization Script
-- =====================================

-- =====================================
-- 1. DATA IMPORT AND INITIAL SETUP
-- =====================================

-- Import CSV data into flexible text table to handle data quality issues
CREATE TABLE raw_data1 (
    timestamp TEXT NULL,
    last_name TEXT NULL,
    first_name TEXT NULL,
    volunteer_area TEXT NULL,
    date_volunteered TEXT NULL,
    volunteer_time TEXT NULL,
    comments TEXT NULL,
    total_miles_personal_car TEXT NULL
);
--fix email_address column issues in import
ALTER TABLE raw_data1 ADD COLUMN email_address TEXT NULL;

-- Verify import success
SELECT COUNT(*) FROM raw_data1;

--DATA CLEANING NUMERIC:
-- Fix mileage entries with string values:
UPDATE raw_data1 SET total_miles_personal_car = '10' WHERE total_miles_personal_car = '10 miles';
UPDATE raw_data1 SET total_miles_personal_car = '40' WHERE total_miles_personal_car = '40 miles';
UPDATE raw_data1 SET total_miles_personal_car = '15' WHERE total_miles_personal_car = '15 miles';

-- Set remaining non-numeric mileage values to NULL
UPDATE raw_data1 
SET total_miles_personal_car = NULL
WHERE total_miles_personal_car !~ '^[0-9]*\.?[0-9]*$';

-- Remove completely empty rows (whitespace cleanup)
DELETE FROM raw_data1 
WHERE (TRIM(timestamp) = '' OR timestamp IS NULL)
  AND (TRIM(last_name) = '' OR last_name IS NULL)
  AND (TRIM(first_name) = '' OR first_name IS NULL)
  AND (TRIM(volunteer_area) = '' OR volunteer_area IS NULL)
  AND (TRIM(date_volunteered) = '' OR date_volunteered IS NULL)
  AND (TRIM(volunteer_time) = '' OR volunteer_time IS NULL)
  AND (TRIM(comments) = '' OR comments IS NULL)
  AND (TRIM(total_miles_personal_car) = '' OR total_miles_personal_car IS NULL);

-- Trim whitespace from all text fields
UPDATE raw_data1 
SET timestamp = TRIM(timestamp),
    last_name = TRIM(last_name),
    first_name = TRIM(first_name),
    volunteer_area = TRIM(volunteer_area),
    date_volunteered = TRIM(date_volunteered),
    volunteer_time = TRIM(volunteer_time),
    comments = TRIM(comments),
    total_miles_personal_car = TRIM(total_miles_personal_car);

-- Remove outlier volunteer time entries (over 999 hours)
DELETE FROM raw_data1 
WHERE volunteer_time ~ '^\d*\.?\d+$' 
  AND volunteer_time::NUMERIC > 999;

-- Fix unrealistic volunteer hours for specific volunteer
UPDATE raw_data1 SET volunteer_time = '6' WHERE volunteer_time = '60' AND last_name = 'cihan';
UPDATE raw_data1 SET volunteer_time = '8' WHERE volunteer_time = '80' AND last_name = 'cihan';

-- Remove entries with invalid date formats
DELETE FROM raw_data1 
WHERE date_volunteered IS NOT NULL 
  AND date_volunteered !~ '^\d{1,2}/\d{1,2}/\d{4}$';

-- =====================================
-- 3. DATA CLEANING: NAME STANDARDIZATION
-- =====================================

-- Fix entries where first and last names were combined in first_name field
UPDATE raw_data1 
SET first_name = 'Dallas', last_name = 'Pearson' 
WHERE first_name = 'Dallas Pearson' AND last_name = 'Dallas Pearson';

UPDATE raw_data1 
SET first_name = 'John', last_name = 'Fry' 
WHERE first_name = 'John Fry' AND last_name = 'John Fry';

-- Convert all names to lowercase for consistency
UPDATE raw_data1 
SET first_name = LOWER(first_name),
    last_name = LOWER(last_name);

-- Correct common name misspellings
UPDATE raw_data1 SET last_name = 'stanton' WHERE last_name = 'statnon';
UPDATE raw_data1 SET first_name = 'stephen' WHERE first_name IN ('s', 'steve');
UPDATE raw_data1 SET first_name = 'melissa' WHERE first_name = 'missy';
UPDATE raw_data1 SET last_name = 'forman' WHERE last_name = 'foreman';
UPDATE raw_data1 SET first_name = 'loren' WHERE first_name = 'liren';
UPDATE raw_data1 SET first_name = 'patrick' WHERE first_name = 'piet';
UPDATE raw_data1 SET first_name = 'michael' WHERE first_name = 'mike';
UPDATE raw_data1 SET first_name = 'beverly' WHERE first_name IN ('beerly','bevelry');
UPDATE raw_data1 SET last_name = 'cihan' WHERE last_name = 'clan';
UPDATE raw_data1 SET last_name = 'harkins' WHERE last_name IN ('harkiins', 'hakins');
UPDATE raw_data1 SET first_name = 'bj' WHERE first_name IN ('bj &', 'bobby');
UPDATE raw_data1 SET last_name = 'allen' WHERE last_name = 'alleb';
UPDATE raw_data1 SET first_name = 'karen' WHERE first_name IN ('kore', 'katen', 'kare');
UPDATE raw_data1 SET first_name = 'jeffrey' WHERE first_name IN ('jeff','jeffrry');
UPDATE raw_data1 SET last_name = 'rankin' WHERE last_name = 'rannkin';
UPDATE raw_data1 SET last_name = 'marton' WHERE last_name IN ('martin', 'merton');
UPDATE raw_data1 SET first_name = 'shaun' WHERE first_name = 'shaen';
UPDATE raw_data1 SET first_name = 'sharon' WHERE first_name IN ('share', 'sharo');
UPDATE raw_data1 SET first_name = 'susan' WHERE first_name = 'suzy';

-- Handle volunteer group entries
UPDATE raw_data1 SET first_name = 'volunteer group' WHERE first_name = 'volunteers';
UPDATE raw_data1 SET last_name = 'volunteer group' WHERE last_name = 'group';

-- =====================================
-- 4. DATA CLEANING: VOLUNTEER AREAS STANDARDIZATION
-- =====================================

-- Convert volunteer areas to lowercase
UPDATE raw_data1 SET volunteer_area = LOWER(volunteer_area);

-- Standardize volunteer areas into 8 main categories for consistent reporting
UPDATE raw_data1 
SET volunteer_area = 
  CASE 
    WHEN volunteer_area LIKE 'inventory%' THEN 'inventory'
    WHEN volunteer_area LIKE '%client care%' OR volunteer_area LIKE '%client servics%' 
         OR volunteer_area LIKE 'client' OR volunteer_area LIKE 'client home visit' THEN 'client care'
    WHEN volunteer_area LIKE '%business%' OR volunteer_area LIKE '%meeting%' THEN 'business needs'
    WHEN volunteer_area LIKE '%volunteer%' OR volunteer_area LIKE '%coordinat%' THEN 'volunteer coordination'
    WHEN volunteer_area LIKE '%epair%' OR volunteer_area LIKE '%furniture%' OR volunteer_area LIKE '%flip%' 
         OR volunteer_area LIKE '%repir%' OR volunteer_area LIKE '%built%' OR volunteer_area LIKE '%tv%' THEN 'repair'
    WHEN volunteer_area LIKE '%transport%' OR volunteer_area LIKE '%deliver%' OR volunteer_area LIKE 'donation p%'
         OR volunteer_area LIKE '%dump%' OR volunteer_area LIKE '%pickup%' THEN 'transportation'
    WHEN volunteer_area LIKE 'it%' OR volunteer_area LIKE '%data%' THEN 'it'
    WHEN volunteer_area LIKE 'financial%' OR volunteer_area LIKE '%donor management%' THEN 'financial'
    ELSE 'other'
  END;

-- =====================================
-- 5. DATA ANONYMIZATION FOR PORTFOLIO
-- =====================================

-- Create backup of original data for reference
--CREATE TABLE raw_data1_backup AS SELECT * FROM raw_data1; --already exists

--drop mapping temp table to recreate

DROP TABLE IF EXISTS first_name_mapping;

-- Create mapping table for consistent anonymization
CREATE TEMP TABLE first_name_mapping AS
WITH fake_names AS (
    SELECT fake_name, ROW_NUMBER() OVER () as rn
    FROM (SELECT unnest(ARRAY[
        'alex','sarah','david','emma','james','lisa','ryan','amy','tom','jane',
        'mike','anna','chris','beth','mark','kate','steve','mary','john','sam',
        'brian','kelly','jason','lauren','kevin','amanda','daniel','nicole','andrew','jessica',
        'joshua','ashley','tyler','brittany','justin','megan','nathan','stephanie','brandon','jennifer',
        'adam','elizabeth','jacob','rachel','scott','hannah','benjamin','samantha','william','madison'
    ]) as fake_name) sub
),
  original_names AS (
     SELECT first_name as original_name, ROW_NUMBER() OVER (ORDER BY first_name) as rn
      FROM (SELECT DISTINCT first_name FROM raw_data1 WHERE first_name IS NOT NULL) t
) 
SELECT 
    o.original_name,
    CASE 
        WHEN o.original_name = 'volunteer group' THEN 'volunteer group'
        ELSE COALESCE(f.fake_name, 'volunteer_' || o.rn)
    END as fake_name
FROM original_names o
LEFT JOIN fake_names f ON o.rn = f.rn;

-- Apply anonymization mapping
UPDATE raw_data1 
SET first_name = fnm.fake_name
FROM first_name_mapping fnm
WHERE raw_data1.first_name = fnm.original_name;

-- Apply 3-letter anonymization to last names
UPDATE raw_data1 
SET last_name = 
    CASE 
        WHEN last_name = 'volunteer group' THEN 'volunteer group'
        ELSE LEFT(last_name, 3)
    END;

-- =====================================
-- 6. DATABASE NORMALIZATION
-- =====================================

-- Create normalized database structure
CREATE TABLE volunteers (
    volunteer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL
);

CREATE TABLE volunteer_areas (
    area_id SERIAL PRIMARY KEY,
    area_name VARCHAR(255) NOT NULL
);

CREATE TABLE volunteer_sessions (
    session_id SERIAL PRIMARY KEY,
    volunteer_id INTEGER REFERENCES volunteers(volunteer_id),
    area_id INTEGER REFERENCES volunteer_areas(area_id),
    date_volunteered DATE,
    volunteer_time DECIMAL(5,2),
    total_miles_personal_car DECIMAL(6,2),
    comments TEXT,
    timestamp TIMESTAMP
);

-- Populate normalized tables
INSERT INTO volunteers (first_name, last_name)
SELECT DISTINCT first_name, last_name 
FROM raw_data1 
WHERE first_name IS NOT NULL AND last_name IS NOT NULL
ORDER BY first_name, last_name;

INSERT INTO volunteer_areas (area_name)
SELECT DISTINCT volunteer_area 
FROM raw_data1 
WHERE volunteer_area IS NOT NULL
ORDER BY volunteer_area;

-- Create date parsing function for accurate date handling
CREATE OR REPLACE FUNCTION parse_date(date_str TEXT) 
RETURNS DATE AS $$
BEGIN
    IF date_str ~ '^\d{1,2}/\d{1,2}/\d{4}$' THEN
        RETURN TO_DATE(date_str, 'MM/DD/YYYY');
    END IF;
    RETURN NULL;
EXCEPTION 
    WHEN OTHERS THEN RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Populate volunteer sessions with proper data type conversions
INSERT INTO volunteer_sessions (volunteer_id, area_id, date_volunteered, volunteer_time, total_miles_personal_car, comments, timestamp)
SELECT 
    v.volunteer_id,
    va.area_id,
    parse_date(r.date_volunteered),
    CASE 
        WHEN r.volunteer_time ~ '^\d*\.?\d+$' AND r.volunteer_time::NUMERIC > 0
        THEN r.volunteer_time::DECIMAL(5,2)
        ELSE NULL 
    END,
    CASE 
        WHEN r.total_miles_personal_car ~ '^\d*\.?\d+$' 
        THEN r.total_miles_personal_car::DECIMAL(6,2)
        ELSE NULL 
    END,
    r.comments,
    NOW()
FROM raw_data1 r
JOIN volunteers v ON (r.first_name = v.first_name AND r.last_name = v.last_name)
JOIN volunteer_areas va ON (r.volunteer_area = va.area_name)
WHERE r.first_name IS NOT NULL AND r.last_name IS NOT NULL AND r.volunteer_area IS NOT NULL
  AND r.date_volunteered IS NOT NULL;

-- Remove entries with unrealistic years (data quality issue from date parsing)
DELETE FROM volunteer_sessions 
WHERE EXTRACT(YEAR FROM date_volunteered) NOT BETWEEN 2022 AND 2025;

-- =====================================
-- 7. CREATE REPORTING VIEWS
-- =====================================

-- Monthly summary view for dashboard reporting
CREATE VIEW monthly_volunteer_summary AS
SELECT 
    DATE_TRUNC('month', date_volunteered) as month,
    COUNT(DISTINCT volunteer_id) as total_volunteers,
    SUM(volunteer_time) as total_hours,
    SUM(total_miles_personal_car) as total_miles,
    COUNT(*) as total_sessions
FROM volunteer_sessions 
WHERE date_volunteered IS NOT NULL
GROUP BY DATE_TRUNC('month', date_volunteered);

-- Volunteer area summary view for performance analysis
CREATE VIEW volunteer_area_summary AS
SELECT 
    va.area_name,
    COUNT(DISTINCT vs.volunteer_id) as total_volunteers,
    SUM(vs.volunteer_time) as total_hours,
    COUNT(*) as total_sessions,
    AVG(vs.volunteer_time) as avg_hours_per_session
FROM volunteer_sessions vs
JOIN volunteer_areas va ON vs.area_id = va.area_id
WHERE vs.date_volunteered IS NOT NULL
GROUP BY va.area_name;

-- Dashboard detail view for visualization tools
CREATE VIEW dashboard_monthly_detail AS
SELECT 
    vs.date_volunteered,
    EXTRACT(YEAR FROM vs.date_volunteered) as year,
    EXTRACT(MONTH FROM vs.date_volunteered) as month,
    va.area_name,
    vs.volunteer_time as hours,
    vs.total_miles_personal_car as miles,
    v.first_name,
    v.last_name
FROM volunteer_sessions vs
JOIN volunteers v ON vs.volunteer_id = v.volunteer_id
JOIN volunteer_areas va ON vs.area_id = va.area_id
WHERE vs.date_volunteered IS NOT NULL;

-- =====================================
-- 8. FINAL DATA EXPORT FOR DASHBOARD
-- =====================================

-- Export cleaned dataset for Google Sheets pivot table dashboard
SELECT 
    EXTRACT(YEAR FROM vs.date_volunteered) as year,
    EXTRACT(MONTH FROM vs.date_volunteered) as month,
    TO_CHAR(vs.date_volunteered, 'Month') as month_name,
    TO_CHAR(vs.date_volunteered, 'YYYY-MM') as year_month,
    va.area_name,
    v.first_name || ' ' || v.last_name as volunteer_name,
    vs.volunteer_time as hours,
    COALESCE(vs.total_miles_personal_car, 0) as miles
FROM volunteer_sessions vs
JOIN volunteers v ON vs.volunteer_id = v.volunteer_id
JOIN volunteer_areas va ON vs.area_id = va.area_id
WHERE vs.date_volunteered IS NOT NULL
  AND EXTRACT(YEAR FROM vs.date_volunteered) BETWEEN 2022 AND 2025
ORDER BY vs.date_volunteered, va.area_name;

-- =====================================
-- 9. DATA VALIDATION QUERIES
-- =====================================

-- Verify final data quality
SELECT 'volunteers' as table_name, COUNT(*) as count FROM volunteers
UNION ALL
SELECT 'volunteer_areas', COUNT(*) FROM volunteer_areas  
UNION ALL
SELECT 'volunteer_sessions', COUNT(*) FROM volunteer_sessions;

-- Check date range validity
SELECT 
    MIN(date_volunteered) as earliest_date,
    MAX(date_volunteered) as latest_date,
    COUNT(*) as total_sessions
FROM volunteer_sessions;

--check parsing
SELECT EXTRACT(YEAR FROM parse_date(date_volunteered)) as year, COUNT(*) 
FROM raw_data1 
WHERE date_volunteered IS NOT NULL
GROUP BY EXTRACT(YEAR FROM parse_date(date_volunteered))
ORDER BY year;

-- Check if raw_data1 has data after the import
SELECT COUNT(*) FROM raw_data1;
SELECT * FROM raw_data1 LIMIT 5;