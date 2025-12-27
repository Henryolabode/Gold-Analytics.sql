-- change over-time trend--
select 
year(order_date) as order_year,
month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from datawarehouseanalytics.`gold.fact_sales`
where order_date  is not null
group by year(order_date),month(order_date)
order by year(order_date),month(order_date);

SELECT 
    DATE_FORMAT(order_date, '%Y-%m-01') AS order_date,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM datawarehouseanalytics.`gold.fact_sales`
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
ORDER BY DATE_FORMAT(order_date, '%Y-%m-01');

-- cumulation analysis.
-- aggregate the data progressively over time to understand whether our business is growing or declining.
-- calculate the total sales per month
-- and the running total of sales over time.

SELECT 
order_date,
total_sales,
sum(total_sales) over (order by order_date) as running_total_sales,
avg(avg_price) over (order by order_date) as moving_average_price
from
(
select
    year(order_date) AS order_date,
    SUM(sales_amount) AS total_sales,
    avg(price) as avg_price
    from datawarehouseanalytics.`gold.fact_sales`
    where order_date is not null
    GROUP BY  year(order_date)
    )t;
    
-- performance analysis
-- helps measure success and compare performance.
/* analyze the yearly performance of products by comparing their sales to both the avg sales performance of the product and the previous Year's sales */
with yearly_product_sales as(
select 
year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales
from datawarehouseanalytics.`gold.fact_sales` f
left join datawarehouseanalytics.`gold.dim_products` p
on f.product_key= p.product_key
where f.order_date is not null
group by
year(f.order_date),
p.product_name)
select
order_year,
product_name,
current_sales,
avg(current_sales) over (partition by product_name) as avg_sales,
current_sales - avg(current_sales) over (partition by product_name) as diff_avg,
case when current_sales - avg(current_sales) over (partition by product_name) > 0 then 'Above avg'
when current_sales - avg(current_sales)over (partition by product_name)< 0 then 'below avg'
else 'avg'
end avg_change,
-- year-over-year Analysis	
lag (current_sales) over (partition by product_name order by order_year)py_sales,
current_sales - lag(current_sales) over (partition by product_name order by order_year) as diff_py,
case when current_sales - lag(current_sales) over (partition by product_name order by order_year) > 0  then 'increase'
when current_sales - lag(current_sales) over (partition by product_name order by order_year) < 0  then 'decrease'
else 'No change'
end py_change
from yearly_product_sales
order by product_name,order_year;
-- which categories contribute the most to overall sales
with category_sales as (
select
category,
sum(sales_amount) total_sales
from datawarehouseanalytics.`gold.fact_sales` f
left join  datawarehouseanalytics.`gold.dim_products` p
on p.product_key= f.product_key
group by category)

select
category,
total_sales,
sum(total_sales) over() overall_sales,
concat(round((cast(total_sales as float)/sum(total_sales) over())*100, 2), '%') as percentage_of_total
from category_sales
order by total_sales desc;

-- segement products into cost rnges and count how many products fall into each segment
with product_segments as (
select product_key,
product_name,
cost,
case when cost < 100 then 'below 100'
when cost between 100 and 500 then '100-500'
when cost between 500 and 1000 then '500-1000'
else 'above 1000'
end cost_range
from  datawarehouseanalytics.`gold.dim_products`)

select 
cost_range,
count(product_key) as total_products
from product_segments 
group by cost_range
order by total_products desc;

/* group customers into three segments base on their spending behaviour:
 - vip: customers with at least 12 months of history and spending morw than $5,000,
 - regular: customers with at least 12 months of history but spending $5000 or less.
 - new: customers with a lifespan less than 12 months.
 and find the total number of customers by each group
 */
 with customer_spending as (
SELECT
    c.customer_key,
    SUM(f.sales_amount) AS total_spending,
    MIN(f.order_date) AS first_order,
    MAX(f.order_date) AS last_order,
    TIMESTAMPDIFF(MONTH, MIN(f.order_date), MAX(f.order_date)) AS lifespan
FROM datawarehouseanalytics.`gold.fact_sales` f
LEFT JOIN datawarehouseanalytics.`gold.dim_customers` c
    ON f.customer_key = c.customer_key
GROUP BY c.customer_key)
select
customer_segment,
count(customer_key) as total_customers
from
	(select 
	customer_key,
	case when lifespan >= 12 and total_spending > 5000 then 'vip'
		when lifespan >= 12 and total_spending <= 5000 then 'regular'
		else 'new'
		end customer_segment 
	from customer_spending) t
group by customer_segment
order by total_customers desc;

/*
customer report
================
purpose:
	-this report consolidates key customer metrics and behaviours
highlights:
	1.gathers essential fields such as names, ages,and transactions details.
    2.segments customers into categories(vip,regular,new) and age groups.
    3.aggreagates customer-level metrics:
     - total orders
     - total sales
     - total quantity purchased
     - total products
     -lifescan (in months)
     4.calculates valuables kpis:
		- recency(months since last order)
        -average order value
        - average monthly spend
*/
-- 1. base query:retrieves core columns from tables
create view datawarehouseanalytics.`gold.report_customers` as
with base_query as (
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    f.product_key, 
    f.order_date,
    f.sales_amount, 
    f.quantity,
    c.customer_key,
    c.customer_number,
    f.order_number,
    TIMESTAMPDIFF(YEAR, c.birthdate, CURDATE()) AS age
FROM datawarehouseanalytics.`gold.fact_sales` f
LEFT JOIN datawarehouseanalytics.`gold.dim_customers` c
    ON c.customer_key = f.customer_key
WHERE f.order_date IS NOT NULL)

/*  2.segments customers into categories(vip,regular,new) and age groups*/
,customer_aggregation as
( 
select 
customer_key,
customer_number,
customer_name,
age,
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
count(distinct product_key) as total_products,
max(order_date) as last_order_date,
TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
from base_query
group by customer_key,
customer_number,
customer_name,
age)
select 
customer_key,
customer_number,
customer_name,
age,
case when age < 20 then 'under 20'
	when age between 20 and 29 then '20-29'
    when age between 30 and 39 then '30-39'
    when age between 40 and 49 then '40-49'
    else '50 and above'
    end as age_group,
case when lifespan >= 12 and total_sales > 5000 then 'vip'
		when lifespan >= 12 and total_sales <= 5000 then 'regular'
		else 'new'
		end customer_segment,
        last_order_date,
        TIMESTAMPDIFF(month, last_order_date, CURDATE()) AS recency,
        total_orders,
        total_sales,
        total_quantity,
        total_products,
        lifespan,
        -- compute average order value (avo)
        case when total_sales= 0 then 0
        else  total_sales / total_orders
       end as avg_order_value,
       -- compute average monthly spend
       case when lifespan = 0 then total_sales
       else total_sales/ lifespan
       end as avg_monthly_spend
        from customer_aggregation;
