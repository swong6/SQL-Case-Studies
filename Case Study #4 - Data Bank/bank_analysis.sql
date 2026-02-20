-- A. Customer Nodes Exploration
-- How many unique nodes are there on the Data Bank system?

select count(distinct node_id)
from customer_nodes
;

-- What is the number of nodes per region?   
-- output -- region_id | node_ct

select region_id,
		count(node_id) as region_ct
from customer_nodes
group by region_id
order by region_id
;

-- How many customers are allocated to each region?

-- output -- region_id | customer_ct
-- customer_ct = count(distinct customer_id)

select	region_id,
		count(distinct customer_id) as customer_ct
from customer_nodes
group by region_id
order by region_id
;

-- How many days on average are customers reallocated to a different node?
-- reallocation days = avg(end_date - start_date)
-- output -- node | avg(days)

select	round(AVG(DATEDIFF(end_date, start_date)),2) AS difference
from customer_nodes
where end_date != '9999-12-31'
;

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

-- output -- region_id | median(difference) | 80th(difference) | 95th(difference)

WITH base AS (
  SELECT
    cn.region_id,
    r.region_name,
    DATEDIFF(cn.end_date, cn.start_date) AS difference
  FROM customer_nodes cn
  JOIN regions r USING (region_id)
  WHERE cn.end_date <> '9999-12-31'
),
ranked AS (
  SELECT
    *,
    CUME_DIST() OVER (PARTITION BY region_id ORDER BY difference) AS cd
  FROM base
)
SELECT
  region_id,
  region_name,
  MIN(difference) AS p95_cutoff
FROM ranked
WHERE cd >= 0.95
GROUP BY region_id, region_name
ORDER BY region_id;


-- B. Customer Transactions
-- What is the unique count and total amount for each transaction type?

-- output -- txn_type | ct | total_amount
-- ct = count(txn_type)
-- total_amount = sum(txn_amount)

select	txn_type,
		count(txn_type) as ct,
        sum(txn_amount) as total_amount
from customer_transactions
group by txn_type
;

-- What is the average total historical deposit counts and amounts for all customers?

-- output -- customer_id | deposit_ct | deposit_amt
-- deposit_ct = count(*)
-- deposit_amt = sum(txn_amount)
-- where txn_type = deposit

with cte as (
select	customer_id,
		count(customer_id) as deposit_ct,
		sum(txn_amount) as deposit_amt
from customer_transactions
where txn_type = 'deposit'
group by customer_id
)
select	round(avg(deposit_ct),2) as avg_ct,
		round(avg(deposit_amt),2) as avg_amt
from cte
;     

-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

-- output -- month | ct(deposit more than one) | ct(1 purchse or 1 withdrawal)

-- cte (cts of each txn_type)
-- outer -- month | cts 
-- where conditions
-- group by month

with cte as (
select	customer_id,
		date_format(txn_date, '%Y-%m-01') as monthly,
        sum(txn_type = 'deposit') as deposit_ct,
        sum(txn_type = 'purchase') as purchase_ct,
        sum(txn_type = 'withdrawal') as withdrawal_ct
from customer_transactions
group by customer_id, monthly

  )
  
select	monthly,
		count(*) as customer_ct
from cte
where deposit_ct > 1
		and (purchase_ct >= 1 or withdrawal_ct >= 1)
group by monthly
order by monthly
;

-- What is the closing balance for each customer at the end of the month?
-- What is the percentage of customers who increase their closing balance by more than 5%?

-- C. Data Allocation Challenge
-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time
-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

-- running customer balance column that includes the impact each transaction
-- customer balance at the end of each month
-- minimum, average and maximum values of the running balance for each customer
-- Using all of the data available - how much data would have been required for each option on a monthly basis?

-- D. Extra Challenge
-- Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

-- If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?

-- Special notes:

-- Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!
-- Extension Request
-- The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.

-- Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.

-- With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.
