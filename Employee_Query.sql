SELECT * FROM dbo.Employee_Data01;

SELECT * FROM dbo.Employee_Data02;



--Returns values from table 1 and 2
SELECT 'Table 01' AS Source_Table,
       Employee_ID,
       First_Name,
       Last_Name,
       Department,
	   Reports_To,
	   Site,
       Salary,
	   Hire_Date
FROM dbo.Employee_Data01

UNION ALL

SELECT 'Table 02' AS Source_Table,
       Employee_ID,
       First_Name,
       Last_Name,
       Department,
	   Reports_To,
	   Site,
       Salary,
	   Hire_Date
FROM dbo.Employee_Data02
ORDER BY Employee_ID;



-- Creates a temporary table.
CREATE TABLE #CombinedTable (
    Employee_ID TINYINT,
    First_Name VARCHAR(50),
    Last_Name VARCHAR(50),
	Department VARCHAR(25),
    Reports_To TINYINT,
    Site VARCHAR(50),
    Salary MONEY,
    Hire_Date VARCHAR(25)
)

INSERT INTO #CombinedTable (Employee_ID, First_Name, Last_Name, Department, Reports_To, Site, Salary, Hire_Date)
SELECT Employee_ID, First_Name, Last_Name, Department, Reports_To, Site, Salary, Hire_Date
FROM Employee_Data01

INSERT INTO #CombinedTable (Employee_ID, First_Name, Last_Name, Department, Reports_To, Site, Salary, Hire_Date)
SELECT Employee_ID, First_Name, Last_Name, Department, Reports_To, Site, Salary, Hire_Date
FROM Employee_Data02

SELECT * FROM #CombinedTable;



--Returns rows that contain null values
SELECT *
FROM #CombinedTable
WHERE Employee_ID IS NULL
   OR First_Name IS NULL
   OR Last_Name IS NULL
   OR Department IS NULL
   OR Reports_To IS NULL
   OR Site IS NULL
   OR Salary IS NULL
   OR Hire_Date IS NULL;


-- Returns corrected Department column
SELECT *,
    UPPER(REPLACE(REPLACE(TRIM(Department), '_', ''), ' ', '')) 
	AS Department_Fixed
FROM #CombinedTable



-- Returns corrected Salary column
SELECT *,
    CASE 
        WHEN Salary = '165000000.00' THEN '1650000.00'
        ELSE Salary
    END AS Salary_Fixed
FROM #CombinedTable
ORDER BY Salary_Fixed DESC;



-- Returns fixed employee ID values
SELECT *,
    CASE
        WHEN Site = 'Washington' 
			THEN Employee_ID + 24
		WHEN First_Name = 'Ted' AND Last_Name = 'Ford' 
			THEN 31
		WHEN First_Name = 'Felicity' AND Last_Name = 'Miller' 
			THEN 32
        ELSE Employee_ID
    END AS Employee_ID_Fixed
FROM #CombinedTable;



-- Returns Reports_To column to reflect correct reports to assignment number
SELECT *,
              CASE
                  WHEN Site = 'Washington' AND Reports_To = 1
                      THEN 25
                  WHEN Site = 'Washington' AND Reports_To = 5
                      THEN 29
				  WHEN ISNULL(Reports_To, 0) = 0
					  THEN 0
                  ELSE Reports_To
              END AS Reports_To_Fixed
FROM #CombinedTable;



-- Corrects Hire_Date format errors and standardizes it to MM/DD/YYYY. Corrected error where year date was incorrect
SELECT *,
		CASE
			WHEN Hire_Date = '4/23/3023' THEN '04/23/2023'
			WHEN TRY_CONVERT(date, Hire_Date, 101) IS NOT NULL 
				THEN CONVERT(varchar, TRY_CONVERT(date, Hire_Date, 101), 101)
			WHEN TRY_CONVERT(date, Hire_Date, 3) IS NOT NULL 
				THEN CONVERT(varchar, TRY_CONVERT(date, Hire_Date, 3), 101)
			WHEN TRY_CONVERT(date, Hire_Date, 1) IS NOT NULL 
				THEN CONVERT(varchar, TRY_CONVERT(date, Hire_Date, 1), 101)
			WHEN TRY_CONVERT(date, Hire_Date, 103) IS NOT NULL 
				THEN CONVERT(varchar, TRY_CONVERT(date, Hire_Date, 103), 101)
			WHEN TRY_CONVERT(date, Hire_Date, 120) IS NOT NULL 
				THEN CONVERT(varchar, TRY_CONVERT(date, Hire_Date, 120), 101)
			WHEN TRY_CONVERT(date, CONCAT(RIGHT(Hire_Date, 4), LEFT(Hire_Date, 4)), 112) IS NOT NULL 
				THEN CONVERT(varchar, TRY_CONVERT(date, CONCAT(RIGHT(Hire_Date, 4), LEFT(Hire_Date, 4))), 101)
			ELSE CONVERT(VARCHAR, TRY_CONVERT(DATE, CAST(CAST(Hire_Date AS INT) + 19000000 AS NVARCHAR), 101), 101)
		END AS Hire_Date_Fixed
