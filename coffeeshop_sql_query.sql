--Create Database
CREATE DATABASE coffee_shop;

--Create Tables
CREATE TABLE orders(
	row_id PRIMARY KEY INT,
	order_id VARCHAR(10),
	created_at TIMESTAMP,
	item_id VARCHAR(10),
	quantity INT,
	cust_name VARCHAR(30),
	in_or_out VARCHAR(5)
);

CREATE TABLE items(
	item_id PRIMARY KEY VARCHAR(10),
	recipe_id VARCHAR(20),
	item_name VARCHAR(30),
	item_cat VARCHAR(20),
	item_size VARCHAR(15),
	item_price NUMERIC(6,2)
);

CREATE TABLE recipes(
	row_id PRIMARY KEY INT,
	recipe_id VARCHAR(20),
	ing_id VARCHAR(15),
	quantity INT
);

CREATE TABLE ingredients(
	ing_id PRIMARY KEY VARCHAR(10),
	ing_name VARCHAR(50),
	ing_weight INT,
	ing_meas VARCHAR(15),
	ing_price NUMERIC(6,2)
);

CREATE TABLE inventory(
	inv_id PRIMARY KEY VARCHAR(15),
	ing_id VARCHAR(15),
	quantity INT
);

CREATE TABLE staff(
	staff_id PRIMARY KEY VARCHAR(10),
	First_name VARCHAR(20),
	last_name VARCHAR(20),
	position VARCHAR(15),
	sal_per_hour NUMERIC(6,2)
);

CREATE TABLE shift(
	shift_id PRIMARY KEY VARCHAR(15),
	day VARCHAR(20),
	start_time TIME,
	end_time TIME
);

CREATE TABLE rota(
	row_id PRIMARY KEY INT,
	rota_id VARCHAR(10),
	date DATE,
	shift_id VARCHAR(15),
	staff_id VARCHAR(15)
);

--Data Cleaning
select * from orders
full join items on orders.item_id=items.item_id
where items.item_id is null or orders.item_id is null;

DELETE FROM orders
WHERE item_id not in(
	select item_id from items
);

--Data Exploration

--1. Total Orders: Counted all customer orders to gauge business activity.
SELECT 
	COUNT(DISTINCT order_id) AS total_order 
FROM orders;

--2. Total Sales: Calculated the total revenue generated.
SELECT  
	SUM(item_price) sales 
FROM orders
JOIN items ON orders.item_id = items.item_id;

--3. Total Items Sold: Summarized the variety and number of items sold.
SELECT 
	item_name,
	COUNT(*) AS sold
FROM orders o
JOIN items i ON o.item_id=i.item_id
GROUP BY 1
ORDER BY 2 DESC;

--4. Average Order Value: Determined the average revenue per order.
SELECT 
	ROUND(SUM(item_price)/COUNT(DISTINCT order_id),2) AS avg_order_value
FROM orders o
JOIN items i ON o.item_id=i.item_id
ORDER BY 1;

--5. Top Selling Items: Identified the most popular items.
SELECT 
	item_name, 
	COUNT(*) AS sold
FROM orders o
LEFT JOIN items i on i.item_id = o.item_id
GROUP BY 1
ORDER BY 2 DESC;

--6. Orders by Hour: Examined the distribution of orders throughout the day.
SELECT 
	DATE(created_at),
	TO_CHAR(created_at, 'Day') AS day,
	EXTRACT(HOUR FROM created_at) AS hour,
	COUNT(*) AS order_count
FROM orders o
LEFT JOIN items i ON o.item_id = i.item_id
GROUP BY 
	GROUPING SETS(
			(1,2,3),
			(1,2)
	)
ORDER BY 1,3;

--7. Sales by Hour: Analyzed hourly revenue trends.
SELECT 
	DATE(created_at),
	TO_CHAR(created_at,'day') AS day,
	EXTRACT(HOUR FROM created_at) AS hour,
	SUM(item_price) AS sales
FROM orders o
LEFT JOIN items i ON o.item_id = i.item_id
GROUP BY
	GROUPING SETS(
			(1,2,3),
			(1,2)
	)
ORDER BY 1,3;

--8. dine in vs take out orders
SELECT 
	in_or_out,
	COUNT(*) orders
FROM orders o 
LEFT JOIN items i ON o.item_id = i.item_id
	WHERE in_or_out IS NOT NULL
	AND in_or_out NOT LIKE ' '
GROUP BY 1;

--9. Cost of each item: Estimated cost of each item sold.
WITH ingredient_used AS(
	SELECT 
		i.item_id,
		item_name,
		item_size,
		r.recipe_id,
		item_price,
		r.quantity,
		(SELECT ing_weight FROM ingredients WHERE ing_id=ing.ing_id),
		(SELECT ing_meas FROM ingredients WHERE ing_id=ing.ing_id),
		(SELECT ing_price FROM ingredients WHERE ing_id=ing.ing_id)
	FROM items i 
	JOIN recipes r ON i.recipe_id = r.recipe_id
	JOIN ingredients ing ON r.ing_id = ing.ing_id
)
SELECT 
	item_name||' '||item_size AS name_size,
	ROUND(SUM((quantity/ing_weight::NUMERIC)*ing_price),2) AS item_cost,
	item_price
FROM ingredient_used
GROUP BY 1,3;

--10. Identified ingredients needing replenishment based on inventory levels. If inventory usage more than 70%, then re-ordering is needed
WITH inventory_stock AS(
	SELECT 
		ing.ing_id,
		ing_name,
		SUM(r.quantity) AS inv_used,
		(SELECT ing_weight*quantity AS inventory FROM ingredients
		LEFT JOIN inventory ON ingredients.ing_id = inventory.ing_id
		WHERE ingredients.ing_id = ing.ing_id),
		(SELECT ing_meas AS measures FROM ingredients WHERE ing_id=ing.ing_id)
	FROM orders o
	JOIN items i ON o.item_id= i.item_id
	JOIN recipes r ON i.recipe_id = r.recipe_id
	JOIN ingredients ing ON r.ing_id = ing.ing_id
	GROUP BY 1,2
	ORDER BY 1
)
SELECT
	*,
	ROUND((inv_used/inventory::NUMERIC)*100.0,2) AS usage_stock_inventory_perc,
	CASE
		WHEN round((inv_used/inventory::NUMERIC)*100.0,2) >70 THEN 'needed'
		ELSE 'not yet'
	END AS re_order
FROM inventory_stock;

--11. Hours Worked by Staff Member: Broke down hours worked by individual employees.
SELECT
first_name,
last_name,
SUM(EXTRACT(HOUR FROM end_time - start_time)) AS hours_worked
FROM rota
JOIN shift ON rota.shift_id = shift.shift_id
JOIN staff ON rota.staff_id = staff.staff_id
GROUP BY 1,2
ORDER BY 3 DESC;

--12. Cost per Staff Member: Analyzed salary expenses per employee.
SELECT
first_name,
last_name,
SUM(
sal_per_hour*
EXTRACT(HOUR FROM end_time - start_time)) AS total_salary
FROM rota
JOIN shift ON rota.shift_id = shift.shift_id
JOIN staff ON rota.staff_id = staff.staff_id
GROUP BY 1,2
ORDER BY 3 DESC;
