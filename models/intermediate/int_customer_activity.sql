with customers as (
    select *
    from {{ ref('stg_customers') }}
),

logins_30_days as (
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
),

campaign_open_rate_60_days as (
    select
        customer_id,
        sum(case when interaction_type = 'opened' then 1 else 0 end) as opened_count,
        sum(case when interaction_type = 'delivered' then 1 else 0 end) as delivered_count,
        sum(case when interaction_type = 'opened' then 1 else 0 end) * 1.0 /
        nullif(sum(case when interaction_type = 'delivered' then 1 else 0 end), 0) as campaign_open_rate
    from {{ ref('stg_campaign_interactions') }}
    where interaction_date > current_date - 60
    and customer_id = 'CUST_004121'
    group by customer_id
)

select 
    customers.customer_id,
    login_count as logins_last_30_days,
    days_since_last_activity,
    support_ticket_count as support_ticket_count_last_90_days,
    campaign_open_rate as campaign_open_rate_last_60_days,
    distinct_active_days as active_days_last_14_days
from customers
    left join logins_30_days on logins_30_days.customer_id = customers.customer_id
    left join days_since_last_activity on days_since_last_activity.customer_id = customers.customer_id
    left join support_ticket_90_days on support_ticket_90_days.customer_id = customers.customer_id
    left join active_days_14 on active_days_14.customer_id = customers.customer_id
    left join campaign_open_rate_60_days on campaign_open_rate_60_days.customer_id = customers.customer_id
