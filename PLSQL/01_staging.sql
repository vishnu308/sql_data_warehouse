-- =============================================================================
-- Step 1: Create Oracle Directory
-- =============================================================================
create or replace directory source_dir as 'c:\Users\Admin\OneDrive - vishnu shendge\Desktop\Data Warehouse\Dataset';
grant read,write on directory source_dir to public;

-- =============================================================================
-- Step 2: Create External Table
-- =============================================================================
-- NOTE: Columns MUST match the CSV file order EXACTLY.
-- CSV Header: Category,City,Country,Customer.ID,Customer.Name,Discount,Market,Number_of_records,Order.Date,Order.ID,Order.Priority,Product.ID,Product.Name,Profit,Quantity,Region,Row.ID,Sales,Segment,Ship.Date,Ship.Mode,Shipping.Cost,State,Sub.Category,Year,Market2,weeknum

begin
   execute immediate 'DROP TABLE staging_superstore';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

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



select *
  from staging_superstore
 where rownum <= 5;