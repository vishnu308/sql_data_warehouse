# Configuration Guide

This document explains all configuration parameters for the Superstore Data Warehouse and how to customize them for different environments.

## Overview

The data warehouse uses centralized configuration to support multiple environments (Development, UAT, Production) without code changes. All environment-specific settings are defined in `config/database_config.sql`.

## Configuration File Location

```
config/database_config.sql
```

## Configuration Parameters

### 1. Directory Paths

#### SOURCE_DATA_DIR
- **Purpose**: Location of source CSV files for external table
- **Type**: Operating system directory path
- **Required**: Yes
- **Example**: 
  ```sql
  DEFINE SOURCE_DATA_DIR = 'C:\Data\Warehouse\Source'
  ```

**Environment-Specific Values:**
- **Development**: `C:\Dev\Data\Warehouse\Source`
- **UAT**: `C:\UAT\Data\Warehouse\Source`
- **Production**: `D:\Production\DataWarehouse\Source`

**Important Notes:**
- Path must exist before running deployment
- Oracle user must have OS-level read permissions
- Use forward slashes (/) or escaped backslashes (\\) on Windows
- Ensure sufficient disk space for data files

#### LOG_DIR
- **Purpose**: Location for ETL logs and error files
- **Type**: Operating system directory path
- **Required**: Yes
- **Example**:
  ```sql
  DEFINE LOG_DIR = 'C:\Data\Warehouse\Logs'
  ```

**Important Notes:**
- Oracle user must have OS-level write permissions
- Logs can grow large; monitor disk usage
- Recommended to separate from data directory

---

### 2. Schema Configuration

#### DW_SCHEMA
- **Purpose**: Schema/user owning the data warehouse objects
- **Type**: Oracle schema name
- **Default**: Current user
- **Example**:
  ```sql
  DEFINE DW_SCHEMA = 'DW_PROD'
  ```

**Environment-Specific Values:**
- **Development**: `DW_DEV`
- **UAT**: `DW_UAT`
- **Production**: `DW_PROD`

#### STAGING_SCHEMA
- **Purpose**: Schema for staging tables and external tables
- **Type**: Oracle schema name
- **Default**: Same as DW_SCHEMA
- **Example**:
  ```sql
  DEFINE STAGING_SCHEMA = 'STAGING_PROD'
  ```

**Best Practice**: Use separate schema for staging in production to isolate raw data from curated data warehouse.

---

### 3. ETL Parameters

#### BATCH_SIZE
- **Purpose**: Number of rows processed per commit in ETL
- **Type**: Integer
- **Default**: 10000
- **Range**: 1000 - 50000
- **Example**:
  ```sql
  DEFINE BATCH_SIZE = 10000
  ```

**Tuning Guidelines:**
- **Smaller batches** (1000-5000): Better for rollback, more overhead
- **Larger batches** (20000-50000): Faster processing, more memory usage
- **Recommended**: Start with 10000, adjust based on performance testing

#### ERROR_THRESHOLD
- **Purpose**: Maximum number of errors before ETL aborts
- **Type**: Integer
- **Default**: 100
- **Example**:
  ```sql
  DEFINE ERROR_THRESHOLD = 100
  ```

**Environment-Specific Values:**
- **Development**: 1000 (more lenient for testing)
- **UAT**: 100 (balanced)
- **Production**: 10 (strict quality control)

#### ENABLE_LOGGING
- **Purpose**: Enable/disable detailed ETL logging
- **Type**: Boolean (TRUE/FALSE)
- **Default**: TRUE
- **Example**:
  ```sql
  DEFINE ENABLE_LOGGING = 'TRUE'
  ```

**Performance Impact**: Logging adds 5-10% overhead but is essential for troubleshooting.

---

### 4. Data Quality Settings

#### CHECK_DUPLICATES
- **Purpose**: Enable duplicate detection during ETL
- **Type**: Boolean (TRUE/FALSE)
- **Default**: TRUE
- **Example**:
  ```sql
  DEFINE CHECK_DUPLICATES = 'TRUE'
  ```

#### ALLOW_NULL_MEASURES
- **Purpose**: Allow NULL values in fact table measures
- **Type**: Boolean (TRUE/FALSE)
- **Default**: FALSE
- **Example**:
  ```sql
  DEFINE ALLOW_NULL_MEASURES = 'FALSE'
  ```

**Recommendation**: Keep FALSE in production to ensure data quality.

---

### 5. Performance Settings

#### PARALLEL_DEGREE
- **Purpose**: Degree of parallelism for ETL operations
- **Type**: Integer
- **Default**: 4
- **Range**: 1 - 16 (depends on CPU cores)
- **Example**:
  ```sql
  DEFINE PARALLEL_DEGREE = 4
  ```

**Tuning Guidelines:**
- Set to number of CPU cores / 2
- Higher values increase resource usage
- Test in non-production first

#### GATHER_STATS
- **Purpose**: Automatically gather statistics after ETL
- **Type**: Boolean (TRUE/FALSE)
- **Default**: TRUE
- **Example**:
  ```sql
  DEFINE GATHER_STATS = 'TRUE'
  ```

