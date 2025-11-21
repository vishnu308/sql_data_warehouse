-- =============================================================================
-- Gather Statistics
-- =============================================================================
-- Purpose: Gather optimizer statistics for all data warehouse objects
-- Author: Data Warehouse Team
-- Version: 1.0.0
-- Created: 2025-11-21
--
-- Description:
--   This script gathers statistics on all dimension and fact tables to ensure
--   optimal query performance. Run this after ETL processes or schema changes.
--
-- Dependencies: All tables must exist
-- =============================================================================

   SET SERVEROUTPUT ON
SET ECHO ON
SET TIMING ON

PROMPT ========================================
PROMPT Gathering Optimizer Statistics
PROMPT ========================================

declare
   v_log_id      number;
   v_start_time  timestamp;
   v_table_count number := 0;
begin
   log_process_start(
      'GATHER_STATISTICS',
      'MAINTENANCE',
      v_log_id
   );
   v_start_time := systimestamp;
   dbms_output.put_line('Starting statistics gathering...');
   dbms_output.put_line('');
    
    -- =========================================================================
    -- Gather statistics on dimension tables
    -- =========================================================================
   dbms_output.put_line('Gathering statistics on dimension tables...');
   begin
      dbms_stats.gather_table_stats(
         ownname          => user,
         tabname          => 'DIM_CUSTOMER',
         estimate_percent => dbms_stats.auto_sample_size,
         method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
         degree           => 4,
         cascade          => true
      );
      dbms_output.put_line('  ✓ DIM_CUSTOMER statistics gathered');
      v_table_count := v_table_count + 1;
   exception
      when others then
         dbms_output.put_line('  ⚠ Warning: Could not gather stats for DIM_CUSTOMER: ' || sqlerrm);
   end;

   begin
      dbms_stats.gather_table_stats(
         ownname          => user,
         tabname          => 'DIM_PRODUCT',
         estimate_percent => dbms_stats.auto_sample_size,
         method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
         degree           => 4,
         cascade          => true
      );
      dbms_output.put_line('  ✓ DIM_PRODUCT statistics gathered');
      v_table_count := v_table_count + 1;
   exception
      when others then
         dbms_output.put_line('  ⚠ Warning: Could not gather stats for DIM_PRODUCT: ' || sqlerrm);
   end;

   begin
      dbms_stats.gather_table_stats(
         ownname          => user,
         tabname          => 'DIM_REGION',
         estimate_percent => dbms_stats.auto_sample_size,
         method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
         degree           => 4,
         cascade          => true
      );
      dbms_output.put_line('  ✓ DIM_REGION statistics gathered');
      v_table_count := v_table_count + 1;
   exception
      when others then
         dbms_output.put_line('  ⚠ Warning: Could not gather stats for DIM_REGION: ' || sqlerrm);
   end;

   begin
      dbms_stats.gather_table_stats(
         ownname          => user,
         tabname          => 'DIM_TIME',
         estimate_percent => dbms_stats.auto_sample_size,
         method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
         degree           => 4,
         cascade          => true
      );
      dbms_output.put_line('  ✓ DIM_TIME statistics gathered');
      v_table_count := v_table_count + 1;
   exception
      when others then
         dbms_output.put_line('  ⚠ Warning: Could not gather stats for DIM_TIME: ' || sqlerrm);
   end;

   dbms_output.put_line('');
    
    -- =========================================================================
    -- Gather statistics on fact table
    -- =========================================================================
   dbms_output.put_line('Gathering statistics on fact table...');
   begin
      dbms_stats.gather_table_stats(
         ownname          => user,
         tabname          => 'FACT_SALES',
         estimate_percent => dbms_stats.auto_sample_size,
         method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
         degree           => 4,
         cascade          => true
      );
      dbms_output.put_line('  ✓ FACT_SALES statistics gathered');
      v_table_count := v_table_count + 1;
   exception
      when others then
         dbms_output.put_line('  ⚠ Warning: Could not gather stats for FACT_SALES: ' || sqlerrm);
   end;

   dbms_output.put_line('');
    
    -- =========================================================================
    -- Summary
    -- =========================================================================
   dbms_output.put_line('========================================');
   dbms_output.put_line('Statistics Gathering Complete');
   dbms_output.put_line('========================================');
   dbms_output.put_line('Tables processed: ' || v_table_count);
   dbms_output.put_line('========================================');
   log_process_end(
      v_log_id,
      p_additional_info => v_table_count || ' tables processed'
   );
exception
   when others then
      dbms_output.put_line('ERROR gathering statistics: ' || sqlerrm);
      log_process_error(
         v_log_id,
         sqlerrm,
         sqlcode
      );
      raise;
end;
/

-- =============================================================================
-- Verify statistics
-- =============================================================================

PROMPT
PROMPT Verifying statistics...
PROMPT

select table_name,
       num_rows,
       blocks,
       to_char(
          last_analyzed,
          'YYYY-MM-DD HH24:MI:SS'
       ) as last_analyzed
  from user_tables
 where table_name in ( 'DIM_CUSTOMER',
                       'DIM_PRODUCT',
                       'DIM_REGION',
                       'DIM_TIME',
                       'FACT_SALES' )
 order by table_name;

PROMPT
PROMPT Statistics gathering completed
PROMPT