# Audience Segmentation with dbt and DuckDB

A dbt project that builds marketing audience segments for a subscription-based telecom company.
It reads five CSV files, cleans them, calculates customer activity metrics and assigns
eligible customers to segments.

## Setup

1. Clone the repository and open the project folder.
2. Create and activate a virtual environment:
```bash
   python -m venv .venv
   .venv\Scripts\activate        # Mac/Linux: source .venv/bin/activate
```
3. Install dbt with DuckDB:
```bash
   pip install dbt-duckdb
```
4. Make sure the five CSV files are in the `data/` folder.
5. Run the project:
```bash
   dbt debug
   dbt run
   dbt test
```

DuckDB stores the database in the file `dev.duckdb`, so no database server is needed.

## Project structure

- `staging/`: cleans and renames the raw CSV data (`stg_*`)
- `intermediate/`: `int_customer_activity`, one row per customer with activity metrics
- `marts/`: `mart_audience_segments`, the final segments
- `tests/`: custom tests for business logic

## Modeling decisions

- **Database:** DuckDB, because it is free and reads CSV files directly.
- **Reference date:** The data is synthetic and ends in [month year], so all time windows
  are calculated from the latest event date in the data instead of today's date.
- **Cleaning:** Text is trimmed and lowercased, bad dates become NULL, and duplicates are removed.
  The `customer_id` in `consent_registry` is padded and prefixed with `CUST_` so it matches the other tables.
- **Phone numbers:** Split on `/` into two numbers, `+` replaced with `00`, non-digits removed,
  and numbers shorter than 8 digits set to NULL.
- **Open rate:** opened divided by delivered. It is NULL (not 0) when nothing was delivered.
- **Eligibility:** Customers must have marketing consent (purpose codes 'PP_011','PP_012','PP_013','PP_014') and
  status `active` or `churned`. Churned customers can only be in `winback_target`.
- **Output format:** One row per customer with a 0/1 column per segment, because a customer can be in several segments.

## Segments

| Segment | Logic |
|---|---|
| high_value_engaged | Premium, logged in on 5+ of the last 14 days, open rate above 30% |
| at_risk_dormant | No login in last 14 days, last activity 30-59 days ago |
| upgrade_candidate | Basic/standard, 10+ logins in 30 days, no support tickets in 90 days |
| winback_target | Churned in last 90 days, open rate above 20% before churn |
| engagement_declining | Active days in last 14 are below 50% of the 14 days before |

## Tests

- Generic tests: `unique`, `not_null`, `accepted_values` and `relationships`
- Custom tests (in `tests/`):
  - `assert_winback_only_churned`: winback_target only contains churned customers
  - `assert_churned_only_in_winback`: churned customers are in no