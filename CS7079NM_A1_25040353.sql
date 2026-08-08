-- create the database
CREATE DATABASE InventoryDW;
USE InventoryDW;

-- create Dim tables
CREATE TABLE Dim_Supplier (
    supplier_key         INT PRIMARY KEY NOT NULL,
    supplier_name        VARCHAR(100),
    supplier_description VARCHAR(255),
    supplier_phone       VARCHAR(30),
    supplier_email       VARCHAR(100),
    supplier_fax         VARCHAR(30),
    first_line_address   VARCHAR(150),
    supplier_postcode    VARCHAR(20),
    supplier_city        VARCHAR(100),
    supplier_state       VARCHAR(100),
    supplier_country_id  VARCHAR(10)
);

CREATE TABLE Dim_Product (
    product_sku           VARCHAR(20) PRIMARY KEY NOT NULL,
    product_name          VARCHAR(200)   NOT NULL,
    product_description   VARCHAR(255)   NOT NULL,
	product_cost_price	  DECIMAL(18,0)	 NOT NULL,
	product_retail_price  DECIMAL(18,0)	 NOT NULL,
    product_condition     VARCHAR(20)    NOT NULL,       
    product_type          VARCHAR(50)    NOT NULL,  
    product_brand         VARCHAR(50)    NOT NULL,
    product_tags          VARCHAR(100)   NOT NULL, 
    date_created_at       DATE           NOT NULL,
    date_discontinued_at  DATE           NOT NULL,
    is_active             BIT            NOT NULL
    
);


CREATE TABLE Dim_Date (
    date_key            INT PRIMARY KEY NOT NULL,
    full_date           DATE            NOT NULL,
    date_name           DATE		    NOT NULL,
    day_of_week         INT             NOT NULL,
    day_name_of_week    VARCHAR(20)     NOT NULL,
    day_of_year         INT             NOT NULL,
    week_of_year        INT             NOT NULL,
    month_name          VARCHAR(20)     NOT NULL,
    month_of_year       INT				NOT NULL,
    calendar_quarter    INT             NOT NULL,
    calendar_year       INT             NOT NULL
);

-- create Fact tables
CREATE TABLE Fact_PO_Sent (
    po_sent_key           INT  PRIMARY KEY   NOT NULL,
    purchase_order_code   VARCHAR(50)     NOT NULL,
	ordered_qty           INT             NOT NULL,
    sent_date_key		  INT             NOT NULL,   
    product_sku           VARCHAR(20)     NOT NULL,   
    supplier_key          INT             NOT NULL,  
    FOREIGN KEY (sent_date_key) REFERENCES Dim_Date (date_key),
    FOREIGN KEY (product_sku) REFERENCES Dim_Product (product_sku),
    FOREIGN KEY (supplier_key) REFERENCES Dim_Supplier (supplier_key)
);

CREATE TABLE Fact_PO_Received (
    po_received_key       INT  PRIMARY KEY   NOT NULL,
    purchase_order_code   VARCHAR(50)     NOT NULL,   
	destination_outlet    VARCHAR(100)    NOT NULL,
	ordered_qty           INT             NOT NULL,
    received_qty          INT             NOT NULL,
    sent_date_key		  INT             NOT NULL, 
	received_date_key	  INT			  NOT NULL,
    product_sku           VARCHAR(20)     NOT NULL,   
    supplier_key          INT             NOT NULL,   
	FOREIGN KEY (sent_date_key) REFERENCES Dim_Date (date_key),
	FOREIGN KEY (received_date_key) REFERENCES Dim_Date (date_key),
	FOREIGN KEY (product_sku) REFERENCES Dim_Product (product_sku),
	FOREIGN KEY (supplier_key) REFERENCES Dim_Supplier (supplier_key),
);

CREATE TABLE Fact_Stock_Level (
    stock_level_key   INT PRIMARY KEY NOT NULL,
	stock_level       INT             NOT NULL,
	cost_price        DECIMAL(18,2)   NOT NULL,
    retail_price      DECIMAL(18,2)   NOT NULL,
    date_key          INT             NOT NULL,   
    product_sku       VARCHAR(20)     NOT NULL,
	FOREIGN KEY (date_key) REFERENCES Dim_Date (date_key),
	FOREIGN KEY (product_sku) REFERENCES Dim_Product (product_sku),

);

-- Create Staging Tables

