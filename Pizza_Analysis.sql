CREATE TABLE customers (
	custid INT NOT NULL,
	first_name VARCHAR(10) NOT NULL,
	last_name VARCHAR(10) NOT NULL,
	email VARCHAR(20) NOT NULL,
	phone BIGINT NOT NULL,
	address VARCHAR(15) NOT NULL,
	city VARCHAR(10) NOT NULL,
	state VARCHAR(10) NOT NULL,
	postal_code INT NOT NULL
);

CREATE TABLE pizzas (
	pizza_id VARCHAR(20) NOT NULL,
	pizza_type_id VARCHAR(20) NOT NULL,
	size VARCHAR(8) NOT NULL,
	price numeric(5,2) NOT NULL
);

CREATE TABLE pizza_types (
	pizza_type_id VARCHAR(18) NOT NULL,
	name VARCHAR(50) NOT NULL,
	category VARCHAR(10) NOT NULL,
	ingredients VARCHAR(120) NOT NULL
);

CREATE TABLE orders (
	order_id INT NOT NULL,
	date DATE NOT NULL,
	time TIME NOT NULL,
	custid INT NOT NULL,
	status VARCHAR(12)
);

CREATE TABLE order_details (
	order_details_id INT NOT NULL,
	order_id INT NOT NULL,
	pizza_id VARCHAR(20) NOT NULL,
	quantity INT NOT NULL
)

SELECT * FROM customers;
SELECT * FROM order_details;
SELECT * FROM orders;
SELECT * FROM pizza_types;
SELECT * FROM pizzas;


ALTER TABLE orders
ADD CONSTRAINT order_id_pk PRIMARY KEY (order_id);

ALTER TABLE order_details
ADD CONSTRAINT order_id_fk
FOREIGN KEY (order_id)
REFERENCES orders(order_id);


ALTER TABLE pizza_types
ADD CONSTRAINT pizza_type_id_pk PRIMARY KEY (pizza_type_id);

ALTER TABLE pizzas
ADD CONSTRAINT pizza_type_id_fk
FOREIGN KEY (pizza_type_id)
REFERENCES pizza_types(pizza_type_id);


ALTER TABLE customers
ADD CONSTRAINT pcustid PRIMARY KEY (custid);

ALTER TABLE orders
ADD CONSTRAINT custid_fk
FOREIGN KEY (custid)
REFERENCES customers(custid);


ALTER TABLE pizzas
ADD CONSTRAINT pizza_pkey PRIMARY KEY (pizza_id);

ALTER TABLE order_details
ADD CONSTRAINT order_items_pizza_fk
FOREIGN KEY (pizza_id)
REFERENCES pizzas(pizza_id);


SELECT * FROM customers;
SELECT * FROM order_details;
SELECT * FROM orders;
SELECT * FROM pizza_types;
SELECT * FROM pizzas;


-- CLEAN Dominos / Store / Ecommerce Database

-- STEP 1 :- To check For duplicates 
-- STEP 2 :- Check for Null Values 
-- STEP 3 :- Treating Null Values
-- STEP 4 :- Handling Negative Values
-- STEP 5 :- Fixing Inconsistent Date Formats & Invalid Dates
-- STEP 6 :- Fixing Invalid Email Addresses
-- STEP 7 :- Checking the Datatype

SELECT * FROM customers;

SELECT custid,email,
	ROW_NUMBER() OVER(PARTITION BY email ORDER BY custid)
FROM customers;


SELECT * FROM orders;

SELECT * 
FROM orders
WHERE date is NULL;


-- 1. Orders Volume Analysis Queries
-- Stakeholder (Operations Manager):

/*
"We are trying to understand our order volume in detail so we can measure store performance and benchmark growth.
Instead of just knowing the total number of unique orders, I'd like a deeper breakdown:

- What is the total number of unique orders placed so far?
- How has this order volume changed month-over-month and year-over-year?
- Can we identify peak and off-peak ordering days?
- How do order volumes vary by day of the week (e.g., weekends vs weekdays)?
- What is the average number of orders per customer?
- Who are our top repeat customers driving the order volume?
- Can you also project the expected order growth trend based on historical data?"
*/

