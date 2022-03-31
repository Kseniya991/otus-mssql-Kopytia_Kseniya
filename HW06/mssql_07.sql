/*

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

USE WideWorldImporters

DECLARE @dml AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)
 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
       + QUOTENAME(CustName)
FROM (Select 
		distinct CustomerName as CustName
		From Sales.Customers as c) AS Cust

SELECT @ColumnName as ColumnName 

SET @dml = 
  N'SELECT InvoiceMonth, ' +@ColumnName + ' FROM
  (
	select
		FORMAT(DATEADD(month,DATEDIFF(MONTH,0,i.InvoiceDate),0), ''dd/MM/yyyy'')  as InvoiceMonth,
		c.CustomerName as CustName,
		orderId
	From Sales.Invoices as i
	join Sales.Customers as c
		on i.customerID = c.CustomerID) AS T
    PIVOT( count(orderId)
           FOR CustName IN (' + @ColumnName + ')) AS PVTTable'

EXEC sp_executesql @dml
