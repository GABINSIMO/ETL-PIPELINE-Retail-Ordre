
--creer un tableau (PROJECT c'est le nom de mon DB)
CREATE TABLE PROJECT.orders(
order_id int primary key
,order_date date
,ship_mode varchar(20)
,segment varchar(20)
,country varchar(20)
,city varchar(20)
,state varchar(20)
,postal_code varchar(20)
,region varchar(20)
,category varchar(20)
,sub_category varchar(20)
,product_id varchar(50)
,quantity int
,discount decimal(7,2)
,sale_price decimal(7,2)
,returns decimal(7,2)
,returns_percent decimal(7,2)
)

--importer le data.csv dans votre DB

--verifier si les donnees on bien ete importées
SELECT * FROM PROJECT.orders


SELECT *
FROM PROJECT.orders
LIMIT 5

--top region by sale
SELECT 
	region AS 'Region'
    ,SUM(sale_price) AS 'Regional sale'
FROM PROJECT.orders
GROUP BY region
ORDER BY 2 desc

--top state by sale
SELECT 
	state AS 'State'
    ,SUM(sale_price) AS 'State sale'
FROM PROJECT.orders
GROUP BY state
ORDER BY 2 desc

--top city by sale
SELECT 
	city AS 'City'
    ,SUM(sale_price) AS 'city sale'
FROM PROJECT.orders
GROUP BY city
ORDER BY 2 desc

--top segment by sale
SELECT 
	segment AS 'Segment'
    ,SUM(sale_price) AS 'Segment sale'
FROM PROJECT.orders
GROUP BY segment
ORDER BY 2 desc

--region with higher frequency
SELECT 
	region AS 'Region'
    ,COUNT(order_id) AS 'Count region'
FROM PROJECT.orders
GROUP BY region
ORDER BY 2 desc

--Shipment mode distribution
WITH cte AS
(SELECT DISTINCT 
	ship_mode
    ,count(order_id) over(partition by ship_mode) as 'Orders'
	,sum(sale_price) over(partition by ship_mode) as 'Sales' 
from PROJECT.orders)
SELECT 
	cte.ship_mode
    ,cte.Orders
    ,cte.Sales, 
ROUND((cte.Sales * 100.0) / (SELECT SUM(sale_price) FROM PROJECT.orders), 3) AS 'Sales %' FROM cte;

--produit avec le meilleur profit en %
SELECT *
FROM (SELECT product_id AS 'Product', returns_percent AS 'Returns', DENSE_RANK() OVER (ORDER BY returns_percent DESC) AS 'Rank'FROM PROJECT.orders) a
WHERE a.Rank<=1 

--produit avec le plus petit profit en %
SELECT *
FROM (SELECT product_id AS 'Produit',returns_percent AS 'return%',DENSE_RANK() OVER (ORDER BY returns_percent ASC) AS 'Rank'FROM PROJECT.orders) a
WHERE a.Rank<=1 

--moyenne de rabais par produit 
SELECT DISTINCT
	category As 'Category'
    ,AVG(discount) OVER (PARTITION BY CATEGORY) AS 'Average Discount'
FROM PROJECT.orders

--produit avec le meilleur discount 
SELECT DISTINCT
	product_id As 'produit'
    ,RANK() OVER (ORDER BY Discount DESC) AS 'Discount'
FROM PROJECT.orders

--order et quantity en fonction de la category et de la sub category
SELECT 
    category As 'Category'
    ,sub_category AS 'sub Category'
	,COUNT(order_id) As 'Count Order'
    ,SUM(quantity) AS 'total Quantity'
FROM PROJECT.orders
GROUP BY category, sub_category




--meilleures sous-catégories sub_category en fonction de leur croissance des ventes entre 2022 et 2023.
CALL TopSubCategoryProfit(5);
DELIMITER $$

CREATE PROCEDURE TopSubCategoryProfit(IN ranking INT)
BEGIN
    -- CTE pour calculer les ventes par année
    WITH cte AS (
        SELECT 
            sub_category AS Sub_Category,
            YEAR(order_date) AS Year,
            SUM(sale_price) AS Total
        FROM PROJECT.orders
        GROUP BY sub_category, YEAR(order_date)
    ),

    -- CTE pour transformer les années en colonnes (remplace PIVOT)
    cte2 AS (
        SELECT 
            sub_category,
            SUM(CASE WHEN Year = 2022 THEN Total ELSE 0 END) AS Sales_2022,
            SUM(CASE WHEN Year = 2023 THEN Total ELSE 0 END) AS Sales_2023
        FROM cte
        GROUP BY sub_category
    )

    -- Sélection finale avec le calcul de la croissance en %
    SELECT 
        sub_category, 
        Sales_2022, 
        Sales_2023, 
        CAST((Sales_2023 - Sales_2022) * 100.0 / NULLIF(Sales_2022, 0) AS DECIMAL(10,2)) AS Growth_Percentage
    FROM cte2
    ORDER BY Growth_Percentage DESC
    LIMIT ranking;

END $$

DELIMITER ;


