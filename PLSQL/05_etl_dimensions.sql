-- =============================================================================
-- Complete ETL Reset and Reload
-- =============================================================================
-- Run this script to completely reset and reload all dimension data

-- Step 1: Drop everything (including fact table)
begin
   execute immediate 'DROP TABLE fact_sales CASCADE CONSTRAINTS';
exception
   when others then
      null;
end;
/
begin
   execute immediate 'DROP TABLE dim_customer CASCADE CONSTRAINTS';
exception
   when others then
      null;
end;
/
begin
   execute immediate 'DROP TABLE dim_product CASCADE CONSTRAINTS';
exception
   when others then
      null;
end;
/
begin
   execute immediate 'DROP TABLE dim_location CASCADE CONSTRAINTS';
exception
   when others then
      null;
end;
/

-- Step 2: Recreate dimension tables
create table dim_customer (
   customer_key  number primary key,
   customer_id   varchar2(50) not null unique,
   customer_name varchar2(100),
   segment       varchar2(50),
   load_date     date default sysdate
);

create table dim_product (
   product_key  number primary key,
   product_id   varchar2(50) not null unique,
   product_name varchar2(255),
   category     varchar2(50),
   sub_category varchar2(50),
   load_date    date default sysdate
);

create table dim_location (
   location_key number primary key,
   city         varchar2(100),
   state        varchar2(100),
   country      varchar2(100),
   region       varchar2(50),
   market       varchar2(50),
   load_date    date default sysdate,
   constraint uk_location unique ( city,
                                   state,
                                   country )
);

-- Step 3: Reset sequences
begin
   execute immediate 'DROP SEQUENCE seq_customer_key';
exception
   when others then
      null;
end;
/
begin
   execute immediate 'DROP SEQUENCE seq_product_key';
exception
   when others then
      null;
end;
/
begin
   execute immediate 'DROP SEQUENCE seq_location_key';
exception
   when others then
      null;
end;
/

create sequence seq_customer_key start with 1 increment by 1;
create sequence seq_product_key start with 1 increment by 1;
create sequence seq_location_key start with 1 increment by 1;

-- Step 4: Populate dimensions
insert into dim_customer (
   customer_key,
   customer_id,
   customer_name,
   segment
)
   select seq_customer_key.nextval,
          customer_id,
          customer_name,
          segment
     from (
      select distinct customer_id,
                      customer_name,
                      segment
        from staging_superstore
       where customer_id is not null
   );

-- Use ROW_NUMBER to handle duplicate product_ids
insert into dim_product (
   product_key,
   product_id,
   product_name,
   category,
   sub_category
)
   select seq_product_key.nextval,
          product_id,
          product_name,
          category,
          sub_category
     from (
      select product_id,
             product_name,
             category,
             sub_category
        from (
         select product_id,
                product_name,
                category,
                sub_category,
                row_number()
                over(partition by product_id
                     order by product_name
                ) as rn
           from staging_superstore
          where product_id is not null
      )
       where rn = 1
   );

-- Use ROW_NUMBER to handle duplicate locations
insert into dim_location (
   location_key,
   city,
   state,
   country,
   region,
   market
)
   select seq_location_key.nextval,
          city,
          state,
          country,
          region,
          market
     from (
      select city,
             state,
             country,
             region,
             market
        from (
         select city,
                state,
                country,
                region,
                market,
                row_number()
                over(partition by city,
                                  state,
                                  country
                     order by city
                ) as rn
           from staging_superstore
          where city is not null
      )
       where rn = 1
   );

commit;

-- Step 5: Verify
select 'DIM_CUSTOMER' as table_name,
       count(*) as row_count
  from dim_customer
union all
select 'DIM_PRODUCT',
       count(*)
  from dim_product
union all
select 'DIM_LOCATION',
       count(*)
  from dim_location
union all
select 'DIM_TIME',
       count(*)
  from dim_time;