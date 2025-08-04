# Coffee Shop Data Analysis SQL Project

## Project Overview

**Project Title**: Coffee Shop data Analysis    

This project is designed to demonstrate SQL skills and techniques typically used by data analysts to explore, clean, and analyze retail sales data. The project involves setting up a coffee shop sales database, performing exploratory data analysis (EDA), and answering specific business questions through SQL queries. This project is ideal for those who are starting their journey in data analysis and want to build a solid foundation in SQL.

## Objectives

1. **Set up a coffee shop database**: Create and populate a coffee shop database with the provided sales, inventory, and staff data.
2. **Data Cleaning**: Identify and remove any records with missing or null values.
3. **Exploratory Data Analysis (EDA)**: Perform basic exploratory data analysis to understand the dataset.
4. **Business Analysis**: Use SQL to answer specific business questions and derive insights from the sales data.

## Project Structure

### 1. Database Setup

- **Database Creation**: The project starts by creating a database named `coffeeshop`.
- **Table Creation**:
  - A table named `orders` is created to store the orders data. The table structure includes columns for row_id, order_id, created_at, item_id, quantity, cust_name, in_or_out.
  - A table named `items` is created to store the items data. The table structure includes columns for item_id, recipe_id, item_name, item_cat, item_size, item_price.
  - A table named `recipes` is created to store the recipes data. The table structure includes columns for row_id, recipe_id, ing_id, quantity.
  - A table named `ingredients` is created to store the ingredients data. The table structure includes columns for ing_id, ing_name, ing_weight, ing_meas, ing_price.
  - A table named `inventory` is created to store the inventory data. The table structure includes columns for inv_id, ing_id, quantity.
  - A table named `staff` is created to store the staff data. The table structure includes columns for staff_id, first_name, last_name, position, sal_per_hour.
  - A table named `shift` is created to store the shift data. The table structure includes columns for shift_id, day, start_time, end_time.
  - A table named `rota` is created to store the rota data. The table structure includes columns for row_id, rota_id, date, shift_id, staff_id.

```sql
CREATE DATABASE coffee_shop;

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
```

### 2. Data Cleaning

- **Null Value Check**: Check for any null values in the dataset and delete records with unnecessary data.

```sql
SELECT * FROM orders
FULL JOIN items on orders.item_id = items.item_id
WHERE items.item_id IS NULL OR orders.item_id IS NULL;

DELETE FROM orders
WHERE item_id NOT IN(
	select item_id from items
);
```

### 3. Data Analysis & Findings

The following SQL queries were developed to answer specific business questions:

1. **Total Orders: Counted all customer orders to gauge business activity**:
```sql
SELECT 
	COUNT(DISTINCT order_id) AS total_order 
FROM orders;
```

2. **Total Sales: Calculated the total revenue generated**:
```sql
SELECT  
	SUM(item_price) sales 
FROM orders
JOIN items ON orders.item_id = items.item_id;
```

3. **Total Items Sold: Summarized the variety and number of items sold**:
```sql
SELECT 
	item_name,
	COUNT(*) AS sold
FROM orders o
JOIN items i ON o.item_id=i.item_id
GROUP BY 1
ORDER BY 2 DESC;
```

4. **Average Order Value: Determined the average revenue per order**:
```sql
SELECT 
	ROUND(SUM(item_price)/COUNT(DISTINCT order_id),2) AS avg_order_value
FROM orders o
JOIN items i ON o.item_id=i.item_id
ORDER BY 1;
```

5. **Top Selling Items: Identified the most popular items**:
```sql
SELECT 
	item_name, 
	COUNT(*) AS sold
FROM orders o
LEFT JOIN items i on i.item_id = o.item_id
GROUP BY 1
ORDER BY 2 DESC;
```

6. **Orders by Hour: Examined the distribution of orders throughout the day**:
```sql
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
```

7. **Sales by Hour: Analyzed hourly revenue trends**:
```sql
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
```

8. **Dine in vs take out orders**:
```sql
SELECT 
	in_or_out,
	COUNT(*) orders
FROM orders o 
LEFT JOIN items i ON o.item_id = i.item_id
WHERE in_or_out IS NOT NULL
AND in_or_out NOT LIKE ' '
GROUP BY 1;
```

9. **Cost of each item: Estimated cost of each item sold**:
```sql
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
```

10. **Identified ingredients needing replenishment based on inventory levels, if inventory usage more than 70%, then re-ordering is needed**:
```sql
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
```

11. **Hours Worked by Staff Member: Broke down hours worked by individual employees**:
```sql
SELECT
  first_name,
  last_name,
  SUM(EXTRACT(HOUR FROM end_time - start_time)) AS hours_worked
FROM rota
JOIN shift ON rota.shift_id = shift.shift_id
JOIN staff ON rota.staff_id = staff.staff_id
GROUP BY 1,2
ORDER BY 3 DESC;
```

12. **Cost per Staff Member: Analyzed salary expenses per employee**:
```sql
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
```


## Findings

- **Sales & Operational Performance**: This analysis helps measure business performance by evaluating sales trends, customer behavior, and operational timing. It supports data-driven decisions such as promotional timing, menu optimization, and customer targeting strategies.
- **Cost & Inventory Management**: This analysis supports cost control and inventory efficiency. Understanding item costs and current stock levels helps ensure profitability and avoid operational disruption due to stockouts or overstocking.
- **Staff Performance & Labor Costs**: Labor data allows management to evaluate staff productivity and optimize workforce planning. Monitoring costs and hours per staff member helps reduce overspending and supports fair and efficient scheduling.

## Reports

- **Sales Summary**: Sales trends highlight peak hours and best performing products.
- **Inventory Analysis**: Inventory analysis reveals areas needing immediate restocking and potential for waste reduction.
- **Labor Cost Breakdown**: Labor cost breakdown indicates opportunities for cost optimization and better shift planning.

## Conclusion

This project serves as a comprehensive introduction to SQL for data analysts, covering database setup, data cleaning, exploratory data analysis, and business-driven SQL queries. The findings from this project can help drive business decisions by understanding sales patterns, operational performance, customer behavior, inventory management,staff performance and labour costs.

## Author - Noval Rama Deanda

This project is part of my portfolio, showcasing the SQL skills essential for data analyst roles. If you have any questions, feedback, or would like to collaborate, feel free to get in touch!

- **LinkedIn**: [Connect with me professionally](https://www.linkedin.com/in/novalrama/)

Thank you for your support, and I look forward to connecting with you!
