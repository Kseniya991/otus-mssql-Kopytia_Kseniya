SET STATISTICS io, time on;

use [WideWorldImporters]
go

--создем временную таблицу сзаказами
CREATE TABLE #OrderDetails
(CustomerID int,
StockItemID int,
UnitPrice decimal(18,3),
Quantity int,
OrderID int
);
	
--вставляем данные вовременную таблицу
with totalSum as 
(SELECT ordTotal.CustomerID 
FROM Sales.OrderLines AS Total
Join Sales.Orders AS ordTotal
On ordTotal.OrderID = Total.OrderID
group by ordTotal.CustomerID
Having SUM(Total.UnitPrice*Total.Quantity) >250000
)
INSERT INTO #OrderDetails
(CustomerID,StockItemID,UnitPrice,Quantity,OrderID)
Select ord.CustomerID, det.StockItemID, det.UnitPrice, det.Quantity, ord.OrderID
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
join totalSum as ts
on ts.CustomerID = ord.CustomerID
join  Warehouse.StockItems AS It
on It.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND it.SupplierId = 12
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0

--select count(*) from #OrderDetails


Select it.CustomerID, it.StockItemID, SUM(it.UnitPrice), SUM(it.Quantity), COUNT(it.OrderID)
FROM #OrderDetails AS it
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = it.StockItemID
GROUP BY it.CustomerID, it.StockItemID
ORDER BY it.CustomerID, it.StockItemID

--исходный запрос
Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId
FROM Warehouse.StockItems AS It
Where It.StockItemID = det.StockItemID) = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total
Join Sales.Orders AS ordTotal
On ordTotal.OrderID = Total.OrderID
WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID
