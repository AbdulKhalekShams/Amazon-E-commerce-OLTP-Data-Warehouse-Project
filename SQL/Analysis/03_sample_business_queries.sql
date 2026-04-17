

SELECT
  SUM(oi.Quantity * oi.UnitPriceEGP) AS GMV,
  COUNT(DISTINCT o.OrderID) AS Orders,
  SUM(oi.Quantity * oi.UnitPriceEGP) / NULLIF(COUNT(DISTINCT o.OrderID),0) AS AOV
FROM dbo.Orders o
JOIN dbo.OrderItems oi ON o.OrderID = oi.OrderID
WHERE o.OrderStatus <> 'Cancelled';


------------------------------------------------------------------------------------------


SELECT
  a.Governorate,
  SUM(oi.Quantity * oi.UnitPriceEGP) AS Sales
FROM dbo.Orders o
JOIN dbo.OrderItems oi ON o.OrderID = oi.OrderID
JOIN dbo.Addresses a ON o.ShipToAddressID = a.AddressID
WHERE o.OrderStatus <> 'Cancelled'
GROUP BY a.Governorate
having a.Governorate = 'South Sinai'
ORDER BY Sales DESC;



--------------------------------------------------------------------------------------------

SELECT
  COUNT(DISTINCT r.OrderItemID) * 1.0 / NULLIF(COUNT(DISTINCT oi.OrderItemID),0) AS ReturnRate
FROM dbo.OrderItems oi
JOIN dbo.Orders o ON oi.OrderID = o.OrderID
LEFT JOIN dbo.Returns r ON r.OrderItemID = oi.OrderItemID
WHERE o.OrderStatus = 'Delivered';


-------------------------------------------------------------------------------------------






















select *
from
		Orders o join OrderItems oi on o.OrderID = oi.OrderID
		join Products p on oi.ProductID = p.ProductID
		join Subcategories sc on p.SubcategoryID = sc.SubcategoryID
		join Categories c on sc.CategoryID = c.CategoryID ;




