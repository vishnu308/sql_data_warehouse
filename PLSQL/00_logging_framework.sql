-- =============================================================================
-- Logging Framework
-- =============================================================================
-- Purpose: Provides centralized logging infrastructure for ETL processes
-- Author: Data Warehouse Team
-- Version: 1.0.0
-- Created: 2025-11-21
--
-- Description:
--   This script creates the logging infrastructure used by all ETL processes.
--   It provides procedures to log execution start, end, errors, and metrics.
--
-- Dependencies: None (must be run first)
-- =============================================================================

SET SERVEROUTPUT ON
SET ECHO ON

PROMPT ========================================
PROMPT Creating Logging Framework
PROMPT ========================================

-- =============================================================================
-- Drop existing logging objects if they exist
-- =============================================================================

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE etl_log PURGE';
   DBMS_OUTPUT.PUT_LINE('Dropped existing ETL_LOG table');
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
      DBMS_OUTPUT.PUT_LINE('ETL_LOG table does not exist, creating new');
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE etl_log_seq';
   DBMS_OUTPUT.PUT_LINE('Dropped existing ETL_LOG_SEQ sequence');
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -2289 THEN
         RAISE;
      END IF;
      DBMS_OUTPUT.PUT_LINE('ETL_LOG_SEQ sequence does not exist, creating new');
END;
/

-- =============================================================================
-- Create ETL Log Table
-- =============================================================================

CREATE TABLE etl_log (
    log_id          NUMBER PRIMARY KEY,
    process_name    VARCHAR2(100) NOT NULL,
    process_type    VARCHAR2(50),           -- ETL, VALIDATION, DEPLOYMENT, etc.
    status          VARCHAR2(20) NOT NULL,  -- STARTED, RUNNING, SUCCESS, ERROR, ABORTED
    start_time      TIMESTAMP NOT NULL,
    end_time        TIMESTAMP,
    duration_sec    NUMBER,
    rows_processed  NUMBER DEFAULT 0,
    rows_inserted   NUMBER DEFAULT 0,
    rows_updated    NUMBER DEFAULT 0,
    rows_deleted    NUMBER DEFAULT 0,
    rows_rejected   NUMBER DEFAULT 0,
    error_message   VARCHAR2(4000),
    error_code      VARCHAR2(20),
    additional_info VARCHAR2(4000),
    created_by      VARCHAR2(100) DEFAULT USER,
    created_date    DATE DEFAULT SYSDATE
);

COMMENT ON TABLE etl_log IS 'Centralized logging table for all ETL processes';
COMMENT ON COLUMN etl_log.log_id IS 'Unique identifier for each log entry';
COMMENT ON COLUMN etl_log.process_name IS 'Name of the ETL process or script';
COMMENT ON COLUMN etl_log.process_type IS 'Type of process: ETL, VALIDATION, DEPLOYMENT';
COMMENT ON COLUMN etl_log.status IS 'Current status: STARTED, RUNNING, SUCCESS, ERROR, ABORTED';
COMMENT ON COLUMN etl_log.rows_processed IS 'Total number of rows processed';
COMMENT ON COLUMN etl_log.rows_rejected IS 'Number of rows rejected due to errors';

-- Create sequence for log_id
CREATE SEQUENCE etl_log_seq START WITH 1 INCREMENT BY 1 NOCACHE;

-- Create index for common queries
CREATE INDEX idx_etl_log_process ON etl_log(process_name, start_time);
CREATE INDEX idx_etl_log_status ON etl_log(status, start_time);

PROMPT ETL_LOG table created successfully

-- =============================================================================
-- Logging Procedures
-- =============================================================================

