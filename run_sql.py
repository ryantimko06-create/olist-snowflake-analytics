"""
Runs .sql files against snowflake, in filename order.

    python run_sql.py sql/staging
    python run_sql.py sql/marts
    python run_sql.py sql/marts/01_fct_orders.sql
"""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent / "load"))
from sf import get_conn  # noqa: E402


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    target = Path(sys.argv[1])
    files = sorted(target.glob("*.sql")) if target.is_dir() else [target]

    conn = get_conn(schema="PUBLIC")
    try:
        for f in files:
            print(f"running {f} ...")
            # execute_string handles files with more than one statement
            conn.execute_string(f.read_text())
    finally:
        conn.close()
    print("done")


if __name__ == "__main__":
    main()
