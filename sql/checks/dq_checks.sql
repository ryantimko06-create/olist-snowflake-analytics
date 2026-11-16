-- sanity checks i ran after loading. not automated, just paste into a worksheet.
-- every query should return 0 rows / 0 unless the comment says otherwise

-- 1. primary keys
select 'orders' as tbl, count(*) - count(distinct order_id) as dupes from raw.orders
union all
select 'customers', count(*) - count(distinct customer_id) from raw.customers
union all
select 'products', count(*) - count(distinct product_id) from raw.products
union all
select 'sellers', count(*) - count(distinct seller_id) from raw.sellers
union all
-- this one is NOT 0 so that's why stg_reviews dedupes
select 'reviews', count(*) - count(distinct review_id) from raw.order_reviews;

-- after dedupe: one review per order
select order_id, count(*)
from staging.stg_reviews
group by 1
having count(*) > 1;

-- orphan
select count(*) as items_without_order
from staging.stg_order_items i
left join staging.stg_orders o on i.order_id = o.order_id
where o.order_id is null;

select count(*) as orders_without_customer
from staging.stg_orders o
left join staging.stg_customers c on o.customer_id = c.customer_id
where c.customer_id is null;

-- delivered orders with no delivery date (there are a few, not 0)
select count(*)
from staging.stg_orders
where order_status = 'delivered'
  and delivered_at is null;

-- timestamps in the wrong order
select count(*)
from staging.stg_orders
where delivered_at < purchased_at;

--  orders with no items at all (mostly canceled / unavailable, expected)
select o.order_status, count(*) as n
from staging.stg_orders o
left join staging.stg_order_items i on o.order_id = i.order_id
where i.order_id is null
group by 1
order by 2 desc;

-- 7does what the customer paid match items + freight?
-- not always - TODO look at the mismatches properly (installment interest? vouchers?)
select count(*) as orders_off_by_more_than_1
from (
    select order_id, sum(price + freight_value) as items_total
    from staging.stg_order_items
    group by 1
) i
join (
    select order_id, sum(payment_value) as paid
    from staging.stg_payments
    group by 1
) p on i.order_id = p.order_id
where abs(i.items_total - p.paid) > 1;

-- 8. row counts by status, just to know what's in there
select order_status, count(*) from staging.stg_orders group by 1 order by 2 desc;

-- thanks jared for the SQL help!
