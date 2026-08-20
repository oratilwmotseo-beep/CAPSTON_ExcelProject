
/* ============================================================================
   ACTIVITY 1 - CREATE THE DATABASE
   ============================================================================ */
IF DB_ID('SuperMart_Db') IS NOT NULL
BEGIN
    ALTER DATABASE SuperMart_Db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SuperMart_Db;
END
GO

CREATE DATABASE SuperMart_Db;
GO

USE SuperMart_Db;
GO

-- Customers table
CREATE TABLE Customers (
    CustomerId  INT IDENTITY(1,1) PRIMARY KEY,
    FirstName   NVARCHAR(50)  NOT NULL,
    LastName    NVARCHAR(50)  NOT NULL,
    City        NVARCHAR(50)  NOT NULL,
    Phone       NVARCHAR(20)  NULL,        -- Only column allowed to be NULL
    Email       NVARCHAR(100) NOT NULL
);
GO

-- Orders table
CREATE TABLE Orders (
    OrderId      INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId   INT NOT NULL,
    OrderDate    DATE NOT NULL,
    StatusCode   CHAR(1) NOT NULL
                 CONSTRAINT CK_Orders_StatusCode CHECK (StatusCode IN ('P','D','C')), -- P-Pending, D-Delivered, C-Canceled
    TotalAmount  DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerId)
        REFERENCES Customers(CustomerId)
);
GO

/* ============================================================================
   ACTIVITY 2 - POPULATE THE DATABASE
   7 customers across Joburg / Pretoria / Cape Town, some NULL phones,
   at least 2 customers with no orders (Customer 6 and 7 below).
   ============================================================================ */
INSERT INTO Customers (FirstName, LastName, City, Phone, Email) VALUES
('John',     'Smith',        'Joburg',    '0821234567', 'john.smith@example.com'),
('Sarah',    'Naidoo',       'Pretoria',  NULL,          'sarah.naidoo@example.com'),
('Thabo',    'Mokoena',      'Cape Town', '0837654321', 'thabo.mokoena@example.com'),
('Emma',     'van der Merwe','Joburg',    NULL,          'emma.vdm@example.com'),
('Lindiwe',  'Dlamini',      'Pretoria',  '0849876543', 'lindiwe.dlamini@example.com'),
('Michael',  'Botha',        'Cape Town', '0712345678', 'michael.botha@example.com'),   -- no orders
('Precious', 'Khumalo',      'Joburg',    NULL,          'precious.khumalo@example.com'); -- no orders
GO

-- 10 orders, different dates/amounts/statuses, only for customers 1-5
INSERT INTO Orders (CustomerId, OrderDate, StatusCode, TotalAmount) VALUES
(1, '2026-01-05', 'D', 450.00),
(1, '2026-03-14', 'P', 1200.50),
(2, '2026-02-20', 'D',  89.99),
(2, '2026-06-11', 'C', 300.00),
(3, '2026-01-28', 'D', 675.25),
(3, '2026-04-02', 'D',  50.00),
(4, '2026-03-30', 'P', 999.99),
(4, '2026-08-15', 'D', 210.75),
(5, '2026-05-19', 'C', 150.00),
(5, '2026-07-07', 'D', 800.00);
GO

/* ============================================================================
   ACTIVITY 3 - BASIC DATA RETRIEVAL
   Customer contact report
   ============================================================================ */
SELECT
    CustomerId,
    FirstName + ' ' + LastName            AS [Customer Name],
    City                                  AS Country,   -- see schema note at top of script
    City,
    COALESCE(Phone, 'No Phone Number')    AS Phone
FROM Customers;
GO

/* ============================================================================
   ACTIVITY 4 - FILTERING DATA
   ============================================================================ */

-- A) Customers from Gauteng (Joburg and Pretoria) using IN
SELECT
    FirstName + ' ' + LastName AS [Customer Name],
    Email,
    City
FROM Customers
WHERE City IN ('Joburg', 'Pretoria');
GO

-- B) Orders placed in Q1 2026 using BETWEEN
SELECT
    OrderId,
    CustomerId,
    OrderDate,
    StatusCode AS Status,
    TotalAmount
FROM Orders
WHERE OrderDate BETWEEN '2026-01-01' AND '2026-03-31';
GO

/* ============================================================================
   ACTIVITY 5 - SQL JOINS
   ============================================================================ */

-- Inner Join: customers who have placed orders
SELECT
    c.FirstName + ' ' + c.LastName AS [Customer Name],
    o.OrderId,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerId = o.CustomerId;
GO

-- Left Join: all customers, including those with no orders
SELECT
    c.FirstName + ' ' + c.LastName AS [Customer Name],
    o.OrderId,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerId = o.CustomerId;
GO

-- Right Join: all orders, including any without a matching customer
SELECT
    c.FirstName + ' ' + c.LastName AS [Customer Name],
    o.OrderId,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
RIGHT JOIN Orders o ON c.CustomerId = o.CustomerId;
GO

-- Full Outer Join: data integrity audit
SELECT
    c.FirstName + ' ' + c.LastName AS [Customer Name],
    o.OrderId,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
FULL OUTER JOIN Orders o ON c.CustomerId = o.CustomerId;
GO

/* ============================================================================
   ACTIVITY 6 - SORTING, AGGREGATION, DATE AND STRING FUNCTIONS
   ============================================================================ */