CREATE TABLE Staging_Date (
    FullDate         VARCHAR(20),  
    DateName         VARCHAR(20),  
    DayOfWeek        INT,
    DayNameOfWeek    VARCHAR(20),
    DayOfYear        VARCHAR(10),
    WeekOfYear       INT,
    MonthName        VARCHAR(20),
    MonthOfYear      INT,
    CalendarQuarter  INT,
    CalendarYear     INT
);

CREATE TABLE Staging_Supplier (
    SupplierName       VARCHAR(100),
    Description        VARCHAR(255),
    Phone              VARCHAR(30),
    Email              VARCHAR(100),
    Fax                VARCHAR(30),
    FirstLineAddress   VARCHAR(150),
    PostCode           VARCHAR(20),
    City               VARCHAR(100),
    State              VARCHAR(100),
    CountryID          VARCHAR(10)
);

CREATE TABLE Staging_ProductDay1 (
    SKU                  VARCHAR(20),
    ProductName          VARCHAR(200),
    Description          VARCHAR(255),
    ConditionType        VARCHAR(20),
    ProductType          VARCHAR(50),
    Brand                VARCHAR(50),
    SupplierName         VARCHAR(100),
    Tags                 VARCHAR(100),
    CostPrice            DECIMAL(10,2),
    RetailPrice          DECIMAL(10,2),
    CurrentStockLevel    INT,
    DateCreatedAt        VARCHAR(10),   
    DateDiscontinuedAt   VARCHAR(10),
    IsActive             BIT
);

CREATE TABLE Staging_ProductDay2 (
    SKU VARCHAR(20),
	ProductName VARCHAR(200),
	Description VARCHAR(255),
    ConditionType VARCHAR(20), 
	ProductType VARCHAR(50),
	Brand VARCHAR(50),
    SupplierName VARCHAR(100), 
	Tags VARCHAR(100),
	CostPrice DECIMAL(10,2),
    RetailPrice DECIMAL(10,2),
	CurrentStockLevel INT,
    DateCreatedAt VARCHAR(10),
	DateDiscontinuedAt VARCHAR(10),
	IsActive BIT
);

CREATE TABLE Staging_ProductDay3 (
    SKU VARCHAR(20), 
	ProductName VARCHAR(200), 
	Description VARCHAR(255),
    ConditionType VARCHAR(20), 
	ProductType VARCHAR(50), 
	Brand VARCHAR(50),
    SupplierName VARCHAR(100),
	Tags VARCHAR(100), 
	CostPrice DECIMAL(10,2),
    RetailPrice DECIMAL(10,2), 
	CurrentStockLevel INT,
    DateCreatedAt VARCHAR(10),
	DateDiscontinuedAt VARCHAR(10),
	IsActive BIT
);

CREATE TABLE Staging_POSent (
    PurchaseOrderCode   VARCHAR(50),
    ProductSKU          VARCHAR(20),
    SupplierName        VARCHAR(100),
    DestinationOutlet   VARCHAR(100),
    SentDate            VARCHAR(10),
    OrderedQty          INT
);

CREATE TABLE Staging_PORecv (
    PurchaseOrderCode     VARCHAR(50),
    ProductSKU            VARCHAR(20),
    SupplierName          VARCHAR(100),
    DestinationOutletID   VARCHAR(100),
    SentDate              VARCHAR(10),
    ReceivedDate          VARCHAR(10),
    ReceivedQty           INT,
    OrderedQty            INT
);

-- empty staging tables due to issue some data are imported using the import wizard
TRUNCATE TABLE Staging_ProductDay1;
TRUNCATE TABLE Staging_ProductDay2;
TRUNCATE TABLE Staging_ProductDay3;
TRUNCATE TABLE Staging_Supplier;
TRUNCATE TABLE Staging_Date;
TRUNCATE TABLE Staging_POSent;
TRUNCATE TABLE Staging_PORecv;

SELECT * FROM Staging_ProductDay1;
SELECT * FROM Staging_ProductDay2;
SELECT * FROM Staging_ProductDay3;
SELECT * FROM Staging_Supplier;
SELECT * FROM Staging_Date;
SELECT * FROM Staging_POSent;
SELECT * FROM Staging_PORecv;

-- bulk insert due to import wizard is not importing data correctly

-- Staging_Date
BULK INSERT Staging_Date
FROM 'C:\Users\USER\Desktop\DWProject\CS7079NM_A1_Data Files\GeneratedDateTime_Dim_2006-2026-2.txt'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '\t',
	ROWTERMINATOR   = '0x0a',
    CODEPAGE        = '1252',
    TABLOCK
);

SELECT COUNT(*) FROM Staging_Date; 

