--data cleaning
--table 1
--Avoiding NULL value found in population
SELECT * 
FROM internet_users
WHERE population IS NOT Null


--checking any miss leading value 
--(easy way to find out wrong info on population and internet users count ie. more users than population)

SELECT country_name, region, internet_users, population
,round ((internet_users/population :: numeric)*100,2) percentage_of_population_use_internet
FROM internet_users
WHERE population IS NOT Null
ORDER BY percentage_of_population_use_internet DESC

--correcting region into continent
--(step 1)

SELECT sub_region, region, COUNT(sub_region) 
FROM internet_users
WHERE population IS NOT Null
GROUP BY sub_region, region

--(step 2)
SELECT country_name, sub_region,region, internet_users, population
,round ((internet_users/population :: numeric)*100,2) percentage_of_population_use_internet,
CASE when sub_region = 'Northern America' then 'North America'
	 when sub_region = 'Caribbean' then 'North America'
	 when sub_region = 'Central America' then 'North America'
	 when sub_region = 'South America' then sub_region
	 else region
END continent
FROM internet_users
WHERE population IS NOT Null

-- extracting required information from table

SELECT country_name,  
CASE when sub_region = 'Northern America' then 'North America'
	 when sub_region = 'Caribbean' then 'North America'
	 when sub_region = 'Central America' then 'North America'
	 when sub_region = 'South America' then sub_region
	 else region
END continent, internet_users, population
,round ((internet_users/population :: numeric)*100,2) percentage_of_population_use_internet
FROM internet_users
WHERE population IS NOT Null

--creating new cleaned table
DROP TABLE IF EXISTS internet_users_cleaned

CREATE TABLE internet_users_cleaned
(
	country_name  VARCHAR(255) PRIMARY KEY,
	continent VARCHAR(255),
	internet_users INT,
	population INT,
	percentage_of_population_use_internet INT
)

INSERT INTO internet_users_cleaned
( SELECT country_name,  
CASE when sub_region = 'Northern America' then 'North America'
	 when sub_region = 'Caribbean' then 'North America'
 	 when sub_region = 'Central America' then 'North America'
	 when sub_region = 'South America' then sub_region
	 else region
END continent, internet_users, population
,round ((internet_users/population :: numeric)*100,2) percentage_of_population_use_internet
FROM internet_users
WHERE population IS NOT Null
)


--cleaning table 2
--finding and avoiding NULL values

SELECT *
FROM internet_speed
WHERE avg_internet_speed is NULL

DELETE from internet_speed
WHERE avg_internet_speed is NULL

--cleaning table 3

SELECT *
FROM internet_prices
ORDER BY internet_plans

DELETE
FROM internet_prices
WHERE internet_plans <=0

SELECT *
FROM internet_prices
ORDER BY Average_price_of_1GB_2022

SELECT *
FROM internet_prices
WHERE Average_price_of_1GB_2021 is null

SELECT *
FROM internet_prices
WHERE Average_price_of_1GB_2020 is null

UPDATE internet_prices
SET Average_price_of_1GB_2020 = 19
WHERE country_name = 'Bermuda'

--avoiding outlier
SELECT*
FROM internet_prices
ORDER BY internet_prices.most_expensive_1gb DESC

DELETE
FROM internet_prices
WHERE internet_prices.most_expensive_1gb >750

--alter column names more readable
ALTER TABLE internet_prices RENAME COLUMN average_price_of_1gb_2022 TO avg_cost_2022;
ALTER TABLE internet_prices RENAME COLUMN average_price_of_1gb_2021 TO avg_cost_2021
ALTER TABLE internet_prices RENAME COLUMN average_price_of_1gb_2020 TO avg_cost_2020

-- getting needed info
SELECT country_name, internet_plans, avg_cost_2022, avg_cost_2021, avg_cost_2020
,round((avg_cost_2022 + avg_cost_2021 + avg_cost_2020)/3,2) as avg_cost_of_all_years
,cheapest_1gb_for_30_days as cheapest_plan, most_expensive_1gb as most_expensive_plan
FROM internet_prices

