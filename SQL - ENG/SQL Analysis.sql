--I've created a database called Analysis, imported the table from the Excel file available in the folder, 
--and named it dbo.CleanData
--If you would like to execute the code, please do the same.


USE Analysis
SELECT * FROM dbo.CleanData

--PLEASE NOTE--
--To check the functionality of the entire code, I recommend creating a new SQL file, importing the Excel file and then 
--running the code.

--Checking the Datatype for all columns
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'CleanData'

-----Changing the data type of salary columns from money to numeric to avoid any future calculation issues-----

--Creating duplicate columns
ALTER TABLE dbo.CleanData
ADD Min_Numeric Money NULL,
	Max_Numeric Money NULL,
	Avg_Numeric Money NULL

--Copying the contents of the columns
UPDATE dbo.CleanData SET Min_Numeric = YearlySalaryMin
UPDATE dbo.CleanData SET Max_Numeric = YearlySalaryMax
UPDATE dbo.CleanData SET Avg_Numeric = YearlySalaryAvg

--Changing the data type for the original columns
ALTER TABLE dbo.CleanData
ALTER COLUMN YearlySalaryMin DECIMAL(22,2) NULL

ALTER TABLE dbo.CleanData
ALTER COLUMN YearlySalaryMax DECIMAL(22,2) NULL

ALTER TABLE dbo.CleanData
ALTER COLUMN YearlySalaryAvg DECIMAL(22,2) NULL

--Counting the number of rows to check what should be the results of the next query
SELECT COUNT(*) as Row_count
FROM dbo.CleanData

--Checking if the values in the rows are the same by comparing the original columns with numeric datatypes
--to their duplicate with money datatype
SELECT 
SUM(CASE WHEN YearlySalaryMin = Min_Numeric THEN 1 ELSE 0 END) AS Comparison,
SUM(CASE WHEN YearlySalaryMax = Max_Numeric THEN 1 ELSE 0 END) AS Comparison,
SUM(CASE WHEN YearlySalaryAvg = Avg_Numeric THEN 1 ELSE 0 END) AS Comparison
FROM dbo.CleanData

--Datatype change was successful, hence deleting the duplicate columns
ALTER TABLE dbo.CleanData
DROP COLUMN Min_Numeric, Max_Numeric, Avg_Numeric


--------CALCULATIONS----------


--TOP 3 Sectors with the highest Average Yearly Salary with no filters
SELECT TOP 3 Sector, CAST(ROUND(AVG(YearlySalaryAvg),2) AS DECIMAL(22,2)) as AverageYearlySalary,
COUNT(*) as Job_Offers
FROM dbo.CleanData
GROUP BY Sector
ORDER BY AverageYearlySalary DESC


--TOP 3 Sectors with the highest Average Yearly Salary with >= 10 job offers
SELECT TOP 3 Sector, CAST(ROUND(AVG(YearlySalaryAvg),2) AS DECIMAL(22,2)) as AverageYearlySalary,
COUNT(*) as Job_Offers
FROM dbo.CleanData
GROUP BY Sector
HAVING COUNT(Sector) >= 10
ORDER BY AverageYearlySalary DESC


--Calculating how much money can be earned in the TOP 3 sectors compared to the Total Average for all sectors
--WTIH CTE must be executed with the query below
WITH 
Sectors_10 (Sector)
AS
(
	SELECT Sector
	FROM dbo.CleanData
	GROUP BY Sector
	HAVING COUNT(Sector) >= 10
),
AllAvg_10 (TotalAvg)
AS
(
	SELECT CAST(ROUND(AVG(YearlySalaryAvg),2) AS DECIMAL(22,2)) as AverageYearlySalary
	FROM dbo.CleanData
	WHERE Sector IN (SELECT Sector FROM Sectors_10)
),
TOP3_Sectors_Avg (Sector, AverageYearlySalary)
AS
(
	SELECT TOP 3 Sector, CAST(ROUND(AVG(YearlySalaryAvg),2) AS DECIMAL(22,2)) as AverageYearlySalary
	FROM dbo.CleanData
	GROUP BY Sector
	HAVING COUNT(Sector) >= 10
	ORDER BY AverageYearlySalary DESC
)

Select Sector, CAST(ROUND(((AverageYearlySalary/TotalAvg) -1)*100, 2) as DECIMAL(22,2)) AS PercSalaryIncrease
from TOP3_Sectors_Avg, AllAvg_10



