/*
Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".
*/

USE WideWorldImporters;

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

CREATE or ALTER FUNCTION Sales.top_cust ()
RETURNS TABLE
AS
RETURN 
(
	Select 
		top (1) i.CustomerID, 
		c.CustomerName,
		sum (il.Quantity * il.UnitPrice) as totalSum
	From Sales.Invoices i
	join Sales.InvoiceLines il 
	on i.InvoiceID = il.InvoiceID
	join Sales.Customers c
	on c.CustomerID = i.CustomerID
	Group by i.CustomerID,c.CustomerName
	Order by sum (il.Quantity * il.UnitPrice) desc
)
GO

SELECT * FROM Sales.top_cust ();
 
--DROP FUNCTION Sales.top_cust

/*2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE SCHEMA [sales_procedure] AUTHORIZATION [dbo]
GO

IF OBJECT_ID ( 'sales_procedure.cust_sales_sum', 'P' ) IS NOT NULL   
    DROP PROCEDURE sales_procedure.cust_sales_sum
GO

CREATE PROCEDURE sales_procedure.cust_sales_sum   
    @SearchID int = null 
AS   
    SET NOCOUNT ON; 
	IF @SearchID IS NULL  
	BEGIN  
	   THROW 50000, 'ОШИБКА: Неоходимо передать идентификатор покупателя.' ,1
	   RETURN 
	END        
	Select 
		i.CustomerID, 
		c.CustomerName,
		sum (il.Quantity * il.UnitPrice) as totalSum
	From Sales.Invoices i
	join Sales.InvoiceLines il 
	on i.InvoiceID = il.InvoiceID
	join Sales.Customers c
	on c.CustomerID = i.CustomerID
	WHERE i.CustomerID = @SearchID
	Group by i.CustomerID,c.CustomerName
GO 

EXECUTE sales_procedure.cust_sales_sum  @SearchID = 100;
/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

CREATE or ALTER FUNCTION Sales.top_person ()
RETURNS TABLE
AS
RETURN 
(	Select 
		top (1) i.SalespersonPersonID, 
		p.FullName,
		sum (il.Quantity * il.UnitPrice) as totalSum
	From Sales.Invoices i
	join Sales.InvoiceLines il 
	on i.InvoiceID = il.InvoiceID
	join Application.People p
	on p.PersonID = i.SalespersonPersonID
	Group by i.SalespersonPersonID,p.FullName
	Order by sum (il.Quantity * il.UnitPrice) desc
)

GO

SELECT * FROM Sales.top_person ();

---------------------------------------
IF OBJECT_ID ( 'sales_procedure.person_sales', 'P' ) IS NOT NULL   
    DROP PROCEDURE sales_procedure.person_sales
GO

CREATE PROCEDURE sales_procedure.person_sales 
WITH EXECUTE AS CALLER 
AS   
    SET NOCOUNT ON; 
	Select 
		top (1) i.SalespersonPersonID, 
		p.FullName,
		sum (il.Quantity * il.UnitPrice) as totalSum
	From Sales.Invoices i
	join Sales.InvoiceLines il 
	on i.InvoiceID = il.InvoiceID
	join Application.People p
	on p.PersonID = i.SalespersonPersonID
	Group by i.SalespersonPersonID,p.FullName
	Order by sum (il.Quantity * il.UnitPrice) desc
GO 

EXECUTE sales_procedure.person_sales ;

/*
Входе выполнения запросов, разницы в скорости  и производительности между запросом  выполняемым внутри функции и  внутри процедуры 
исходя из плана запроса не было. Стоимость запроса в обоих случаях была равна 50%.
*/

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

CREATE or ALTER FUNCTION Sales.sum_cust 
(
    @CustomerID INT
)
RETURNS TABLE
AS
RETURN 
(
	Select 
		i.CustomerID, 
		c.CustomerName,
		sum (il.Quantity * il.UnitPrice) as totalSum
	From Sales.Invoices i
	join Sales.InvoiceLines il 
	on i.InvoiceID = il.InvoiceID
	join Sales.Customers c
	on c.CustomerID = i.CustomerID
	where c.CustomerID = @CustomerID
	Group by i.CustomerID,c.CustomerName
)
GO

SELECT cust.CustomerID,cust.CustomerName, totalSum
FROM Sales.Customers cust
CROSS APPLY Sales.sum_cust(CustomerID) AS CustomerSum
Order by cust.CustomerID