--making a cleaned table
CREATE TABLE internet_prices_cleaned
(
	country_name  VARCHAR(255) PRIMARY KEY,
	internet_plans INT, 
	avg_cost_2022 DECIMAL, 
	avg_cost_2021 DECIMAL,
	avg_cost_2020 DECIMAL,
	avg_cost_of_all_years DECIMAL,
	cheapest_plan DECIMAL, 
	most_expensive_plan DECIMAL
)

INSERT INTO internet_prices_cleaned
( 
	SELECT country_name, internet_plans, avg_cost_2022, avg_cost_2021, avg_cost_2020
	,round((avg_cost_2022 + avg_cost_2021 + avg_cost_2020)/3,2) as avg_cost_of_all_years
	,cheapest_1gb_for_30_days as cheapest_plan, most_expensive_1gb as most_expensive_plan
	FROM internet_prices
)

--EDA
-- percentage of polulation use internet
SELECT country_name, internet_users, percentage_of_population_use_internet
FROM internet_users_cleaned
ORDER BY internet_users DESC

-- percentage of population use internet continent wise
SELECT DISTINCT continent, SUM (population) OVER (PARTITION by continent) as population_continent
,SUM(internet_users) OVER (PARTITION BY continent) as internet_users_continent,
round (((SUM(internet_users) OVER (PARTITION BY continent)/ SUM(population) 
		 OVER (PARTITION by continent) :: Decimal)) * 100,0) as percent_of_population_use_internet
FROM internet_users_cleaned

--or by using window 
WITH users_continentCTE AS
(
	SELECT DISTINCT continent, SUM (population) OVER (PARTITION by continent) as population_continent
	,SUM(internet_users) OVER (PARTITION BY continent) as internet_users_continent
	FROM internet_users_cleaned
)

SELECT *,ROUND((internet_users_continent/population_continent:: DECIMAL)*100,0) AS percent_of_population_use_internet
FROM users_continentCTE

-- second model
SELECT DISTINCT continent, SUM (internet_users)
FROM internet_users_cleaned
GROUP BY continent

--number of plans with average cost of plan
SELECT country_name,internet_plans, avg_cost_of_all_years
FROM internet_prices_cleaned
ORDER BY internet_plans desc, avg_cost_of_all_years

--continent wise internet speed
SELECT DISTINCT us.continent, round (AVG (sp.avg_internet_speed),0) as avg_internet_speed
FROM internet_users_cleaned us
JOIN internet_speed sp
ON us.country_name = sp.country_name
GROUP BY us.continent
ORDER BY avg_internet_speed DESC

--finding countries speed difference in continent
SELECT DISTINCT us.continent, us.country_name, sp.avg_internet_speed
FROM internet_users_cleaned us
JOIN internet_speed sp
ON us.country_name = sp.country_name
GROUP BY us.continent,us.country_name, sp.avg_internet_speed
ORDER BY  us.continent 

--top 5 highest internet users countries
SELECT country_name, internet_users
FROM internet_users_cleaned
ORDER BY internet_users DESC
LIMIT 5

-- top 5 highest internet users countries' internet cost in 2020, 2021 and 2022
SELECT us.country_name, ps.avg_cost_2020, ps.avg_cost_2021, ps.avg_cost_2022
FROM internet_users_cleaned us
JOIN internet_prices_cleaned ps
ON ps.country_name = us.country_name
ORDER BY us.internet_users DESC
LIMIT 5

-- finding correlation between number of internet users and average cost of internet plans by countries
SELECT us.country_name, ps.avg_cost_of_all_years
FROM internet_users_cleaned us
JOIN internet_prices_cleaned ps
ON ps.country_name = us.country_name
ORDER BY us.internet_users DESC

-- Is there any countries where less than 50% of population use internet
SELECT continent, count (continent) AS countries_less_than_half_of_population_use_internet
FROM internet_users_cleaned
WHERE percentage_of_population_use_internet <50
Group by continent