-- Procedure: log_process_start
-- Purpose: Log the start of an ETL process
CREATE OR REPLACE PROCEDURE log_process_start (
    p_process_name  IN VARCHAR2,
    p_process_type  IN VARCHAR2 DEFAULT 'ETL',
    p_log_id        OUT NUMBER
) AS
BEGIN
    INSERT INTO etl_log (
        log_id,
        process_name,
        process_type,
        status,
        start_time
    ) VALUES (
        etl_log_seq.NEXTVAL,
        p_process_name,
        p_process_type,
        'STARTED',
        SYSTIMESTAMP
    ) RETURNING log_id INTO p_log_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Process started: ' || p_process_name || ' (Log ID: ' || p_log_id || ')');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in log_process_start: ' || SQLERRM);
        RAISE;
END log_process_start;
/

-- Procedure: log_process_end
-- Purpose: Log the successful completion of an ETL process
CREATE OR REPLACE PROCEDURE log_process_end (
    p_log_id            IN NUMBER,
    p_rows_processed    IN NUMBER DEFAULT 0,
    p_rows_inserted     IN NUMBER DEFAULT 0,
    p_rows_updated      IN NUMBER DEFAULT 0,
    p_rows_deleted      IN NUMBER DEFAULT 0,
    p_rows_rejected     IN NUMBER DEFAULT 0,
    p_additional_info   IN VARCHAR2 DEFAULT NULL
) AS
    v_start_time TIMESTAMP;
    v_duration   NUMBER;
BEGIN
    -- Get start time to calculate duration
    SELECT start_time INTO v_start_time
    FROM etl_log
    WHERE log_id = p_log_id;
    
    -- Calculate duration in seconds
    v_duration := EXTRACT(DAY FROM (SYSTIMESTAMP - v_start_time)) * 86400 +
                  EXTRACT(HOUR FROM (SYSTIMESTAMP - v_start_time)) * 3600 +
                  EXTRACT(MINUTE FROM (SYSTIMESTAMP - v_start_time)) * 60 +
                  EXTRACT(SECOND FROM (SYSTIMESTAMP - v_start_time));
    
    UPDATE etl_log
    SET status = 'SUCCESS',
        end_time = SYSTIMESTAMP,
        duration_sec = v_duration,
        rows_processed = p_rows_processed,
        rows_inserted = p_rows_inserted,
        rows_updated = p_rows_updated,
        rows_deleted = p_rows_deleted,
        rows_rejected = p_rows_rejected,
        additional_info = p_additional_info
    WHERE log_id = p_log_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Process completed successfully (Log ID: ' || p_log_id || ')');
    DBMS_OUTPUT.PUT_LINE('Duration: ' || ROUND(v_duration, 2) || ' seconds');
    DBMS_OUTPUT.PUT_LINE('Rows processed: ' || p_rows_processed);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in log_process_end: ' || SQLERRM);
        RAISE;
END log_process_end;
/

-- Procedure: log_process_error
-- Purpose: Log an error in an ETL process
CREATE OR REPLACE PROCEDURE log_process_error (
    p_log_id        IN NUMBER,
    p_error_message IN VARCHAR2,
    p_error_code    IN VARCHAR2 DEFAULT NULL
) AS
    v_start_time TIMESTAMP;
    v_duration   NUMBER;
BEGIN
    -- Get start time to calculate duration
    SELECT start_time INTO v_start_time
    FROM etl_log
    WHERE log_id = p_log_id;
    
    -- Calculate duration in seconds
    v_duration := EXTRACT(DAY FROM (SYSTIMESTAMP - v_start_time)) * 86400 +
                  EXTRACT(HOUR FROM (SYSTIMESTAMP - v_start_time)) * 3600 +
                  EXTRACT(MINUTE FROM (SYSTIMESTAMP - v_start_time)) * 60 +
                  EXTRACT(SECOND FROM (SYSTIMESTAMP - v_start_time));
    
    UPDATE etl_log
    SET status = 'ERROR',
        end_time = SYSTIMESTAMP,
        duration_sec = v_duration,
        error_message = SUBSTR(p_error_message, 1, 4000),
        error_code = p_error_code
    WHERE log_id = p_log_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Process failed with error (Log ID: ' || p_log_id || ')');
    DBMS_OUTPUT.PUT_LINE('Error: ' || p_error_message);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in log_process_error: ' || SQLERRM);
        -- Don't raise here to avoid masking the original error
