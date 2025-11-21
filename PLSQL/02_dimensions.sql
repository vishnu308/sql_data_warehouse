-- =============================================================================
-- DIMENSION TABLES - Data Warehouse Schema
-- =============================================================================
-- These tables store the descriptive attributes (Who, What, Where, When)
-- Each dimension has a surrogate key (auto-generated integer) as the primary key

-- =============================================================================
-- 1. DIM_CUSTOMER - Who bought?
-- =============================================================================
-- Drop if exists
begin
   execute immediate 'DROP TABLE dim_customer';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

begin
   execute immediate 'DROP SEQUENCE seq_customer_key';
exception
   when others then
      if sqlcode != -2289 then
         raise;
      end if;
end;
/

create table dim_customer (
   customer_key  number primary key,
   customer_id   varchar2(50) not null unique,
   customer_name varchar2(100),
   segment       varchar2(50),
   load_date     date default sysdate
);

-- Sequence to auto-generate customer_key values
create sequence seq_customer_key start with 1 increment by 1;

-- =============================================================================
-- 2. DIM_PRODUCT - What was sold?
-- =============================================================================
-- Drop if exists
begin
   execute immediate 'DROP TABLE dim_product';
exception
   when others then
      if sqlcode != -942 then
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

create table dim_product (
   product_key  number primary key,
   product_id   varchar2(50) not null unique,
   product_name varchar2(255),
   category     varchar2(50),
   sub_category varchar2(50),
   load_date    date default sysdate
);

-- Sequence to auto-generate product_key values
create sequence seq_product_key start with 1 increment by 1;

-- =============================================================================
-- 3. DIM_LOCATION - Where was it sold?
-- =============================================================================
-- Drop if exists
begin
   execute immediate 'DROP TABLE dim_location';
exception
   when others then
      if sqlcode != -942 then
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

create table dim_location (
   location_key number primary key,
   city         varchar2(100),
   state        varchar2(100),
   country      varchar2(100),
   region       varchar2(50),
   market       varchar2(50),
   load_date    date default sysdate,
    -- Composite unique constraint (same city+state+country = same location)
   constraint uk_location unique ( city,
                                   state,
                                   country )
);

-- Sequence to auto-generate location_key values
create sequence seq_location_key start with 1 increment by 1;

-- =============================================================================
-- 4. DIM_TIME - When did it happen?
-- =============================================================================
-- Drop if exists
begin
   execute immediate 'DROP TABLE dim_time';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

-- This is a "Calendar Table" with one row per day
create table dim_time (
   date_key     number primary key,     -- Format: YYYYMMDD (e.g., 20111215)
   full_date    date not null unique,
   year         number(4),
   quarter      number(1),
   month        number(2),
   month_name   varchar2(10),
   week_of_year number(2),
   day_of_month number(2),
   day_of_week  number(1),
   day_name     varchar2(10),
   is_weekend   char(1),                -- 'Y' or 'N'
   load_date    date default sysdate
);

-- Note: We will populate DIM_TIME with a script (not a sequence)
-- because we need to generate all dates from 2011-2014