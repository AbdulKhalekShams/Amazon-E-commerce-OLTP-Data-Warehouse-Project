IF DB_ID('AmazonDW') IS NULL
    CREATE DATABASE AmazonDW;
GO


------- Create  Dim Date -------------------------------------------------------

USE AmazonDW;
GO

IF OBJECT_ID('dbo.DimDate','U') IS NOT NULL DROP TABLE dbo.DimDate;
GO

CREATE TABLE dbo.DimDate(
    DateKey     INT         NOT NULL PRIMARY KEY,  -- yyyymmdd
    [Date]      DATE        NOT NULL,
    [Year]      SMALLINT    NOT NULL,
    [Quarter]   TINYINT     NOT NULL,
    [Month]     TINYINT     NOT NULL,
    MonthName   NVARCHAR(20) NOT NULL,
    [Day]       TINYINT     NOT NULL,
    DayName     NVARCHAR(20) NOT NULL
);
GO

DECLARE @StartDate DATE, @EndDate DATE;
SELECT @StartDate = MIN(OrderDate), @EndDate = MAX(OrderDate)
FROM AmazonOLTP.dbo.Orders;

;WITH d AS (
    SELECT @StartDate AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt) FROM d WHERE dt < @EndDate
)
INSERT INTO dbo.DimDate(DateKey, [Date], [Year], [Quarter], [Month], MonthName, [Day], DayName)
SELECT
    CONVERT(INT, FORMAT(dt,'yyyyMMdd')) AS DateKey,
    dt,
    YEAR(dt),
    DATEPART(QUARTER, dt),
    MONTH(dt),
    DATENAME(MONTH, dt),
    DAY(dt),
    DATENAME(WEEKDAY, dt)
FROM d
OPTION (MAXRECURSION 0);
GO


-----------------------------------------------------------------------------------------------------------------------

------------------------ Create Dim Customer ----------------------------------------------


IF OBJECT_ID('dbo.DimCustomer','U') IS NOT NULL DROP TABLE dbo.DimCustomer;
GO

CREATE TABLE dbo.DimCustomer(
    CustomerKey  INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID   VARCHAR(12) NOT NULL,         -- Business Key
    Gender       CHAR(1) NOT NULL,
    Segment      NVARCHAR(20) NOT NULL,
    SignupDate   DATE NOT NULL,
    IsPrime      BIT NOT NULL,
    BirthYear    SMALLINT NOT NULL
);
GO

INSERT INTO dbo.DimCustomer(CustomerID, Gender, Segment, SignupDate, IsPrime, BirthYear)
SELECT CustomerID, Gender, Segment, SignupDate, IsPrime, BirthYear
FROM AmazonOLTP.dbo.Customers;
GO

CREATE UNIQUE INDEX UX_DimCustomer_CustomerID ON dbo.DimCustomer(CustomerID);
GO


------------------------------------------------------------------------------------------------------------------------------------
------------------------------ Create Dim Seller -----------------------------------------------------------------------------------

IF OBJECT_ID('dbo.DimSeller','U') IS NOT NULL DROP TABLE dbo.DimSeller;
GO

CREATE TABLE dbo.DimSeller(
    SellerKey   INT IDENTITY(1,1) PRIMARY KEY,
    SellerID    VARCHAR(12) NOT NULL,
    SellerType  NVARCHAR(30) NOT NULL,
    Rating      DECIMAL(3,2) NOT NULL,
    OnboardDate DATE NOT NULL
);
GO

INSERT INTO dbo.DimSeller(SellerID, SellerType, Rating, OnboardDate)
SELECT SellerID, SellerType, Rating, OnboardDate
FROM AmazonOLTP.dbo.Sellers;
GO

CREATE UNIQUE INDEX UX_DimSeller_SellerID ON dbo.DimSeller(SellerID);
GO


-----------------------------------------------------------------------------------------------------------------------------------------
---------------------------- Create Dim Geo (from addresses) ----------------------------------------------------------------------------

IF OBJECT_ID('dbo.DimGeo','U') IS NOT NULL DROP TABLE dbo.DimGeo;
GO

CREATE TABLE dbo.DimGeo(
    GeoKey      INT IDENTITY(1,1) PRIMARY KEY,
    AddressID   VARCHAR(12) NOT NULL,        -- Business Key (هنا بنعامل Address كـ Geo)
    Governorate NVARCHAR(60) NOT NULL,
    City        NVARCHAR(80) NOT NULL,
    District    NVARCHAR(120) NOT NULL,
    PostalCode  VARCHAR(10) NOT NULL
);
GO

INSERT INTO dbo.DimGeo(AddressID, Governorate, City, District, PostalCode)
SELECT AddressID, Governorate, City, District, PostalCode
FROM AmazonOLTP.dbo.Addresses;
GO

CREATE UNIQUE INDEX UX_DimGeo_AddressID ON dbo.DimGeo(AddressID);
GO




----------------------------------------------------------------------------------------------------------------------------------------------
-------------------------- Create Dim Product ------------------------------------------------------------------------------------------------

IF OBJECT_ID('dbo.DimProduct','U') IS NOT NULL DROP TABLE dbo.DimProduct;
GO

