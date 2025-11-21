-- =============================================================================
-- ETL Script 1: Populate DIM_TIME (Calendar Table)
-- =============================================================================
-- This script generates one row for each day from 2011-01-01 to 2014-12-31

declare
   v_start_date   date := to_date ( '2011-01-01','YYYY-MM-DD' );
   v_end_date     date := to_date ( '2014-12-31','YYYY-MM-DD' );
   v_current_date date;
begin
    -- Start from the first date
   v_current_date := v_start_date;
    
    -- Loop through each day
   while v_current_date <= v_end_date loop
      insert into dim_time (
         date_key,
         full_date,
         year,
         quarter,
         month,
         month_name,
         week_of_year,
         day_of_month,
         day_of_week,
         day_name,
         is_weekend
      ) values (
            -- date_key: Format as YYYYMMDD (e.g., 20111215)
       to_number(to_char(
         v_current_date,
         'YYYYMMDD'
      )),
            
            -- full_date: The actual date
                 v_current_date,
            
            -- year: Extract year (e.g., 2011)
                 to_number(to_char(
                    v_current_date,
                    'YYYY'
                 )),
            
            -- quarter: Extract quarter (1, 2, 3, 4)
                 to_number(to_char(
                    v_current_date,
                    'Q'
                 )),
            
            -- month: Extract month number (1-12)
                 to_number(to_char(
                    v_current_date,
                    'MM'
                 )),
            
            -- month_name: Extract month name (January, February, etc.)
                 trim(to_char(
                    v_current_date,
                    'Month'
                 )),
            
            -- week_of_year: ISO week number (1-53)
                 to_number(to_char(
                    v_current_date,
                    'IW'
                 )),
            
            -- day_of_month: Day number in month (1-31)
                 to_number(to_char(
                    v_current_date,
                    'DD'
                 )),
            
            -- day_of_week: Day number in week (1=Sunday, 7=Saturday)
                 to_number(to_char(
                    v_current_date,
                    'D'
                 )),
            
            -- day_name: Day name (Monday, Tuesday, etc.)
                 trim(to_char(
                    v_current_date,
                    'Day'
                 )),
            
            -- is_weekend: 'Y' if Saturday or Sunday, 'N' otherwise
                 case
                    when to_char(
                       v_current_date,
                       'D'
                    ) in ( '1',
                           '7' ) then
                       'Y'
                    else
                       'N'
                 end
      );
        
        -- Move to the next day
      v_current_date := v_current_date + 1;
   end loop;

   commit;
   dbms_output.put_line('DIM_TIME populated successfully!');
   dbms_output.put_line('Total rows inserted: ' || sql%rowcount);
end;
/

-- Verify the data
select count(*) as total_days
  from dim_time;

-- Show a sample of the data
select *
  from dim_time
 where rownum <= 10
 order by full_date;