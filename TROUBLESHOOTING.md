# Troubleshooting Guide

This guide helps you diagnose and resolve common issues encountered during deployment and operation of the Superstore Data Warehouse.

## Table of Contents

- [Deployment Issues](#deployment-issues)
- [External Table Issues](#external-table-issues)
- [ETL Failures](#etl-failures)
- [Data Quality Issues](#data-quality-issues)
- [Performance Problems](#performance-problems)
- [Connection Issues](#connection-issues)

---

## Deployment Issues

### Error: ORA-01031: insufficient privileges

**Symptom**: Deployment fails with privilege error

**Cause**: User lacks required database privileges

**Solution**:
```sql
-- Connect as DBA and grant required privileges
GRANT CREATE TABLE TO <username>;
GRANT CREATE SEQUENCE TO <username>;
GRANT CREATE PROCEDURE TO <username>;
GRANT CREATE VIEW TO <username>;
GRANT CREATE DIRECTORY TO <username>;
GRANT UNLIMITED TABLESPACE TO <username>;
```

**Verification**:
```sql
SELECT privilege FROM user_sys_privs;
```

---

### Error: ORA-00955: name is already used by an existing object

**Symptom**: Cannot create table because it already exists

**Cause**: Previous deployment left objects in place

**Solution 1** (Recommended): Run cleanup script
```sql
@PLSQL/00_cleanup.sql
```

**Solution 2**: Drop specific object
```sql
DROP TABLE <table_name> PURGE;
```

**Prevention**: Always run cleanup before fresh deployment

---

### Error: Directory path does not exist

**Symptom**: Cannot create Oracle directory

**Cause**: File system path in configuration doesn't exist

**Solution**:
1. Create the directory on the file system:
   ```bash
   # Windows
   mkdir "C:\Data\Warehouse\Source"
   
   # Linux
   mkdir -p /data/warehouse/source
   ```

2. Verify Oracle user has OS permissions:
   ```bash
   # Windows - Grant permissions to Oracle user
   icacls "C:\Data\Warehouse\Source" /grant OracleUser:F
   
   # Linux
   chmod 755 /data/warehouse/source
   chown oracle:oinstall /data/warehouse/source
   ```

3. Update configuration file with correct path

---

## External Table Issues

### Error: ORA-29913: error in executing ODCIEXTTABLEOPEN callout

**Symptom**: Cannot read from external table

**Cause**: Multiple possible causes

**Solution 1**: Verify file exists
```bash
# Check if superstore.csv exists in the directory
dir "C:\Data\Warehouse\Source\superstore.csv"  # Windows
ls -l /data/warehouse/source/superstore.csv    # Linux
```

**Solution 2**: Check directory permissions
```sql
-- Verify directory is created
SELECT directory_name, directory_path FROM all_directories WHERE directory_name = 'SOURCE_DIR';

-- Test read access
SELECT COUNT(*) FROM staging_superstore WHERE ROWNUM <= 10;
```

**Solution 3**: Verify file format
- Ensure CSV is UTF-8 encoded
- Check for special characters in file path
- Verify line endings (Windows: CRLF, Linux: LF)

---

### Error: ORA-29400: data cartridge error - KUP-04040: file not found

**Symptom**: External table cannot find CSV file

**Cause**: File name mismatch or wrong directory

**Solution**:
1. Verify exact file name (case-sensitive on Linux):
   ```sql
   -- Check external table definition
   SELECT * FROM user_external_locations WHERE table_name = 'STAGING_SUPERSTORE';
   ```

2. Ensure file name matches exactly (including extension)

3. Check directory path:
   ```sql
   SELECT directory_path FROM all_directories WHERE directory_name = 'SOURCE_DIR';
   ```

---

### Error: Rejected rows in external table

**Symptom**: Some rows are rejected during load

**Cause**: Data format issues in CSV

**Solution**:
1. Check bad file for details:
   ```bash
   # Location: Dataset directory
   # File name: STAGING_SUPERSTORE_*.bad
   type STAGING_SUPERSTORE_*.bad  # Windows
   cat STAGING_SUPERSTORE_*.bad   # Linux
   ```

2. Check log file:
   ```bash
   type STAGING_SUPERSTORE_*.log  # Windows
   cat STAGING_SUPERSTORE_*.log   # Linux
   ```

3. Common issues:
   - Extra commas in data
   - Unescaped quotes
   - Wrong number of columns
   - Special characters

4. Fix source data and reload

---

## ETL Failures

### Error: ETL process hangs or runs very slowly

**Symptom**: ETL takes much longer than expected

**Cause**: Performance issues or locking

**Solution 1**: Check for locks
```sql
SELECT 
    s.sid,
    s.serial#,
    s.username,
    s.program,
    o.object_name,
    l.locked_mode
FROM v$locked_object l
JOIN dba_objects o ON l.object_id = o.object_id
JOIN v$session s ON l.session_id = s.sid
WHERE o.object_name IN ('DIM_CUSTOMER', 'DIM_PRODUCT', 'DIM_REGION', 'DIM_TIME', 'FACT_SALES');
```

**Solution 2**: Check system resources
```sql
-- Check temp space
SELECT tablespace_name, used_space, tablespace_size 
FROM dba_temp_free_space;

-- Check active sessions
SELECT COUNT(*) FROM v$session WHERE status = 'ACTIVE';
```

**Solution 3**: Optimize batch size
- Reduce `BATCH_SIZE` in configuration if memory constrained
- Increase if you have resources available

---

### Error: Duplicate key violation during ETL

**Symptom**: ORA-00001: unique constraint violated

**Cause**: Duplicate records in source data or re-running ETL without cleanup

**Solution 1**: Check for duplicates in source
```sql
@PLSQL/check_duplicates.sql
```

**Solution 2**: Truncate dimension tables before reload
```sql
TRUNCATE TABLE dim_customer;
TRUNCATE TABLE dim_product;
TRUNCATE TABLE dim_region;
TRUNCATE TABLE fact_sales;
```

**Solution 3**: Use MERGE instead of INSERT (modify ETL scripts)

---

### Error: Foreign key violation in fact table

**Symptom**: ORA-02291: integrity constraint violated - parent key not found

**Cause**: Dimension tables not fully loaded before fact table ETL

**Solution**:
1. Verify all dimensions are populated:
   ```sql
   SELECT 'DIM_CUSTOMER' as table_name, COUNT(*) FROM dim_customer
   UNION ALL
   SELECT 'DIM_PRODUCT', COUNT(*) FROM dim_product
   UNION ALL
   SELECT 'DIM_REGION', COUNT(*) FROM dim_region
   UNION ALL
   SELECT 'DIM_TIME', COUNT(*) FROM dim_time;
   ```

2. Re-run dimension ETL if needed:
   ```sql
   @PLSQL/04_etl_dim_time.sql
   @PLSQL/05_etl_dimensions.sql
   ```

3. Then re-run fact table ETL:
   ```sql
   TRUNCATE TABLE fact_sales;
   @PLSQL/06_etl_fact_sales.sql
   ```

---

## Data Quality Issues

### Issue: Orphaned records detected

**Symptom**: Data quality checks report orphaned records in fact table

**Cause**: Missing dimension records or data inconsistency

**Solution**:
1. Identify orphaned records:
   ```sql
   -- Find fact records without customer
   SELECT DISTINCT f.customer_key
   FROM fact_sales f
   WHERE NOT EXISTS (SELECT 1 FROM dim_customer c WHERE c.customer_key = f.customer_key);
   ```

2. Check source data for these keys

3. Options:
   - Add missing dimension records
   - Remove orphaned fact records
   - Use default/unknown dimension record

---

### Issue: NULL values in measures

**Symptom**: Data quality checks report NULL sales or profit

**Cause**: Source data contains NULL values

**Solution**:
1. Identify NULL records:
   ```sql
   SELECT * FROM fact_sales WHERE sales IS NULL OR profit IS NULL;
   ```

2. Check corresponding source records:
   ```sql
   SELECT * FROM staging_superstore WHERE sales IS NULL OR profit IS NULL;
   ```

3. Options:
   - Fix source data
   - Use default values (e.g., 0)
   - Exclude these records

---

### Issue: Negative profit values

**Symptom**: Unexpected negative profit

**Cause**: This may be valid (returns, discounts) or data error

**Solution**:
1. Investigate negative profit records:
   ```sql
   SELECT 
       f.*,
       p.product_name,
       c.customer_name
   FROM fact_sales f
   JOIN dim_product p ON f.product_key = p.product_key
   JOIN dim_customer c ON f.customer_key = c.customer_key
   WHERE f.profit < 0
   ORDER BY f.profit;
   ```

2. Verify business logic:
   - Check if discount > sales
   - Verify shipping cost calculations
   - Confirm these are legitimate returns

---

## Performance Problems

### Issue: Queries are slow

**Symptom**: Analytical queries take too long

**Solution 1**: Verify statistics are current
```sql
SELECT table_name, last_analyzed
FROM user_tables
WHERE table_name IN ('DIM_CUSTOMER', 'DIM_PRODUCT', 'DIM_REGION', 'DIM_TIME', 'FACT_SALES');

-- If outdated, regather
@PLSQL/09_gather_statistics.sql
```

**Solution 2**: Check indexes exist
```sql
SELECT table_name, index_name, column_name
FROM user_ind_columns
WHERE table_name IN ('DIM_CUSTOMER', 'DIM_PRODUCT', 'DIM_REGION', 'DIM_TIME', 'FACT_SALES')
ORDER BY table_name, index_name;
```

**Solution 3**: Analyze slow query
```sql
-- Enable autotrace
SET AUTOTRACE ON EXPLAIN

-- Run your slow query
SELECT ...

-- Review execution plan
```

**Solution 4**: Consider partitioning (for large datasets)

---

### Issue: ETL runs out of memory

**Symptom**: ORA-04030: out of process memory

**Cause**: Batch size too large or insufficient memory

**Solution**:
1. Reduce batch size in configuration:
   ```sql
   DEFINE BATCH_SIZE = 5000  -- Reduce from 10000
   ```

2. Increase PGA memory:
   ```sql
   ALTER SYSTEM SET pga_aggregate_target = 2G SCOPE=BOTH;
   ```

3. Process data in smaller chunks

---

## Connection Issues

### Error: ORA-12154: TNS:could not resolve the connect identifier

**Symptom**: Cannot connect to database

**Cause**: TNS configuration issue

**Solution**:
1. Verify tnsnames.ora configuration
2. Test connection:
   ```bash
   tnsping <database_name>
   ```
3. Use full connection string:
   ```bash
   sqlplus user/pass@hostname:1521/servicename
   ```

---

### Error: ORA-01017: invalid username/password

**Symptom**: Authentication failure

**Cause**: Wrong credentials or account locked

**Solution**:
1. Verify username:
   ```sql
   -- Connect as DBA
   SELECT username, account_status FROM dba_users WHERE username = 'YOUR_USER';
   ```

2. Unlock account if needed:
   ```sql
   ALTER USER <username> ACCOUNT UNLOCK;
   ```

3. Reset password:
   ```sql
   ALTER USER <username> IDENTIFIED BY <new_password>;
   ```

---

## Logging and Diagnostics

### View Recent ETL Logs

```sql
SELECT * FROM v_etl_log_recent ORDER BY start_time DESC;
```

### View Failed Processes

```sql
SELECT 
    process_name,
    start_time,
    error_message,
    error_code
FROM etl_log
WHERE status = 'ERROR'
ORDER BY start_time DESC;
```

### View ETL Summary

```sql
SELECT * FROM v_etl_summary;
```

### Enable SQL Trace

```sql
ALTER SESSION SET SQL_TRACE = TRUE;
-- Run your problematic query
ALTER SESSION SET SQL_TRACE = FALSE;

-- Find trace file in diagnostic directory
```

---

## Getting Additional Help

### Oracle Error Messages

Look up Oracle error codes:
```bash
oerr ora <error_number>
# Example: oerr ora 1031
```

### Check Alert Log

```sql
SELECT value FROM v$diag_info WHERE name = 'Diag Trace';
```

### Useful Diagnostic Queries

```sql
-- Check tablespace usage
SELECT 
    tablespace_name,
    ROUND(used_space * 8192 / 1024 / 1024, 2) as used_mb,
    ROUND(tablespace_size * 8192 / 1024 / 1024, 2) as total_mb
FROM dba_tablespace_usage_metrics;

-- Check invalid objects
SELECT object_name, object_type, status
FROM user_objects
WHERE status = 'INVALID';

-- Recompile invalid objects
BEGIN
    DBMS_UTILITY.compile_schema(schema => USER);
END;
/
```

---

## Prevention Best Practices

1. **Always backup before major changes**
   ```sql
   EXEC backup_all_tables;
   ```

2. **Test in development first**
   - Never test directly in production
   - Validate in UAT before production deployment

3. **Monitor logs regularly**
   ```sql
   SELECT * FROM v_etl_log_recent;
   ```

4. **Keep statistics current**
   - Run after significant data changes
   - Schedule regular statistics gathering

5. **Document customizations**
   - Note any changes to scripts
   - Update configuration documentation

---

**Document Version**: 1.0.0  
**Last Updated**: November 2025  
**Feedback**: Please report issues not covered in this guide
