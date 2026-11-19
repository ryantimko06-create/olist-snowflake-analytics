"""
Pulls a few result sets from the marts and saves charts to img/.

    python analysis/make_charts.py
    python analysis/make_charts.py --csv     # also dump the dataframes to exports/ (for tableau)
"""



import sys
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
IMG = ROOT / "img"
EXPORTS = ROOT / "exports"

Q_MONTHLY = """
select order_month, count(*) as orders, sum(order_total) as revenue
from marts.fct_orders
where order_status not in ('canceled', 'unavailable')
  and order_month >= '2017-01-01' and order_month < '2018-09-01'
group by 1 order by 1
"""

Q_DELAY = """
select
    case
        when days_late <= -7 then '7+ early'
        when days_late <   0 then '1-6 early'
        when days_late =   0 then 'on the day'
        when days_late <=  3 then '1-3 late'
        when days_late <=  7 then '4-7 late'
        else                      '8+ late'
    end as bucket,
    min(days_late) as sort_key,
    count(*) as orders,
    avg(review_score) as avg_review
from marts.fct_orders
where order_status = 'delivered' and delivered_at is not null and review_score is not null
group by 1 order by 2
"""

Q_COHORT = """
select
    c.cohort_month,
    datediff('month', c.cohort_month, o.order_month) as month_number,
    count(distinct o.customer_unique_id) as customers
from marts.fct_orders o
join marts.dim_customers c on o.customer_unique_id = c.customer_unique_id
where o.order_status not in ('canceled', 'unavailable')
  and c.cohort_month >= '2017-01-01' and c.cohort_month < '2018-03-01'
group by 1, 2
"""


def fetch(conn, sql):
    cur = conn.cursor()
    try:
        df = cur.execute(sql).fetch_pandas_all()
    finally:
        cur.close()
    # snowflake gives back UPPERCASE column names, and numbers as Decimal sometimes... so I accounted for that
    df.columns = [c.lower() for c in df.columns]
    for col in df.columns:
        if df[col].dtype == object:
            try:
                df[col] = pd.to_numeric(df[col])
            except (ValueError, TypeError):
                pass
    return df


def chart_monthly(df):
    df["order_month"] = pd.to_datetime(df["order_month"])
    fig, ax = plt.subplots(figsize=(9, 4))
    ax.plot(df["order_month"], df["revenue"] / 1000, marker="o", color="#2a6f97")
    ax.set_title("Monthly revenue (R$ thousands)") 
    ax.set_ylabel("R$ k")
    ax.set_ylim(bottom=0)
    ax.grid(axis="y", alpha=0.3)
    ax.spines[["top", "right"]].set_visible(False)
    fig.autofmt_xdate()
    fig.tight_layout()
    fig.savefig(IMG / "monthly_revenue.png", dpi=150)
    plt.close(fig)


def chart_delay(df): #pandas dataframe
    fig, ax = plt.subplots(figsize=(8, 4))
    colors = ["#c1121f" if "late" in b else "#2a6f97" for b in df["bucket"]]
    bars = ax.bar(df["bucket"], df["avg_review"], color=colors)
    ax.bar_label(bars, fmt="%.2f")
    ax.set_ylim(0, 5.5)
    ax.set_title("Avg review score by delivery vs. estimated date")
    ax.set_ylabel("avg review (1-5)")
    ax.set_xlabel("days relative to estimate")
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    fig.savefig(IMG / "review_by_delay.png", dpi=150)
    plt.close(fig)


def chart_cohort(df): #pandas dataframe
    df["cohort_month"] = pd.to_datetime(df["cohort_month"])
    pivot = df.pivot(index="cohort_month", columns="month_number", values="customers")
    pct = pivot.div(pivot[0], axis=0) * 100
    # month 0 is always 100% and kills the color scale, so drop it. first 6 months is enough
    pct = pct.loc[:, [m for m in pct.columns if 1 <= m <= 6]]

    fig, ax = plt.subplots(figsize=(8, 6))
    im = ax.imshow(pct.values, cmap="Blues", aspect="auto")
    ax.set_xticks(range(len(pct.columns)))
    ax.set_xticklabels(pct.columns)
    ax.set_yticks(range(len(pct.index)))
    ax.set_yticklabels([d.strftime("%Y-%m") for d in pct.index])
    ax.set_xlabel("months since first order")
    ax.set_title("% of cohort ordering again")
    vmax = pct.max().max()
    for i in range(pct.shape[0]):
        for j in range(pct.shape[1]):
            v = pct.iat[i, j]
            if pd.notna(v):
                ax.text(j, i, f"{v:.1f}", ha="center", va="center", fontsize=8,
                        color="white" if v > vmax * 0.6 else "black")
    fig.colorbar(im, ax=ax, label="%")
    fig.tight_layout()
    fig.savefig(IMG / "cohort_retention.png", dpi=150)
    plt.close(fig)


def main():
    sys.path.append(str(ROOT / "load"))
    from sf import get_conn #connection

    IMG.mkdir(exist_ok=True)
    conn = get_conn(schema="MARTS")
    try:
        frames = {
            "monthly_revenue": fetch(conn, Q_MONTHLY),
            "review_by_delay": fetch(conn, Q_DELAY),
            "cohort_retention": fetch(conn, Q_COHORT),
        }
    finally:
        conn.close()

    if "--csv" in sys.argv:
        EXPORTS.mkdir(exist_ok=True)
        for name, df in frames.items():
            df.to_csv(EXPORTS / f"{name}.csv", index=False)

    chart_monthly(frames["monthly_revenue"])
    chart_delay(frames["review_by_delay"])
    chart_cohort(frames["cohort_retention"])
    print("saved charts to img/")


if __name__ == "__main__":
    main()
