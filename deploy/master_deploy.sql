-- =============================================================================
-- Master Deployment Script
-- =============================================================================
-- Purpose: Automated deployment of the entire data warehouse
-- Author: Data Warehouse Team
-- Version: 1.0.0
-- Created: 2025-11-21
--
-- Description:
--   This is the main deployment script that orchestrates the complete
--   data warehouse setup. It executes all scripts in the correct order
--   and provides comprehensive logging and error handling.
--
-- Usage:
--   sqlplus username/password@database @deploy/master_deploy.sql
--
-- Prerequisites:
--   - Oracle Database 19c or higher
--   - Appropriate privileges (CREATE TABLE, CREATE DIRECTORY, etc.)
--   - Source data file (superstore.csv) in configured directory
--   - Configuration file updated for your environment
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET ECHO ON
SET FEEDBACK ON
SET TIMING ON
SET VERIFY OFF

PROMPT ========================================
PROMPT Data Warehouse Master Deployment
PROMPT ========================================
PROMPT Version: 1.0.0
PROMPT Date: 2025-11-21
PROMPT ========================================

-- =============================================================================
-- Load Configuration
-- =============================================================================

PROMPT
PROMPT Loading configuration...
PROMPT

@@../config/database_config.sql

PROMPT
PROMPT Configuration loaded successfully
PROMPT

-- =============================================================================
-- Pre-Deployment Checks
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 1: Pre-Deployment Checks
PROMPT ========================================
PROMPT

-- Check Oracle version
DECLARE
    v_version VARCHAR2(100);
BEGIN
    SELECT version INTO v_version FROM v$instance;
    DBMS_OUTPUT.PUT_LINE('Oracle Database Version: ' || v_version);
    
    IF SUBSTR(v_version, 1, 2) < '19' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Oracle 19c or higher required');
    END IF;
END;
/

-- Check user privileges
DECLARE
    v_priv_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_priv_count
    FROM user_sys_privs
    WHERE privilege IN ('CREATE TABLE', 'CREATE SEQUENCE', 'CREATE PROCEDURE');
    
    IF v_priv_count < 3 THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: Some required privileges may be missing');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✓ Required privileges verified');
    END IF;
END;
/

PROMPT
PROMPT Pre-deployment checks completed
PROMPT

PAUSE Press Enter to continue with deployment...

-- =============================================================================
-- Phase 2: Logging Framework
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 2: Creating Logging Framework
PROMPT ========================================
PROMPT

@@../PLSQL/00_logging_framework.sql

PROMPT
PROMPT Logging framework created
PROMPT

-- =============================================================================
-- Phase 3: Cleanup (Optional)
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 3: Cleanup Existing Objects
PROMPT ========================================
PROMPT
PROMPT WARNING: This will drop all existing data warehouse objects!
PROMPT

ACCEPT run_cleanup PROMPT 'Run cleanup? (YES/NO): '

BEGIN
    IF UPPER('&run_cleanup') = 'YES' THEN
        DBMS_OUTPUT.PUT_LINE('Running cleanup...');
        @@../PLSQL/00_cleanup.sql
    ELSE
        DBMS_OUTPUT.PUT_LINE('Skipping cleanup');
    END IF;
END;
/

-- =============================================================================
-- Phase 4: Staging Setup
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 4: Setting Up Staging Layer
PROMPT ========================================
PROMPT

@@../PLSQL/01_staging.sql

PROMPT
PROMPT Staging layer created
PROMPT

-- =============================================================================
-- Phase 5: Create Dimension Tables
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 5: Creating Dimension Tables
PROMPT ========================================
PROMPT

@@../PLSQL/02_dimensions.sql

PROMPT
PROMPT Dimension tables created
PROMPT

-- =============================================================================
-- Phase 6: Create Fact Table
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 6: Creating Fact Table
PROMPT ========================================
PROMPT

@@../PLSQL/03_fact_table.sql

