-- ============================================================================
-- Storage Lifecycle Policy Example
-- ============================================================================
-- This script demonstrates:
-- 1. Creating a transaction table with common identifiers
-- 2. Creating a storage lifecycle policy to archive data older than 2 quarters
-- 3. Archiving to COOL storage for 3 years before expiration
-- ============================================================================

-- Step 1: Create the transaction table
USE ROLE R_DBA;
USE SCHEMA SANDBOX_DB.PUBLIC;
CREATE OR REPLACE TABLE transactions (
    transaction_id NUMBER AUTOINCREMENT PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    account_id NUMBER,
    transaction_quarter VARCHAR(7),  -- Format: YYYY-Q# (e.g., '2024-Q3')
    transaction_date DATE NOT NULL,
    transaction_description VARCHAR(500),
    transaction_amount DECIMAL(18,2) NOT NULL,
    transaction_type VARCHAR(50),    -- e.g., 'DEBIT', 'CREDIT', 'TRANSFER'
    currency_code VARCHAR(3) DEFAULT 'USD',
    created_timestamp TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    modified_timestamp TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

-- calculate the starting date of the current quarter from the current date
select date_trunc(quarter, current_date()) as current_quarter_start_date;
select date_trunc(quarter, DATEADD(QUARTER, -1, CURRENT_DATE())) as last_quarter_start_date;


-- Step 2: Create the storage lifecycle policy
-- Archives data older than 2 quarters (6 months) to COOL storage
-- Data remains in COOL storage for 3 years (1095 days) before expiration
CREATE OR REPLACE STORAGE LIFECYCLE POLICY transaction_retention_policy
  AS (transaction_date DATE)
  RETURNS BOOLEAN ->
    transaction_date < date_trunc(quarter, DATEADD(QUARTER, -1, CURRENT_DATE())) -- last_quarter_start_date
  ARCHIVE_TIER = COOL
  ARCHIVE_FOR_DAYS = 1095  -- 3 years
  COMMENT = 'Archives transactions older than 2 quarters to COOL storage for 3 years';

-- Step 3: Attach the policy to the transactions table
ALTER TABLE transactions 
  SET STORAGE_LIFECYCLE_POLICY = transaction_retention_policy;


-- Notes:
-- 1. The policy waits ~24 hours after attachment before first execution
-- 2. Policy runs automatically daily using shared compute resources
-- 3. Data older than 2 quarters will be moved to COOL storage
-- 4. After 3 years in COOL storage, data will be permanently deleted
-- 5. Archived data can be retrieved using: CREATE TABLE ... FROM ARCHIVE OF
-- 6. COOL storage requires minimum 90-day archival period (we use 1095 days)
-- 7. As of Nov 2025, archival policies are currently only available on AWS accounts 


-- ============================================================================
-- Verification Queries
-- ============================================================================

-- View the policy details
DESC STORAGE LIFECYCLE POLICY transaction_retention_policy;

-- View table properties including the attached policy
SHOW PARAMETERS LIKE 'STORAGE_LIFECYCLE_POLICY' IN TABLE transactions;


-- ============================================================================
-- Retrieving Archived Data
-- ============================================================================

-- Step 1: Use EXPLAIN to estimate retrieval costs before retrieving data
-- This helps you understand how many files/partitions will be retrieved from archive storage
-- Look for:
--   - 'createTableFromArchiveData' operation in the output
--   - 'ARCHIVE OF <table>' in the objects column
--   - 'assignedPartitions' value <<< THIS INDICATES the number of files/partitions to restore!
-- For billing details per file/partition, see "Archive Storage Retrieval File Processing" in table 5 of Consumption Table:
--  https://www.snowflake.com/legal-files/CreditConsumptionTable.pdf
EXPLAIN
CREATE TABLE transactions_q1_2023_restored
  FROM ARCHIVE OF transactions AS t
  WHERE t.transaction_date BETWEEN '2023-01-01' AND '2023-03-31';

-- Step 2: After reviewing EXPLAIN output, execute the actual data retrieval
-- Creates a new table with archived data from Q1 2023
-- Note: WHERE clause is REQUIRED when retrieving archived data
-- Note: This operation can be expensive - filter carefully to minimize costs
CREATE TABLE transactions_q1_2023_restored
  FROM ARCHIVE OF transactions AS t
  WHERE t.transaction_date BETWEEN '2023-01-01' AND '2023-03-31';


-- Important notes about COLD tier retrieval:
-- - Restoration from COLD tier can take up to 48 hours
-- - Set STATEMENT_TIMEOUT_IN_SECONDS to at least 172800 (48 hours)
-- - Set ABORT_DETACHED_QUERY = FALSE
-- - Maximum 1 million files per restore operation from COLD tier

-- Be sure to run these before executing the retrieval query from the COLD tier!
ALTER SESSION SET STATEMENT_TIMEOUT_IN_SECONDS = 172800;
ALTER SESSION SET ABORT_DETACHED_QUERY = FALSE;


-- ============================================================================
-- Monitoring Queries
-- ============================================================================

-- Check policy execution history (after policy has run)
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.STORAGE_LIFECYCLE_POLICY_EXECUTIONS
WHERE POLICY_NAME = 'TRANSACTION_RETENTION_POLICY'
ORDER BY EXECUTION_START_TIME DESC;

-- View all storage lifecycle policies in the current database
SHOW STORAGE LIFECYCLE POLICIES;

-- Monitor retrieval operations from archive storage
-- Use this view to track retrieval history and costs
SELECT 
    QUERY_ID,
    START_TIME,
    END_TIME,
    SOURCE_TABLE_NAME,
    BYTES_RETRIEVED,
    FILES_RETRIEVED,
    CREDITS_USED
FROM SNOWFLAKE.ACCOUNT_USAGE.ARCHIVE_STORAGE_DATA_RETRIEVAL_USAGE_HISTORY
WHERE SOURCE_TABLE_NAME = 'TRANSACTIONS'
ORDER BY START_TIME DESC;


-- ====================================================================================================
-- Cleanup Queries
-- ====================================================================================================
DROP TABLE IF EXISTS transactions_q1_2023_restored;
DROP TABLE  IF EXISTS transactions;
DROP STORAGE LIFECYCLE POLICY transaction_retention_policy;
