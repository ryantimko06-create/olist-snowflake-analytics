"""
Dumps the marts to csv for tableau.

    python analysis/export_for_tableau.py

Tableau Public can't connect to a database - it only reads files - so the
workflow is: model in snowflake, export here, point tableau at exports/.

Writes three files. orders.csv covers most of the dashboard on its own;
the other two are there for the category / seller and segment views.
exports/ is gitignored.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXPORTS = ROOT / "exports"

# the delivery bucket is done here rather than in tableau so the sql stays the
# single source of truth - same CASE as 02_delivery_vs_reviews.sql
ORDERS = """
select
    order_id,
    customer_unique_id,
    customer_state,
    order_status,
    purchased_at,
    order_month,
    delivered_at,
    estimated_delivery_at,
    n_items,
    n_sellers,
    items_total,
    freight_total,
    order_total,
    payment_total,
    main_payment_type,
    installments,
    days_to_deliver,
    days_promised,
    days_late,
    is_late,
    review_score,
    case
        when days_late is null then null
        when days_late <= -7 then '1. 7+ days early'
        when days_late <   0 then '2. 1-6 days early'
        when days_late =   0 then '3. on the day'
        when days_late <=  3 then '4. 1-3 days late'
        when days_late <=  7 then '5. 4-7 days late'
        else                      '6. 8+ days late'
    end as delivery_bucket
from marts.fct_orders
"""

ITEMS = """
select
    order_id,
    item_number,
    product_id,
    category,
    seller_id,
    seller_state,
    customer_state,
    same_state,
    order_status,
    order_month,
    price,
    freight_value,
    is_late,
    review_score
from marts.fct_order_items
"""

CUSTOMERS = """
select
    customer_unique_id,
    state,
    cohort_month,
    first_order_at,
    last_order_at,
    n_orders,
    total_spent,
    is_repeat
from marts.dim_customers
"""

TABLES = {
    "orders": ORDERS,
    "order_items": ITEMS,
    "customers": CUSTOMERS,
}


def main():
    sys.path.append(str(ROOT / "load"))
    from sf import get_conn

    EXPORTS.mkdir(exist_ok=True)
    conn = get_conn(schema="MARTS")
    try:
        for name, sql in TABLES.items():
            cur = conn.cursor()
            try:
                df = cur.execute(sql).fetch_pandas_all() #get everything
            finally:
                cur.close()
            df.columns = [c.lower() for c in df.columns]
            out = EXPORTS / f"{name}.csv"
            df.to_csv(out, index=False)
            print(f"{name:<14} {len(df):>9,} rows  ->  {out.relative_to(ROOT)}")
    finally:
        conn.close()

    print("\nopen tableau -> connect -> text file -> pick exports/orders.csv")


if __name__ == "__main__":
    main()