FROM #CombinedTable;



-- Returns corrected errors in First_Name and Last_Name columns. This creates a subquery which creates an 'initial' column of values which focuses on correcting errors in the first names. 
-- Then performs a second pass where it focuses on correcting the last names resulting in the fixed first and last names list. 
-- Also, corrects issue with missing first name value for 'Bob Taylor'
SELECT Employee_ID, First_Name, Last_Name, Department, Reports_To, Site, Salary, Hire_Date,
	CASE
		WHEN Last_Name = 'Taylor' THEN 'Bob'
		WHEN First_Name IS NULL AND CHARINDEX(' ', Last_Name_Initial) > 0 THEN LEFT(Last_Name_Initial, CHARINDEX(' ', Last_Name_Initial) - 1)
		ELSE First_Name_Initial
	END AS First_Name_Fixed,
	CASE
		WHEN First_Name IS NULL AND CHARINDEX(' ', Last_Name_Initial) > 0 THEN SUBSTRING(Last_Name_Initial, CHARINDEX(' ', Last_Name_Initial) + 1, LEN(Last_Name_Initial))
		ELSE Last_Name_Initial
	END AS Last_Name_Fixed
FROM (
	SELECT *,
		CASE
			WHEN (First_Name IS NULL AND Last_Name LIKE '% %') OR CHARINDEX(' ', First_Name) > 0 THEN LEFT(ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, ''), CHARINDEX(' ', ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, '')) - 1)
			ELSE First_Name
		END AS First_Name_Initial,
		CASE
			WHEN (First_Name IS NULL AND Last_Name LIKE '% %') OR CHARINDEX(' ', First_Name) > 0 THEN SUBSTRING(ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, ''), CHARINDEX(' ', ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, '')) + 1, LEN(ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, '')))
			ELSE Last_Name
		END AS Last_Name_Initial
	FROM #CombinedTable
) AS NameSubquery



---------------------------------------------------------------------------------------------------------------------
-- Adds new 'Fixed' columns to temporary combined table
ALTER TABLE #CombinedTable
ADD RowID INT IDENTITY(1, 1),
	Employee_ID_Fixed TINYINT,
	First_Name_Fixed VARCHAR(50),
	Last_Name_Fixed VARCHAR(50),
	Department_Fixed VARCHAR(25),
	Reports_To_Fixed TINYINT,
	Salary_Fixed MONEY,
	Hire_Date_Fixed DATE,
	Manager_Name VARCHAR(50),
	Unique_ID VARCHAR(50)

SELECT * FROM #CombinedTable;



-- Updates temporary table to include fixed employee ID column
UPDATE #CombinedTable
SET Employee_ID_Fixed = CASE
							WHEN Site = 'Washington' 
								THEN Employee_ID + 24
							WHEN First_Name = 'Ted' AND Last_Name = 'Ford' 
								THEN 31
							WHEN First_Name = 'Felicity' AND Last_Name = 'Miller' 
								THEN 32
						ELSE Employee_ID
END

SELECT * FROM #CombinedTable
ORDER BY Employee_ID_Fixed;



