USE WideWorldImporters
/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/
Select 
	StockItemID
	,StockItemName
From Warehouse.StockItems
Where StockItemName like'%urgent%' 
	or StockItemName like'Animal%';
/*

2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/
Select 
	s.SupplierID
	,s.SupplierName
	,p.SupplierID
From Purchasing.Suppliers as s
left join Purchasing.PurchaseOrders as p
on s.SupplierID = p.SupplierID
where p.SupplierID is null;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/
select 
	o.OrderID
	,Convert(nvarchar(10),o.OrderDate,104) as OrderDate
	,DateName(month,o.OrderDate) as MonthOrderDate
	,DATEPART(QUARTER, o.OrderDate) as QUARTEROrderDate
	,case
		when DATEPART (month, o.OrderDate ) in (1,2,3,4)
			then 1
		when  DATEPART (month, o.OrderDate ) in (5,6,7.8)
			then 2
		else 3
	end as TrimesterOrderDate
	,s.CustomerName
From Sales.Orders as o
left join Sales.OrderLines as ol
on ol.OrderID = o.OrderID
left join Sales.Customers as s
on o.CustomerID  = s.CustomerID
where (ol.UnitPrice>100 or ol.Quantity>20) 
	and o.PickingCompletedWhen  is not null
group by o.OrderID,s.CustomerName,o.OrderDate
order by QUARTEROrderDate asc,TrimesterOrderDate asc, OrderDate asc;

--Вариант 2
select 
	o.OrderID
	,Convert(nvarchar(10),o.OrderDate,104) as OrderDate
	,DateName(month,o.OrderDate) as MonthOrderDate
	,DATEPART(QUARTER, o.OrderDate) as QUARTEROrderDate
	,case
		when DATEPART (month, o.OrderDate ) in (1,2,3,4)
			then 1
		when  DATEPART (month, o.OrderDate ) in (5,6,7.8)
			then 2
		else 3
	end as TrimesterOrderDate
	,s.CustomerName
From Sales.Orders as o
left join Sales.OrderLines as ol
on ol.OrderID = o.OrderID
left join Sales.Customers as s
on o.CustomerID  = s.CustomerID
where (ol.UnitPrice>100 or ol.Quantity>20) 
	and o.PickingCompletedWhen  is not null
group by o.OrderID,s.CustomerName,o.OrderDate
order by QUARTEROrderDate asc,TrimesterOrderDate asc, OrderDate asc
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY;
/*

4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/
select 
	dm.DeliveryMethodName
	,po.ExpectedDeliveryDate
	,s.SupplierName
	,p.FullName
From Purchasing.Suppliers as s
left join  Purchasing.PurchaseOrders po 
on s.SupplierID= po.SupplierID
left join Application.DeliveryMethods dm
on dm.DeliveryMethodId = s.DeliveryMethodID
left join Application.People p
on p.PersonID = po.ContactPersonID
where ExpectedDeliveryDate between '2013-01-01' and '2013-02-01'
	and (dm.DeliveryMethodName like 'Air Freight' or dm.DeliveryMethodName like 'Refrigerated Air Freight' )
		and po.IsOrderFinalized = 1;
/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/
select 
	top 10 o.OrderID
	,c.CustomerName
	,p.FullName
	,o.OrderDate 
from Sales.Orders o
left join Sales.Customers c
on o.CustomerID = c.CustomerID
left join Application.People p
on p.PersonID=o.SalespersonPersonID
order by o.OrderDate ;
/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице .
*/
Select
  c.CustomerID
  ,c.CustomerName
  ,c.PhoneNumber
From Sales.Customers c
join Sales.Orders o
on o.CustomerID = c.CustomerID
join Sales.OrderLines ol
on ol.orderID = o.OrderID
join Warehouse.StockItems s
on s.StockItemID = ol.StockItemID
where s.StockItemName like 'Chocolate frogs 250g'
group by c.CustomerID,c.CustomerName,c.PhoneNumber;