-- What is the total number of unique orders placed so far?

SELECT COUNT(DISTINCT order_id) FROM orders;



-- How has this order volume changed month-over-month and year-over-year?

SELECT * FROM orders;

-- CREATE VIEW mom_growth_pct AS
WITH monthly_orders AS(
	SELECT *,
		EXTRACT (MONTH FROM date) as month 
	FROM orders
)
SELECT month, 
	COUNT(order_id) as order_count,
	LAG(COUNT(order_id)) OVER(order by month) as prev_month,
	 ROUND(100.0 * (COUNT(order_id) - 
	 		  LAG(COUNT(order_id)) OVER(order by month))
	 / NULLIF(LAG(COUNT(order_id)) OVER(order by month),0),2) AS mom_growth_pct -- 100 * (CURRENT MONTH - PREV MONTH)/PREV MONTH
FROM monthly_orders
GROUP BY month
ORDER BY month;


-- Can we identify peak and off-peak ordering days? Ans: Peak order = "Friday" Off-peak order : Sunday

SELECT 
	EXTRACT(ISODOW FROM date) as day_of_week,
	COUNT(order_id) AS order_count
FROM orders
GROUP BY 1
ORDER BY 1;

SELECT 
	TO_CHAR(DATE, 'Day') AS day_name,
	COUNT(order_id) AS number_of_Order
FROM orders
GROUP BY 1
ORDER BY 2;

-- How do order volumes vary by day of the week (e.g., weekends vs weekdays)?

SELECT * FROM orders;

WITH daywise_order AS(
	SELECT 
		EXTRACT(ISODOW FROM date) as day_of_week,
		COUNT(order_id) as total_order
	FROM orders
	GROUP BY 1
	ORDER BY 1
)
SELECT 
	day_of_week,
	total_order,
	LAG(total_order) OVER(ORDER BY day_of_week) as prev_day,
	ROUND(100 * (total_order - LAG(total_order) OVER(ORDER BY day_of_week)) 
	/ NULLIF(LAG(total_order) OVER(ORDER BY day_of_week),0),2)
FROM daywise_order


-- What is the average number of orders per customer?

SELECT * FROM customers;

CREATE VIEW avg_order_per_customer AS 
SELECT 
	ROUND(COUNT(DISTINCT order_id) * 1.0
	/ COUNT(DISTINCT custid),2) AS avg_order_per_customer
FROM orders

SELECT * FROM avg_order_per_customer


-- Who are our top repeat customers driving the order volume?

SELECT * FROM orders

SELECT 
	o.custid,
	c.first_name,
	c.last_name,
	c.city,
	COUNT(order_id) as most_order
FROM orders as o
	LEFT JOIN customers as c ON o.custid = c.custid
GROUP BY 1, 2, 3, 4, o.custid
ORDER BY 5 DESC;

-- Can you also project the expected order growth trend based on historical data?"

SELECT 
	date,
	COUNT(DISTINCT order_id) as daily_order,
	SUM(COUNT(DISTINCT order_id)) OVER(ORDER BY date) as cumlative_orders
FROM orders
GROUP BY 1
ORDER BY 1;


-- 2. Total Revenue from Pizza Sales

SELECT * FROM order_details;
SELECT * FROM pizzas;

SELECT SUM(o.quantity * p.price) AS total_revenue
FROM order_details as o
	JOIN pizzas as p ON o.pizza_id = p.pizza_id;


-- 3. Highest-Priced Pizza

SELECT * FROM pizza_types;
SELECT * FROM pizzas;


SELECT * 
FROM pizzas
WHERE price = (SELECT MAX(price) FROM pizzas)


SELECT name, category, size, price
FROM pizzas as pz
	JOIN pizza_types as pz_ty ON pz.pizza_type_id = pz_ty.pizza_type_id
WHERE pz.price = (SELECT max(price) FROM pizzas);


-- Alternative Method
SELECT 
	name, 
	category, 
	size,
	price
FROM pizzas as pz
	JOIN pizza_types as pz_ty ON pz.pizza_type_id = pz_ty.pizza_type_id
