-- Q: how did revenue / orders / AOV move month to month?
-- revenue = items + freight, excluding canceled + unavailable orders
--
-- the first few months (2016) and the last ones (sep-oct 2018) only have a handful of orders,
-- looks like the extract was cut off, so i limit to jan 2017 - aug 2018

with monthly as (
    select
        order_month,
        count(*)                          as orders,
        count(distinct customer_unique_id) as customers,
        sum(order_total)                  as revenue,
        round(avg(order_total), 2)        as aov
    from marts.fct_orders
    where order_status not in ('canceled', 'unavailable')
      and order_month >= '2017-01-01'
      and order_month <  '2018-09-01'
    group by 1
)

select
    order_month,
    orders,
    customers,
    revenue,
    aov,
    round(100.0 * (revenue - lag(revenue) over (order by order_month))
          / nullif(lag(revenue) over (order by order_month), 0), 1) as revenue_mom_pct
from monthly
order by order_month;
