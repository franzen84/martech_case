with params as (
    select max(event_date) as as_of_date
    from {{ ref('stg_product_events') }}
), --For testing, you can replace this with a hardcoded date.

customers as (
    select *
    from {{ ref('stg_customers') }}
),

logins_14_days as (
    select
        customer_id,
        count(*) as login_count,
        count(distinct event_date) as login_days
    from {{ ref('stg_product_events') }}
    where event_type = 'login'
        and event_date > (select as_of_date from params) - 14
    group by customer_id
),

logins_30_days as (
    select
        customer_id,
        count(*) as login_count
    from {{ ref('stg_product_events') }}
    where event_type = 'login'
        and event_date > (select as_of_date from params) - 30
    group by customer_id
),

days_since_last_activity as (
    select
        customer_id,
        (select as_of_date from params) - max(event_date) as days_since_last_activity
    from {{ ref('stg_product_events') }}
    group by customer_id
),

support_ticket_90_days as (
    select
        customer_id,
        count(*) as support_ticket_count
    from {{ ref('stg_product_events') }}
    where event_type = 'support_ticket'
        and event_date > (select as_of_date from params) - 90
    group by customer_id
),

active_days_14 as (
    select
        customer_id,
        count(distinct event_date) filter (
            where event_date > (select as_of_date from params) - 14
        ) as distinct_active_days,
        count(distinct event_date) filter (
            where event_date >  (select as_of_date from params) - 28
              and event_date <= (select as_of_date from params) - 14
        ) as distinct_active_days_prev
    from {{ ref('stg_product_events') }}
    where event_date > (select as_of_date from params) - 28
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
    where interaction_date > (select as_of_date from params) - 60
    group by customer_id
),

campaign_open_rate_pre_churn as (
    select
        s.customer_id,
        sum(case when interaction_type = 'opened' then 1 else 0 end) as opened_count,
        sum(case when interaction_type = 'delivered' then 1 else 0 end) as delivered_count,
        sum(case when interaction_type = 'opened' then 1 else 0 end) * 1.0 /
        nullif(sum(case when interaction_type = 'delivered' then 1 else 0 end), 0) as campaign_open_rate
    from {{ ref('stg_campaign_interactions') }} s
    inner join {{ ref('stg_customers') }} c on c.customer_id = s.customer_id
    where c.subscription_status = 'churned'
      and s.interaction_date <= c.status_change_date
    group by s.customer_id
)


select 
    customers.customer_id,
    params.as_of_date, --For reference in other models.
    coalesce(logins_14_days.login_count, 0) as logins_last_14_days,
    coalesce(logins_14_days.login_days, 0) as login_days_last_14_days,
    coalesce(logins_30_days.login_count, 0) as logins_last_30_days,
    days_since_last_activity.days_since_last_activity,
    coalesce(support_ticket_90_days.support_ticket_count, 0) as support_ticket_count_last_90_days,
    campaign_open_rate_60_days.campaign_open_rate as campaign_open_rate_last_60_days,
    campaign_open_rate_pre_churn.campaign_open_rate as campaign_open_rate_pre_churn,
    coalesce(active_days_14.distinct_active_days, 0) as active_days_last_14_days,
    coalesce(active_days_14.distinct_active_days_prev, 0) as active_days_prev_14_days

from customers
    cross join params
    left join logins_14_days on logins_14_days.customer_id = customers.customer_id
    left join logins_30_days on logins_30_days.customer_id = customers.customer_id
    left join days_since_last_activity on days_since_last_activity.customer_id = customers.customer_id
    left join support_ticket_90_days on support_ticket_90_days.customer_id = customers.customer_id
    left join active_days_14 on active_days_14.customer_id = customers.customer_id
    left join campaign_open_rate_60_days on campaign_open_rate_60_days.customer_id = customers.customer_id
    left join campaign_open_rate_pre_churn on campaign_open_rate_pre_churn.customer_id = customers.customer_id
