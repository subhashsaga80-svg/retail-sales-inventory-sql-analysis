show databases ;
use case_study_retail_analytics ;
show  tables from case_study_retail_analytics ;
ALTER TABLE `customer_profiles-1-1714027410`
RENAME TO `customer_profiles`;
ALTER TABLE `product_inventory-1-1714027438`
RENAME TO `product_inventory`;
ALTER TABLE `sales_transaction-1714027462`
RENAME TO `sales_transaction`;

select * from customer_profiles ;
ALTER TABLE customer_profiles
RENAME COLUMN `ï»¿CustomerID` TO `CustomerID`;
describe customer_profiles ;

ALTER TABLE customer_profiles
MODIFY COLUMN joindate DATE;

update  customer_profiles
set location = trim(Location) ;

-- where location is null

SELECT COUNT(*) AS total_blank_location
FROM customer_profiles
WHERE Location IS NULL
   OR TRIM(Location) = '';
   
   SELECT CustomerID, Location
FROM customer_profiles
WHERE Location IS NULL
   OR TRIM(Location) = '';
   update customer_profiles
   set location = "West"
   where CustomerID = 4 ;
   SELECT *
FROM customer_profiles 
where CustomerID = 4 ;
UPDATE customer_profiles
SET Location = ''
WHERE CustomerID = 4;

select * from product_inventory ;
alter table product_inventory
modify  column ï»¿ProductID text  ;

ALTER TABLE product_inventory
RENAME COLUMN `ï»¿ProductID` TO `ProductID`;

select count(*) from product_inventory ;
-- where Price is not null or ProductID = '' ;

select * from sales_transaction ;
alter table sales_transaction
rename column `ï»¿TransactionID` to `TransactionID` ;
alter table sales_transaction
modify column TransactionDate date ;

select * from customer_profiles ;
select * from product_inventory ;
select * from sales_transaction ;



select * from sales_transaction ;
/*
Write a query to identify the number of duplicates in "sales_transaction" table. 
Also, create a separate table containing the unique values and remove the the original table from the databases 
and replace the name of the new table with the original name.
*/
select TransactionID , count(*) as duplicate_count
from sales_transaction 
group by TransactionID 
having count(*) > 1 ;
create table unique_sales_transaction as select distinct * from sales_transaction ;
drop table sales_transaction ;
select * from sales_transaction ;
alter table unique_sales_transaction 
rename to sales_transaction ;

select * from sales_transaction ;
select * from product_inventory ;

select st.TransactionID , st.Price as TransactionPrice , pi.Price as InventoryPrice
from sales_transaction st 
inner join product_inventory pi 
on pi.ProductID = st.ProductID 
where st.Price != pi.Price ;

alter table customer_profiles
rename customers ;
alter table product_inventory
rename product ;
alter table sales_transaction
rename sales ;
alter table customers
modify joindate date ;

 select joindate, str_to_date(joindate, "%d/%m/%y") as new_date 
from customers ;
update customers
set joindate = str_to_date(joindate, "%d-%m-%y") ;


select * from customers ;
update customers
set location ='Unknown'
where location ='' ;
select TransactionID,count(*) as transaction_count
from sales 
group by TransactionID 
having transaction_count > 1 ;

-- analyse total sales and quanties for each product 
select p.ProductID, sum(s.QuantityPurchased) as net_Quantity, 
round(sum(p.price * s.QuantityPurchased),2) as net_sales from product p 
join sales s
on p.ProductID = s.ProductID 
 group by p.ProductID;
 
 -- analyze the purchase frequency of the customers
 select CustomerID , count(*) as cnt_trans
 from sales
 group by CustomerID
 order by cnt_trans desc ;
 
-- create a view to stores sales and products info together 

create view sales_detailed as (select p.ProductName,p.Category,p.StockLevel,
s.TransactionID,s.CustomerID,s.ProductID,s.QuantityPurchased,s.TransactionDate,s.price from product p 
join sales s
on p.ProductID = s.ProductID 
);

select * from sales_detailed ;
-- analyze sales by product category 
select Category , round(sum(QuantityPurchased * price ),2) as net_sales 
from sales_detailed 
group by Category ;

-- Finding Top selling Product : using limit and rank

select Productid, round(sum(QuantityPurchased * price),2)
 as net_sell
from sales_detailed 
group by Productid
order by net_sell desc
limit 10;

with sales_detail as (select Productid, round(sum(QuantityPurchased * price),2)
 as net_sell,
 rank() over(order by round(sum(QuantityPurchased * price),2) desc) as sales_Rank
from sales_detailed 
group by Productid
)

select Productid , net_sell,sales_Rank
FROM sales_detail 
where sales_Rank  < 11;

-- to calculate sales on daily sales trend

select TransactionDate , round(sum(QuantityPurchased*price),2) as net_sales 
from sales_detailed 
group by TransactionDate 
order by TransactionDate ;

-- identify the day of the week has the highest avg sales 

with daily_net_sales as ( select TransactionDate , round(sum(QuantityPurchased*price),2) as net_sales 
from sales_detailed 
group by TransactionDate  
)
select dayofweek(TransactionDate) as dow , round(avg(net_sales),2) as avg_sales
from daily_net_sales 
group by dayofweek(TransactionDate) 
order by avg_sales desc;

-- identify the quarter that has the highest avg sales

with daily_net_sales as ( select TransactionDate , round(sum(QuantityPurchased*price),2) as net_sales 
from sales_detailed 
group by TransactionDate  
)
select quarter(TransactionDate) as quar_series , round(avg(net_sales),2) as avg_sales
from daily_net_sales 
group by quarter(TransactionDate)
order by avg_sales desc ;

-- Calculat Month-on-Month Sales Growth with LAG()**

with monthly_net_sales as (select month(TransactionDate) as tran_mnth , round(sum(QuantityPurchased * price),2) as net_sale
from sales_detailed
group by tran_mnth 
order by tran_mnth)
select tran_mnth,(net_sale-lag(net_sale) over(order by tran_mnth))/net_sale * 100 as increasemental_sales 
from monthly_net_sales ;

-- Filter High-Frequency Customers with the HAVING Clause

select CustomerID , count(*) as freq
from sales
group by CustomerID 
having freq > 10;

-- Defin Customer Loyalty: Time Between First and Last Purchase

select CustomerID ,  (max(TransactionDate)- min(TransactionDate)) as loyality_indicator  
from sales_detailed
group by CustomerID 
order by loyality_indicator desc ;

-- Segmenting Customers Using CASE WHEN Statements

with loyality_cust as (select CustomerID ,  (max(TransactionDate)- min(TransactionDate)) as loyality_indicator  
from sales_detailed
group by CustomerID 
order by loyality_indicator desc
)
select CustomerID , case 
when loyality_indicator < 113568 then 'active'
when loyality_indicator < 18009 then 'moderate'
else 'excellent'
end as Customer_Segmentation
from loyality_cust ;  


