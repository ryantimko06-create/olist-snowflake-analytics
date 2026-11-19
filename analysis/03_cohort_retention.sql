-- Q: do customers come back?
-- monthly cohorts by first purchase, % of the cohort ordering again N months later
--
-- has to be customer_unique_id. customer_id is per order in this dataset,
-- so grouping on it makes every customer look like a one-time buyer.

with orders as (
    select
        o.customer_unique_id,
        c.cohort_month,
        datediff('month', c.cohort_month, o.order_month) as month_number
    from marts.fct_orders o
    join marts.dim_customers c
        on o.customer_unique_id = c.customer_unique_id
    where o.order_status not in ('canceled', 'unavailable')
),

cohort_size as (
    select cohort_month, count(*) as cohort_customers
    from marts.dim_customers
    group by 1
)

select
    o.cohort_month,
    s.cohort_customers,
    o.month_number,
    count(distinct o.customer_unique_id) as active_customers,
    round(100.0 * count(distinct o.customer_unique_id) / s.cohort_customers, 2) as retention_pct
from orders o
join cohort_size s on o.cohort_month = s.cohort_month
where o.cohort_month >= '2017-01-01'
  and o.month_number between 0 and 12
group by 1, 2, 3
order by 1, 3;


-- the short version: overall repeat rate
select
    count(*)                                         as customers,
    count_if(is_repeat)                              as repeat_customers,
    round(100.0 * count_if(is_repeat) / count(*), 2) as repeat_pct
from marts.dim_customers;
