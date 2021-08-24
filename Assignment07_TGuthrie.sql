--*************************************************************************--
-- Title: Assignment07
-- Author: TGuthrie
-- Desc: This file demonstrates how to use Functions
-- Change Log: When,Who,What
-- 22 Aug 2021,TGuthrie,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment07DB_TGuthrie')
	 Begin 
	  Alter Database [Assignment07DB_TGuthrie] set Single_user With Rollback Immediate;
	  Drop Database Assignment07DB_TGuthrie;
	 End
	Create Database Assignment07DB_TGuthrie;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment07DB_TGuthrie;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [money] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL
,[ProductID] [int] NOT NULL
,[ReorderLevel] int NOT NULL -- New Column 
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, ReorderLevel, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, ReorderLevel, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, ReorderLevel, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Order By 1, 2
go

-- Adding Views (Module 06) -- 
Create View vCategories With SchemaBinding
 AS
  Select CategoryID, CategoryName From dbo.Categories;
go
Create View vProducts With SchemaBinding
 AS
  Select ProductID, ProductName, CategoryID, UnitPrice From dbo.Products;
go
Create View vEmployees With SchemaBinding
 AS
  Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID From dbo.Employees;
go
Create View vInventories With SchemaBinding 
 AS
  Select InventoryID, InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count] From dbo.Inventories;
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From vCategories;
go
Select * From vProducts;
go
Select * From vInventories;
go
Select * From vEmployees;
go

/********************************* Questions and Answers ********************************
'NOTES------------------------------------------------------------------------------------ 
 1) You must use the BASIC views for each table.
 2) Remember that Inventory Counts are Randomly Generated. So, your counts may not match mine
 3) To make sure the Dates are sorted correctly, you can use Functions in the Order By clause!
------------------------------------------------------------------------------------------'*/

-- Question 1 (5% of pts): What built-in SQL Server function can you use to show a list 
-- of Product names, and the price of each product, with the price formatted as US dollars?
-- Order the result by the product!

	Select	ProductName,						-- Get this column 
			Format (UnitPrice,'C', 'en-us')		-- Get the cost, but in original table it's an int, so change to a currency
		From vProducts							-- View the informaton is coming from
		Order By UnitPrice;						-- Sort the output by the price
	go

-- Question 2 (10% of pts): What built-in SQL Server function can you use to show a list 
-- of Category and Product names, and the price of each product, 
-- with the price formatted as US dollars?
-- Order the result by the Category and Product!

	Select	CategoryName,										-- Get this column
			ProductName,										-- Get this column
			Format (UnitPrice,'C', 'en-us')						-- Get this column, but format as $
		From vCategories Inner Join vProducts					-- Data is from two views, so join first
			On vCategories.CategoryID = vProducts.CategoryID	-- by these values
		Order By 
			CategoryName,
			ProductName;										-- Sort by these names
	go

-- Question 3 (10% of pts): What built-in SQL Server function can you use to show a list 
-- of Product names, each Inventory Date, and the Inventory Count,
-- with the date formatted like "January, 2017?" 
-- Order the results by the Product, Date, and Count!

	-- Got this to work
	/*
		Select	ProductName,										-- Get this column
				InventoryDate,										-- Get this column
				[Count]												-- Get this column
			From vProducts Inner Join vInventories					-- Data is from two views, so join first
				On vProducts.ProductID = vInventories.ProductID		-- on these values 
			Order By												-- Sort by these columns
				ProductName,										-- First
				InventoryDate,										-- Second
				[Count];											-- Third
		go
	*/
	-- Adding the quirky date type
	Select	ProductName,										-- Get this column
			DateName(mm, InventoryDate) + ', '					-- Get the Month, Year from the data column
				+ DateName(yyyy, Inventorydate),
			[Count]												-- Get this column
		From vProducts Inner Join vInventories					-- Data is from two views, so join first
			On vProducts.ProductID = vInventories.ProductID		-- on these values 
		Order By												-- Sort by these columns
			ProductName,										-- First
			InventoryDate,										-- Second
			[Count];											-- Third
					   