PROMPT
PROMPT Fact table created
PROMPT

-- =============================================================================
-- Phase 7: Create Rollback Procedures
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 7: Creating Rollback Procedures
PROMPT ========================================
PROMPT

@@../PLSQL/08_rollback_procedures.sql

PROMPT
PROMPT Rollback procedures created
PROMPT

-- =============================================================================
-- Phase 8: ETL - Time Dimension
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 8: Loading Time Dimension
PROMPT ========================================
PROMPT

@@../PLSQL/04_etl_dim_time.sql

PROMPT
PROMPT Time dimension loaded
PROMPT

-- =============================================================================
-- Phase 9: ETL - Other Dimensions
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 9: Loading Dimension Tables
PROMPT ========================================
PROMPT

@@../PLSQL/05_etl_dimensions.sql

PROMPT
PROMPT Dimension tables loaded
PROMPT

-- =============================================================================
-- Phase 10: ETL - Fact Table
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 10: Loading Fact Table
PROMPT ========================================
PROMPT

@@../PLSQL/06_etl_fact_sales.sql

PROMPT
PROMPT Fact table loaded
PROMPT

-- =============================================================================
-- Phase 11: Gather Statistics
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 11: Gathering Optimizer Statistics
PROMPT ========================================
PROMPT

@@../PLSQL/09_gather_statistics.sql

PROMPT
PROMPT Statistics gathered
PROMPT

-- =============================================================================
-- Phase 12: Data Quality Checks
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 12: Running Data Quality Checks
PROMPT ========================================
PROMPT

@@../PLSQL/07_data_quality_checks.sql

PROMPT
PROMPT Data quality checks completed
PROMPT

-- =============================================================================
-- Phase 13: Post-Deployment Validation
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Phase 13: Post-Deployment Validation
PROMPT ========================================
PROMPT

-- Verify all tables exist
SELECT 'Table: ' || table_name || ' - Rows: ' || NVL(TO_CHAR(num_rows), 'Not analyzed') as status
FROM user_tables
WHERE table_name IN ('DIM_CUSTOMER', 'DIM_PRODUCT', 'DIM_REGION', 'DIM_TIME', 'FACT_SALES')
ORDER BY table_name;

-- Verify row counts
PROMPT
PROMPT Row counts:
PROMPT

SELECT 'DIM_CUSTOMER' as table_name, COUNT(*) as row_count FROM dim_customer
UNION ALL
SELECT 'DIM_PRODUCT', COUNT(*) FROM dim_product
UNION ALL
SELECT 'DIM_REGION', COUNT(*) FROM dim_region
UNION ALL
SELECT 'DIM_TIME', COUNT(*) FROM dim_time
UNION ALL
SELECT 'FACT_SALES', COUNT(*) FROM fact_sales;

-- =============================================================================
-- Deployment Summary
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Deployment Summary
PROMPT ========================================
PROMPT

SELECT 
    process_name,
    status,
    TO_CHAR(start_time, 'YYYY-MM-DD HH24:MI:SS') as start_time,
    ROUND(duration_sec, 2) as duration_sec,
    rows_processed,
    error_message
FROM etl_log
WHERE start_time >= SYSDATE - 1/24  -- Last hour
ORDER BY start_time;

PROMPT
PROMPT ========================================
PROMPT Deployment Completed Successfully!
PROMPT ========================================
PROMPT
PROMPT Next Steps:
PROMPT   1. Review the deployment summary above
PROMPT   2. Verify row counts match expectations
PROMPT   3. Run sample analytical queries
PROMPT   4. Set up backup schedule
PROMPT   5. Configure monitoring
PROMPT
PROMPT Documentation:
PROMPT   - README.md: Project overview
PROMPT   - CONFIG.md: Configuration guide
PROMPT   - TROUBLESHOOTING.md: Common issues
PROMPT
PROMPT ========================================

SPOOL OFF
