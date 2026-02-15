
create database business_questions;

USE business_questions;
GO


/*select statement*/

select * from customers_cleaned
select * from products_cleaned
select * from sales_cleaned
select * from returns_cleaned
select * from stores_cleaned


/*Removing_columns*/
ALTER TABLE customers_cleaned DROP COLUMN column1;
ALTER TABLE products_cleaned DROP COLUMN column1;
ALTER TABLE sales_cleaned DROP COLUMN column1;
ALTER TABLE stores_cleaned DROP COLUMN column1;
ALTER TABLE returns_cleaned DROP COLUMN column1;


/*Foreign_key*/

ALTER TABLE sales_cleaned
ADD CONSTRAINT fk_customers
FOREIGN KEY (customer_id)
REFERENCES customers_cleaned(customer_id)

ALTER TABLE sales_cleaned
ADD CONSTRAINT fk_products
FOREIGN KEY (product_id)
REFERENCES products_cleaned(product_id)

ALTER TABLE returns_cleaned
ADD CONSTRAINT fk_orders
FOREIGN KEY (order_id)
REFERENCES sales_cleaned(order_id)

INSERT INTO stores_cleaned VALUES ('unknown','Online','Online','-','-',0)

ALTER TABLE sales_cleaned
ADD CONSTRAINT fk_stores
FOREIGN KEY (store_id)
REFERENCES stores_cleaned(store_id);


/*Indexes*/

CREATE INDEX index_customer
ON sales_cleaned (customer_id)

CREATE INDEX index_product
ON sales_cleaned(product_id)

CREATE INDEX index_store
ON sales_cleaned(store_id)

CREATE INDEX index_order_date
ON sales_cleaned(order_date)




/*TOTAL PROFIT */
SELECT ROUND(SUM(profit),2) AS TOTAL_PROFIT FROM sales_cleaned 


/*RETURN PERCENTAGE */
SELECT ROUND(CAST(COUNT(r.return_id)*100.0 /COUNT(s.order_id) AS FLOAT),2) AS 'Total Return %' FROM sales_cleaned s
LEFT JOIN returns_cleaned r
ON s.order_id = r.order_id


/*DISCOUNT PERCENTAGE*/
SELECT ROUND(SUM(discount_pct * total_amount)/ NULLIF(SUM(total_amount), 0)* 100,2) AS "Total Discount %"
FROM sales_cleaned;





/*1. What is the total revenue generated in the last 12 months? */
SELECT ROUND(SUM(total_amount),2) AS TOTAL_REVENUE_GENERATED_IN_LAST_12_MONTHS
FROM sales_cleaned
WHERE order_date >= DATEADD(MONTH,-12,(select MAX(order_date) from sales_cleaned))


/*2.Which are the top 5 best-selling products by quantity? */
SELECT TOP 5 p.product_name AS Product_Name , SUM(s.quantity) AS Total_Quantity from products_cleaned p
JOIN sales_cleaned s
ON p.product_id=s.product_id
GROUP BY p.product_name
ORDER BY SUM(s.quantity) DESC


/*3. How many customers are from each region? */
SELECT region as Region , COUNT(customer_id) as No_of_Customers
FROM customers_cleaned
GROUP BY region


/*4. Which store has the highest profit? */
SELECT TOP 1 s.store_name AS Store_Name ,ROUND(SUM(sd.profit),2) AS Profit FROM sales_cleaned sd
JOIN stores_cleaned s
ON s.store_id=sd.store_id
GROUP BY s.store_name  
ORDER BY Profit DESC	


/*5. What is the return rate by product category? */
SELECT p.category as Category,CAST(ROUND(CAST(COUNT(r.order_id) * 100.0 / NULLIF(COUNT(s.order_id), 0) AS FLOAT),2) AS VARCHAR(50))+' %' AS Return_Rate FROM products_cleaned p
JOIN sales_cleaned s
ON s.product_id = p.product_id
LEFT JOIN returns_cleaned r
ON s.order_id = r.order_id
GROUP BY p.category


/*6. What is the average revenue per customer by age group? */
SELECT c.age_group AS Age_Group , ROUND(AVG(s.total_amount),2) AS Avg_Revenue FROM sales_cleaned s
JOIN customers_cleaned c
on c.customer_id=s.customer_id
GROUP BY Age_Group


/*7. Which sales channel (Online vs In-Store) is more profitable on average? */
SELECT TOP 1 s.sales_channel AS Sales_Channel , ROUND(AVG(s.profit),2) AS Avg_Profit FROM sales_cleaned s
GROUP BY Sales_Channel 
ORDER BY Avg_Profit DESC


/*8. How has monthly profit changed over the last 2 years by region? */
SELECT s.region AS Region,YEAR(sd.order_date) AS Sales_Year,MONTH(sd.order_date) AS Sales_Month,ROUND(SUM(sd.profit),2) AS Monthly_Profit
FROM sales_cleaned sd
JOIN stores_cleaned s
ON sd.store_id = s.store_id
WHERE sd.order_date >= DATEADD(YEAR,-2,(SELECT MAX(order_date) FROM sales_cleaned)) AND s.region<>'-'
GROUP BY s.region,YEAR(sd.order_date),MONTH(sd.order_date)
ORDER BY Region,Sales_Year,Sales_Month;


/*9. Identify the top 3 products with the highest return rate in each category. */
SELECT Category , Product_Name, Return_Rate FROM( 
SELECT  p.category AS Category, p.product_name AS Product_Name, 
CONCAT(ROUND(CAST(COUNT(r.order_id)*100.0/NULLIF(COUNT(s.order_id),0) AS FLOAT),2),'%') AS Return_Rate ,
ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY COUNT(r.order_id)*100.0/NULLIF(COUNT(s.order_id),0) DESC) AS RANK FROM products_cleaned p
JOIN sales_cleaned s
ON s.product_id=p.product_id
LEFT JOIN returns_cleaned r
ON r.order_id=s.order_id
GROUP BY p.category , p.product_name
)t
WHERE RANK<=3


/*10. Which 5 customers have contributed the most to total profit, and what is their tenure with the company? */
SELECT TOP 5 CONCAT(c.first_name,' ',C.last_name) AS Customer_Name, ROUND(SUM(s.profit),2) AS Profit , CAST(DATEDIFF(MONTH , c.signup_date , GETDATE()) AS VARCHAR(255))+' Months' AS "Tenure (in months)" FROM customers_cleaned c
JOIN sales_cleaned s
ON s.customer_id= c.customer_id
GROUP BY CONCAT(c.first_name,' ',C.last_name), c.customer_id, CAST(DATEDIFF(MONTH , c.signup_date , GETDATE()) AS VARCHAR(255))
ORDER BY Profit DESC
