with customers as (
    select
        customer_id,
        email,
        phone_number,
        phone_number_secondary,
        subscription_plan,
        subscription_status,
        status_change_date
    from {{ ref('stg_customers') }}
    where subscription_status in ('active', 'churned')
),

marketing_consent as (
    select distinct 
        customer_id
    from {{ ref('stg_consent_registry') }} consent_registry
    where consent_registry.purpose_code in ('PP_011','PP_012','PP_013','PP_014') --(Basic marketing, Direct marketing contact - Email, Direct marketing contact - SMS, Direct marketing contact - Phone)
),

base as (
    select
        c.customer_id,
        c.email,
        c.phone_number,
        c.phone_number_secondary,
        c.subscription_plan,
        c.subscription_status,
        c.status_change_date,
        a.logins_last_14_days,
        a.login_days_last_14_days,
        a.logins_last_30_days,
        a.days_since_last_activity,
        a.support_ticket_count_last_90_days,
        a.campaign_open_rate_last_60_days,
        a.campaign_open_rate_pre_churn,
        a.active_days_last_14_days,
        a.active_days_prev_14_days,
        a.as_of_date
    from customers c
    inner join marketing_consent m on m.customer_id = c.customer_id
    left join {{ ref("int_customer_activity")}} a on a.customer_id = c.customer_id
),

segments as (
    select
        *,
        case when subscription_status = 'active'
            and subscription_plan = 'premium'
            and login_days_last_14_days >= 5
            and campaign_open_rate_last_60_days > 0.30
            then 1 else 0 end as is_high_value_engaged,

        case when subscription_status = 'active'
            and logins_last_14_days = 0
            and days_since_last_activity >= 30
            and days_since_last_activity < 60
            then 1 else 0 end as is_at_risk_dormant,

        case when subscription_status = 'active'
            and subscription_plan in ('basic', 'standard')
            and logins_last_30_days >= 10
            and support_ticket_count_last_90_days = 0
            then 1 else 0 end as is_upgrade_candidate,

        case when subscription_status = 'churned'
            and status_change_date > as_of_date - 90
            and campaign_open_rate_pre_churn > 0.20
            then 1 else 0 end as is_winback_target,

        case when subscription_status = 'active'
            and active_days_prev_14_days > 0
            and active_days_last_14_days < 0.5 * active_days_prev_14_days
            then 1 else 0 end as is_engagement_declining
    from base
)

select 
    *
    --count(*)  
from segments
where is_high_value_engaged + is_at_risk_dormant + is_upgrade_candidate
    + is_winback_target + is_engagement_declining > 0