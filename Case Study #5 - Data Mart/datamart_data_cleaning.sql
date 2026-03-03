DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TEMP TABLE clean_weekly_sales AS (
SELECT
  TO_DATE(week_date, 'DD/MM/YY') AS week_date,
  DATE_PART('week', TO_DATE(week_date, 'DD/MM/YY')) AS week_number,
  DATE_PART('month', TO_DATE(week_date, 'DD/MM/YY')) AS month_number,
  DATE_PART('year', TO_DATE(week_date, 'DD/MM/YY')) AS calendar_year,
  region, 
  platform, 
  segment,
  CASE 
    WHEN RIGHT(segment,1) = '1' THEN 'Young Adults'
    WHEN RIGHT(segment,1) = '2' THEN 'Middle Aged'
    WHEN RIGHT(segment,1) in ('3','4') THEN 'Retirees'
    ELSE 'unknown' END AS age_band,
  CASE 
    WHEN LEFT(segment,1) = 'C' THEN 'Couples'
    WHEN LEFT(segment,1) = 'F' THEN 'Families'
    ELSE 'unknown' END AS demographic,
  transactions,
  ROUND((sales::NUMERIC/transactions),2) AS avg_transaction,
  sales
FROM data_mart.weekly_sales
);

-- 2. Data Exploration
-- What day of the week is used for each week_date value?
select distinct(to_char(week_date, 'day')) as weekday
from clean_weekly_sales 
limit 10;

-- What range of week numbers are missing from the dataset?
with cte as (
select generate_series(1,52) as week_number
  )
select distinct week_no.week_number
from cte as week_no
left join clean_weekly_sales as sales
on week_no.week_number = sales.week_number
where sales.week_number is null
;
-- How many total transactions were there for each year in the dataset?
select calendar_year,
		sum(transactions) as ct
from clean_weekly_sales
group by calendar_year
order by calendar_year
;
-- What is the total sales for each region for each month?
select	region,
		sum(sales) as total_sales
from clean_weekly_sales
group by region
order by region
;
-- What is the total count of transactions for each platform
select	platform,
		sum(transactions) as total_transactions
from clean_weekly_sales
group by platform
order by platform
;
-- What is the percentage of sales for Retail vs Shopify for each month?

-- case when to categorize as retail sales and shopfiy sales 
-- outer query - retail_sales/shopify_sales per month
with cte as (
select	calendar_year,
		month_number,
		sum(case when platform = 'Retail' then sales else 0 end) as retail_sales,
        sum(case when platform = 'Shopify' then sales else 0 end) as shopify_sales,
        sum(sales) as total_sales
from clean_weekly_sales
group by month_number, calendar_year
order by 1,2
  )
select	calendar_year,
		month_number,
        cast((100.0*retail_sales/total_sales) as decimal(5,2)) as retail_percentage,
        cast((100.0*shopify_sales/total_sales) as decimal(5,2)) as sale_percentage,
        cast(((retail_sales + shopify_sales)/total_sales) as decimal(5,2)) as total_percentage
from cte
;

-- What is the percentage of sales by demographic for each year in the dataset?
-- Which age_band and demographic values contribute the most to Retail sales?
-- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