CREATE TABLE dbo.DimProduct(
    ProductKey      INT IDENTITY(1,1) PRIMARY KEY,
    ProductID       VARCHAR(12) NOT NULL,
    SKU             VARCHAR(30) NOT NULL,
    ProductName     NVARCHAR(200) NOT NULL,
    Brand           NVARCHAR(80) NOT NULL,
    CategoryName    NVARCHAR(80) NOT NULL,
    SubcategoryName NVARCHAR(80) NOT NULL,
    ListPriceEGP    DECIMAL(18,2) NOT NULL,
    UnitCostEGP     DECIMAL(18,2) NOT NULL,
    IsFragile       BIT NOT NULL,
    WarrantyMonths  SMALLINT NOT NULL,
    SellerID        VARCHAR(12) NOT NULL       -- هنحتاجه عشان نطلع SellerKey بسهولة في Fact
);
GO

INSERT INTO dbo.DimProduct(ProductID, SKU, ProductName, Brand, CategoryName, SubcategoryName,
                           ListPriceEGP, UnitCostEGP, IsFragile, WarrantyMonths, SellerID)
SELECT
    p.ProductID, p.SKU, p.ProductName, p.Brand,
    c.CategoryName,
    s.SubcategoryName,
    p.ListPriceEGP, p.UnitCostEGP, p.IsFragile, p.WarrantyMonths,
    p.SellerID
FROM AmazonOLTP.dbo.Products p
JOIN AmazonOLTP.dbo.Subcategories s ON p.SubcategoryID = s.SubcategoryID
JOIN AmazonOLTP.dbo.Categories c ON s.CategoryID = c.CategoryID;
GO

CREATE UNIQUE INDEX UX_DimProduct_ProductID ON dbo.DimProduct(ProductID);
GO



----------------------------------------------------------------------------------------------------------------------------------
--------------------- Create Fact_Sales (Most important table esm3 klamy ) -------------------------------------------------------

IF OBJECT_ID('dbo.FactSales','U') IS NOT NULL DROP TABLE dbo.FactSales;
GO

CREATE TABLE dbo.FactSales(
    SalesKey        BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderItemID     VARCHAR(12) NOT NULL, -- Degenerate key (مفيد للتتبع)
    OrderID         VARCHAR(12) NOT NULL, -- Degenerate key
    DateKey         INT NOT NULL,
    CustomerKey     INT NOT NULL,
    ProductKey      INT NOT NULL,
    SellerKey       INT NOT NULL,
    GeoKey          INT NOT NULL,

    Channel         NVARCHAR(30) NOT NULL,
    PaymentMethod   NVARCHAR(30) NOT NULL,
    OrderStatus     NVARCHAR(20) NOT NULL,

    Quantity        INT NOT NULL,
    UnitPriceEGP    DECIMAL(18,2) NOT NULL,
    DiscountPct     DECIMAL(5,2) NOT NULL,

    RevenueEGP      DECIMAL(18,2) NOT NULL,
    CostEGP         DECIMAL(18,2) NOT NULL,
    GrossProfitEGP  DECIMAL(18,2) NOT NULL
);
GO

INSERT INTO dbo.FactSales(
    OrderItemID, OrderID, DateKey, CustomerKey, ProductKey, SellerKey, GeoKey,
    Channel, PaymentMethod, OrderStatus,
    Quantity, UnitPriceEGP, DiscountPct,
    RevenueEGP, CostEGP, GrossProfitEGP
)
SELECT
    oi.OrderItemID,
    o.OrderID,
    CONVERT(INT, FORMAT(o.OrderDate,'yyyyMMdd')) AS DateKey,
    dc.CustomerKey,
    dp.ProductKey,
    ds.SellerKey,
    dg.GeoKey,
    o.Channel,
    o.PaymentMethod,
    o.OrderStatus,
    oi.Quantity,
    oi.UnitPriceEGP,
    oi.DiscountPct,
    CAST(oi.Quantity * oi.UnitPriceEGP AS DECIMAL(18,2)) AS RevenueEGP,
    CAST(oi.Quantity * dp.UnitCostEGP AS DECIMAL(18,2)) AS CostEGP,
    CAST((oi.Quantity * oi.UnitPriceEGP) - (oi.Quantity * dp.UnitCostEGP) AS DECIMAL(18,2)) AS GrossProfitEGP
FROM AmazonOLTP.dbo.OrderItems oi
JOIN AmazonOLTP.dbo.Orders o ON oi.OrderID = o.OrderID
JOIN dbo.DimCustomer dc ON o.CustomerID = dc.CustomerID
JOIN dbo.DimGeo dg ON o.ShipToAddressID = dg.AddressID
JOIN dbo.DimProduct dp ON oi.ProductID = dp.ProductID
JOIN dbo.DimSeller ds ON dp.SellerID = ds.SellerID
WHERE o.OrderStatus <> 'Cancelled';
GO





--------------------------------   روابط (FKs) في DW  ----------------------------------------------



ALTER TABLE dbo.FactSales ADD CONSTRAINT FK_FactSales_DimDate     FOREIGN KEY (DateKey)     REFERENCES dbo.DimDate(DateKey);
ALTER TABLE dbo.FactSales ADD CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerKey) REFERENCES dbo.DimCustomer(CustomerKey);
ALTER TABLE dbo.FactSales ADD CONSTRAINT FK_FactSales_DimProduct  FOREIGN KEY (ProductKey)  REFERENCES dbo.DimProduct(ProductKey);
ALTER TABLE dbo.FactSales ADD CONSTRAINT FK_FactSales_DimSeller   FOREIGN KEY (SellerKey)   REFERENCES dbo.DimSeller(SellerKey);
ALTER TABLE dbo.FactSales ADD CONSTRAINT FK_FactSales_DimGeo      FOREIGN KEY (GeoKey)      REFERENCES dbo.DimGeo(GeoKey);
GO



