# Snowflake Storage Lifecycle Policy Demo

A practical example of archiving data to COOL storage using Snowflake's Storage Lifecycle Policies.

## What It Does

Automatically archives transaction data older than 2 quarters to COOL storage, retains for 3 years, then expires.

## Key Features

- ✅ Built on an example transaction table with common identifiers
- ✅ Automated archival policy (runs daily)
- ✅ Cost-effective COOL tier storage
- ✅ Archive retrieval with cost estimation
- ✅ Monitoring queries included

## Important Notes

- **AWS only** (as of Nov 2025)
- Policy activates ~24 hours after attachment
- COOL tier requires 90-day minimum retention
- Retrieval costs vary by number of files/partition retrieved

## Documentation
- https://docs.snowflake.com/en/user-guide/storage-management/storage-lifecycle-policies
- https://docs.snowflake.com/en/user-guide/storage-management/storage-lifecycle-policies-billing
- https://docs.snowflake.com/en/user-guide/storage-management/storage-lifecycle-policies-create-manage
- https://docs.snowflake.com/en/user-guide/storage-management/storage-lifecycle-policies-retrieving-archived-data
- https://docs.snowflake.com/en/user-guide/storage-management/storage-lifecycle-policies-monitoring
