"""
Uploads the olist csvs to the internal stage and copies them into the raw tables.

run sql/00_setup.sql and sql/01_raw_tables.sql before running this


    python load/load_raw.py (table name) for specific tables
"""
import sys
from pathlib import Path

from sf import get_conn

DATA_DIR = Path(__file__).resolve().parent.parent / "data"

# raw table -> csv
FILES = {
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "customers": "olist_customers_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}


def load_table(cur, table, fname):
    path = DATA_DIR / fname #establish path
    if not path.exists():
        print(f"!! {fname} skipped/, not found")
        return

    # as_posix because PUT doesn't like windows backslashes, connector intercepts and streams
    #internal stage @olist_stage
    #gzips --> .gz landing
    #overwrite = true to avoid memory error
    cur.execute(f"put file://{path.as_posix()} @olist_stage auto_compress=true overwrite=true")

    # truncate so rerunning doesn't double everything

    """
    notes for learning
    truncate to avoid DELETE FROM on other single row, avoid errors on re-run
    """
    cur.execute(f"truncate table {table}")
    cur.execute(
        f"""
        copy into {table}
        from @olist_stage/{fname}.gz
        file_format = (format_name = 'csv_fmt')
        on_error = 'abort_statement'
        """
    )
    n = cur.execute(f"select count(*) from {table}").fetchone()[0]
    print(f"{table:<22} {n:>9,} rows") #format table name left align, number of rows right with commas


def main():
    only = sys.argv[1:] #if specifics (line 2)

    #conn = only.co

    conn = get_conn() #establish connection
    cur = conn.cursor() #establish cursor
    try:
        for table, fname in FILES.items():
            if only and table not in only:
                continue
            load_table(cur, table, fname)
    finally: #unconditional
        cur.close()
        conn.close()

    #with get_conn() as conn, conn.cursor() as cur:
    #for table, fname in FILES.items():
    #    if only and table not in only:
    #        continue
    #    load_table(cur, table, fname)


if __name__ == "__main__":
    main()
