
USE WideWorldImporters
 
/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/
--Вариант 1
SELECT
	PersonId, 
	FullName
FROM Application.People p
WHERE IsSalesperson = 1 and p.PersonId not in (Select 
													SalespersonPersonID
											   from Sales.Invoices
											   where InvoiceDate = '2015-07-04')
;
--Вариант 1
;WITH CTE AS 
(
	Select 
		SalespersonPersonID
	from Sales.Invoices
	where InvoiceDate = '2015-07-04'
)
SELECT
	distinct PersonId, 
	FullName
FROM Application.People p
left join cte
	on p.PersonId = cte.SalespersonPersonID
WHERE IsSalesperson = 1 and  cte.SalespersonPersonID is null
;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
--Вариант 1
SELECT 
	StockItemID, 
	StockItemName, 
	UnitPrice 
FROM Warehouse.StockItems
where UnitPrice= (SELECT 
					min(UnitPrice) 
				  FROM Warehouse.StockItems);
--Вариант2
SELECT 
	StockItemID, 
	StockItemName, 
	UnitPrice 
FROM Warehouse.StockItems
where UnitPrice= (select 
					top 1 UnitPrice 
				  FROM Warehouse.StockItems
				  order by UnitPrice asc);


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/
--Вариант 1
Select 
	*
From Sales.Customers as c
where c.CustomerID in (Select 
							top 5 CustomerID
						From Sales.CustomerTransactions
						order by TransactionAmount desc);
--Вариант 2
;with cte as 
(
	Select 
		top 5 CustomerID
	From Sales.CustomerTransactions
	order by TransactionAmount desc)
	Select
	*
	From Sales.Customers as c
	where c.CustomerID in (select CustomerID from cte);

/*
--4. Выберите города (ид и название), в которые были доставлены товары, 
--входящие в тройку самых дорогих товаров, а также имя сотрудника, 
--который осуществлял упаковку заказов (PackedByPersonID).
*/

;with top_products as 
(Select
	top 3 StockItemID
From Warehouse.StockItems
order by UnitPrice desc)
,cust_city as 
(Select 
	c.CityID,
	c.CityName,
	i.InvoiceID,
	p.FullName
From Sales.Invoices i
join Sales.Customers as cust
on cust.CustomerID = i.CustomerID
join Application.Cities c
on cust.DeliveryCityID = c.CityID
join Application.People p
on p.PersonID = i.PackedByPersonID)
Select 
	cc.CityID,
	cc.CityName,
	cc.FullName
From cust_city cc
join Sales.InvoiceLines il
on il.InvoiceID = cc.InvoiceID
	and il.StockItemID in (Select  StockItemID
						   From top_products)
Group by cc.CityID,	cc.CityName,cc.FullName

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --
/*
Запрос выбирает по всем продажам,с суммой продажи больше 27000
Номер заказа, дату продажи, Имя сотрудника совершившего продажу,сумму продажи,сумму заказапо србранны товарам
Попробовала оптимизировать в сторону читабельности запроса. Везде, где можно было заменить подзапросы на join  сделала это.
Разбила основной запрос на две части продажи и заказы вынесла их в cte. Попроизводительность запросов  (в части плана запроса)получилось одинакова, по 50%.
*/
;with cte as 
(SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	p.FullName AS SalesPersonName,
	SUM(SalesTotals.Quantity*SalesTotals.UnitPrice) AS TotalSummByInvoice,
	Invoices.OrderID
FROM Sales.Invoices
JOIN Sales.InvoiceLines as SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID
join Application.People p
on p.PersonID = Invoices.SalespersonPersonID
GROUP BY Invoices.InvoiceId,Invoices.InvoiceDate,p.FullName,OrderID
HAVING SUM(Quantity*UnitPrice) > 27000
)
,cte2 as 
(SELECT 
	SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) as TotalSummForPickedItems,
	Orders.OrderId 
FROM Sales.OrderLines
join Sales.Orders
on OrderLines.OrderId = Orders.OrderId 
Where Orders.PickingCompletedWhen is not NULL
group by Orders.OrderId)
select 
	InvoiceID, 
	InvoiceDate,
	SalesPersonName,
	TotalSummByInvoice,
	TotalSummForPickedItems
from cte
join cte2 
on cte.OrderID = cte2.OrderID
ORDER BY TotalSummByInvoice DESC