-- Task 1: Customer directory
SELECT
    UPPER(FirstName + ' ' + LastName) AS [Customer Name],
    City                               AS Country,  -- see schema note at top of script
    LEN(FirstName)                     AS FirstNameLength
FROM Customers
ORDER BY FirstName ASC;
GO

-- Task 2: Customer distribution by country/city
SELECT
    City AS Country,   -- see schema note at top of script
    COUNT(*) AS TotalCustomers
FROM Customers
GROUP BY City
ORDER BY TotalCustomers DESC;
GO

-- Task 3: Order summary report
SELECT
    COUNT(*)          AS TotalOrders,
    AVG(TotalAmount)  AS AverageOrderAmount,
    MAX(TotalAmount)  AS HighestOrderAmount,
    MIN(TotalAmount)  AS LowestOrderAmount
FROM Orders;
GO

-- Task 4: Order activity, sorted by highest order amount to lowest
SELECT
    OrderId,
    OrderDate,
    YEAR(OrderDate)                    AS OrderYear,
    MONTH(OrderDate)                   AS OrderMonth,
    DATEDIFF(DAY, OrderDate, GETDATE()) AS DaysSinceOrder,
    TotalAmount
FROM Orders
ORDER BY TotalAmount DESC;
GO

/* ============================================================================
   ACTIVITY 7 - ADVANCED QUERIES AND STORED PROCEDURES
   ============================================================================ */

-- Section A: Customers who have placed at least one order (via subquery)

-- Version 1: subquery with IN
SELECT
    CustomerId,
    FirstName + ' ' + LastName AS [Customer Name],
    City AS Country            -- see schema note at top of script
FROM Customers
WHERE CustomerId IN (SELECT DISTINCT CustomerId FROM Orders);
GO

-- Version 2: subquery with EXISTS
SELECT
    c.CustomerId,
    c.FirstName + ' ' + c.LastName AS [Customer Name],
    c.City AS Country               -- see schema note at top of script
FROM Customers c
WHERE EXISTS (
    SELECT 1 FROM Orders o WHERE o.CustomerId = c.CustomerId
);
GO

-- Section B, Task 1: View showing customer order activity
CREATE OR ALTER VIEW CustomerOrders AS
SELECT
    c.FirstName + ' ' + c.LastName AS CustomerName,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerId = o.CustomerId;
GO

-- Test the view
SELECT * FROM CustomerOrders;
GO

-- Section B, Task 2: CTE - total orders placed per customer
WITH CustomerOrderCounts AS (
    SELECT
        c.CustomerId,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        COUNT(o.OrderId) AS NumberOfOrders
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerId = o.CustomerId
    GROUP BY c.CustomerId, c.FirstName, c.LastName
)
SELECT CustomerName, NumberOfOrders
FROM CustomerOrderCounts
ORDER BY NumberOfOrders DESC;
GO

-- Section C: Stored procedure to retrieve all orders for a given customer
CREATE OR ALTER PROCEDURE GetCustomerOrders
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- IF...ELSE logic: make sure the customer actually exists first
    IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerId = @CustomerID)
    BEGIN
        PRINT 'No customer found with CustomerID = ' + CAST(@CustomerID AS VARCHAR(10));
        RETURN;
    END
    ELSE
    BEGIN
        SELECT
            OrderId,
            OrderDate,
            StatusCode AS OrderStatus,
            TotalAmount
        FROM Orders
        WHERE CustomerId = @CustomerID;
    END
END
GO

-- Execute the stored procedure for CustomerID = 1
EXEC GetCustomerOrders @CustomerID = 1;
GO

/* ============================================================================
   ACTIVITY 8 - TRANSACTIONS AND ERROR HANDLING
   (Required by the Learning Outcomes / Project Submission checklist)
   Demonstrates: IF...ELSE, TRANSACTIONS, TRY...CATCH
   A stored procedure that safely places a new order for an existing customer.
   ============================================================================ */
CREATE OR ALTER PROCEDURE PlaceNewOrder
    @CustomerID   INT,
    @OrderDate    DATE,
    @StatusCode   CHAR(1),
    @TotalAmount  DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- IF...ELSE logic: validate the customer exists before starting a transaction
    IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerId = @CustomerID)
    BEGIN
        PRINT 'Cannot place order: CustomerID ' + CAST(@CustomerID AS VARCHAR(10)) + ' does not exist.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Orders (CustomerId, OrderDate, StatusCode, TotalAmount)
        VALUES (@CustomerID, @OrderDate, @StatusCode, @TotalAmount);

        COMMIT TRANSACTION;
        PRINT 'Order successfully placed for CustomerID ' + CAST(@CustomerID AS VARCHAR(10)) + '.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        PRINT 'An error occurred while placing the order: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- Successful example
EXEC PlaceNewOrder @CustomerID = 2, @OrderDate = '2026-09-01', @StatusCode = 'P', @TotalAmount = 275.50;
GO

-- Failure example: invalid StatusCode value triggers the CHECK constraint,
-- which is caught by TRY...CATCH and rolled back safely
EXEC PlaceNewOrder @CustomerID = 3, @OrderDate = '2026-09-02', @StatusCode = 'X', @TotalAmount = 100.00;
GO

-- Confirm the successful order was saved and the failed one was not
SELECT * FROM Orders ORDER BY OrderId;
GO