-- Staging_Supplier
BULK INSERT Staging_Supplier
FROM 'C:\Users\USER\Desktop\DWProject\CS7079NM_A1_Data Files\SampleOfSuppliers.txt'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '\t',
	ROWTERMINATOR   = '0x0a',
    CODEPAGE        = '1252',
    TABLOCK
);

SELECT COUNT(*) FROM Staging_Supplier; 

-- Convert literal "NULL" text to real NULLs
UPDATE Staging_Supplier SET Description      = NULL WHERE Description = 'NULL';
UPDATE Staging_Supplier SET Phone            = NULL WHERE Phone = 'NULL';
UPDATE Staging_Supplier SET Email            = NULL WHERE Email = 'NULL';
UPDATE Staging_Supplier SET Fax              = NULL WHERE Fax = 'NULL';
UPDATE Staging_Supplier SET FirstLineAddress = NULL WHERE FirstLineAddress = 'NULL';
UPDATE Staging_Supplier SET PostCode         = NULL WHERE PostCode = 'NULL';
UPDATE Staging_Supplier SET City             = NULL WHERE City = 'NULL';
UPDATE Staging_Supplier SET State            = NULL WHERE State = 'NULL';
UPDATE Staging_Supplier SET CountryID        = NULL WHERE CountryID = 'NULL';

-- Staging_ProductDay1, Staging_ProductDay2 and Staging_ProductDay3
BULK INSERT Staging_ProductDay1
FROM 'C:\Users\USER\Desktop\DWProject\CS7079NM_A1_Data Files\SampleOfProductsDay1.txt'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '\t',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '1252',
    TABLOCK
);

SELECT * FROM Staging_ProductDay1;

BULK INSERT Staging_ProductDay2
FROM 'C:\Users\USER\Desktop\DWProject\CS7079NM_A1_Data Files\SampleOfProductsDay2.txt'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '\t',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '1252',
    TABLOCK
);

SELECT * FROM Staging_ProductDay2;

BULK INSERT Staging_ProductDay3
FROM 'C:\Users\USER\Desktop\DWProject\CS7079NM_A1_Data Files\SampleOfProductsDay3.txt'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '\t',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '1252',
    TABLOCK
);

SELECT * FROM Staging_ProductDay3;

-- Staging_PORecv
BULK INSERT Staging_PORecv
FROM 'C:\Users\USER\Desktop\DWProject\CS7079NM_A1_Data Files\SampleOfReceivedPurchaseOrders.txt'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '\t',
    ROWTERMINATOR   = '0x0a',
    CODEPAGE        = '1252',
    TABLOCK
);

SELECT * FROM Staging_PORecv;

-- Staging_POSent
BULK INSERT Staging_POSent
FROM 'C:\Users\USER\Desktop\DWProject\CS7079NM_A1_Data Files\SampleofSentPurchaseOrders.txt'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = '\t',
    ROWTERMINATOR   = '0x0a',
    CODEPAGE        = '1252',
    TABLOCK
);

SELECT * FROM Staging_POSent;

-- checking row counts
SELECT COUNT(*) AS row_count FROM Staging_Date;
SELECT COUNT(*) AS row_count FROM Staging_Supplier;
SELECT COUNT(*) AS row_count FROM Staging_ProductDay1;
SELECT COUNT(*) AS row_count FROM Staging_ProductDay2;
SELECT COUNT(*) AS row_count FROM Staging_ProductDay3;
SELECT COUNT(*) AS row_count FROM Staging_PORecv;
SELECT COUNT(*) AS row_count FROM Staging_POSent;

-- clearing Dim and Fact Tables
TRUNCATE TABLE Fact_Stock_Level;
TRUNCATE TABLE Fact_PO_Received;
TRUNCATE TABLE Fact_PO_Sent;

DELETE FROM Dim_Product;
DELETE FROM Dim_Supplier;
DELETE FROM Dim_Date;

-- Moving staging data into dimensional tables

-- Dim_Date
INSERT INTO Dim_Date (date_key, full_date, date_name, day_of_week,
                       day_name_of_week, day_of_year, week_of_year,
                       month_name, month_of_year, calendar_quarter, calendar_year)
SELECT
    CAST(FORMAT(CONVERT(DATE, FullDate, 103), 'yyyyMMdd') AS INT),
    CONVERT(DATE, FullDate, 103),
	CONVERT(DATE, DateName, 111),
    DayOfWeek,
    DayNameOfWeek,
    CAST(LTRIM(RTRIM(DayOfYear)) AS INT),
    WeekOfYear,
    MonthName,
    MonthOfYear,
    CalendarQuarter,
    CalendarYear
