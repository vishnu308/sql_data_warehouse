-- =============================================================================
-- Staging Layer Setup
-- =============================================================================
-- Purpose: Create external table for loading source data
-- Author: Data Warehouse Team
-- Version: 1.0.0 (Production)
-- Created: 2025-11-21
--
-- Description:
--   This script creates the staging layer for the data warehouse:
--   1. Creates Oracle directory pointing to source data location
--   2. Creates external table to read superstore.csv
--   3. Validates data can be read successfully
--
-- Prerequisites:
--   - Configuration file loaded (@@config/database_config.sql)
--   - Source CSV file exists in configured directory
--   - User has CREATE DIRECTORY privilege
--   - Oracle user has OS-level read permissions on directory
--
-- Usage:
--   @@config/database_config.sql
--   @@PLSQL/01_staging.sql
-- =============================================================================

   SET SERVEROUTPUT ON
SET ECHO ON

PROMPT ========================================
PROMPT Setting Up Staging Layer
PROMPT ========================================

declare
   v_log_id number;
begin
   log_process_start(
      'STAGING_SETUP',
      'DEPLOYMENT',
      v_log_id
   );
   dbms_output.put_line('Starting staging layer setup...');
   log_process_end(
      v_log_id,
      p_additional_info => 'Staging setup initiated'
   );
exception
   when others then
      dbms_output.put_line('Note: Logging framework not yet available');
end;
/

-- =============================================================================
-- Step 1: Create Oracle Directory
-- =============================================================================

PROMPT
PROMPT Creating Oracle directory for source data...
PROMPT

-- Drop existing directory if it exists
begin
   execute immediate 'DROP DIRECTORY source_dir';
   dbms_output.put_line('Dropped existing SOURCE_DIR directory');
exception
   when others then
      if sqlcode != -4043 then
         raise;
      end if;
      dbms_output.put_line('SOURCE_DIR directory does not exist, creating new');
end;
/

-- Create directory using configuration variable
-- Note: Path must exist on file system and Oracle user must have OS permissions
create or replace directory source_dir as '&SOURCE_DATA_DIR';

PROMPT Directory created: SOURCE_DIR
PROMPT Path: &SOURCE_DATA_DIR
PROMPT

-- Security Note: Grant to specific users/roles in production, not PUBLIC
-- For development/testing, we grant to current user
-- In production, replace with: GRANT READ ON DIRECTORY source_dir TO <specific_user>;
grant read on directory source_dir to &dw_schema;

PROMPT Directory permissions granted
PROMPT

-- =============================================================================
-- Step 2: Drop Existing Staging Table
-- =============================================================================

PROMPT Dropping existing staging table if it exists...
PROMPT

begin
   execute immediate 'DROP TABLE staging_superstore';
   dbms_output.put_line('Dropped existing STAGING_SUPERSTORE table');
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
      dbms_output.put_line('STAGING_SUPERSTORE table does not exist, creating new');
end;
/

-- =============================================================================
-- Step 3: Create External Table
-- =============================================================================

PROMPT
PROMPT Creating external table: STAGING_SUPERSTORE
PROMPT

-- NOTE: Column order MUST match CSV file exactly
-- CSV Header: Category,City,Country,Customer.ID,Customer.Name,Discount,Market,
--             Number_of_records,Order.Date,Order.ID,Order.Priority,Product.ID,
--             Product.Name,Profit,Quantity,Region,Row.ID,Sales,Segment,Ship.Date,
--             Ship.Mode,Shipping.Cost,State,Sub.Category,Year,Market2,weeknum

create table staging_superstore (
   category          varchar2(255),
   city              varchar2(255),
   country           varchar2(255),
   customer_id       varchar2(255),
   customer_name     varchar2(255),
   discount          varchar2(255),
   market            varchar2(255),
   number_of_records varchar2(255),
   order_date        varchar2(255),
   order_id          varchar2(255),
   order_priority    varchar2(255),
   product_id        varchar2(255),
   product_name      varchar2(255),
   profit            varchar2(255),
   quantity          varchar2(255),
   region            varchar2(255),
   row_id            varchar2(255),
   sales             varchar2(255),
   segment           varchar2(255),
   ship_date         varchar2(255),
   ship_mode         varchar2(255),
   shipping_cost     varchar2(255),
   state             varchar2(255),
   sub_category      varchar2(255),
   year              varchar2(255),
   market2           varchar2(255),
   weeknum           varchar2(255)
)
organization external ( type oracle_loader
   default directory source_dir access parameters (
      records
      delimited by newline
      skip 1
      fields terminated by ',' optionally enclosed by '"' missing field values are null
   ) location ( 'superstore.csv' )
) reject limit unlimited;

PROMPT External table created successfully
PROMPT

-- Note: Cannot add comments to external tables
-- COMMENT ON TABLE staging_superstore IS 'External table for loading superstore CSV data';

-- =============================================================================
-- Step 4: Validate External Table
-- =============================================================================

PROMPT
PROMPT Validating external table can read data...
PROMPT

declare
   v_count        number;
   v_sample_count number := 5;
begin
    -- Count total rows
   select count(*)
     into v_count
     from staging_superstore;
   dbms_output.put_line('Total rows in staging table: ' || v_count);
   if v_count = 0 then
      raise_application_error(
         -20001,
         'External table is empty! Check file location and permissions.'
      );
   end if;
    
    -- Display sample records
   dbms_output.put_line('');
   dbms_output.put_line('Sample records from staging table:');
   dbms_output.put_line('-----------------------------------');
   for rec in (
      select category,
             product_name,
             sales,
             profit
        from staging_superstore
       where rownum <= v_sample_count
   ) loop
      dbms_output.put_line('Category: '
                           || rec.category
                           || ', Product: '
                           || rec.product_name
                           || ', Sales: '
                           || rec.sales
                           || ', Profit: ' || rec.profit);
   end loop;

   dbms_output.put_line('');
   dbms_output.put_line('✓ External table validation successful');
exception
   when others then
      dbms_output.put_line('');
      dbms_output.put_line('❌ ERROR validating external table:');
      dbms_output.put_line(sqlerrm);
      dbms_output.put_line('');
      dbms_output.put_line('Troubleshooting steps:');
      dbms_output.put_line('1. Verify file exists: &SOURCE_DATA_DIR\superstore.csv');
      dbms_output.put_line('2. Check Oracle user has read permissions on directory');
      dbms_output.put_line('3. Verify CSV file format (UTF-8, comma-delimited)');
      dbms_output.put_line('4. Check for .bad and .log files in source directory');
      raise;
end;
/

-- =============================================================================
-- Summary
-- =============================================================================

PROMPT
PROMPT ========================================
PROMPT Staging Layer Setup Complete
PROMPT ========================================
PROMPT
PROMPT Objects created:
PROMPT   - Directory: SOURCE_DIR
PROMPT   - External Table: STAGING_SUPERSTORE
PROMPT
PROMPT Configuration:
PROMPT   - Source Directory: &SOURCE_DATA_DIR
PROMPT   - Data File: superstore.csv
PROMPT
PROMPT Next Steps:
PROMPT   - Create dimension tables (02_dimensions.sql)
PROMPT   - Create fact table (03_fact_table.sql)
PROMPT   - Run ETL processes
PROMPT
PROMPT ========================================