
USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
;With invoice as
(
	Select
		i.InvoiceID,
		i.InvoiceDate,
		c.CustomerName,
		sum(il.Quantity * il.UnitPrice) as SumInvoice
	From Sales.Invoices i
	left join Sales.InvoiceLines il
		on i.InvoiceID =il.InvoiceID
	join Sales.Customers c
		on c.CustomerID = i.CustomerID
	where Year(i.InvoiceDate) >=2015
	group by i.InvoiceID,i.InvoiceDate,c.CustomerName
)
Select 
	i.InvoiceID,
	i.CustomerName,
	i.InvoiceDate,
	i.SumInvoice,
	sum(i2.SumInvoice) as TotalInvoice
from invoice i
inner join invoice i2
	on  year(i2.InvoiceDate) <= year(i.InvoiceDate) 
		and month(i2.InvoiceDate) <= Month(i.InvoiceDate) 
group by year(i.InvoiceDate),month(i.InvoiceDate),i.InvoiceID,i.CustomerName,i.InvoiceDate,i.SumInvoice
order by i.InvoiceDate,i.InvoiceID

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
;With invoice as
(
	Select
		i.InvoiceID,
		i.InvoiceDate,
		c.CustomerName,
		sum(il.Quantity * il.UnitPrice) as SumInvoice
	From Sales.Invoices i
	left join Sales.InvoiceLines il
		on i.InvoiceID =il.InvoiceID
	join Sales.Customers c
		on c.CustomerID = i.CustomerID
	where Year(i.InvoiceDate) >=2015
	group by i.InvoiceID,i.InvoiceDate,c.CustomerName
)
Select 
	i.InvoiceID,
	i.CustomerName,
	i.InvoiceDate,
	i.SumInvoice,
	sum(SumInvoice) over (partition by year(i.InvoiceDate),month(i.InvoiceDate) order by year(i.InvoiceDate),month(i.InvoiceDate)) as total
from invoice i
order by i.InvoiceDate,i.InvoiceID

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
;with top_sales as 
(
	Select 
		MonthSale,
		StockItemName,
		StockItemQuantity,
		row_number () over (partition by MonthSale order by StockItemQuantity desc ) as rn
	From (
			select
				month(i.InvoiceDate) as MonthSale,
				si.StockItemName,
				sum(il.Quantity)as StockItemQuantity 
			From Sales.Invoices i
			left join Sales.InvoiceLines il
				on i.InvoiceID = il.InvoiceID
			join Warehouse.StockItems si
				on si.StockItemID = il.StockItemID
			where year (i.InvoiceDate)=2016
			group by month(i.InvoiceDate),il.StockItemID,si.StockItemName
		) as sales
)
Select
	MonthSale,
	StockItemName
From top_sales
where rn<=2
order by MonthSale,rn 
/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/
Select
	StockItemID,
	StockItemName,
	Brand,
	UnitPrice,
	dense_rank() over (order by left (StockItemName,1))  as rn,
	sum(QuantityPerOuter) over(partition by StockItemID) as QuantityItem,
	sum(QuantityPerOuter) over(partition by left (StockItemName,1)) as QuantityItem_Letter,
	LEAD(StockItemID) OVER(ORDER BY StockItemName) as NextId,
	Lag(StockItemID) OVER(ORDER BY StockItemName) as PrevId,
	LAG(StockItemName,2,'No items') OVER(ORDER BY StockItemName) as PrevName, 
	NTILE(30) OVER(ORDER BY TypicalWeightPerUnit)  as WeightGroups
From Warehouse.StockItems
/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/


Select
	SalespersonPersonID,
	FullName as SalespersonPersonFullName,
	LastCust as LastCustID,
	c.CustomerName
	LastDate,
	TotalSum
From 
(
	Select
		SalespersonPersonID,
		Invoices.InvoiceID,
		p.FullName,
		FIRST_VALUE (CustomerID) over (partition by SalespersonPersonID order by InvoiceDate desc, Invoices.InvoiceID desc) as LastCust,
		FIRST_VALUE (InvoiceDate) over (partition by SalespersonPersonID order by InvoiceDate desc,Invoices.InvoiceID desc) as LastDate,
		FIRST_VALUE (Invoices.InvoiceID) over (partition by SalespersonPersonID order by InvoiceDate desc,Invoices.InvoiceID desc) as LastInvoices,
		TotalSum,
		ROW_NUMBER() over (partition by SalespersonPersonID order by SalespersonPersonID)as rn 
	From Sales.Invoices 
	join 
	(
		Select
			InvoiceID,
			Sum (Quantity*UnitPrice) as TotalSum
		From Sales.InvoiceLines
		group by InvoiceID
	) il
		on Invoices.InvoiceID = il.InvoiceID
	join Application.People as p
		on p.PersonID = Invoices.SalespersonPersonID
) as SalesInvoice
join Sales.Customers as c
on SalesInvoice.LastCust = c.CustomerID
Where rn = 1;

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
Select
	CustomerID,
	CustomerName,
	StockItemID,
	StockItemDescription,
	UnitPrice,
	InvoiceDate
From(
		Select
			i.CustomerID,
			c.CustomerName,
			il.StockItemID,
			il.Description as StockItemDescription ,
			il.UnitPrice,
			max(i.InvoiceDate) as InvoiceDate,
			DENSE_RANK() over (partition by i.CustomerID order by il.UnitPrice desc,il.StockItemID) as dr
		From Sales.Invoices as i
		join Sales.InvoiceLines as il
			on i.InvoiceID = il.InvoiceID
		join Warehouse.StockItems as si
			on si.StockItemID =il.StockItemID
		join Sales.Customers as c
			on c.CustomerID = i.CustomerID
		group by i.CustomerID,c.CustomerName,il.StockItemID,il.Description,	il.UnitPrice
	) as TopSalesProucts
where dr <=2
Order by CustomerID, UnitPrice desc