FROM Staging_Date;

SELECT COUNT(*) FROM Staging_Date;
SELECT COUNT(*) FROM Dim_Date;
SELECT * FROM Dim_Date;

-- Dim Supplier
INSERT INTO Dim_Supplier (supplier_key, supplier_name, supplier_description, supplier_phone,
                           supplier_email, supplier_fax, first_line_address,
                           supplier_postcode, supplier_city, supplier_state, supplier_country_id)
SELECT
	ROW_NUMBER() OVER (ORDER BY SupplierName),
    SupplierName,
    NULLIF(Description, 'NULL'),
    NULLIF(Phone, 'NULL'),
    NULLIF(Email, 'NULL'),
    NULLIF(Fax, 'NULL'),
    NULLIF(FirstLineAddress, 'NULL'),
    NULLIF(PostCode, 'NULL'),
    NULLIF(City, 'NULL'),
    NULLIF(State, 'NULL'),
    NULLIF(CountryID, 'NULL')
FROM Staging_Supplier;

SELECT COUNT(*) FROM Staging_Supplier;
SELECT COUNT(*) FROM Dim_Supplier;
SELECT * FROM Dim_Supplier;

-- checking Staging_ProductDay1/2/3 tables before moving to Dim_Product table
SELECT TOP 5 * FROM Staging_ProductDay1;
SELECT TOP 5 * FROM Staging_ProductDay2;
SELECT TOP 5 * FROM Staging_ProductDay3;

SELECT COUNT(*) FROM Staging_ProductDay1;
SELECT COUNT(*) FROM Staging_ProductDay2;
SELECT COUNT(*) FROM Staging_ProductDay3;

-- moving data from Staging_ProductDay1/2/3 into Dim_Product table
WITH Product_Source AS
(
    SELECT *
    FROM Staging_ProductDay1
    UNION ALL
    SELECT *
    FROM Staging_ProductDay2
    UNION ALL
    SELECT *
    FROM Staging_ProductDay3
),

Product_Latest AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY SKU
            ORDER BY CONVERT(DATE,DateCreatedAt,103) DESC
        ) AS rn

    FROM Product_Source
)

INSERT INTO Dim_Product
(
    product_sku,
    product_name,
    product_description,
    product_cost_price,
    product_retail_price,
    product_condition,
    product_type,
    product_brand,
    product_tags,
    date_created_at,
    date_discontinued_at,
    is_active
)

SELECT

    SKU,
    ISNULL(ProductName,'Unknown'),
    ISNULL(Description,'No Description'),
    ISNULL(CAST(CostPrice AS DECIMAL(18,0)),0),
    ISNULL(CAST(RetailPrice AS DECIMAL(18,0)),0),
    ISNULL(ConditionType,'Unknown'),
    ISNULL(ProductType,'Unknown'),
    ISNULL(Brand,'Unknown'),
    ISNULL(Tags,'Unknown'),
    CONVERT(DATE,DateCreatedAt,103),
    CASE 
        WHEN DateDiscontinuedAt IS NULL 
			OR DateDiscontinuedAt = 'NULL'
        THEN NULL
        ELSE CONVERT(DATE,DateDiscontinuedAt,103)
    END,
    ISNULL(IsActive,1)
FROM Product_Latest
WHERE rn = 1;

SELECT *
FROM Dim_Product;

-- Moving staging data into fact tables

-- Fact_Stock_Level
WITH Stock_Source AS
(
    SELECT
        SKU,
        CurrentStockLevel,
        CostPrice,
        RetailPrice,
        DateCreatedAt
    FROM Staging_ProductDay1
    UNION ALL
    SELECT
        SKU,
        CurrentStockLevel,
        CostPrice,
        RetailPrice,
        DateCreatedAt
    FROM Staging_ProductDay2
    UNION ALL
    SELECT
        SKU,
        CurrentStockLevel,
        CostPrice,
        RetailPrice,
        DateCreatedAt
    FROM Staging_ProductDay3
)

INSERT INTO Fact_Stock_Level
(
    stock_level_key,
    stock_level,
    cost_price,
    retail_price,
    date_key,
    product_sku
)

SELECT
    ROW_NUMBER() OVER(ORDER BY SKU, DateCreatedAt),
    ISNULL(CurrentStockLevel,0),
    ISNULL(CAST(CostPrice AS DECIMAL(18,2)),0),
    ISNULL(CAST(RetailPrice AS DECIMAL(18,2)),0),
    d.date_key,
    p.product_sku
