"""
Runs the whole project locally in DuckDB, no Snowflake needed.

    pip install duckdb
    python local_test.py

Loads data/*.csv into an in-memory duckdb, builds the staging views and the
marts, then runs every query in analysis/ and prints the results.

It is a smoke test for the SQL, not a replacement for Snowflake: it rewrites
the raw DDL's snowflake types (timestamp_ntz, number) into duckdb ones. The
staging / marts / analysis sql runs unchanged.
"""
import re
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data"

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


def snowflake_to_duckdb(ddl: str) -> str:
    ddl = ddl.replace("timestamp_ntz", "timestamp")
    ddl = re.sub(r"number\(\s*\d+\s*,\s*\d+\s*\)", "decimal(18,2)", ddl, flags=re.I)
    ddl = re.sub(r"\bnumber\b", "bigint", ddl, flags=re.I)
    ddl = re.sub(r"^\s*use\s+.*?;\s*$", "", ddl, flags=re.I | re.M)
    return ddl


def split_statements(sql: str):
    out = []
    for stmt in sql.split(";"):
        body = "\n".join(
            line for line in stmt.splitlines() if line.strip() and not line.strip().startswith("--")
        )
        if body.strip():
            out.append(stmt)
    return out


def run_file(con, path: Path, show=False):
    for stmt in split_statements(path.read_text()):
        try:
            res = con.execute(stmt)
        except Exception as e:
            print(f"\n!! {path.name} failed:\n{stmt.strip()[:300]}\n   {e}\n")
            continue
        if show and res.description:
            df = res.df()
            if len(df):
                print(df.to_string(index=False, max_rows=25))
                print()


def main():
    missing = [f for f in FILES.values() if not (DATA / f).exists()]
    if missing:
        print("missing csvs in data/ :")
        for f in missing:
            print("  ", f)
        sys.exit(1)

    con = duckdb.connect()
    for s in ("raw", "staging", "marts"):
        con.execute(f"create schema if not exists {s}")

    print("== loading csvs ==")
    con.execute("use raw")
    con.execute(snowflake_to_duckdb((ROOT / "sql" / "01_raw_tables.sql").read_text()))
    con.execute("use memory.main")

    for table, fname in FILES.items():
        con.execute(
            f"""
            insert into raw.{table}
            select * from read_csv('{(DATA / fname).as_posix()}',
                                   header=true, all_varchar=true, nullstr='')
            """
        )
        n = con.execute(f"select count(*) from raw.{table}").fetchone()[0]
        print(f"{table:<22} {n:>9,} rows")

    print("\n== staging ==")
    for f in sorted((ROOT / "sql" / "staging").glob("*.sql")):
        run_file(con, f)
        print(" ", f.name)

    print("\n== marts ==")
    for f in sorted((ROOT / "sql" / "marts").glob("*.sql")):
        run_file(con, f)
        n = con.execute(f"select count(*) from marts.{f.stem.split('_', 1)[-1]}").fetchone()[0]
        print(f"  {f.name:<26} {n:>8,} rows")

    checks = ROOT / "sql" / "checks" / "dq_checks.sql"
    if checks.exists():
        print("\n== dq checks ==")
        run_file(con, checks, show=True)

    analysis = ROOT / "analysis"
    if analysis.exists():
        for f in sorted(analysis.glob("*.sql")):
            print(f"\n== {f.name} ==")
            run_file(con, f, show=True)

    if (analysis / "make_charts.py").exists() and "--charts" in sys.argv:
        print("\n== charts ==")
        sys.path.insert(0, str(analysis))
        import make_charts as mc

        mc.IMG.mkdir(exist_ok=True)
        mc.chart_monthly(con.execute(mc.Q_MONTHLY).df())
        mc.chart_delay(con.execute(mc.Q_DELAY).df())
        mc.chart_cohort(con.execute(mc.Q_COHORT).df())
        print(f"  wrote pngs to {mc.IMG}")

    print("done")


if __name__ == "__main__":
    main()