-- Question 4 (10% of pts): How can you CREATE A VIEW called vProductInventories 
-- That shows a list of Product names, each Inventory Date, and the Inventory Count, 
-- with the date FORMATTED like January, 2017? Order the results by the Product, Date,
-- and Count!
	/* Getting the basic view & select statement to work
		-- Drop View vProductInventories
		Create View vProductInventories As							-- New view
			Select	ProductName,									-- Column to bring in
					InventoryDate,									-- Column to bring in
					[Count]											-- Column to bring in
			From vProducts Inner Join vInventories					-- Join 2 tables to get the data
				On vProducts.ProductID = vInventories.ProductID;	-- using these columns to match

		Select * From vProductInventories							-- Show the table
			Order By ProductName, InventoryDate, [Count];			-- Sort by these fields
	*/

	/* Getting date in the requested format
		-- Drop View vProductInventories
		Create View vProductInventories As							-- New view
			Select	ProductName,									-- Column to bring in
					InventoryDate,
					TheDate = DateName(mm, InventoryDate) + ', '				-- Get the Month, Year from the data column
						+ DateName(yyyy, Inventorydate),			
					[Count]											-- Column to bring in
			From vProducts Inner Join vInventories					-- Join 2 tables to get the data
				On vProducts.ProductID = vInventories.ProductID;	-- using these columns to match

		Select * From vProductInventories							-- Show the table
			Order By ProductName, TheDate, [Count];			-- Sort by these fields
	*/

	/* Getting date sequenced propertly */
		-- Drop View vProductInventories
		Create View vProductInventories As									-- New view
			Select	ProductName,											-- Column to bring in
					TheDate = DateName(mm, InventoryDate) + ', '			-- Get the Month, Year from the data column
						+ DateName(yyyy, Inventorydate),			
					[Count]													-- Column to bring in
			From vProducts Inner Join vInventories							-- Join 2 tables to get the data
				On vProducts.ProductID = vInventories.ProductID;			-- using these columns to match

		Select * From vProductInventories									-- Show the table
			Order By ProductName, Year (TheDate), Month(TheDate), [Count];	-- Sort by these fields
		go

-- Question 5 (10% of pts): How can you CREATE A VIEW called vCategoryInventories 
-- that shows a list of Category names, Inventory Dates, 
-- and a TOTAL Inventory Count BY CATEGORY, with the date FORMATTED like January, 2017?
	/* Setting up the select, joins, & basic order by and joins: Need to join Cat to Prod to Inv via CatID then ProdID
		Select	CategoryName,											-- Column to bring in from vCategory
				InventoryDate,											-- Column to bring in from vInventories
				[Count]													-- Column to bring in from vInventories
		From vCategories Inner Join vProducts
			On vCategories.CategoryID = vProducts.CategoryID			-- Join vCat & vProd on CatID
		Inner Join vInventories											-- Join result with vInv on ProdID
			On vProducts.ProductID = vInventories.ProductID				-- using these columns to match
		Order By CategoryName;
	*/
	/* Get TOTAL Inventory Count
		Select	CategoryName,											-- Column to bring in from vCategory
				InventoryDate,											-- Column to bring in from vInventories
				Sum([Count]) As TotalCount								-- Column to bring in from vInventories
		From vCategories Inner Join vProducts
			On vCategories.CategoryID = vProducts.CategoryID			-- Join vCat & vProd on CatID
		Inner Join vInventories											-- Join result with vInv on ProdID
			On vProducts.ProductID = vInventories.ProductID				-- using these columns to match
		Group By CategoryName, InventoryDate							-- How to group the resulting table
		Order By CategoryName;											-- Sort by the CategoryName
	*/
	/* Format the date as requested: January, 2017
		Select	CategoryName,											-- Column to bring in from vCategory
				DateName(mm, InventoryDate) + ', '						-- Get the Month, Year from the data column
					+ DateName(yyyy, Inventorydate) As 'Inventory Date',-- Label the column Inventory Date
				Sum([Count]) As TotalCount								-- Column to bring in from vInventories
		From vCategories Inner Join vProducts
			On vCategories.CategoryID = vProducts.CategoryID			-- Join vCat & vProd on CatID
		Inner Join vInventories											-- Join result with vInv on ProdID
			On vProducts.ProductID = vInventories.ProductID				-- using these columns to match
		Group By CategoryName, InventoryDate							-- How to group the resulting table
		Order By CategoryName;											-- Sort by the CategoryName
	*/
	/* Create the view*/
		-- Drop View vCategoryInventories
		Create View vCategoryInventories As
			Select	CategoryName,											-- Column to bring in from vCategory
					DateName(mm, InventoryDate) + ', '						-- Get the Month, Year from the data column
						+ DateName(yyyy, Inventorydate) As 'Inventory Date',-- Label the column Inventory Date
					Sum([Count]) As TotalCount								-- Column to bring in from vInventories
			From vCategories Inner Join vProducts
				On vCategories.CategoryID = vProducts.CategoryID			-- Join vCat & vProd on CatID
			Inner Join vInventories											-- Join result with vInv on ProdID
				On vProducts.ProductID = vInventories.ProductID				-- using these columns to match
			Group By CategoryName, InventoryDate;							-- How to group the resulting table

		Select * From vCategoryInventories								-- Show the new view
			Order By CategoryName;										-- Sort by the CategoryName
		go