FROM Stock_Source s
INNER JOIN Dim_Date d
ON d.full_date = CONVERT(DATE,s.DateCreatedAt,103)
INNER JOIN Dim_Product p
ON p.product_sku = s.SKU;

-- checking values
SELECT * FROM Fact_Stock_Level;

SELECT *
FROM Dim_Product;

-- Fact_PO_Sent table
INSERT INTO Fact_PO_Sent
(
    po_sent_key,
    purchase_order_code,
    ordered_qty,
    sent_date_key,
    product_sku,
    supplier_key
)
SELECT
    ROW_NUMBER() OVER (ORDER BY po.PurchaseOrderCode) AS po_sent_key,
    po.PurchaseOrderCode,
    ISNULL(po.OrderedQty,0),
    d.date_key,
    p.product_sku,
    s.supplier_key
FROM Staging_POSent po
INNER JOIN Dim_Date d
    ON d.full_date = CONVERT(DATE, po.SentDate, 103)
INNER JOIN Dim_Product p
    ON p.product_sku = po.ProductSKU
INNER JOIN Dim_Supplier s
    ON s.supplier_name = po.SupplierName;

--check
SELECT *
FROM Fact_PO_Sent;

-- Fact_PO_Received
INSERT INTO Fact_PO_Received
(
    po_received_key,
    purchase_order_code,
    destination_outlet,
    ordered_qty,
    received_qty,
    sent_date_key,
    received_date_key,
    product_sku,
    supplier_key
)

SELECT
    ROW_NUMBER() OVER (ORDER BY po.PurchaseOrderCode) AS po_received_key,
    po.PurchaseOrderCode,
    ISNULL(po.DestinationOutletID,'Unknown'),
    ISNULL(po.OrderedQty,0),
    ISNULL(po.ReceivedQty,0),
    sent_date.date_key,
    received_date.date_key,
    p.product_sku,
    s.supplier_key
FROM Staging_PORecv po
-- Match Sent Date
INNER JOIN Dim_Date sent_date
    ON sent_date.full_date = CONVERT(DATE,po.SentDate,103)
-- Match Received Date
INNER JOIN Dim_Date received_date
    ON received_date.full_date = CONVERT(DATE,po.ReceivedDate,103)
-- Match Product
INNER JOIN Dim_Product p
    ON p.product_sku = po.ProductSKU
-- Match Supplier
INNER JOIN Dim_Supplier s
    ON s.supplier_name = po.SupplierName;


-- check values
SELECT *
FROM Fact_PO_Received;

-- check data is moved to the Dim and Fact tables
SELECT 'Dim_Date' t, COUNT(*) FROM Dim_Date
UNION ALL SELECT 'Dim_Supplier', COUNT(*) FROM Dim_Supplier
UNION ALL SELECT 'Dim_Product', COUNT(*) FROM Dim_Product
UNION ALL SELECT 'Fact_Stock_Level', COUNT(*) FROM Fact_Stock_Level
UNION ALL SELECT 'Fact_PO_Sent', COUNT(*) FROM Fact_PO_Sent
UNION ALL SELECT 'Fact_PO_Received', COUNT(*) FROM Fact_PO_Received;

--checking Dim and Fact tables
SELECT * FROM Dim_Date;
SELECT * FROM Dim_Supplier;
SELECT * FROM Dim_Product;
SELECT * FROM Fact_PO_Sent;
SELECT * FROM Fact_PO_Received;
SELECT * FROM Fact_Stock_Level;

-- Issue in exporting Dim_Supplier table
SELECT supplier_key, supplier_country_id,
       DATALENGTH(supplier_country_id) AS byte_length
FROM Dim_Supplier;
-- If byte_length is 5 for a value that displays as "NULL" (4 letters), that extra byte is the hidden \r
-- Fix: strip any stray CR/LF characters, then convert genuine "NULL" text to real NULL
UPDATE Dim_Supplier
SET supplier_country_id = NULLIF(
    LTRIM(RTRIM(REPLACE(REPLACE(supplier_country_id, CHAR(13), ''), CHAR(10), ''))),
    'NULL'
);

SELECT supplier_key, supplier_country_id, DATALENGTH(ISNULL(supplier_country_id,'')) 
FROM Dim_Supplier;

-- fix the issue in Dim_Product table
UPDATE Dim_Product
SET product_tags = REPLACE(product_tags, ', ', '- ')
WHERE product_tags LIKE '%,%';

SELECT product_sku, product_tags FROM Dim_Product WHERE product_sku IN ('SEN222', 'SOl2211');






