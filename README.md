# Snowflake Storage Lifecycle Policy Demo

A practical example of archiving data to COOL storage using Snowflake's Storage Lifecycle Policies.

## What It Does

Automatically archives transaction data older than 2 quarters to COOL storage, retains for 3 years, then expires.

## Key Features

- ✅ Transaction table with common identifiers
- ✅ Automated archival policy (runs daily)
- ✅ Cost-effective COOL tier storage
- ✅ Archive retrieval with cost estimation
- ✅ Monitoring queries included

## Quick Start

```sql
-- 1. Create table and policy
SOURCE lifecycle-policy-script.sql

-- 2. Retrieve archived data (with cost preview)
EXPLAIN CREATE TABLE restored FROM ARCHIVE OF transactions 
  WHERE transaction_date BETWEEN '2023-01-01' AND '2023-03-31';
```

## Important Notes

- **AWS only** (as of Nov 2025)
- Policy activates ~24 hours after attachment
- COOL tier requires 90-day minimum retention
- Retrieval costs vary by partition count

## Reference

Full documentation in [`lifecycle-policy-script.sql`](./lifecycle-policy-script.sql)

