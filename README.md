# olist-snowflake-analytics

Analysis of the Olist brazilian e-commerce dataset (~100k orders, 2016-2018) in Snowflake.

Still WIP. Data is loaded and modeled, analysis queries are next.


## how to run

1. get the data, see `data/README.md`
2. run `sql/00_setup.sql` then `sql/01_raw_tables.sql` in a snowsight worksheet
3. `pip install -r requirements.txt`, copy `.env.example` to `.env` and fill it in
4. load + build:

```
python load/load_raw.py
python run_sql.py sql/staging
python run_sql.py sql/marts
```

`sql/checks/dq_checks.sql` has the tests i ran after loading. completely optional though.
