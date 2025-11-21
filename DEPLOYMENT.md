# Deployment Guide

This guide provides step-by-step instructions for deploying the Superstore Data Warehouse to any environment (Development, UAT, or Production).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Deployment Steps](#deployment-steps)
- [Post-Deployment Validation](#post-deployment-validation)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

- **Oracle Database**: 19c or higher
- **Disk Space**: Minimum 2GB free space
- **Memory**: Minimum 4GB RAM recommended
- **CPU**: Multi-core processor recommended for parallel operations

### Database Privileges

The deployment user must have the following privileges:

```sql
GRANT CREATE TABLE TO <username>;
GRANT CREATE SEQUENCE TO <username>;
GRANT CREATE PROCEDURE TO <username>;
GRANT CREATE VIEW TO <username>;
GRANT CREATE DIRECTORY TO <username>;
GRANT UNLIMITED TABLESPACE TO <username>;
```

### File System Access

- Read access to source data directory
- Write access to log directory
- Oracle user must have OS-level permissions to these directories

### Required Files

- `superstore.csv` - Source data file
- All SQL scripts in the repository
- Configuration file for your environment

---

## Pre-Deployment Checklist

### 1. Environment Preparation

- [ ] Oracle Database is running and accessible
- [ ] Database user created with required privileges
- [ ] Source data directory created
- [ ] Log directory created
- [ ] `superstore.csv` file copied to source data directory

### 2. Configuration

- [ ] Copy `config/database_config.sql` to environment-specific version
- [ ] Update `SOURCE_DATA_DIR` path
- [ ] Update `LOG_DIR` path
- [ ] Verify `DW_SCHEMA` and `STAGING_SCHEMA` names
- [ ] Adjust performance parameters if needed

### 3. Backup (if upgrading existing installation)

- [ ] Backup existing data warehouse tables
- [ ] Export current data (optional)
- [ ] Document current row counts

### 4. Verification

- [ ] Test database connectivity
- [ ] Verify file paths are accessible
- [ ] Check disk space availability
- [ ] Review deployment plan with stakeholders

---

## Deployment Steps

### Option 1: Automated Deployment (Recommended)

The master deployment script automates the entire process.

#### Step 1: Connect to Database

```bash
sqlplus username/password@database
```

#### Step 2: Run Master Deployment Script

```sql
@deploy/master_deploy.sql
```

The script will:
1. Load configuration
2. Run pre-deployment checks
3. Create logging framework
4. Optionally cleanup existing objects
5. Create staging layer
6. Create dimension and fact tables
7. Run ETL processes
8. Gather statistics
9. Perform data quality checks
10. Generate deployment report

#### Step 3: Review Output

The script will display:
- Status of each phase
- Row counts for all tables
- Any errors or warnings
- Deployment summary

**Expected Duration**: 5-15 minutes depending on data volume and system performance

---

### Option 2: Manual Deployment

For more control, execute scripts individually in this order:

#### Phase 1: Configuration

```sql
@config/database_config.sql
```

#### Phase 2: Logging Framework

```sql
@PLSQL/00_logging_framework.sql
```

#### Phase 3: Cleanup (Optional)

```sql
@PLSQL/00_cleanup.sql
```

**Warning**: This drops all existing data warehouse objects!

#### Phase 4: Staging Layer

```sql
@PLSQL/01_staging.sql
```

Verify staging table:
```sql
SELECT COUNT(*) FROM staging_superstore;
```

Expected: ~51,000 rows

#### Phase 5: Dimension Tables

```sql
@PLSQL/02_dimensions.sql
```

#### Phase 6: Fact Table

```sql
@PLSQL/03_fact_table.sql
```

#### Phase 7: Rollback Procedures

```sql
@PLSQL/08_rollback_procedures.sql
```

#### Phase 8: ETL - Time Dimension

```sql
@PLSQL/04_etl_dim_time.sql
```

Verify:
```sql
SELECT COUNT(*) FROM dim_time;
```

Expected: ~1,500 rows (covering date range in data)

#### Phase 9: ETL - Other Dimensions

```sql
@PLSQL/05_etl_dimensions.sql
```

Verify:
```sql
SELECT 'DIM_CUSTOMER' as table_name, COUNT(*) FROM dim_customer
UNION ALL
SELECT 'DIM_PRODUCT', COUNT(*) FROM dim_product
UNION ALL
SELECT 'DIM_REGION', COUNT(*) FROM dim_region;
```

Expected:
- DIM_CUSTOMER: ~800 rows
- DIM_PRODUCT: ~1,800 rows
- DIM_REGION: ~500 rows

#### Phase 10: ETL - Fact Table

```sql
@PLSQL/06_etl_fact_sales.sql
```

Verify:
```sql
SELECT COUNT(*) FROM fact_sales;
```

Expected: ~51,000 rows

#### Phase 11: Statistics

```sql
@PLSQL/09_gather_statistics.sql
```

#### Phase 12: Data Quality Checks

```sql
@PLSQL/07_data_quality_checks.sql
```

All checks should pass with 0 errors.

---

## Post-Deployment Validation

### 1. Verify Table Creation

```sql
SELECT table_name, num_rows
FROM user_tables
WHERE table_name IN ('DIM_CUSTOMER', 'DIM_PRODUCT', 'DIM_REGION', 'DIM_TIME', 'FACT_SALES')
ORDER BY table_name;
```

All tables should exist with expected row counts.

### 2. Verify Data Quality

```sql
@PLSQL/07_data_quality_checks.sql
```

Should report 0 errors and 0 warnings.

### 3. Test Sample Queries

```sql
-- Total sales by category
SELECT 
    p.category,
    SUM(f.sales) as total_sales,
    SUM(f.profit) as total_profit
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_sales DESC;
```

Expected: 3 categories (Technology, Furniture, Office Supplies)

### 4. Verify Logging

```sql
SELECT * FROM v_etl_log_recent;
```

Should show all ETL processes with 'SUCCESS' status.

### 5. Check Statistics

```sql
SELECT table_name, last_analyzed
FROM user_tables
WHERE table_name IN ('DIM_CUSTOMER', 'DIM_PRODUCT', 'DIM_REGION', 'DIM_TIME', 'FACT_SALES');
```

All tables should have recent `last_analyzed` timestamps.

---

## Rollback Procedures

### Scenario 1: Deployment Failed Mid-Process

If deployment fails partway through:

1. **Review error logs**:
   ```sql
   SELECT * FROM etl_log WHERE status = 'ERROR' ORDER BY start_time DESC;
   ```

2. **Cleanup partial deployment**:
   ```sql
   @PLSQL/00_cleanup.sql
   ```

3. **Fix the issue** (check TROUBLESHOOTING.md)

4. **Re-run deployment**

### Scenario 2: Need to Restore Previous Version

If you backed up before deployment:

1. **Restore all tables**:
   ```sql
   EXEC restore_table('DIM_CUSTOMER', 'YYYYMMDD_HH24MISS');
   EXEC restore_table('DIM_PRODUCT', 'YYYYMMDD_HH24MISS');
   EXEC restore_table('DIM_REGION', 'YYYYMMDD_HH24MISS');
   EXEC restore_table('DIM_TIME', 'YYYYMMDD_HH24MISS');
   EXEC restore_table('FACT_SALES', 'YYYYMMDD_HH24MISS');
   ```

2. **Verify restoration**:
   ```sql
   SELECT table_name, COUNT(*) FROM dim_customer GROUP BY table_name
   UNION ALL
   SELECT table_name, COUNT(*) FROM fact_sales GROUP BY table_name;
   ```

### Scenario 3: Data Quality Issues Detected

If data quality checks fail:

1. **Review specific failures**:
   ```sql
   @PLSQL/07_data_quality_checks.sql
   ```

2. **Investigate root cause** (check source data)

3. **Options**:
   - Fix source data and re-run ETL
   - Restore from backup
   - Apply data corrections manually

---

## Environment-Specific Considerations

### Development Environment

- Use smaller batch sizes for faster iteration
- Enable verbose logging
- Keep old backups for testing rollback procedures
- Error threshold can be higher (1000)

### UAT Environment

- Mirror production configuration
- Test complete deployment from scratch
- Validate all data quality checks pass
- Document deployment time for production planning

### Production Environment

- **Schedule deployment during maintenance window**
- **Backup existing data before deployment**
- Use optimal batch sizes (10,000)
- Set strict error threshold (10)
- Monitor system resources during deployment
- Have rollback plan ready
- Notify stakeholders before and after deployment

---

## Deployment Timing

### Estimated Durations

| Phase | Duration | Notes |
|-------|----------|-------|
| Pre-deployment checks | 2 min | Verification only |
| Logging framework | 1 min | One-time setup |
| Staging setup | 2 min | Depends on file size |
| Dimension/Fact DDL | 2 min | Table creation |
| Time dimension ETL | 1 min | ~1,500 rows |
| Other dimensions ETL | 3 min | ~3,000 rows total |
| Fact table ETL | 5 min | ~51,000 rows |
| Statistics gathering | 2 min | Parallel execution |
| Data quality checks | 2 min | Validation queries |
| **Total** | **~20 min** | May vary by system |

### Optimization Tips

- Increase `PARALLEL_DEGREE` for faster processing (if CPU available)
- Increase `BATCH_SIZE` for larger datasets
- Run during off-peak hours
- Ensure adequate temp tablespace

---

## Post-Deployment Tasks

### Immediate

- [ ] Verify all tables populated correctly
- [ ] Run data quality checks
- [ ] Test sample analytical queries
- [ ] Review ETL logs for warnings
- [ ] Document actual vs. expected row counts

### Within 24 Hours

- [ ] Set up backup schedule
- [ ] Configure monitoring alerts
- [ ] Grant appropriate user access
- [ ] Update documentation with any changes
- [ ] Communicate deployment success to stakeholders

### Within 1 Week

- [ ] Monitor query performance
- [ ] Review and optimize slow queries
- [ ] Set up regular ETL schedule (if incremental loads planned)
- [ ] Train users on new system
- [ ] Gather user feedback

---

## Support and Escalation

### Common Issues

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for solutions to common problems.

### Getting Help

1. Check deployment logs in `etl_log` table
2. Review error messages in console output
3. Consult TROUBLESHOOTING.md
4. Check Oracle documentation for specific errors

### Escalation Path

1. **Database Administrator**: For privilege or connectivity issues
2. **System Administrator**: For file system or OS-level issues
3. **Development Team**: For data quality or business logic issues

---

## Deployment Checklist Summary

**Before Deployment**:
- ✓ Prerequisites verified
- ✓ Configuration updated
- ✓ Backups created (if applicable)
- ✓ Stakeholders notified

**During Deployment**:
- ✓ Monitor progress
- ✓ Watch for errors
- ✓ Verify each phase completes

**After Deployment**:
- ✓ Validation tests passed
- ✓ Data quality checks passed
- ✓ Sample queries working
- ✓ Documentation updated
- ✓ Stakeholders notified

---

**Document Version**: 1.0.0  
**Last Updated**: November 2025  
**Next Review**: After first production deployment
