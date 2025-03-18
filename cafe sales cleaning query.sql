-- ************************
-- CLEANING CAFE SALES DATA
-- ************************
SELECT 
    *
FROM
    dirty_cafe_sales;

-- cleaned temp table - doesnt exist if query is fully run
SELECT 
    *
FROM
    clean_cafe_sales;



-- CREATE TABLE menu_prices (
--    item VARCHAR(255),
--    price DECIMAL(10 , 2 )
-- );

-- INSERT INTO menu_prices (item, price)       -- Creates a table for Prices 
-- VALUES
-- 	 ('Coffee', 2),
--     ('Tea', 1.5),
--    ('Sandwich', 4),
--    ('Salad', 5),
--    ('Cake', 3),
--    ('Cookie', 1),
--    ('Smoothie', 4),
--    ('Juice', 3);

-- Query Start

DROP TABLE IF EXISTS clean_cafe_sales;
-- Create TEMP TABLE copying dirty data collumn structure
CREATE TABLE clean_cafe_sales LIKE dirty_cafe_sales;

-- Insert dirty data into TEMP table
INSERT INTO clean_cafe_sales
SELECT *
FROM dirty_cafe_sales;

-- Duplicate Check / Removal
WITH DuplicationDelete AS (
    SELECT `Transaction ID`,
           `Item`,
           `Quantity`,
           `Price Per Unit`,
           `Total Spent`,
           `Payment Method`,
           `Location`,
           `Transaction Date`,
           ROW_NUMBER() OVER (PARTITION BY `Transaction ID`, `Item`, `Quantity`, `Price Per Unit`, `Total Spent`, `Payment Method`, `Location`, `Transaction Date` ORDER BY `Transaction ID`) AS rn
    FROM clean_cafe_sales
)
DELETE FROM clean_cafe_sales
WHERE `Transaction ID` IN (
    SELECT `Transaction ID`
    FROM DuplicationDelete
    WHERE rn > 1
);

-- Standardization Of Data

UPDATE clean_cafe_sales 
SET 
    `Item` = CASE
        WHEN `Item` IN ('ERROR' , 'UNKNOWN', '') THEN NULL
        ELSE `Item`
    END,
    Location = CASE
        WHEN Location IN ('ERROR' , 'UNKNOWN', '') THEN NULL
        ELSE Location
    END,
    `Payment Method` = CASE
        WHEN `Payment Method` IN ('ERROR' , 'UNKNOWN', '') THEN NULL
        ELSE `Payment Method`
    END,
    `Transaction Date` = CASE
        WHEN `Transaction Date` IN ('ERROR' , 'UNKNOWN', '') THEN NULL
        ELSE `Transaction Date`
    END,
    `Total Spent` = CASE
        WHEN
            `Quantity` IS NULL
                OR `Price Per Unit` IS NULL
        THEN
            NULL
        ELSE `Quantity` * `Price Per Unit`
    END;


WITH UniquePrices AS (
    SELECT `price`
    FROM menu_prices
    GROUP BY `price`
    HAVING COUNT(*) = 1
)
UPDATE clean_cafe_sales ccs
JOIN menu_prices mp
    ON ccs.`Price Per Unit` = mp.`price`
    AND ccs.`Item` IS NULL  -- Update only NULL values
JOIN UniquePrices up
    ON mp.`price` = up.`price`
SET ccs.`Item` = mp.`item`;
-- Finds Items With unique pricing in the menu prices i.e cookies costing £1 and no other menu items costing £1 we can populate the missing item fields with cookie based on the price per unit column using a join

ALTER TABLE clean_cafe_sales
MODIFY COLUMN `Transaction Date` DATE; -- changes the Column date to data type Transaction date, no need to use string to date as its already in correct format 

ALTER TABLE clean_cafe_sales
MODIFY COLUMN `Total Spent` decimal(10,2);

SELECT * FROM clean_cafe_sales;

DROP VIEW IF EXISTS cleaned_cafe_data;

CREATE VIEW cleaned_cafe_data AS
SELECT * 
FROM clean_cafe_sales;

