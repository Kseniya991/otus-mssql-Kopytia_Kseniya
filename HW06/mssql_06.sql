USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

Select 
	*
From
	(select
		FORMAT(DATEADD(month,DATEDIFF(MONTH,0,i.InvoiceDate),0), 'dd/MM/yyyy')  as InvoiceMonth,
		substring(c.CustomerName,CHARINDEX('(',c.CustomerName)+1, (CHARINDEX(')',c.CustomerName)-CHARINDEX('(',c.CustomerName) )-1) as CustName,
		i.OrderID
	From Sales.Invoices as i
	join Sales.Customers as c
		on i.customerID = c.CustomerID
			and c.[CustomerID] in (2,3,4,5,6)) as cust
PIVOT
	(count(OrderID)
		FOR CustName IN ([Peeples Valley], [AZ, Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND])
	)AS pvt
;


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
SELECT 
	CustomerName,
	AddressLine
FROM (
		select
			CustomerName,
			DeliveryAddressLine1,
			DeliveryAddressLine2
		From  Sales.Customers 
		Where CustomerName like ('Tailspin Toys%')
) AS PeopleAdress
UNPIVOT (AddressLine FOR Name IN (DeliveryAddressLine1, DeliveryAddressLine2)) AS unpt;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/
SELECT 
	CountryID,
	CountryName,
	Code
FROM (
		Select
			CountryID,
			CountryName,
			ISNull(IsoAlpha3Code,0) as IsoAlphaCode,
			cast (IsNull(IsoNumericCode,0) as nvarchar(3)) as IsoNumCode
		from Application.Countries
	) AS Country
UNPIVOT (Code FOR Name IN (IsoAlphaCode, IsoNumCode)) AS unpt;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
SELECT
	S.customerID,
	C.CustomerName, 
	S.StockItemID,
	S.UnitPrice,
	S.InvoiceDateLast
FROM Sales.Customers C
CROSS APPLY (select top 2
				i.customerID,
				il.StockItemID,
				il.UnitPrice,
				max(i.InvoiceDate) as InvoiceDateLast
			From Sales.Invoices as i 
			join Sales.InvoiceLines as il
				on i.InvoiceID = il.InvoiceID
			WHERE i.CustomerID = C.CustomerID
			group by i.customerID,il.StockItemID,il.UnitPrice
			Order by i.customerID,il.UnitPrice desc,il.StockItemID
) AS S
ORDER BY C.CustomerName;
