use WideWorldImporters;

--создаем файловую группу
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [SalespersonID]
GO

--добавляем файл БД
ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'Salesperson', FILENAME = N'c:\test\SalespersonID.ndf' , 
SIZE = 1097152KB , FILEGROWTH = 65536KB ) TO FILEGROUP [SalespersonID]
GO

--создаем функцию партиционирования по SalespersonID 
CREATE PARTITION FUNCTION [fnSalespersonPartition](INT) AS RANGE LEFT FOR VALUES
(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,
21,22,23,24,25);																																																									
GO
-- партиционируем, используя созданную функцию
CREATE PARTITION SCHEME [schmSalespersonPartition] AS PARTITION [fnSalespersonPartition] 
ALL TO ([SalespersonID])
GO

--создаем первую таблицу

CREATE TABLE [Sales].[OrderLinesSalesperson](
	[OrderLineID] [int] NOT NULL,
	[OrderID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[PickedQuantity] [int] NOT NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
) ON [schmSalespersonPartition]([SalespersonPersonID])
GO

--создаем кластерный индекс для первой таблицы
ALTER TABLE [Sales].[OrderLinesSalesperson] ADD CONSTRAINT PK_Sales_OrderLinesSalesperson 
PRIMARY KEY CLUSTERED  (SalespersonPersonID, OrderID, OrderLineID)
 ON [schmSalespersonPartition]([SalespersonPersonID]);

 --создаем вторую таблицу

 CREATE TABLE [Sales].[OrdersSalesperson](
	[OrderID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[Comments] [nvarchar](max) NULL,
	[DeliveryInstructions] [nvarchar](max) NULL,
	[InternalComments] [nvarchar](max) NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
) ON [schmSalespersonPartition]([SalespersonPersonID])
GO

--создаем индекс для второй таблицы
ALTER TABLE [Sales].[OrdersSalesperson] ADD CONSTRAINT PK_Sales_OrdersSalesperson 
PRIMARY KEY CLUSTERED  (SalespersonPersonID, OrderID)
ON [schmSalespersonPartition]([SalespersonPersonID]);

--Выгружаем данные

-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

--SELECT @@SERVERNAME

exec master..xp_cmdshell 'bcp "SELECT [OrderLineID], L.[OrderID], O.[SalespersonPersonID], [StockItemID], [Description], [PackageTypeID], [Quantity],[UnitPrice], [TaxRate], [PickedQuantity], L.[PickingCompletedWhen], L.[LastEditedBy], L.[LastEditedWhen] FROM [WideWorldImporters].Sales.Orders AS O JOIN [WideWorldImporters].Sales.OrderLines AS L ON O.OrderID = L.OrderID" queryout "c:\test\OrderLines.txt" -T -w -t "@eu&$" -S DESKTOP-NTI7U5F\SQL2017'

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Orders" out  "c:\test\Orders.txt" -T -w -t "@eu&$" -S DESKTOP-NTI7U5F\SQL2017'

--переносм данные в партиционированные таблицы
DECLARE 
	@path VARCHAR(256),
	@FileName VARCHAR(256),
	@onlyScript BIT, 
	@query	nVARCHAR(MAX),
	@dbname VARCHAR(255),
	@batchsize INT
	
	SELECT @dbname = DB_NAME();
	SET @batchsize = 1000;

	/*******************************************************************/
	/*******************************************************************/
	/******Change for path and file name*******************************/
	SET @path = 'c:\test\';
	SET @FileName = 'OrderLines.txt';
	/*******************************************************************/
	/*******************************************************************/
	/*******************************************************************/

	SET @onlyScript = 0;
	
	BEGIN TRY

		IF @FileName IS NOT NULL
		BEGIN
			SET @query = 'BULK INSERT ['+@dbname+'].[Sales].[OrderLinesSalesperson]
				   FROM "'+@path+@FileName+'"
				   WITH 
					 (
						BATCHSIZE = '+CAST(@batchsize AS VARCHAR(255))+', 
						DATAFILETYPE = ''widechar'',
						FIELDTERMINATOR = ''@eu&$'',
						ROWTERMINATOR =''\n'',
						KEEPNULLS,
						TABLOCK        
					  );'

			PRINT @query

			IF @onlyScript = 0
				EXEC sp_executesql @query 
			PRINT 'Bulk insert '+@FileName+' is done, current time '+CONVERT(VARCHAR, GETUTCDATE(),120);
		END;
	END TRY

	BEGIN CATCH
		SELECT   
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_MESSAGE() AS ErrorMessage; 

		PRINT 'ERROR in Bulk insert '+@FileName+' , current time '+CONVERT(VARCHAR, GETUTCDATE(),120);

	END CATCH
	
select Count(*) AS OrderLines from [Sales].[OrderLinesSalesperson];

GO



DECLARE 
	@path VARCHAR(256),
	@FileName VARCHAR(256),
	@onlyScript BIT, 
	@query	nVARCHAR(MAX),
	@dbname VARCHAR(255),
	@batchsize INT
	
	SELECT @dbname = DB_NAME();
	SET @batchsize = 1000;
	SET @onlyScript = 0
	/*******************************************************************/
	/*******************************************************************/
	/******Change for path and file name*******************************/
	SET @path = 'c:\test\';
SET @FileName = 'Orders.txt';
BEGIN TRY

		IF @FileName IS NOT NULL
		BEGIN
			SET @query = 'BULK INSERT ['+@dbname+'].[Sales].[OrdersSalesperson]
				   FROM "'+@path+@FileName+'"
				   WITH 
					 (
						BATCHSIZE = '+CAST(@batchsize AS VARCHAR(255))+', 
						DATAFILETYPE = ''widechar'',
						FIELDTERMINATOR = ''@eu&$'',
						ROWTERMINATOR =''\n'',
						KEEPNULLS,
						TABLOCK        
					  );'

			PRINT @query

			IF @onlyScript = 0
				EXEC sp_executesql @query 
			PRINT 'Bulk insert '+@FileName+' is done, current time '+CONVERT(VARCHAR, GETUTCDATE(),120);
		END;
	END TRY

	BEGIN CATCH
		SELECT   
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_MESSAGE() AS ErrorMessage; 

		PRINT 'ERROR in Bulk insert '+@FileName+' , current time '+CONVERT(VARCHAR, GETUTCDATE(),120);

	END CATCH


select Count(*) AS Orders from [Sales].OrdersSalesperson;



select * from [Sales].[OrdersSalesperson];

--Проверяем все ли корректно отработало и партиционировались ли данные

select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1

--смотрим как конкретно по диапазонам разделились данные
SELECT  $PARTITION.fnSalespersonPartition([SalespersonPersonID]) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN([SalespersonPersonID])
		,MAX([SalespersonPersonID]) 
FROM Sales.OrdersSalesperson
GROUP BY $PARTITION.fnSalespersonPartition([SalespersonPersonID]) 
ORDER BY Partition ;  
