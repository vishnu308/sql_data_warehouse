-- =============================================================================
-- Database Configuration File
-- =============================================================================
-- Purpose: Centralized configuration for all environments
-- Usage: @@config/database_config.sql at the start of deployment scripts
--
-- INSTRUCTIONS:
-- 1. Copy this file to create environment-specific versions:
--    - database_config_dev.sql
--    - database_config_uat.sql
--    - database_config_prod.sql
-- 2. Modify the values below for your environment
-- 3. Load the appropriate config file during deployment
-- =============================================================================

-- =============================================================================
-- DIRECTORY PATHS
-- =============================================================================
-- NOTE: Paths must exist before deployment and Oracle user needs permissions

-- Source data directory (where superstore.csv is located)
DEFINE SOURCE_DATA_DIR = 'C:\Users\Admin\OneDrive - vishnu shendge\Desktop\Data Warehouse\Dataset'

-- Log directory (for ETL logs and error files)
DEFINE LOG_DIR = 'C:\Users\Admin\OneDrive - vishnu shendge\Desktop\Data Warehouse\Logs'

-- =============================================================================
-- SCHEMA CONFIGURATION
-- =============================================================================

-- Data warehouse schema (owner of dimension and fact tables)
DEFINE DW_SCHEMA = 'SYSTEM'

-- Staging schema (owner of staging and external tables)
DEFINE STAGING_SCHEMA = 'SYSTEM'

-- =============================================================================
-- ETL PARAMETERS
-- =============================================================================

-- Batch size for bulk operations (rows per commit)
-- Recommended: 10000 for balanced performance
-- Range: 1000 (safer, slower) to 50000 (faster, more memory)
DEFINE BATCH_SIZE = 10000

-- Maximum errors before ETL aborts
-- Development: 1000, UAT: 100, Production: 10
DEFINE ERROR_THRESHOLD = 100

-- Enable detailed ETL logging (TRUE/FALSE)
-- Set to FALSE only if performance is critical and logs are too large
DEFINE ENABLE_LOGGING = TRUE

-- =============================================================================
-- DATA QUALITY SETTINGS
-- =============================================================================

-- Check for duplicates during ETL (TRUE/FALSE)
DEFINE CHECK_DUPLICATES = TRUE

-- Allow NULL values in fact table measures (TRUE/FALSE)
-- Recommended: FALSE for production data quality
DEFINE ALLOW_NULL_MEASURES = FALSE

-- =============================================================================
-- PERFORMANCE SETTINGS
-- =============================================================================

-- Degree of parallelism for ETL operations
-- Recommended: Number of CPU cores / 2
-- Range: 1 (serial) to 16 (highly parallel)
DEFINE PARALLEL_DEGREE = 4

-- Automatically gather optimizer statistics after ETL (TRUE/FALSE)
-- Recommended: TRUE for optimal query performance
DEFINE GATHER_STATS = TRUE

-- =============================================================================
-- VALIDATION
-- =============================================================================
-- Display loaded configuration
PROMPT ========================================
PROMPT Configuration Loaded
PROMPT ========================================
PROMPT Source Data Directory: &SOURCE_DATA_DIR
PROMPT Log Directory: &LOG_DIR
PROMPT DW Schema: &DW_SCHEMA
PROMPT Staging Schema: &STAGING_SCHEMA
PROMPT Batch Size: &BATCH_SIZE
PROMPT Error Threshold: &ERROR_THRESHOLD
PROMPT Enable Logging: &ENABLE_LOGGING
PROMPT Check Duplicates: &CHECK_DUPLICATES
PROMPT Parallel Degree: &PARALLEL_DEGREE
PROMPT Gather Statistics: &GATHER_STATS
PROMPT ========================================