-- Writes fixed names to #CombinedTable NS = NameSubquery, CT = CombinedTable
UPDATE CT
SET CT.First_Name_Fixed = CASE
        WHEN CT.Last_Name = 'Taylor' THEN 'Bob'
        WHEN CT.First_Name IS NULL AND CHARINDEX(' ', NS.Last_Name_Initial) > 0 THEN LEFT(NS.Last_Name_Initial, CHARINDEX(' ', NS.Last_Name_Initial) - 1)
        ELSE NS.First_Name_Initial
    END,
    CT.Last_Name_Fixed = CASE
        WHEN CT.First_Name IS NULL AND CHARINDEX(' ', NS.Last_Name_Initial) > 0 THEN SUBSTRING(NS.Last_Name_Initial, CHARINDEX(' ', NS.Last_Name_Initial) + 1, LEN(NS.Last_Name_Initial))
        ELSE NS.Last_Name_Initial
    END
FROM #CombinedTable CT
JOIN (
    SELECT RowID, First_Name, Last_Name,
        CASE
            WHEN (First_Name IS NULL AND Last_Name LIKE '% %') OR CHARINDEX(' ', ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, '')) > 0 THEN LEFT(ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, ''), CHARINDEX(' ', ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, '')) - 1)
            ELSE First_Name
        END AS First_Name_Initial,
        CASE
            WHEN (First_Name IS NULL AND Last_Name LIKE '% %') OR CHARINDEX(' ', ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, '')) > 0 THEN SUBSTRING(ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, ''), CHARINDEX(' ', ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, '')) + 1, LEN(ISNULL(First_Name, '') + ' ' + ISNULL(Last_Name, '')))
            ELSE Last_Name
        END AS Last_Name_Initial
    FROM #CombinedTable
) AS NS ON CT.RowID = NS.RowID

SELECT * FROM #CombinedTable;



-- Updates temporary table to include fixed deparment column
UPDATE #CombinedTable
SET Department_Fixed = UPPER(REPLACE(REPLACE(TRIM(Department), '_', ''), ' ', ''))

SELECT * FROM #CombinedTable;



-- Fixes Reports_To column to reflect correct 
UPDATE #CombinedTable
SET Reports_To_Fixed = 
    CASE
        WHEN Site = 'Washington' AND Reports_To = 1
            THEN 25
        WHEN Site = 'Washington' AND Reports_To = 5
            THEN 29
        WHEN ISNULL(Reports_To, 0) = 0
            THEN 0
        ELSE Reports_To
    END

SELECT * FROM #CombinedTable;



-- Updates temporary table to include fixed salary column
UPDATE #CombinedTable
SET Salary_Fixed = REPLACE(Salary, '165000000.00', '1650000.00')

SELECT * FROM #CombinedTable
ORDER BY Salary_Fixed DESC;



-- Writes fixed hire dates to #CombinedTable
UPDATE #CombinedTable
SET Hire_Date_Fixed = 
    CASE
		WHEN Hire_Date = '4/23/3023' 
			THEN '04/23/2023'
		WHEN TRY_CONVERT(date, Hire_Date, 101) IS NOT NULL 
			THEN CONVERT(varchar, TRY_CONVERT(date, Hire_Date, 101), 101)
		WHEN TRY_CONVERT(date, Hire_Date, 3) IS NOT NULL 
			THEN CONVERT(varchar, TRY_CONVERT(date, Hire_Date, 3), 101)
		WHEN TRY_CONVERT(date, Hire_Date, 1) IS NOT NULL 
			THEN CONVERT(varchar, TRY_CONVERT(date, Hire_Date, 1), 101)
		WHEN TRY_CONVERT(date, Hire_Date, 103) IS NOT NULL 
			THEN CONVERT(varchar, TRY_CONVERT(date, Hire_Date, 103), 101)
		WHEN TRY_CONVERT(date, Hire_Date, 120) IS NOT NULL 
			THEN CONVERT(varchar, TRY_CONVERT(date, Hire_Date, 120), 101)
		WHEN TRY_CONVERT(date, CONCAT(RIGHT(Hire_Date, 4), LEFT(Hire_Date, 4)), 112) IS NOT NULL 
			THEN CONVERT(varchar, TRY_CONVERT(date, CONCAT(RIGHT(Hire_Date, 4), LEFT(Hire_Date, 4))), 101)
		ELSE CONVERT(VARCHAR, TRY_CONVERT(DATE, CAST(CAST(Hire_Date AS INT) + 19000000 AS NVARCHAR), 101), 101)
    END

SELECT * FROM #CombinedTable;