--Finding TOP 3 states with the highest number of job offers and the highest average salary for Information Technology

--Instead of creating a subquery/WITH CTE I've decided to manually enter the Sector Name and Average Salary
--as there are only 3 sectors and each one has 2 records that need to be entered, hence creating
--a subquery/CTE doesn't seem like the best solution
SELECT TOP 3 LocationState, CAST(ROUND(AVG(YearlySalaryAvg),2) as DECIMAL(22,2)) as AverageYearlySalary, 
COUNT(*) as NumberOfJobOffers
FROM dbo.CleanData
WHERE Sector = 'Information Technology'
GROUP BY LocationState
HAVING AVG(YearlySalaryAvg) >= 113191.67
ORDER BY NumberOfJobOffers DESC, AverageYearlySalary DESC



--Finding TOP 3 states with the highest number of job offers and the highest average salary for Biotech & Pharmaceuticals
SELECT TOP 3 LocationState, CAST(ROUND(AVG(YearlySalaryAvg),2) as DECIMAL(22,2)) as AverageYearlySalary, 
COUNT(*) as NumberOfJobOffers
FROM dbo.CleanData
WHERE Sector = 'Biotech & Pharmaceuticals'
GROUP BY LocationState
HAVING AVG(YearlySalaryAvg) >= 112441.44
ORDER BY NumberOfJobOffers DESC, AverageYearlySalary DESC



--Finding TOP 3 states with the highest number of job offers and the highest average salary for Insurance
SELECT TOP 3 LocationState, CAST(ROUND(AVG(YearlySalaryAvg),2) as DECIMAL(22,2)) as AverageYearlySalary, 
COUNT(*) as NumberOfJobOffers
FROM dbo.CleanData
WHERE Sector = 'Insurance'
GROUP BY LocationState
HAVING AVG(YearlySalaryAvg) >= 105942.03
ORDER BY NumberOfJobOffers DESC, AverageYearlySalary DESC


--Creating a Temporary Table to modify the Revenue records in such a way that there are only 3 groups
--while leaving the original table unmodified
SELECT 
*,
CASE 
	WHEN Revenue IN ('Less than $1 million (USD)', '$1 to $5 million (USD)', '$5 to $10 million (USD)', 
	'$10 to $25 million (USD)', '$25 to $50 million (USD)', '$50 to $100 million (USD)') 
	THEN 'Below $100 Mil' 
	WHEN Revenue IN ('$100 to $500 million (USD)', '$500 million to $1 billion (USD)') 
	THEN 'Between $100 Mil - $1B' 
	WHEN Revenue IN ('$1 to $2 billion (USD)', '$2 to $5 billion (USD)','$5 to $10 billion (USD)',
	'$10+ billion (USD)')
	THEN 'Above $1B'
	ELSE Revenue 
END AS RevenueG
INTO #RevenueGroups
FROM dbo.CleanData
WHERE Revenue != 'Unknown / Non-Applicable'


--Finding the revenue impact on the number of jobs and average salary in the top 3 states from top 3 sectors--

--Information Technology
SELECT LocationState AS State, RevenueG as Revenue, 
CAST(ROUND(AVG(YearlySalaryAvg),2) AS DECIMAL(10,2)) AS AverageSalary, COUNT(*) AS NumberOfJobOffers
FROM #RevenueGroups
WHERE Sector = 'Information Technology'	AND LocationState IN ('CA', 'NY', 'WA')
GROUP BY LocationState, RevenueG
ORDER BY LocationState ASC


--Biotech & Pharmaceuticals
SELECT LocationState AS State, RevenueG as Revenue, 
CAST(ROUND(AVG(YearlySalaryAvg),2) AS DECIMAL(10,2)) AS AverageSalary, COUNT(*) AS NumberOfJobOffers
FROM #RevenueGroups
WHERE Sector = 'Biotech & Pharmaceuticals'	AND LocationState IN ('MA', 'CA', 'NY')
GROUP BY LocationState, RevenueG
ORDER BY LocationState ASC


--Insurance
SELECT LocationState AS State, RevenueG as Revenue, 
CAST(ROUND(AVG(YearlySalaryAvg),2) AS DECIMAL(10,2)) AS AverageSalary, COUNT(*) AS NumberOfJobOffers
FROM #RevenueGroups
WHERE Sector = 'Insurance'	AND LocationState IN ('NY', 'IL', 'NC')
GROUP BY LocationState, RevenueG
ORDER BY LocationState ASC
