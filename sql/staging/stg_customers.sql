-- IMPORTANT: customer_id is generated per ORDER. the actual person is customer_unique_id.
-- anything about repeat purchases has to use customer_unique_id
create or replace view staging.stg_customers as
select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix as zip_prefix,
    customer_city            as city,
    upper(customer_state)    as state
from raw.customers;
