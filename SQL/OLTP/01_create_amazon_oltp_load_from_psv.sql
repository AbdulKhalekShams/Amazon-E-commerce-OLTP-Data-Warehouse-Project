/* =========================================================
   Amazon Egypt Workshop (OLTP) — SQL Server Setup + Load (PSV)
   ---------------------------------------------------------
   This version loads PIPE-separated files (*.psv) to avoid
   issues with commas inside text fields (company names, districts, etc.)

   Steps:
   1) Unzip amazon_egypt_workshop_dataset_PSV.zip
   2) Copy folder "amazon_egypt_workshop_psv" to e.g.:
        C:\Data\amazon_egypt_workshop_psv\
   3) Run this script in SSMS (Run as Admin recommended)
   ========================================================= */

DECLARE @DataPath NVARCHAR(4000) = N'C:\Users\Abdelkhalek.Shams\Desktop\Amazon Workshop\amazon_egypt_workshop_dataset_PSV\amazon_egypt_workshop_psv\';

IF DB_ID('AmazonOLTP') IS NULL
BEGIN
    CREATE DATABASE AmazonOLTP;
END
GO

USE AmazonOLTP;
GO

-- Drop tables if re-running
IF OBJECT_ID('dbo.Returns','U') IS NOT NULL DROP TABLE dbo.Returns;
IF OBJECT_ID('dbo.Shipments','U') IS NOT NULL DROP TABLE dbo.Shipments;
IF OBJECT_ID('dbo.Payments','U') IS NOT NULL DROP TABLE dbo.Payments;
IF OBJECT_ID('dbo.OrderTotals','U') IS NOT NULL DROP TABLE dbo.OrderTotals;
IF OBJECT_ID('dbo.OrderItems','U') IS NOT NULL DROP TABLE dbo.OrderItems;
IF OBJECT_ID('dbo.Orders','U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Products','U') IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.Subcategories','U') IS NOT NULL DROP TABLE dbo.Subcategories;
IF OBJECT_ID('dbo.Categories','U') IS NOT NULL DROP TABLE dbo.Categories;
IF OBJECT_ID('dbo.Sellers','U') IS NOT NULL DROP TABLE dbo.Sellers;
IF OBJECT_ID('dbo.Addresses','U') IS NOT NULL DROP TABLE dbo.Addresses;
IF OBJECT_ID('dbo.Customers','U') IS NOT NULL DROP TABLE dbo.Customers;
GO

/* IMPORTANT: redeclare @DataPath after GO */
DECLARE @DataPath NVARCHAR(4000) = N'C:\Users\Abdelkhalek.Shams\Desktop\Amazon Workshop\amazon_egypt_workshop_dataset_PSV\amazon_egypt_workshop_psv\';
DECLARE @SQL NVARCHAR(MAX);

-- Create tables
CREATE TABLE dbo.Customers(
    CustomerID     VARCHAR(12)   NOT NULL,
    FirstName      NVARCHAR(60)  NOT NULL,
    LastName       NVARCHAR(60)  NOT NULL,
    Gender         CHAR(1)       NOT NULL,
    Phone          VARCHAR(20)   NOT NULL,
    Email          NVARCHAR(120) NOT NULL,
    SignupDate     DATE          NOT NULL,
    IsPrime        BIT           NOT NULL,
    BirthYear      SMALLINT      NOT NULL,
    Segment        NVARCHAR(20)  NOT NULL,
    CONSTRAINT PK_Customers PRIMARY KEY (CustomerID)
);

CREATE TABLE dbo.Addresses(
    AddressID      VARCHAR(12)    NOT NULL,
    CustomerID     VARCHAR(12)    NOT NULL,
    Governorate    NVARCHAR(60)   NOT NULL,
    City           NVARCHAR(80)   NOT NULL,
    District       NVARCHAR(120)  NOT NULL,
    PostalCode     VARCHAR(10)    NOT NULL,
    IsDefault      BIT            NOT NULL,
    CONSTRAINT PK_Addresses PRIMARY KEY (AddressID)
);

CREATE TABLE dbo.Sellers(
    SellerID       VARCHAR(12)    NOT NULL,
    SellerName     NVARCHAR(200)  NOT NULL,
    SellerType     NVARCHAR(30)   NOT NULL,
    OnboardDate    DATE           NOT NULL,
    Rating         DECIMAL(3,2)   NOT NULL,
    CONSTRAINT PK_Sellers PRIMARY KEY (SellerID)
);

CREATE TABLE dbo.Categories(
    CategoryID     VARCHAR(12)   NOT NULL,
    CategoryName   NVARCHAR(80)  NOT NULL,
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryID)
);

CREATE TABLE dbo.Subcategories(
    SubcategoryID    VARCHAR(12)  NOT NULL,
    CategoryID       VARCHAR(12)  NOT NULL,
    SubcategoryName  NVARCHAR(80) NOT NULL,
    CONSTRAINT PK_Subcategories PRIMARY KEY (SubcategoryID)
);

