
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

-- output -- year | demographic | sales %
-- sales % = sales / total_yearly_sales

-- (1) cte: sales per year/demographic + sum(sales) as total_sales
-- (2) outer: year, percentage calculations 

with cte as (
select	calendar_year,
		demographic,
        sum(sales) as demographic_sales
from clean_weekly_sales
group by 1,2
  ),
cte2 as (
select	*,
  		sum(demographic_sales) over (partition by calendar_year) as yearly_sales
from cte
)
select	calendar_year,
		demographic,
		round((100*demographic_sales/yearly_sales),2) as sales_percentage
from cte2
order by calendar_year, demographic
;

-- Which age_band and demographic values contribute the most to Retail sales?

-- output -- age_band | demographic | retail_sales_contribution

-- highest retail sales: platform = 'Retail' & sum(sales) group by age_band & demographic
-- outer: max(sales)

with cte as (
select	age_band, 
		demographic,
        sum(sales) as total_sales
from clean_weekly_sales
    where platform = 'Retail'
group by age_band, demographic
)

select age_band,
		demographic,
        max(total_sales) as highest_sales
from cte
group by 1,2
order by 3 desc
limit 1
;

select	age_band,
		demographic,
        round(100.0*sum(sales) / 
        (select sum(sales) from clean_weekly_sales where platform = 'Retail'),2)
        as retail_sales_contribution
from clean_weekly_sales
where platform = 'Retail'
group by age_band, demographic
order by retail_sales_contribution desc
;

-- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

SELECT calendar_year,
       platform,
       ROUND(SUM(sales)/SUM(transactions), 2) AS correct_avg,
       ROUND(AVG(avg_transaction), 2) AS incorrect_avg
FROM clean_weekly_sales
GROUP BY 1,
         2
ORDER BY 1,
         2;
