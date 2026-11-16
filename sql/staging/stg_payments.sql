-- an order can have several payment rows (e.g. voucher + credit card)
create or replace view staging.stg_payments as
select
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
from raw.order_payments
where payment_type <> 'not_defined';   -- a handful of rows, all payment_value 0
