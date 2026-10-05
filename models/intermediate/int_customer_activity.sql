with logins_30_days as (
    select
        customer_id,
        count(*) as login_count
    from {{ ref('stg_product_events') }}
    where event_type = 'login'
        and event_date > current_date - 30
    group by customer_id
),

days_since_last_activity as (
    select
        customer_id,
        current_date - max(event_date) as days_since_last_activity
    from {{ ref('stg_product_events') }}
    group by customer_id
),

support_ticket_90_days as (
    select
        customer_id,
        count(*) as support_ticket_count
    from {{ ref('stg_product_events') }}
    where event_type = 'support_ticket'
        and event_date > current_date - 90
    group by customer_id
),

active_days_14 as (
    select
        customer_id,
        count(distinct event_date) as distinct_active_days
    from {{ ref('stg_product_events') }}
    where event_date > current_date - 14
    group by customer_id
)

/*
Total logins in last 30 days
Days since last activity
Total support tickets in last 90 days
Count of distinct active days in last 14 days


Campaign open rate (opens / delivered) over last 60 days

*/



select * from active_days_14
