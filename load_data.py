import duckdb

con = duckdb.connect("dev.duckdb")

con.execute("""
CREATE OR REPLACE TABLE customers AS
SELECT *
FROM read_csv_auto('data/customers.csv')
""")

con.close()

print("Done")