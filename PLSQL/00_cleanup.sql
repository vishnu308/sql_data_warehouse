-- =============================================================================
-- CLEANUP SCRIPT - Drop all Data Warehouse objects
-- =============================================================================
-- Run this script to start fresh

-- Drop Fact Table first (it has foreign keys to dimensions)
begin
   execute immediate 'DROP TABLE fact_sales CASCADE CONSTRAINTS';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

-- Drop Dimension Tables
begin
   execute immediate 'DROP TABLE dim_customer CASCADE CONSTRAINTS';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

begin
   execute immediate 'DROP TABLE dim_product CASCADE CONSTRAINTS';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

begin
   execute immediate 'DROP TABLE dim_location CASCADE CONSTRAINTS';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

begin
   execute immediate 'DROP TABLE dim_time CASCADE CONSTRAINTS';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

-- Drop Sequences
begin
   execute immediate 'DROP SEQUENCE seq_customer_key';
exception
   when others then
      if sqlcode != -2289 then
         raise;
      end if;
end;
/

begin
   execute immediate 'DROP SEQUENCE seq_product_key';
exception
   when others then
      if sqlcode != -2289 then
         raise;
      end if;
end;
/

begin
   execute immediate 'DROP SEQUENCE seq_location_key';
exception
   when others then
      if sqlcode != -2289 then
         raise;
      end if;
end;
/

begin
   execute immediate 'DROP SEQUENCE seq_sales_key';
exception
   when others then
      if sqlcode != -2289 then
         raise;
      end if;
end;
/