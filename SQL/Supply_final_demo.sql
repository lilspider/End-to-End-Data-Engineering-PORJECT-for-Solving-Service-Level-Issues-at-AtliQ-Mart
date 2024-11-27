USE master;


CREATE DATABASE Supply_Chain_1;


USE Supply_Chain_1;

-- Create the dimension tables for customers
CREATE TABLE dim_customers (
    customer_id int PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL
);

-- Create the dimension table for products
CREATE TABLE dim_products (
    product_name VARCHAR(255) NOT NULL,
    product_id INT PRIMARY KEY,
    category VARCHAR(255) NOT NULL
);

-- Create the dimension table for dates
CREATE TABLE dim_date (
    date DATE PRIMARY KEY,
    mmm_yy date NOT NULL,
    week_no varchar(15) NOT NULL
);

-- Create the dimension table for order targets
CREATE TABLE dim_targets_orders (
    customer_id int,
    ontime_target DECIMAL(10,2),
    infull_target DECIMAL(10,2),
    otif_target DECIMAL(10,2),
    PRIMARY KEY (customer_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id)
);

-- Create the fact table for order lines
CREATE TABLE fact_order_lines (
    order_id varchar(50),
    order_placement_date varchar(255),
    customer_id int,
    product_id INT,
    order_qty int,
    agreed_delivery_date varchar(255),
    actual_delivery_date varchar(255),
    delivered_qty int,
    PRIMARY KEY (order_id, customer_id, product_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id)
);

-- Create the fact table for aggregated orders
CREATE TABLE fact_orders_aggregate (
    order_id varchar(250),
    customer_id int,
    order_placement_date varchar(250),
    on_time INT,
    in_full INT,
    otif INT,
    PRIMARY KEY (order_id, customer_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id)
);







--------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------
-- Bulk insert data into the dim_customers table from a CSV file
BULK INSERT dim_customers
FROM 'C:\Users\PC\Downloads\dim_customers.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

-- Preview the first 10 records of dim_customers
SELECT TOP 10 * FROM dim_customers;

-- Bulk insert data into the dim_products table from a CSV file
BULK INSERT dim_products
FROM 'C:\Users\PC\Downloads\dim_products.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

-- Preview the first 10 records of dim_products
SELECT TOP 10 * FROM dim_products;

-- Bulk insert data into the dim_date table from a CSV file
BULK INSERT dim_date
FROM 'C:\Users\PC\Downloads\dim_date.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

-- Preview the first 10 records of dim_date
SELECT TOP 10 * FROM dim_date;

-- Bulk insert data into the dim_targets_orders table from a CSV file
BULK INSERT dim_targets_orders
FROM 'C:\Users\PC\Downloads\dim_targets_orders.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

-- Preview the first 10 records of dim_targets_orders
SELECT TOP 10 * FROM dim_targets_orders;

-- Bulk insert data into the fact_order_lines table from a CSV file
BULK INSERT fact_order_lines
FROM 'C:\Users\PC\Downloads\oreder_line_3.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

-- Bulk insert data into the fact_orders_aggregate table from a CSV file
BULK INSERT fact_orders_aggregate
FROM 'C:\Users\PC\Downloads\fact_orders_aggregate_1.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);




------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------







-- Clean up order_placement_date by trimming spaces
UPDATE fact_order_lines
SET order_placement_date = LTRIM(RTRIM(order_placement_date));



-- Add a new column to store the converted order placement date
ALTER TABLE fact_order_lines
ADD order_placement_date_converted DATE;



-- Convert order_placement_date to DATE format and store it in the new column
UPDATE fact_order_lines
SET order_placement_date_converted = TRY_CONVERT(DATE, LTRIM(RTRIM(order_placement_date)), 103);



-- Drop the original VARCHAR order_placement_date column
ALTER TABLE fact_order_lines
DROP COLUMN order_placement_date;



-- Rename the converted date column
EXEC sp_rename 'fact_order_lines.order_placement_date_converted', 'order_placement_date', 'COLUMN';




-- Clean and convert agreed_delivery_date
UPDATE fact_order_lines
SET agreed_delivery_date = LTRIM(RTRIM(agreed_delivery_date));



-- Add a temporary column to store the converted agreed delivery date
ALTER TABLE fact_order_lines
ADD agreed_delivery_date_temp DATE;



