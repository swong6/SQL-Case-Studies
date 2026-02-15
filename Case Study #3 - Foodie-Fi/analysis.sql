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
