-- =============================================================================
-- Rollback Procedures
-- =============================================================================
-- Purpose: Provide backup and restore capabilities for data warehouse
-- Author: Data Warehouse Team
-- Version: 1.0.0
-- Created: 2025-11-21
--
-- Description:
--   This script provides procedures to backup and restore data warehouse tables.
--   Use these procedures before major ETL runs or schema changes.
--
-- Dependencies: None
-- =============================================================================

   SET SERVEROUTPUT ON
SET ECHO ON

PROMPT ========================================
PROMPT Creating Rollback Procedures
PROMPT ========================================

-- =============================================================================
-- Procedure: backup_table
-- Purpose: Create a backup copy of a table
-- =============================================================================

create or replace procedure backup_table (
   p_table_name    in varchar2,
   p_backup_suffix in varchar2 default to_char(
      sysdate,
      'YYYYMMDD_HH24MISS'
   )
) as
   v_backup_name varchar2(128);
   v_sql         varchar2(4000);
   v_count       number;
   v_log_id      number;
begin
   log_process_start(
      'BACKUP_' || p_table_name,
      'BACKUP',
      v_log_id
   );
   v_backup_name := p_table_name
                    || '_BKP_'
                    || p_backup_suffix;
   dbms_output.put_line('Creating backup: ' || v_backup_name);
    
    -- Drop backup table if it exists
   begin
      execute immediate 'DROP TABLE '
                        || v_backup_name
                        || ' PURGE';
      dbms_output.put_line('Dropped existing backup table');
   exception
      when others then
         if sqlcode != -942 then
            raise;
         end if;
   end;
    
    -- Create backup as a copy of original table
   v_sql := 'CREATE TABLE '
            || v_backup_name
            || ' AS SELECT * FROM '
            || p_table_name;
   execute immediate v_sql;
    
    -- Get row count
   execute immediate 'SELECT COUNT(*) FROM ' || v_backup_name
     into v_count;
   dbms_output.put_line('Backup created successfully: '
                        || v_count || ' rows backed up');
   log_process_end(
      v_log_id,
      p_rows_processed  => v_count,
      p_additional_info => 'Backup table: ' || v_backup_name
   );
exception
   when others then
      dbms_output.put_line('ERROR creating backup: ' || sqlerrm);
      log_process_error(
         v_log_id,
         sqlerrm,
         sqlcode
      );
      raise;
end backup_table;
/

-- =============================================================================
-- Procedure: restore_table
-- Purpose: Restore a table from backup
-- =============================================================================

create or replace procedure restore_table (
   p_table_name    in varchar2,
   p_backup_suffix in varchar2
) as
   v_backup_name varchar2(128);
   v_sql         varchar2(4000);
   v_count       number;
   v_log_id      number;
begin
   log_process_start(
      'RESTORE_' || p_table_name,
      'RESTORE',
      v_log_id
   );
   v_backup_name := p_table_name
                    || '_BKP_'
                    || p_backup_suffix;
   dbms_output.put_line('Restoring from backup: ' || v_backup_name);
    
    -- Verify backup exists
   begin
      execute immediate 'SELECT COUNT(*) FROM ' || v_backup_name
        into v_count;
   exception
      when others then
         raise_application_error(
            -20002,
            'Backup table '
            || v_backup_name
            || ' does not exist'
         );
   end;
    
    -- Truncate original table
   execute immediate 'TRUNCATE TABLE ' || p_table_name;
   dbms_output.put_line('Truncated original table');
    
    -- Restore data from backup
   v_sql := 'INSERT INTO '
            || p_table_name
            || ' SELECT * FROM '
            || v_backup_name;
   execute immediate v_sql;
   commit;
   dbms_output.put_line('Restore completed successfully: '
                        || v_count || ' rows restored');
   log_process_end(
      v_log_id,
      p_rows_processed  => v_count,
      p_rows_inserted   => v_count,
      p_additional_info => 'Restored from: ' || v_backup_name
   );

exception
   when others then
      rollback;
      dbms_output.put_line('ERROR during restore: ' || sqlerrm);
      log_process_error(
         v_log_id,
         sqlerrm,
         sqlcode
      );
      raise;
end restore_table;
/

-- =============================================================================
-- Procedure: backup_all_tables
-- Purpose: Backup all data warehouse tables
-- =============================================================================

create or replace procedure backup_all_tables (
   p_backup_suffix in varchar2 default to_char(
      sysdate,
      'YYYYMMDD_HH24MISS'
   )
) as
   v_log_id number;