CREATE TABLE dbo.Products(
    ProductID      VARCHAR(12)     NOT NULL,
    SKU            VARCHAR(30)     NOT NULL,
    ProductName    NVARCHAR(200)   NOT NULL,
    Brand          NVARCHAR(80)    NOT NULL,
    SubcategoryID  VARCHAR(12)     NOT NULL,
    SellerID       VARCHAR(12)     NOT NULL,
    UnitCostEGP    DECIMAL(18,2)   NOT NULL,
    ListPriceEGP   DECIMAL(18,2)   NOT NULL,
    IsFragile      BIT             NOT NULL,
    WarrantyMonths SMALLINT        NOT NULL,
    CONSTRAINT PK_Products PRIMARY KEY (ProductID)
);

CREATE TABLE dbo.Orders(
    OrderID          VARCHAR(12)   NOT NULL,
    OrderDate        DATE          NOT NULL,
    CustomerID       VARCHAR(12)   NOT NULL,
    ShipToAddressID  VARCHAR(12)   NOT NULL,
    Channel          NVARCHAR(30)  NOT NULL,
    PaymentMethod    NVARCHAR(30)  NOT NULL,
    OrderStatus      NVARCHAR(20)  NOT NULL,
    IsPaid           BIT           NOT NULL,
    CONSTRAINT PK_Orders PRIMARY KEY (OrderID)
);

CREATE TABLE dbo.OrderItems(
    OrderItemID   VARCHAR(12)    NOT NULL,
    OrderID       VARCHAR(12)    NOT NULL,
    ProductID     VARCHAR(12)    NOT NULL,
    Quantity      INT            NOT NULL,
    UnitPriceEGP  DECIMAL(18,2)  NOT NULL,
    DiscountPct   DECIMAL(5,2)   NOT NULL,
    LineStatus    NVARCHAR(20)   NOT NULL,
    CONSTRAINT PK_OrderItems PRIMARY KEY (OrderItemID)
);

CREATE TABLE dbo.OrderTotals(
    OrderID         VARCHAR(12)    NOT NULL,
    SubtotalEGP     DECIMAL(18,2)  NOT NULL,
    ShippingFeeEGP  DECIMAL(18,2)  NOT NULL,
    VatRate         DECIMAL(5,2)   NOT NULL,
    VAT_EGP         DECIMAL(18,2)  NOT NULL,
    GrossEGP        DECIMAL(18,2)  NOT NULL,
    CONSTRAINT PK_OrderTotals PRIMARY KEY (OrderID)
);

CREATE TABLE dbo.Payments(
    PaymentID       VARCHAR(12)     NOT NULL,
    OrderID         VARCHAR(12)     NOT NULL,
    PaymentMethod   NVARCHAR(30)    NOT NULL,
    PaymentDate     DATE            NULL,
    PaymentStatus   NVARCHAR(20)    NOT NULL,
    FailureReason   NVARCHAR(200)   NULL,
    CONSTRAINT PK_Payments PRIMARY KEY (PaymentID)
);

CREATE TABLE dbo.Shipments(
    ShipmentID      VARCHAR(12)     NOT NULL,
    OrderID         VARCHAR(12)     NOT NULL,
    Carrier         NVARCHAR(50)    NOT NULL,
    ShipDate        DATE            NOT NULL,
    DeliveryDate    DATE            NULL,
    ShipmentStatus  NVARCHAR(30)    NOT NULL,
    CONSTRAINT PK_Shipments PRIMARY KEY (ShipmentID)
);

CREATE TABLE dbo.Returns(
    ReturnID         VARCHAR(12)     NOT NULL,
    OrderItemID      VARCHAR(12)     NOT NULL,
    ReturnDate       DATE            NULL,
    ReturnReason     NVARCHAR(80)    NOT NULL,
    RefundAmountEGP  DECIMAL(18,2)   NOT NULL,
    ReturnStatus     NVARCHAR(20)    NOT NULL,
    CONSTRAINT PK_Returns PRIMARY KEY (ReturnID)
);

-- Load PSV files (PIPE separated)
SET @SQL = N'BULK INSERT dbo.Customers FROM ''' + @DataPath + N'OLTP_Customers.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

SET @SQL = N'BULK INSERT dbo.Addresses FROM ''' + @DataPath + N'OLTP_Addresses.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

SET @SQL = N'BULK INSERT dbo.Sellers FROM ''' + @DataPath + N'OLTP_Sellers.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

SET @SQL = N'BULK INSERT dbo.Categories FROM ''' + @DataPath + N'OLTP_Categories.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

SET @SQL = N'BULK INSERT dbo.Subcategories FROM ''' + @DataPath + N'OLTP_Subcategories.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

SET @SQL = N'BULK INSERT dbo.Products FROM ''' + @DataPath + N'OLTP_Products.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

SET @SQL = N'BULK INSERT dbo.Orders FROM ''' + @DataPath + N'OLTP_Orders.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