ORDER BY price DESC
LIMIT 1;
-- WHERE pz.price = (SELECT max(price) FROM pizzas);


-- 4. Most Common Pizza Size Ordered 


SELECT * FROM order_details;
SELECT * FROM pizzas;

SELECT 
	p.size, 
	COUNT(od.order_details_id) as total_order
FROM order_details as od
	JOIN pizzas as p ON od.pizza_id = p.pizza_id
GROUP BY 1
ORDER BY 1;

-- Top 5 Most Ordered Pizza Types

SELECT * FROM order_details;
SELECT * FROM pizza_types;
SELECT * FROM pizzas;


SELECT 
	p.pizza_type_id,
	pt.name, 
	COUNT(order_details_id) as total_sold
FROM order_details AS od
	JOIN pizzas AS p ON od.pizza_id = p.pizza_id
	JOIN pizza_types AS pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 5;


-- Top 5 Least Ordered Pizza Types

SELECT p.pizza_type_id, pt.name, COUNT(order_details_id)
FROM order_details AS od
	JOIN pizzas AS p ON od.pizza_id = p.pizza_id
	JOIN pizza_types AS pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY 1, 2
ORDER BY 3 ASC
LIMIT 5;


-- Total Quantity by Pizza Category

SELECT * FROM order_details;
SELECT * FROM pizzas;
SELECT * FROM pizza_types;

SELECT pt.category, SUM(od.quantity) AS total_qnty_sold
FROM order_details as od
	JOIN pizzas as p ON od.pizza_id = p.pizza_id
	JOIN pizza_types as pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY 1
ORDER BY 2 desc;


-- Pizza Order by Hours of the Day

SELECT * FROM order_details;
SELECT * FROM orders;

SELECT 
	EXTRACT(HOUR FROM time) as hour,
	COUNT(*) as total_pizza_order
FROM orders as o
	JOIN order_details as od on o.order_id = od.order_id
GROUP BY 1
ORDER BY 1 ASC;

-- Order by Hours of the Day

SELECT 
	EXTRACT(HOUR FROM time) as hour,
	COUNT(*) total_order
FROM orders
GROUP BY 1
ORDER BY 1;

-- Category Wise Pizza Distribution

SELECT * FROM orders;
SELECT * FROM pizza_types;
SELECT * FROM order_details;
SELECT * FROM pizzas;

SELECT pt.category, COUNT(od.order_details_id) AS pizza_sold_in_each_category
FROM orders AS o
	JOIN order_details AS od ON o.order_id = od.order_id
	JOIN pizzas AS p ON p.pizza_id = od.pizza_id
	JOIN pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY 1
ORDER BY 2 DESC;


-- Average Pizzas Ordered per Day

SELECT * FROM orders;
SELECT * FROM order_details;

SELECT ROUND(AVG(daily_order),2) as avg_order_per_day
FROM
	(SELECT date, SUM(QUANTITY) AS daily_order
	FROM orders AS o
		JOIN order_details AS od ON o.order_id = od.order_id
	GROUP BY 1
)


-- Top 3 Pizzas by Revenue

SELECT * FROM order_details;
SELECT * FROM orders;
SELECT * FROM pizzas;
SELECT * FROM pizza_types;

-- Method 1
SELECT 
	pt.name AS pizza, 
	SUM(od.quantity * p.price) AS revenue
FROM order_details AS od
	JOIN pizzas AS p On od.pizza_id = p.pizza_id
	JOIN pizza_types AS pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;


-- METHOD -2
WITH CTE AS(
	SELECT 
		pt.name AS pizza, 
		SUM(od.quantity * p.price) AS revenue,
		RANK() OVER(ORDER BY SUM(od.quantity * p.price)) AS rank
	FROM order_details AS od
		JOIN pizzas AS p On od.pizza_id = p.pizza_id
		JOIN pizza_types AS pt ON pt.pizza_type_id = p.pizza_type_id
	GROUP BY 1
)
SELECT pizza, revenue
FROM CTE
WHERE rank <= 3;

-- Bottom 3 Pizzas by Revenue