begin
   log_process_start(
      'BACKUP_ALL_TABLES',
      'BACKUP',
      v_log_id
   );
   dbms_output.put_line('========================================');
   dbms_output.put_line('Backing up all data warehouse tables');
   dbms_output.put_line('Backup suffix: ' || p_backup_suffix);
   dbms_output.put_line('========================================');
    
    -- Backup dimension tables
   dbms_output.put_line('Backing up dimension tables...');
   backup_table(
      'DIM_CUSTOMER',
      p_backup_suffix
   );
   backup_table(
      'DIM_PRODUCT',
      p_backup_suffix
   );
   backup_table(
      'DIM_REGION',
      p_backup_suffix
   );
   backup_table(
      'DIM_TIME',
      p_backup_suffix
   );
    
    -- Backup fact table
   dbms_output.put_line('Backing up fact table...');
   backup_table(
      'FACT_SALES',
      p_backup_suffix
   );
   dbms_output.put_line('========================================');
   dbms_output.put_line('All tables backed up successfully');
   dbms_output.put_line('========================================');
   log_process_end(
      v_log_id,
      p_additional_info => 'All tables backed up with suffix: ' || p_backup_suffix
   );
exception
   when others then
      dbms_output.put_line('ERROR during backup: ' || sqlerrm);
      log_process_error(
         v_log_id,
         sqlerrm,
         sqlcode
      );
      raise;
end backup_all_tables;
/

-- =============================================================================
-- Procedure: list_backups
-- Purpose: List all available backups
-- =============================================================================

create or replace procedure list_backups as
begin
   dbms_output.put_line('========================================');
   dbms_output.put_line('Available Backups');
   dbms_output.put_line('========================================');
   for rec in (
      select table_name,
             substr(
                table_name,
                instr(
                   table_name,
                   '_BKP_'
                ) + 5
             ) as backup_date,
             num_rows
        from user_tables
       where table_name like '%_BKP_%'
       order by table_name
   ) loop
      dbms_output.put_line(rec.table_name
                           || ' ('
                           || nvl(
         to_char(rec.num_rows),
         'unknown'
      ) || ' rows)');
   end loop;

   dbms_output.put_line('========================================');
end list_backups;
/

-- =============================================================================
-- Procedure: cleanup_old_backups
-- Purpose: Remove backups older than specified days
-- =============================================================================

create or replace procedure cleanup_old_backups (
   p_days_to_keep in number default 7
) as
   v_cutoff_date varchar2(20);
   v_backup_date varchar2(20);
   v_count       number := 0;
   v_log_id      number;
begin
   log_process_start(
      'CLEANUP_OLD_BACKUPS',
      'MAINTENANCE',
      v_log_id
   );
   v_cutoff_date := to_char(
      sysdate - p_days_to_keep,
      'YYYYMMDD'
   );
   dbms_output.put_line('Removing backups older than '
                        || p_days_to_keep || ' days');
   dbms_output.put_line('Cutoff date: ' || v_cutoff_date);
   for rec in (
      select table_name
        from user_tables
       where table_name like '%_BKP_%'
   ) loop
        -- Extract date from backup name (format: TABLENAME_BKP_YYYYMMDD_HH24MISS)
      v_backup_date := substr(
         rec.table_name,
         instr(
              rec.table_name,
              '_BKP_'
           ) + 5,
         8
      );

      if v_backup_date < v_cutoff_date then
         dbms_output.put_line('Dropping old backup: ' || rec.table_name);
         execute immediate 'DROP TABLE '
                           || rec.table_name
                           || ' PURGE';
         v_count := v_count + 1;
      end if;
   end loop;

   dbms_output.put_line('Cleanup completed: '
                        || v_count || ' old backups removed');
   log_process_end(
      v_log_id,
      p_additional_info => v_count || ' backups removed'
   );
exception
   when others then
      dbms_output.put_line('ERROR during cleanup: ' || sqlerrm);
      log_process_error(
         v_log_id,
         sqlerrm,
         sqlcode
      );
      raise;
end cleanup_old_backups;
/

-- =============================================================================
-- Grant permissions
-- =============================================================================

grant execute on backup_table to public;
grant execute on restore_table to public;
grant execute on backup_all_tables to public;
grant execute on list_backups to public;
grant execute on cleanup_old_backups to public;

-- =============================================================================
-- Verification
-- =============================================================================

PROMPT ========================================
PROMPT Rollback Procedures Created Successfully
PROMPT ========================================
PROMPT
PROMPT Procedures created:
PROMPT   - BACKUP_TABLE
PROMPT   - RESTORE_TABLE
PROMPT   - BACKUP_ALL_TABLES
PROMPT   - LIST_BACKUPS
PROMPT   - CLEANUP_OLD_BACKUPS
PROMPT
PROMPT Usage Examples:
PROMPT
PROMPT   -- Backup all tables before ETL
PROMPT   EXEC backup_all_tables;
PROMPT
PROMPT   -- Backup specific table
PROMPT   EXEC backup_table('FACT_SALES');
PROMPT
PROMPT   -- List available backups
PROMPT   EXEC list_backups;
PROMPT
PROMPT   -- Restore from backup
PROMPT   EXEC restore_table('FACT_SALES', '20251121_143000');
PROMPT
PROMPT   -- Cleanup old backups
PROMPT   EXEC cleanup_old_backups(7);
PROMPT
PROMPT ========================================