-- Updates table with Manager Names
UPDATE c1
SET Manager_Name = CONCAT(c2.First_Name_Fixed, ' ', c2.Last_Name_Fixed,
              CASE
                  WHEN c1.Reports_To_Fixed = 0 THEN 'Owner'
                  ELSE ''
              END)
FROM #CombinedTable AS c1
LEFT JOIN #CombinedTable AS c2 ON c1.Reports_To_Fixed = c2.Employee_ID_Fixed;


SELECT * FROM #CombinedTable;



-- Updates table which combines first and last names with the department and employee ID
UPDATE #CombinedTable
SET Unique_ID = CONCAT(First_Name_Fixed, Last_Name_Fixed, Department_Fixed)

SELECT * FROM #CombinedTable;


--  Drops RowID column
ALTER TABLE #CombinedTable
DROP COLUMN RowID;

SELECT * FROM #CombinedTable;



--Performs Duplicate check
SELECT Employee_ID_Fixed, First_Name_Fixed, Last_Name_Fixed, Unique_ID, COUNT(*) AS DuplicateCount
FROM #CombinedTable
GROUP BY Employee_ID_Fixed, First_Name_Fixed, Last_Name_Fixed, Unique_ID
HAVING COUNT(*) > 1
ORDER BY Employee_ID_Fixed;



--Delete duplicate rows
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Employee_ID_Fixed ORDER BY (SELECT NULL)) AS RowNumber
    FROM #CombinedTable
)
DELETE FROM CTE WHERE RowNumber > 1

SELECT * FROM #CombinedTable ORDER BY Employee_ID_Fixed;



-- Create the permanent table with the desired columns
CREATE TABLE Employee_Master (
    Employee_ID TINYINT,
    First_Name VARCHAR(50),
    Last_Name VARCHAR(50),
	Department VARCHAR(25),
    Reports_To TINYINT,
    Site VARCHAR(50),
    Salary MONEY,
    Hire_Date DATE,
	Manager_Name VARCHAR(50),
	Unique_ID VARCHAR(50),
);

-- Insert the fixed columns from the temporary table into the permanent table
INSERT INTO Employee_Master (Employee_ID, First_Name, Last_Name, Department, Reports_To, Site, Salary, Hire_Date, Manager_Name, Unique_ID)
SELECT Employee_ID_Fixed, First_Name_Fixed, Last_Name_Fixed, Department_Fixed, Reports_To_Fixed, Site, Salary_Fixed, Hire_Date_Fixed, Manager_Name, Unique_ID
FROM #CombinedTable;

SELECT * FROM Employee_Master;



-- Drops temporary table as it's no longer needed
DROP TABLE #CombinedTable;



-- Alter the table schema to make Employee_ID NOT NULL
ALTER TABLE Employee_Master
ALTER COLUMN Employee_ID INT NOT NULL;



-- Add PRIMARY KEY constraint on Employee_ID column
ALTER TABLE Employee_Master
ADD CONSTRAINT PK_CombinedTable PRIMARY KEY (Employee_ID);

SELECT * FROM Employee_Master;


-- Returns average salary for delivery department
SELECT AVG(Salary) AS AverageSalary_Delivery
FROM Employee_Master
WHERE Department = 'Delivery';



-- Returns average salary for accounting department
SELECT AVG(Salary) AS AverageSalary_Warehouse
FROM Employee_Master
WHERE Department = 'Warehouse';



-- Create's pivot table of the average salary of delivery, IT and warehouse employees based on site as well as totals
SELECT P.Department, ROUND(P.[Springfield], 2) AS AverageSalary_Springfield, ROUND(P.[Glendale], 2) AS AverageSalary_Glendale, ROUND(P.[Washington], 2) AS AverageSalary_Washington, ROUND(T.AverageSalary_Total, 2) AS AverageSalary_Total
FROM
(
    SELECT Department, Site, AVG(Salary) AS AverageSalary
    FROM Employee_Master
    WHERE Department IN ('Delivery', 'Warehouse', 'IT')
    GROUP BY Department, Site
) AS PivotData
PIVOT
(
    AVG(AverageSalary)
    FOR Site IN ([Springfield], [Glendale], [Washington])
) AS P
JOIN
(
    SELECT Department, AVG(Salary) AS AverageSalary_Total
    FROM Employee_Master
    WHERE Department IN ('Delivery', 'Warehouse', 'IT')
    GROUP BY Department
) AS T ON P.Department = T.Department;

