-- one row per real customer (customer_unique_id)
-- built from fct_orders, so it has to run after it (hence the number prefixes)
create or replace table marts.dim_customers as
select
    customer_unique_id,
    min(purchased_at)                    as first_order_at,
    date_trunc('month', min(purchased_at)) as cohort_month,
    max(purchased_at)                    as last_order_at,
    count(*)                             as n_orders,
    sum(order_total)                     as total_spent,
    max_by(customer_state, purchased_at) as state,       -- state on their latest order
    count(*) > 1                         as is_repeat
from marts.fct_orders
where order_status not in ('canceled', 'unavailable') -- take out edge 
group by 1;