-- Question 6 (10% of pts): How can you CREATE ANOTHER VIEW called 
-- vProductInventoriesWithPreviouMonthCounts to show 
-- a list of Product names, Inventory Dates, Inventory Count, AND the Previous Month
			-- Columns Needed
				--Product names					ProductName
				--Inventory Dates				TheDate
				--Inventory Count				[Count]
				--AND the Previous Month		PreviousMonth
			
			--Counts
				--	Set Nulls to 0
				--	Set 1996 counts to 0

			--Order by
				--	ProductName
				--	InventoryDate
				--	Count
-- Count? Use a functions to set any null counts or 1996 counts to zero. Order the
-- results by the Product, Date, and Count. This new view must use your
-- vProductInventories view!

	/* Set up basic view & order by
	Select	ProductName,											-- Pull this column
			TheDate,												-- this column
			[Count]													-- and this column
		From vProductInventories									-- from the view listed
		Order By ProductName, TheDate, [Count];						-- Sort the view by this
	*/
	/* Create a count from last month column. Has nulls & diff prod takes other prod
		Select	ProductName,										-- Pull this column
			TheDate,												-- this column
			[Count],												-- and this column
			PreviousMonth = 
				IIF(Year(TheDate) = 1996,							-- If
				0,													-- Then
				Lag(Sum([Count])) Over								-- Else
					   (Order By Productname, Month(TheDate))
				)
		From vProductInventories									-- from the view listed
		Group By ProductName, TheDate, [Count];						-- Sort the view by this
	*/
	/* Replace nulls
		Select	ProductName,											-- Pull this column
			TheDate,													-- this column
			[Count],													-- and this column
			PreviousMonth = 
				IsNull (IIf(Year(TheDate) = 1996, 0,					-- If year is 1996, then PreMon = 0
							Lag(Sum([Count])) Over						-- IIf, Else check last months count
								(Order By ProductName, Month(TheDate))),
				0)														-- from IsNull
		From vProductInventories									-- Grom the view listed
		Group By ProductName, TheDate, [Count];						-- Sort by
	*/
	/* Problem to solve: see if it is a new product before looking at last month.
	  -- Seems like an if / iif statement: If this lines prod != last line,
	  -- then last months count = 0.
			--Going to need lag given the table is ordered by product
			--IIf (productthismonth <> productlast month
			--	Then previousmonthCount = 0
			--	Else PreviousMonthCount = LastMonthsCount

			--IIf (Product name <> Lag(ProductName,1) Over (Order By ProductName, Month(TheDate)),
			--	PreviousMonth = 0,												Then
			--	Lag(Sum([Count])) Over (Order By ProductName, Month(TheDate)))  Else
		Select	ProductName,											-- Pull this column
			TheDate,													-- this column
			[Count],													-- and this column
			PreviousMonth =												-- Set the 3rd column to
				IsNull (												-- 0 if it is null
					IIf (ProductName <> Lag(ProductName,1)				-- If last months product is not the same as this mont
					  Over (Order By ProductName, Month(TheDate)), 0,	-- Then, set value to 0
						IIf(Year(TheDate) = 1996, 0,					-- Else, If year is 1996, then PreMon = 0
							Lag(Sum([Count])) Over						-- IIf, Else check last months count
							  (Order By ProductName, Month(TheDate)))),
				0)														-- from IsNull
		From vProductInventories									-- Grom the view listed
		Group By ProductName, TheDate, [Count];						-- Sort by
	*/
	/* Make a view out of the above: vProductInventoriesWithPreviouMonthCounts */
		Create View vProductInventoriesWithPreviouMonthCounts As	
			Select	ProductName,											-- Pull this column
					TheDate,													-- this column
					[Count],													-- and this column
					PreviousMonth =												-- Set the 3rd column to
						IsNull (												-- 0 if it is null
							IIf (ProductName <> Lag(ProductName,1)				-- If last months product is not the same as this mont
							  Over (Order By ProductName, Month(TheDate)), 0,	-- Then, set value to 0
								IIf(Year(TheDate) = 1996, 0,					-- Else, If year is 1996, then PreMon = 0
									Lag(Sum([Count])) Over						-- IIf, Else check last months count
									  (Order By ProductName, Month(TheDate)))),
						0)														-- from IsNull
				From vProductInventories										-- From the view listed
				Group By ProductName, TheDate, [Count];							-- Sort by
		go

		Select * From vProductInventoriesWithPreviouMonthCounts;			-- Show the new view
		go

