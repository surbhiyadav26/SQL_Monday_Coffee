-- Report & Data Analysis
USE monday_coffee_db;

-- Q.1 COFFEE Consumer Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT city_name , round((population*0.25)/1000000,2) as coffee_consumers_Millions , city_rank
from city
order by 2 desc;

-- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT c.city_name , SUM(s.total) as total_revenue
from sales s
join  customers co on s.customer_id=co.customer_id
join city c on co.city_id=c.city_id
WHERE year(s.sale_date)=2023 AND quarter(s.sale_date)=4
GROUP BY c.city_name
ORDER BY 2 DESC;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT p.product_name , COUNT(s.product_id) AS unit_sold
FROM sales s 
RIGHT JOIN products p ON s.product_id=p.product_id
GROUP BY p.product_name
ORDER BY 2 DESC;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?
-- city and total sale
-- no cus in each these city

SELECT c.city_name ,
		SUM(s.total) as total_revenue,
        COUNT(DISTINCT s.customer_id) as cust,
        ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id),2) as avg_perCustomer
from sales s
join  customers co on s.customer_id=co.customer_id
join city c on co.city_id=c.city_id
GROUP BY c.city_name
ORDER BY 4 DESC;

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)
WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;

-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?


SELECT * FROM
(SELECT ci.city_name,
	   p.product_name,
       COUNT(s.sale_id) as no_of_order,
       DENSE_RANK() OVER (PARTITION BY ci.city_name order by COUNT(s.sale_id) desc) as R
FROM sales s
JOIN products p on s.product_id = p.product_id
JOIN customers c on s.customer_id = c.customer_id
JOIN city ci on c.city_id = ci.city_id
GROUP BY 1,2) AS T1
WHERE R<=3;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT ci.city_name ,
	COUNT(DISTINCT s.customer_id) as cust
from city ci
Left join customers c on ci.city_id = c.city_id
join sales s on c.customer_id = s.customer_id
where s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1
ORDER BY 2 DESC;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)/
					COUNT(DISTINCT s.customer_id)
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent/
									ct.total_cx
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 5 DESC;

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales
AS
(
	SELECT c.city_name,
        month(sale_date) AS MONTH,
        year(sale_date) AS YEAR,
        SUM(s.total) as total_revenue
	FROM sales s
    JOIN customers cu on s.customer_id= cu.customer_id
    join city c on cu.city_id = c.city_id
    GROUP BY 1,2,3
    ORDER BY 1,3,2
),

 growth_ratio AS
(
	SELECT city_name,MONTH,YEAR,
    total_revenue as cr_month_sale,
    LAG( total_revenue,1) OVER (partition by city_name) as prev_month_sale
    FROM monthly_sales
)
select * , 
      ROUND((cr_month_sale-prev_month_sale)/prev_month_sale * 100,2) as gr_ratio
    FROM growth_ratio  
    where prev_month_sale IS NOT NULL;

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id),2) as avg_sale_pr_cx
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent,
    ROUND((population * 0.25)/1000000, 2) as estimated_coffee_consumers
FROM city
)
SELECT 
	cr.city_name,
    ct.total_revenue,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(cr.estimated_rent/ct.total_cx, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;





























