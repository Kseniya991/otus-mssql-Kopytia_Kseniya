-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO  Sales.Customers
(CustomerID,CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,
DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,
FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,DeliveryLocation,PostalAddressLine1,
PostalAddressLine2,PostalPostalCode,LastEditedBy)
VALUES
	(NEXT VALUE FOR Sequences.CustomerID,'Ivanov1',1061,5,NULL,3261,NULL,3,19881,19881,1600.00,'2016-05-07',0.000,0,0,7,'(206) 555-0100','(206) 555-0101',NULL,NULL,'http://www.microsoft.com/','Shop 12','652 Victoria Lane',90243,0xE6100000010C11154FE2182D4740159ADA087A035FC0,'PO Box 8112','Milicaville',90243,1),
	(NEXT VALUE FOR Sequences.CustomerID,'Petrov',1061,5,NULL,3261,NULL,3,19881,19881,1600.00,'2016-05-07',0.000,0,0,7,'(206) 555-0100','(206) 555-0101',NULL,NULL,'http://www.microsoft.com/','Shop 12','652 Victoria Lane',90243,0xE6100000010C11154FE2182D4740159ADA087A035FC0,'PO Box 8112','Milicaville',90243,1),
	(NEXT VALUE FOR Sequences.CustomerID,'Sidorov',1061,5,NULL,3261,NULL,3,19881,19881,1600.00,'2016-05-07',0.000,0,0,7,'(206) 555-0100','(206) 555-0101',NULL,NULL,'http://www.microsoft.com/','Shop 12','652 Victoria Lane',90243,0xE6100000010C11154FE2182D4740159ADA087A035FC0,'PO Box 8112','Milicaville',90243,1),
	(NEXT VALUE FOR Sequences.CustomerID,'Smirnov',1061,5,NULL,3261,NULL,3,19881,19881,1600.00,'2016-05-07',0.000,0,0,7,'(206) 555-0100','(206) 555-0101',NULL,NULL,'http://www.microsoft.com/','Shop 12','652 Victoria Lane',90243,0xE6100000010C11154FE2182D4740159ADA087A035FC0,'PO Box 8112','Milicaville',90243,1),
	(NEXT VALUE FOR Sequences.CustomerID,'Popov',1061,5,NULL,3261,NULL,3,19881,19881,1600.00,'2016-05-07',0.000,0,0,7,'(206) 555-0100','(206) 555-0101',NULL,NULL,'http://www.microsoft.com/','Shop 12','652 Victoria Lane',90243,0xE6100000010C11154FE2182D4740159ADA087A035FC0,'PO Box 8112','Milicaville',90243,1);


/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM	Sales.Customers
	WHERE CustomerName = 'Sidorov' 


/*
3. Изменить одну запись, из добавленных через UPDATE
*/
Update Sales.Customers
SET 
	CustomerName = 'Ivanov',
	FaxNumber = '(999) 999-999'
WHERE CustomerName = 'Ivanov1';


/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

MERGE Sales.Customers AS target 
USING (Select
			5556 as CustomerID,
			'Sidorov' as CustomerName,
			5556 as BillToCustomerID,
			3 as CustomerCategoryID
	) 
	AS source (CustomerID,CustomerName,BillToCustomerID,CustomerCategoryID) 
	ON
	(target.CustomerName = source.CustomerName) 
WHEN MATCHED 
	THEN UPDATE SET CustomerID = source.CustomerID,
					CustomerName = source.CustomerName,
					BillToCustomerID = source.BillToCustomerID,
					CustomerCategoryID = source.CustomerCategoryID
WHEN NOT MATCHED 
	THEN INSERT (CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,
				DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,
				FaxNumber,DeliveryRun,RunPosition,WebsiteURL,DeliveryAddressLine1,DeliveryAddressLine2,DeliveryPostalCode,DeliveryLocation,PostalAddressLine1,
				PostalAddressLine2,PostalPostalCode,LastEditedBy) 
		VALUES ('Sidorov',1061,5,NULL,3261,NULL,3,19881,19881,1600.00,'2016-05-07',0.000,0,0,7,'(206) 555-0100','(206) 555-0101',NULL,NULL,'http://www.microsoft.com/','Shop 12','652 Victoria Lane',90243,0xE6100000010C11154FE2182D4740159ADA087A035FC0,'PO Box 8112','Milicaville',90243,1) 
OUTPUT deleted.*, $action, inserted.*;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

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

SELECT @@SERVERNAME


exec master..xp_cmdshell 'bcp "[WideWorldImporters].Application.People" out  "C:\test\Application_People.txt" -T -w -t"@eu&$1&" -S  DESKTOP-NTI7U5F\SQL2017'

-----------///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
drop table if exists [Application].[People_BulkTest]

CREATE TABLE [Application].[People_BulkTest](
	[PersonID] [int] NOT NULL,
	[FullName] [nvarchar](50) NOT NULL,
	[PreferredName] [nvarchar](50) NOT NULL,
	[SearchName]  AS (concat([PreferredName],N' ',[FullName])) PERSISTED NOT NULL,
	[IsPermittedToLogon] [bit] NOT NULL,
	[LogonName] [nvarchar](50) NULL,
	[IsExternalLogonProvider] [bit] NOT NULL,
	[HashedPassword] [varbinary](max) NULL,
	[IsSystemUser] [bit] NOT NULL,
	[IsEmployee] [bit] NOT NULL,
	[IsSalesperson] [bit] NOT NULL,
	[UserPreferences] [nvarchar](max) NULL,
	[PhoneNumber] [nvarchar](20) NULL,
	[FaxNumber] [nvarchar](20) NULL,
	[EmailAddress] [nvarchar](256) NULL,
	[Photo] [varbinary](max) NULL,
	[CustomFields] [nvarchar](max) NULL,
	[OtherLanguages]  AS (json_query([CustomFields],N'$.OtherLanguages')),
	[LastEditedBy] [int] NOT NULL,
	[ValidFrom] [datetime2](7) GENERATED ALWAYS AS ROW START NOT NULL,
	[ValidTo] [datetime2](7) GENERATED ALWAYS AS ROW END NOT NULL,
 CONSTRAINT [PK_Application_People_BulkTest] PRIMARY KEY CLUSTERED 
(
	[PersonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [USERDATA],
	PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
) ON [USERDATA] TEXTIMAGE_ON [USERDATA]
----//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

BULK INSERT [WideWorldImporters].[Application].[People_BulkTest]
				FROM "C:\test\Application_People.txt"
				WITH 
					(
					BATCHSIZE = 1000, 
					DATAFILETYPE = 'widechar',
					FIELDTERMINATOR = '@eu&$1&',
					ROWTERMINATOR ='\n',
					KEEPNULLS,
					TABLOCK        
					);