**Important**: Keep TRUE in production for optimal query performance.

---

## Environment Setup

### Development Environment

```sql
-- config/database_config_dev.sql
DEFINE SOURCE_DATA_DIR = 'C:\Dev\Data\Warehouse\Source'
DEFINE LOG_DIR = 'C:\Dev\Data\Warehouse\Logs'
DEFINE DW_SCHEMA = 'DW_DEV'
DEFINE STAGING_SCHEMA = 'DW_DEV'
DEFINE BATCH_SIZE = 5000
DEFINE ERROR_THRESHOLD = 1000
DEFINE ENABLE_LOGGING = 'TRUE'
DEFINE CHECK_DUPLICATES = 'TRUE'
DEFINE ALLOW_NULL_MEASURES = 'FALSE'
DEFINE PARALLEL_DEGREE = 2
DEFINE GATHER_STATS = 'TRUE'
```

### UAT Environment

```sql
-- config/database_config_uat.sql
DEFINE SOURCE_DATA_DIR = 'C:\UAT\Data\Warehouse\Source'
DEFINE LOG_DIR = 'C:\UAT\Data\Warehouse\Logs'
DEFINE DW_SCHEMA = 'DW_UAT'
DEFINE STAGING_SCHEMA = 'STAGING_UAT'
DEFINE BATCH_SIZE = 10000
DEFINE ERROR_THRESHOLD = 100
DEFINE ENABLE_LOGGING = 'TRUE'
DEFINE CHECK_DUPLICATES = 'TRUE'
DEFINE ALLOW_NULL_MEASURES = 'FALSE'
DEFINE PARALLEL_DEGREE = 4
DEFINE GATHER_STATS = 'TRUE'
```

### Production Environment

```sql
-- config/database_config_prod.sql
DEFINE SOURCE_DATA_DIR = 'D:\Production\DataWarehouse\Source'
DEFINE LOG_DIR = 'D:\Production\DataWarehouse\Logs'
DEFINE DW_SCHEMA = 'DW_PROD'
DEFINE STAGING_SCHEMA = 'STAGING_PROD'
DEFINE BATCH_SIZE = 10000
DEFINE ERROR_THRESHOLD = 10
DEFINE ENABLE_LOGGING = 'TRUE'
DEFINE CHECK_DUPLICATES = 'TRUE'
DEFINE ALLOW_NULL_MEASURES = 'FALSE'
DEFINE PARALLEL_DEGREE = 8
DEFINE GATHER_STATS = 'TRUE'
```

---

## Using Configuration in Scripts

### Loading Configuration

At the beginning of each script:
```sql
-- Load environment configuration
@@config/database_config.sql

-- Use configuration variables
CREATE OR REPLACE DIRECTORY source_dir AS '&SOURCE_DATA_DIR';
```

### Referencing Variables

```sql
-- In PL/SQL
DECLARE
    v_batch_size NUMBER := &BATCH_SIZE;
    v_log_dir VARCHAR2(500) := '&LOG_DIR';
BEGIN
    -- Use variables
END;
```

---

## Configuration Validation

Before deployment, validate your configuration:

```sql
-- Check directory paths exist
SELECT directory_name, directory_path 
FROM all_directories 
WHERE directory_name = 'SOURCE_DIR';

-- Verify schema exists
SELECT username FROM all_users WHERE username = '&DW_SCHEMA';

-- Test write permissions
BEGIN
    UTL_FILE.FOPEN('&LOG_DIR', 'test.log', 'W');
    UTL_FILE.FCLOSE_ALL;
END;
```

---

## Security Considerations

### Sensitive Information

**DO NOT** store in configuration files:
- Database passwords
- Connection strings with credentials
- API keys or tokens

**Use instead:**
- Oracle Wallet for credentials
- Environment variables
- Secure credential store

### File Permissions

Configuration files should have restricted permissions:
```bash
# Windows
icacls database_config.sql /inheritance:r /grant:r "Administrators:F"

# Linux/Unix
chmod 600 database_config.sql
```

### Version Control

Add to `.gitignore`:
```
config/*_prod.sql
config/passwords.txt
.env.production
```

---

## Troubleshooting

### Common Issues

**Issue**: Directory not found error
- **Solution**: Verify `SOURCE_DATA_DIR` path exists and is accessible

**Issue**: Permission denied on directory
- **Solution**: Grant OS-level read/write permissions to Oracle user

**Issue**: Configuration variable not substituted
- **Solution**: Ensure `@@config/database_config.sql` is called before using variables

**Issue**: Performance degradation
- **Solution**: Adjust `BATCH_SIZE` and `PARALLEL_DEGREE` based on system resources

---

## Best Practices

1. **Version Control**: Keep environment-specific configs in separate files
2. **Documentation**: Comment all non-obvious configuration choices
3. **Testing**: Test configuration changes in DEV before UAT/PROD
4. **Backup**: Keep backup of working production configuration
5. **Validation**: Always run pre-deployment checks before applying config changes
6. **Monitoring**: Monitor ETL performance after configuration changes

---

## Related Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment procedures
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [README.md](README.md) - Project overview