-- Convert agreed_delivery_date to DATE format and store it in the new column
UPDATE fact_order_lines
SET agreed_delivery_date_temp = TRY_CONVERT(DATE, LTRIM(RTRIM(agreed_delivery_date)), 103);



-- Drop the original VARCHAR agreed_delivery_date column
ALTER TABLE fact_order_lines
DROP COLUMN agreed_delivery_date;



-- Rename the temporary column to agreed_delivery_date
EXEC sp_rename 'fact_order_lines.agreed_delivery_date_temp', 'agreed_delivery_date', 'COLUMN';




-- Clean and convert actual_delivery_date
UPDATE fact_order_lines
SET actual_delivery_date = LTRIM(RTRIM(actual_delivery_date));



-- Add a new column to store the converted actual delivery date
ALTER TABLE fact_order_lines
ADD actual_delivery_date_converted DATE;



-- Convert actual_delivery_date to DATE format and store it in the new column
UPDATE fact_order_lines
SET actual_delivery_date_converted = TRY_CONVERT(DATE, LTRIM(RTRIM(actual_delivery_date)), 103);



-- Drop the original VARCHAR actual_delivery_date column
ALTER TABLE fact_order_lines
DROP COLUMN actual_delivery_date;



-- Rename the new converted column to actual_delivery_date
EXEC sp_rename 'fact_order_lines.actual_delivery_date_converted', 'actual_delivery_date', 'COLUMN';



-- Alter delivered_qty column to ensure it is an INT
ALTER TABLE fact_order_lines
ALTER COLUMN delivered_qty INT;





----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

-- Add a foreign key constraint for order_placement_date in fact_order_lines
ALTER TABLE fact_order_lines
ADD CONSTRAINT FK_fact_order_lines_order_placement_date
FOREIGN KEY (order_placement_date) REFERENCES dim_date(date);


-- Identify distinct agreed_delivery_date values not present in dim_date
SELECT DISTINCT agreed_delivery_date
FROM fact_order_lines
WHERE TRY_CONVERT(DATE, agreed_delivery_date, 103) NOT IN (SELECT date FROM dim_date);



-- Insert missing date into dim_date
INSERT INTO dim_date (date, mmm_yy, week_no)
VALUES ('2022-08-31', '2022-08-01', '36');

-- Add foreign key constraint for agreed_delivery_date
ALTER TABLE fact_order_lines
ADD CONSTRAINT FK_fact_order_lines_agreed_delivery_date
FOREIGN KEY (agreed_delivery_date) REFERENCES dim_date(date);

-- Insert additional missing dates into dim_date
INSERT INTO dim_date (date, mmm_yy, week_no)
VALUES 
('2022-09-01', '2022-09-01', '35'),
('2022-09-02', '2022-09-01', '35'),
('2022-09-03', '2022-09-01', '35');

-- Identify distinct actual_delivery_date values not present in dim_date
SELECT DISTINCT actual_delivery_date
FROM fact_order_lines
WHERE TRY_CONVERT(DATE, actual_delivery_date, 103) NOT IN (SELECT date FROM dim_date);

-- Add foreign key constraint for actual_delivery_date
ALTER TABLE fact_order_lines
ADD CONSTRAINT FK_fact_order_lines_actual_delivery_date
FOREIGN KEY (actual_delivery_date) REFERENCES dim_date(date);




----------------------------------------------------------------------------------
----------------------------------------------------------------------------------



-- Add a new column for order_placement_date in fact_orders_aggregate
ALTER TABLE fact_orders_aggregate
ADD order_placement_date_converted DATE;

-- Convert order_placement_date to DATE format and store it in the new column
UPDATE fact_orders_aggregate
SET order_placement_date_converted = TRY_CONVERT(DATE, LTRIM(RTRIM(order_placement_date)), 103);

-- Check for conversion errors in the new column
SELECT COUNT(*) AS InvalidDateCount
FROM fact_orders_aggregate
WHERE order_placement_date_converted IS NULL;

-- Drop the original order_placement_date column
ALTER TABLE fact_orders_aggregate
DROP COLUMN order_placement_date;

-- Rename the converted date column
EXEC sp_rename 'fact_orders_aggregate.order_placement_date_converted', 'order_placement_date', 'COLUMN';

-- Add a foreign key constraint for order_placement_date in fact_orders_aggregate
ALTER TABLE fact_orders_aggregate
ADD CONSTRAINT FK_fact_orders_aggregate_order_placement_date
FOREIGN KEY (order_placement_date) REFERENCES dim_date(date);