END log_process_error;
/

-- Procedure: log_progress
-- Purpose: Update progress of a running ETL process
CREATE OR REPLACE PROCEDURE log_progress (
    p_log_id            IN NUMBER,
    p_rows_processed    IN NUMBER,
    p_additional_info   IN VARCHAR2 DEFAULT NULL
) AS
BEGIN
    UPDATE etl_log
    SET status = 'RUNNING',
        rows_processed = p_rows_processed,
        additional_info = p_additional_info
    WHERE log_id = p_log_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Progress update (Log ID: ' || p_log_id || '): ' || p_rows_processed || ' rows processed');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in log_progress: ' || SQLERRM);
        -- Don't raise to avoid interrupting the ETL process
END log_progress;
/

-- =============================================================================
-- Utility Views
-- =============================================================================

-- View: Recent ETL executions
CREATE OR REPLACE VIEW v_etl_log_recent AS
SELECT 
    log_id,
    process_name,
    process_type,
    status,
    start_time,
    end_time,
    ROUND(duration_sec, 2) as duration_sec,
    rows_processed,
    rows_inserted,
    rows_updated,
    rows_rejected,
    error_message,
    created_by
FROM etl_log
WHERE start_time >= SYSDATE - 7  -- Last 7 days
ORDER BY start_time DESC;

COMMENT ON VIEW v_etl_log_recent IS 'Recent ETL executions (last 7 days)';

-- View: ETL execution summary
CREATE OR REPLACE VIEW v_etl_summary AS
SELECT 
    process_name,
    process_type,
    COUNT(*) as total_executions,
    SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) as successful,
    SUM(CASE WHEN status = 'ERROR' THEN 1 ELSE 0 END) as failed,
    ROUND(AVG(duration_sec), 2) as avg_duration_sec,
    MAX(start_time) as last_execution,
    SUM(rows_processed) as total_rows_processed
FROM etl_log
GROUP BY process_name, process_type
ORDER BY last_execution DESC;

COMMENT ON VIEW v_etl_summary IS 'Summary statistics for all ETL processes';

-- =============================================================================
-- Grant permissions (adjust as needed for your environment)
-- =============================================================================

-- Grant execute on procedures to public (modify for production)
GRANT EXECUTE ON log_process_start TO PUBLIC;
GRANT EXECUTE ON log_process_end TO PUBLIC;
GRANT EXECUTE ON log_process_error TO PUBLIC;
GRANT EXECUTE ON log_progress TO PUBLIC;

-- Grant select on views
GRANT SELECT ON v_etl_log_recent TO PUBLIC;
GRANT SELECT ON v_etl_summary TO PUBLIC;

-- =============================================================================
-- Verification
-- =============================================================================

PROMPT ========================================
PROMPT Logging Framework Created Successfully
PROMPT ========================================
PROMPT
PROMPT Objects created:
PROMPT   - Table: ETL_LOG
PROMPT   - Sequence: ETL_LOG_SEQ
PROMPT   - Procedure: LOG_PROCESS_START
PROMPT   - Procedure: LOG_PROCESS_END
PROMPT   - Procedure: LOG_PROCESS_ERROR
PROMPT   - Procedure: LOG_PROGRESS
PROMPT   - View: V_ETL_LOG_RECENT
PROMPT   - View: V_ETL_SUMMARY
PROMPT
PROMPT Usage Example:
PROMPT   DECLARE
PROMPT     v_log_id NUMBER;
PROMPT   BEGIN
PROMPT     log_process_start('MY_ETL_PROCESS', 'ETL', v_log_id);
PROMPT     -- Your ETL logic here
PROMPT     log_process_end(v_log_id, p_rows_processed => 1000);
PROMPT   EXCEPTION
PROMPT     WHEN OTHERS THEN
PROMPT       log_process_error(v_log_id, SQLERRM, SQLCODE);
PROMPT       RAISE;
PROMPT   END;
PROMPT ========================================
