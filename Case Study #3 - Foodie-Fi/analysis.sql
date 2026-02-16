-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

SELECT customer_id, s.plan_id, plan_name, start_date
FROM 
subscriptions s 
inner join plans p 
on p.plan_id = s.plan_id
where customer_id in (1,2,11,13,15,16,18,19)
;

-- Customer 1 Observations -- 
-- Initiated with free trial, then subbed to basic monthly

-- Customer 13 Observations -- 
-- Started with free trial, joined basic monthly then upgraded to pro monthly

-- Customer 15 Observations -- 
-- Started with free trial, upgraded to pro monthly then unsubbed on April 29th.

-- B. Data Analysis Questions
-- How many customers has Foodie-Fi ever had?

select count(distinct customer_id) as customer_ct
from subscriptions
;

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

-- output -- month | count(start_date)
-- where plan_id = trial

select month(start_date) as start_date_month, 
		count(distinct customer_id) as ct
from subscriptions s 
inner join plans p 
on s.plan_id = p.plan_id
where s.plan_id = 0
group by start_date_month
order by start_date_month
;


-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

-- output -- year_start_date | plan_name | ct
-- where year > 2020

select	plan_id,
		plan_name,
        count(*) as ct
from subscriptions s 
inner join plans p 
using (plan_id)
where year(start_date) > 2020
group by plan_id, plan_name
order by plan_id, plan_name
;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

-- output -- plan_name | customer_ct | churn_percentage

select	plan_name,
        count(*) as customer_ct,
        round(100*count(distinct customer_id)/
        (select count(distinct customer_id) from subscriptions),2) 
from subscriptions s 
inner join plans p 
using (plan_id)
where plan_name = 'churn'
;

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

-- output -- churn_ct | churn_percentage
-- churn_ct = where plan_id = 4 and prev_plan = 0
-- row_number() over (partition by customer_id order by start_date) as ranking
with cte as (
select	customer_id,
		plan_id,
        start_date,
		lead(plan_id) over (partition by customer_id order by start_date) as next_plan,
		rank() over (partition by customer_id order by start_date) as ranking
from subscriptions s 
inner join plans p 
using (plan_id)
)

select	plan_id,
		count(*) as churner_ct,
        round(100*count(*)/
        (select count(distinct customer_id) from subscriptions),2) as churner_percentage
from cte
where plan_id = 0
	and next_plan = 4
    and ranking = 1
group by plan_id
;
-- What is the number and percentage of customer plans after their initial free trial?

with  cte as (
select	customer_id,
		plan_id,
        start_date,
		lag(plan_id) over (partition by customer_id order by start_date) as prev_plan
from subscriptions s 
inner join plans p 
using (plan_id)
  )
select	plan_id,
		count(*) as retention_ct,
        round(100*count(*)/
        (select count(distinct customer_id) from subscriptions), 2) as retention_percentage
from cte
where prev_plan = 0
group by plan_id
order by plan_id
;
-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

-- output -- plan_name | customer_ct | percentage
-- where startdate <= '2020-12-31'
with cte as (
select *,
		row_number() over (partition by customer_id order by start_date desc) as latest_plan
from subscriptions
join plans using (plan_id)
where start_date <= '2020-12-31'
)

select	plan_id,
		plan_name,
		count(customer_id) as customer_ct,
        round(100*count(*)/
        (select count(distinct customer_id) from subscriptions),2) as percentage
from cte
where latest_plan = 1 
group by plan_id,plan_name
order by plan_id,plan_name
;


-- How many customers have upgraded to an annual plan in 2020?

-- upgrade = 

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
