import os

import snowflake.connector
from dotenv import load_dotenv

load_dotenv()


def get_conn(schema="RAW"):
    return snowflake.connector.connect( #fill in as needed! can also circumnavigate on "fake data"
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"], 
        role=os.getenv("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE", "OLIST_WH"),
        database="OLIST",
        schema=schema,
    )