SELECT pt.name AS pizza, SUM(od.quantity * p.price) AS revenue
FROM order_details AS od
	JOIN pizzas AS p On od.pizza_id = p.pizza_id
	JOIN pizza_types AS pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY 1
ORDER BY 2 ASC
LIMIT 3;


-- Revenue Contribution by Each Pizza in Percentage(%)

SELECT 
	pt.name AS pizza, 
	SUM(od.quantity * p.price) AS revenue,
	CONCAT(ROUND(100 * SUM(od.quantity * p.price) / SUM(SUM(od.quantity * p.price))OVER(),2),'%') pcnt_contribution
FROM order_details AS od
	JOIN pizzas AS p On od.pizza_id = p.pizza_id
	JOIN pizza_types AS pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY 1
ORDER BY 3 DESC;


-- Cumulative Revenue Over Month-on-Month


SELECT * FROM orders;
SELECT * FROM order_details;
SELECT * FROM pizzas;


SELECT 
	month,
	monthy_revenue,
	SUM(monthy_revenue) OVER(ORDER BY month) AS cumulative_revenue
FROM 
	(SELECT 
		EXTRACT(MONTH FROM o.date) AS month,
		SUM(od.quantity * p.price) AS monthy_revenue
	FROM orders AS o
		JOIN order_details AS od ON o.order_id = od.order_id
		JOIN pizzas AS p ON p.pizza_id = od.pizza_id
	GROUP BY 1
	ORDER BY 1);


-- Top 10 Customer by spending

SELECT * FROM customers;
SELECT * FROM orders;
SELECT * FROM order_details;
SELECT * FROM pizzas;

CREATE VIEW customer_spending As 
SELECT c.custid, c.first_name,c.last_name, SUM(od.quantity * p.price) AS total_spending
FROM order_details AS od
	JOIN orders AS o ON o.order_id = od.order_id
	JOIN customers AS c On o.custid = c.custid
	JOIN pizzas AS p ON p.pizza_id = od.pizza_id
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

SELECT * FROM customer_spending;

-- Order by Weekdays

-- Average Order Size per day

SELECT * FROM order_details;


WITH CTE AS(
	SELECT 
		1.0 * COUNT(DISTINCT order_id) as no_of_order, 
		1.0 * SUM(quantity) as total_quantity_order
	FROM order_details
)
SELECT ROUND(total_quantity_order / no_of_order,2) AS avg_order_person
FROM CTE

-- METHOD - 02
SELECT ROUND(AVG(total_order),2) AS avg_order_per_person
FROM (
	SELECT 
		order_id,
		SUM(quantity) as total_order
	FROM order_details
	GROUP BY 1
)


-- Seasonal Trends

SELECT * FROM Orders

SELECT 
	EXTRACT(MONTH FROM date) AS month,
	COUNT(*) AS num_of_order
FROM orders
GROUP BY 1
ORDER BY 1;


-- Revenue by Pizza Size

SELECT * FROM pizzas;
SELECT * FROM order_details;

SELECT p.size, SUM(od.quantity * p.price) as revenue
FROM order_details AS od
	JOIN pizzas AS p ON od.pizza_id = p.pizza_id
GROUP BY 1
order by 2 DESC;


-- Customer Segmentation
WITH
	CUST_SPEND AS (
		SELECT
			c.custid,
			SUM(od.quantity * p.price) AS total_spent
		FROM
			customers c
			JOIN orders o ON c.custid = o.custid
			JOIN order_details od ON o.order_id = od.order_id
			JOIN pizzas p ON od.pizza_id = p.pizza_id
		GROUP BY
			c.custid
	)
SELECT
	CASE
		WHEN total_spent > 500 THEN 'High Value'
		ELSE 'Regular'
	END AS segment,
	COUNT(*) AS customer_count
FROM
	cust_spend
GROUP BY
	segment;

-- Repeat Customer Rate

WITH cust_orders AS (
SELECT custId, COUNT (DISTINCT order_id) AS order_count
FROM orders
GROUP BY custId
)
SELECT ROUND (100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_rate
FROM cust_orders;








