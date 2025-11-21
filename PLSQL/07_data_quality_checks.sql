-- =============================================================================
-- Data Quality Checks
-- =============================================================================
-- Purpose: Validate data quality after ETL processes
-- Author: Data Warehouse Team
-- Version: 1.0.0
-- Created: 2025-11-21
--
-- Description:
--   This script performs comprehensive data quality checks on the data warehouse.
--   It validates referential integrity, business rules, and data completeness.
--   Run this after ETL processes to ensure data quality.
--
-- Dependencies: All dimension and fact tables must exist
-- =============================================================================

   SET SERVEROUTPUT ON SIZE UNLIMITED
SET ECHO ON
SET FEEDBACK ON

PROMPT ========================================
PROMPT Data Quality Checks
PROMPT ========================================

declare
   v_log_id        number;
   v_error_count   number := 0;
   v_warning_count number := 0;
   v_check_name    varchar2(100);
   v_result_count  number;
begin
    -- Start logging
   log_process_start(
      'DATA_QUALITY_CHECKS',
      'VALIDATION',
      v_log_id
   );
   dbms_output.put_line('Starting data quality validation...');
   dbms_output.put_line('');
    
    -- =========================================================================
    -- CHECK 1: Orphaned Records in Fact Table
    -- =========================================================================
   v_check_name := 'Orphaned Records - Customer';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales f
    where not exists (
      select 1
        from dim_customer c
       where c.customer_key = f.customer_key
   );

   if v_result_count > 0 then
      dbms_output.put_line('  ❌ FAILED: Found '
                           || v_result_count || ' fact records with invalid customer_key');
      v_error_count := v_error_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: All fact records have valid customer references');
   end if;
   dbms_output.put_line('');
    
    -- Check Product references
   v_check_name := 'Orphaned Records - Product';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales f
    where not exists (
      select 1
        from dim_product p
       where p.product_key = f.product_key
   );

   if v_result_count > 0 then
      dbms_output.put_line('  ❌ FAILED: Found '
                           || v_result_count || ' fact records with invalid product_key');
      v_error_count := v_error_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: All fact records have valid product references');
   end if;
   dbms_output.put_line('');
    
    -- Check Region references
   v_check_name := 'Orphaned Records - Region';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales f
    where not exists (
      select 1
        from dim_region r
       where r.region_key = f.region_key
   );

   if v_result_count > 0 then
      dbms_output.put_line('  ❌ FAILED: Found '
                           || v_result_count || ' fact records with invalid region_key');
      v_error_count := v_error_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: All fact records have valid region references');
   end if;
   dbms_output.put_line('');
    
    -- Check Time references
   v_check_name := 'Orphaned Records - Time';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales f
    where not exists (
      select 1
        from dim_time t
       where t.time_key = f.time_key
   );

   if v_result_count > 0 then
      dbms_output.put_line('  ❌ FAILED: Found '
                           || v_result_count || ' fact records with invalid time_key');
      v_error_count := v_error_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: All fact records have valid time references');
   end if;
   dbms_output.put_line('');
    
    -- =========================================================================
    -- CHECK 2: Duplicate Records in Dimensions
    -- =========================================================================
   v_check_name := 'Duplicate Customers';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from (
      select customer_id,
             count(*) as cnt
        from dim_customer
       group by customer_id
      having count(*) > 1
   );

   if v_result_count > 0 then
      dbms_output.put_line('  ⚠ WARNING: Found '
                           || v_result_count || ' duplicate customer_id values');
      v_warning_count := v_warning_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: No duplicate customers found');
   end if;
   dbms_output.put_line('');
   v_check_name := 'Duplicate Products';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from (
      select product_id,
             count(*) as cnt
        from dim_product
       group by product_id
      having count(*) > 1
   );

   if v_result_count > 0 then
      dbms_output.put_line('  ⚠ WARNING: Found '
                           || v_result_count || ' duplicate product_id values');
      v_warning_count := v_warning_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: No duplicate products found');
   end if;
   dbms_output.put_line('');
    
    -- =========================================================================
    -- CHECK 3: NULL Values in Critical Fields
    -- =========================================================================
   v_check_name := 'NULL Sales Values';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales
    where sales is null;

   if v_result_count > 0 then
      dbms_output.put_line('  ❌ FAILED: Found '
                           || v_result_count || ' records with NULL sales');
      v_error_count := v_error_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: No NULL sales values found');
   end if;
   dbms_output.put_line('');
   v_check_name := 'NULL Profit Values';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales
    where profit is null;

   if v_result_count > 0 then
      dbms_output.put_line('  ❌ FAILED: Found '
                           || v_result_count || ' records with NULL profit');
      v_error_count := v_error_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: No NULL profit values found');
   end if;
   dbms_output.put_line('');
   v_check_name := 'NULL Quantity Values';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales
    where quantity is null;

   if v_result_count > 0 then
      dbms_output.put_line('  ❌ FAILED: Found '
                           || v_result_count || ' records with NULL quantity');
      v_error_count := v_error_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: No NULL quantity values found');
   end if;
   dbms_output.put_line('');
    
    -- =========================================================================
    -- CHECK 4: Date Range Validation
    -- =========================================================================
   v_check_name := 'Future Dates';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales f
     join dim_time t
   on f.time_key = t.time_key
    where t.full_date > sysdate;

   if v_result_count > 0 then
      dbms_output.put_line('  ⚠ WARNING: Found '
                           || v_result_count || ' records with future dates');
      v_warning_count := v_warning_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: No future dates found');
   end if;
   dbms_output.put_line('');
   v_check_name := 'Invalid Date Range';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales f
     join dim_time t
   on f.time_key = t.time_key
    where t.full_date < date '2000-01-01'
       or t.full_date > date '2030-12-31';

   if v_result_count > 0 then
      dbms_output.put_line('  ⚠ WARNING: Found '
                           || v_result_count || ' records outside expected date range (2000-2030)');
      v_warning_count := v_warning_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: All dates within expected range');
   end if;
   dbms_output.put_line('');
    
    -- =========================================================================
    -- CHECK 5: Business Rule Validation
    -- =========================================================================
   v_check_name := 'Negative Sales';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales
    where sales < 0;

   if v_result_count > 0 then
      dbms_output.put_line('  ⚠ WARNING: Found '
                           || v_result_count || ' records with negative sales (possible returns)');
      v_warning_count := v_warning_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: No negative sales values');
   end if;
   dbms_output.put_line('');
   v_check_name := 'Zero Quantity';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales
    where quantity = 0;

   if v_result_count > 0 then
      dbms_output.put_line('  ⚠ WARNING: Found '
                           || v_result_count || ' records with zero quantity');
      v_warning_count := v_warning_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: All records have non-zero quantity');
   end if;
   dbms_output.put_line('');
   v_check_name := 'Discount > 100%';
   dbms_output.put_line('CHECK: ' || v_check_name);
   select count(*)
     into v_result_count
     from fact_sales
    where discount > 1.0;

   if v_result_count > 0 then
      dbms_output.put_line('  ❌ FAILED: Found '
                           || v_result_count || ' records with discount > 100%');
      v_error_count := v_error_count + 1;
   else
      dbms_output.put_line('  ✓ PASSED: All discounts within valid range');
   end if;
   dbms_output.put_line('');
    
    -- =========================================================================
    -- CHECK 6: Data Completeness
    -- =========================================================================
   v_check_name := 'Empty Dimension Tables';
   dbms_output.put_line('CHECK: ' || v_check_name);
   declare
      v_customer_count number;
      v_product_count  number;
      v_region_count   number;
      v_time_count     number;
      v_empty_dims     number := 0;
   begin
      select count(*)
        into v_customer_count
        from dim_customer;
      select count(*)
        into v_product_count
        from dim_product;
      select count(*)
        into v_region_count
        from dim_region;
      select count(*)
        into v_time_count
        from dim_time;

      if v_customer_count = 0 then
         dbms_output.put_line('  ❌ FAILED: DIM_CUSTOMER is empty');
         v_empty_dims := v_empty_dims + 1;
      end if;

      if v_product_count = 0 then
         dbms_output.put_line('  ❌ FAILED: DIM_PRODUCT is empty');
         v_empty_dims := v_empty_dims + 1;
      end if;

      if v_region_count = 0 then
         dbms_output.put_line('  ❌ FAILED: DIM_REGION is empty');
         v_empty_dims := v_empty_dims + 1;
      end if;

      if v_time_count = 0 then
         dbms_output.put_line('  ❌ FAILED: DIM_TIME is empty');
         v_empty_dims := v_empty_dims + 1;
      end if;

      if v_empty_dims = 0 then
         dbms_output.put_line('  ✓ PASSED: All dimension tables populated');
         dbms_output.put_line('    - Customers: ' || v_customer_count);
         dbms_output.put_line('    - Products: ' || v_product_count);
         dbms_output.put_line('    - Regions: ' || v_region_count);
         dbms_output.put_line('    - Time: ' || v_time_count);
      else
         v_error_count := v_error_count + v_empty_dims;
      end if;
   end;
   dbms_output.put_line('');
    
    -- =========================================================================
    -- Summary
    -- =========================================================================
   dbms_output.put_line('========================================');
   dbms_output.put_line('Data Quality Check Summary');
   dbms_output.put_line('========================================');
   dbms_output.put_line('Errors: ' || v_error_count);
   dbms_output.put_line('Warnings: ' || v_warning_count);
   if
      v_error_count = 0
      and v_warning_count = 0
   then
      dbms_output.put_line('Status: ✓ ALL CHECKS PASSED');
      log_process_end(
         v_log_id,
         p_additional_info => 'All quality checks passed'
      );
   elsif v_error_count = 0 then
      dbms_output.put_line('Status: ⚠ PASSED WITH WARNINGS');
      log_process_end(
         v_log_id,
         p_additional_info => v_warning_count || ' warnings found'
      );
   else
      dbms_output.put_line('Status: ❌ FAILED - Data quality issues detected');
      log_process_error(
         v_log_id,
         v_error_count || ' critical errors found',
         'DQ_ERROR'
      );
      raise_application_error(
         -20001,
         'Data quality validation failed with '
         || v_error_count
         || ' errors'
      );
   end if;
   dbms_output.put_line('========================================');
exception
   when others then
      dbms_output.put_line('ERROR during data quality checks: ' || sqlerrm);
      log_process_error(
         v_log_id,
         sqlerrm,
         sqlcode
      );
      raise;
end;
/

PROMPT
PROMPT Data quality checks completed
PROMPT