SET @SQL = N'BULK INSERT dbo.OrderItems FROM ''' + @DataPath + N'OLTP_OrderItems.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

SET @SQL = N'BULK INSERT dbo.OrderTotals FROM ''' + @DataPath + N'OLTP_OrderTotals.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

SET @SQL = N'BULK INSERT dbo.Payments FROM ''' + @DataPath + N'OLTP_Payments.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

SET @SQL = N'BULK INSERT dbo.Shipments FROM ''' + @DataPath + N'OLTP_Shipments.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

SET @SQL = N'BULK INSERT dbo.Returns FROM ''' + @DataPath + N'OLTP_Returns.psv'' WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';
EXEC(@SQL);

PRINT 'Load complete. Adding constraints + indexes...';

-- Foreign keys (integrity)
ALTER TABLE dbo.Addresses
ADD CONSTRAINT FK_Addresses_Customers
FOREIGN KEY (CustomerID) REFERENCES dbo.Customers(CustomerID);

ALTER TABLE dbo.Subcategories
ADD CONSTRAINT FK_Subcategories_Categories
FOREIGN KEY (CategoryID) REFERENCES dbo.Categories(CategoryID);

ALTER TABLE dbo.Products
ADD CONSTRAINT FK_Products_Subcategories
FOREIGN KEY (SubcategoryID) REFERENCES dbo.Subcategories(SubcategoryID);

ALTER TABLE dbo.Products
ADD CONSTRAINT FK_Products_Sellers
FOREIGN KEY (SellerID) REFERENCES dbo.Sellers(SellerID);

ALTER TABLE dbo.Orders
ADD CONSTRAINT FK_Orders_Customers
FOREIGN KEY (CustomerID) REFERENCES dbo.Customers(CustomerID);

ALTER TABLE dbo.Orders
ADD CONSTRAINT FK_Orders_Addresses
FOREIGN KEY (ShipToAddressID) REFERENCES dbo.Addresses(AddressID);

ALTER TABLE dbo.OrderItems
ADD CONSTRAINT FK_OrderItems_Orders
FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID);

ALTER TABLE dbo.OrderItems
ADD CONSTRAINT FK_OrderItems_Products
FOREIGN KEY (ProductID) REFERENCES dbo.Products(ProductID);

ALTER TABLE dbo.OrderTotals
ADD CONSTRAINT FK_OrderTotals_Orders
FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID);

ALTER TABLE dbo.Payments
ADD CONSTRAINT FK_Payments_Orders
FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID);

ALTER TABLE dbo.Shipments
ADD CONSTRAINT FK_Shipments_Orders
FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID);

ALTER TABLE dbo.Returns
ADD CONSTRAINT FK_Returns_OrderItems
FOREIGN KEY (OrderItemID) REFERENCES dbo.OrderItems(OrderItemID);

-- Basic indexes
CREATE INDEX IX_Orders_OrderDate ON dbo.Orders(OrderDate);
CREATE INDEX IX_OrderItems_OrderID ON dbo.OrderItems(OrderID);
CREATE INDEX IX_OrderItems_ProductID ON dbo.OrderItems(ProductID);

PRINT 'AmazonOLTP ready ✅';
SELECT COUNT(*) AS OrdersCount FROM dbo.Orders;
SELECT COUNT(*) AS OrderItemsCount FROM dbo.OrderItems;








-----------------------------------------------------------------------------------
--------------------------------------------------------------------------------


USE AmazonOLTP;
GO

-- 1) لو جدول Returns اتعمل (غالبًا اتعمل لكنه فاضي) هنعدّل العمود
ALTER TABLE dbo.Returns
ALTER COLUMN RefundAmountEGP DECIMAL(18,2) NULL;
GO

-- 2) اعمل BULK INSERT تاني لملف Returns فقط
DECLARE @DataPath NVARCHAR(4000) = N'C:\Users\Abdelkhalek.Shams\Desktop\Amazon Workshop\amazon_egypt_workshop_dataset_PSV\amazon_egypt_workshop_psv\';
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
BULK INSERT dbo.Returns
FROM ''' + @DataPath + N'OLTP_Returns.psv''
WITH (FIRSTROW=2, FIELDTERMINATOR=''|'', ROWTERMINATOR=''0x0d0a'', TABLOCK, CODEPAGE=''65001'');';

EXEC(@SQL);
GO

-- 3) نظّف: أي RefundAmountEGP NULL خليها 0 (أو خليها -1 لو عايز تميّزها)
UPDATE dbo.Returns
SET RefundAmountEGP = 0
WHERE RefundAmountEGP IS NULL;
GO

-- (اختياري) رجّعها NOT NULL بعد التنضيف
ALTER TABLE dbo.Returns
ALTER COLUMN RefundAmountEGP DECIMAL(18,2) NOT NULL;
GO

SELECT COUNT(*) AS ReturnsCount FROM dbo.Returns;



