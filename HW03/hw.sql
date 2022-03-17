USE WideWorldImporters
/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
Select 
	YEAR (i.InvoiceDate) as yearInvoice
	,MONTH (i.InvoiceDate) as MonthInvoice 
	,avg(il.UnitPrice)as avgPrice
	,sum(il.UnitPrice * il.Quantity)as sumInvoice
From Sales.Invoices i
left join sales.InvoiceLines il
on i.InvoiceID = il.InvoiceID
Group by YEAR (i.InvoiceDate),MONTH (i.InvoiceDate)
Order by YEAR (i.InvoiceDate),MONTH (i.InvoiceDate)
;

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 10 000
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select 
	YEAR (i.InvoiceDate) as yearInvoice
	,MONTH (i.InvoiceDate) as MonthInvoice 
	,sum(il.UnitPrice * il.Quantity)as sumInvoice
From Sales.Invoices i
left join sales.InvoiceLines il
on i.InvoiceID = il.InvoiceID
Group by YEAR (i.InvoiceDate),MONTH (i.InvoiceDate)
Having sum(il.UnitPrice * il.Quantity)>10000
union 
Select 
	YEAR (i.InvoiceDate) as yearInvoice
	,MONTH (i.InvoiceDate) as MonthInvoice 
	,0
From Sales.Invoices i
left join sales.InvoiceLines il
on i.InvoiceID = il.InvoiceID
Group by YEAR (i.InvoiceDate),MONTH (i.InvoiceDate)
Having sum(il.UnitPrice * il.Quantity)<10000
Order by YEAR (i.InvoiceDate),MONTH (i.InvoiceDate)
;

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.
Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного
Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
Select 
	YEAR (i.InvoiceDate) as yearInvoice
	,MONTH (i.InvoiceDate) as MonthInvoice 
	,si.StockItemName
	,sum(il.UnitPrice * il.Quantity)as sumInvoice
	,min(i.InvoiceDate) as firstDateInvoice
	,Sum(il.Quantity) as SumQuantity
From Sales.Invoices i
left join sales.InvoiceLines il
on i.InvoiceID = il.InvoiceID
left join Warehouse.StockItems si
on si.StockItemID = il.StockItemID
Group by YEAR (i.InvoiceDate),MONTH (i.InvoiceDate),StockItemName
Having Sum(il.Quantity)<50
union
Select 
	YEAR (i.InvoiceDate) as yearInvoice
	,MONTH (i.InvoiceDate) as MonthInvoice 
	,si.StockItemName
	,0 as sumInvoice
	,'' as firstDateInvoice
	,0 as SumQuantity
From Sales.Invoices i
left join sales.InvoiceLines il
on i.InvoiceID = il.InvoiceID
left join Warehouse.StockItems si
on si.StockItemID = il.StockItemID
Group by YEAR (i.InvoiceDate),MONTH (i.InvoiceDate),StockItemName
Having Sum(il.Quantity)>50
Order by YEAR (i.InvoiceDate),MONTH (i.InvoiceDate)
;