-- Check that it works: Select * From vProductInventoriesWithPreviousMonthCounts;
go

-- Question 7 (20% of pts): How can you CREATE one more VIEW 
-- called vProductInventoriesWithPreviousMonthCountsWithKPIs
-- to show a list of Product names, Inventory Dates, Inventory Count, the Previous Month 
-- Count and a KPI that displays an increased count as 1, 
-- the same count as 0, and a decreased count as -1? Order the results by the 
-- Product, Date, and Count!
-- Important: This new view must use your vProductInventoriesWithPreviousMonthCounts view!
	
	/* Call on code from #6, but additional column called KPI (col5) that is filled in like this
				If Count < PreviousCount, then -1     Note this is col 3 & 4
				If Count = PreviousCount, then 0
				If Count > PreviousCount, then 1
		Use a case function rather than the ifs
	*/	
	/* Create the select statement to create the new table
		Select
			ProductName,										-- Get this column
			TheDate,											-- Get column
			[Count],											-- Get column
			PreviousMonth,										-- Get column
			KPI =	Case										-- Create a new column from the previous 2
						When [Count] < PreviousMonth Then -1	-- If inventory is less than last month's inventory
						When [Count] = PreviousMonth Then  0	--   Equal to last months inventory
						When [Count] > PreviousMonth Then  1	--   Less than last months inventory
						Else 'How did that happen!'				-- Not sure this could happen, but just in case (pun intended)
					End  -- Case								-- Close out the case statement
			From vProductInventoriesWithPreviouMonthCounts		-- Take data from this view
			Order By ProductName, TheDate, [Count];				-- Sort the results
	*/
	/* Create the view & call on it */
		Create View vProductInventoriesWithPreviousMonthCountsWithKPIs As
			Select
				ProductName,										-- Get this column
				TheDate,											-- Get column
				[Count],											-- Get column
				PreviousMonth,										-- Get column
				KPI =	Case										-- Create a new column from the previous 2
							When [Count] < PreviousMonth Then -1	-- If inventory is less than last month's inventory
							When [Count] = PreviousMonth Then  0	--   Equal to last months inventory
							When [Count] > PreviousMonth Then  1	--   Less than last months inventory
							Else 'How did that happen!'				-- Not sure this could happen, but just in case (pun intended)
						End  -- Case								-- Close out the case statement
				From vProductInventoriesWithPreviouMonthCounts;		-- Take data from this view

		Select * From vProductInventoriesWithPreviousMonthCountsWithKPIs	-- Show the new view
			Order By ProductName, TheDate, [Count];							-- Sort the results

-- Question 8 (25% of pts): (from the module forum for the course)
-- CREATE a User Defined Function (UDF) called fProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, the Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- The function must use the ProductInventoriesWithPreviousMonthCountsWithKPIs view!
	/* Make UDF that shows	ProductName
							TheDate
							[Count]
							PreviousMonth
							KPI
			For KPI values as an input (-1,0,1)
			Select [columns above] where KPI = [input value to UDF] From [incredibly long name view]
	*/
	--Drop Function dbo.fProductInventoriesWithPreviousMonthCountsWithKPIs
	Create Function dbo.fProductInventoriesWithPreviousMonthCountsWithKPIs (@InputValue Int)	-- Make a function that returns a table
		Returns Table
		As
			Return (
				Select	ProductName,															-- Add this column
						TheDate,																-- Ditto
						[Count],																-- Same
						PreviousMonth,															-- Same
						KPI																		-- Same
					From vProductInventoriesWithPreviousMonthCountsWithKPIs						-- from this view
					Where KPI = @InputValue														-- Only return values that meet the input value
			);
		go

Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs( 1);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs( 0);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);
/***************************************************************************************/