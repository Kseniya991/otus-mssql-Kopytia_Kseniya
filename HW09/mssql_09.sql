----------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
*/


DECLARE @xmlDocument  xml

SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'C:\test\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
as data 

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

MERGE Warehouse.StockItems AS target 
USING (SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] nvarchar(100)  '@Name',
	[SupplierID] int 'SupplierID',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID',
	[QuantityPerOuter] int 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] int 'LeadTimeDays',
	[IsChillerStock] bit 'IsChillerStock',
	[TaxRate] decimal(18,3) 'TaxRate',
	[UnitPrice] decimal(18,2) 'UnitPrice')
	) 
	AS source (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice) 
	ON
	(target.StockItemName = source.StockItemName) 
WHEN MATCHED 
	THEN UPDATE SET
					StockItemName = source.StockItemName,
					SupplierID = source.SupplierID,
					UnitPackageID = source.UnitPackageID,
					OuterPackageID = source.OuterPackageID,
					QuantityPerOuter = source.QuantityPerOuter,
					TypicalWeightPerUnit = source.TypicalWeightPerUnit,
					LeadTimeDays = source.LeadTimeDays,
					IsChillerStock = source.IsChillerStock,
					TaxRate = source.TaxRate,
					UnitPrice = source.UnitPrice,
					LastEditedBy = 1
WHEN NOT MATCHED 
	THEN INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice,LastEditedBy) 
		VALUES (source.StockItemName,source.SupplierID,source.UnitPackageID,source.OuterPackageID,source.QuantityPerOuter,source.TypicalWeightPerUnit,source.LeadTimeDays,source.IsChillerStock,source.TaxRate,source.UnitPrice,1) 
OUTPUT deleted.*, $action, inserted.*;

EXEC sp_xml_removedocument @docHandle

GO

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
Сделать два варианта: с помощью OPENXML и через XQuery.
*/

 DECLARE @x XML

 SELECT @x = (SELECT 
     StockItemName AS [@Name],
     SupplierID AS [SupplierID],
	 UnitPackageID AS [Package/UnitPackageID], 
     OuterPackageID AS [Package/OuterPackageID], 
     QuantityPerOuter AS [Package/QuantityPerOuter], 
     TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit],
     LeadTimeDays AS [LeadTimeDays],
     IsChillerStock AS [IsChillerStock],
     TaxRate AS [TaxRate],
     UnitPrice AS [UnitPrice]
 FROM Warehouse.StockItems
 FOR XML PATH('Item'), ROOT('StockItems'))

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @x

-----------------------------------------------Вариант 1
SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] nvarchar(100)  '@Name',
	[SupplierID] int 'SupplierID',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID',
	[QuantityPerOuter] int 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] int 'LeadTimeDays',
	[IsChillerStock] bit 'IsChillerStock',
	[TaxRate] decimal(18,3) 'TaxRate',
	[UnitPrice] decimal(18,2) 'UnitPrice')
-----------------------------------------------------Вариант 2
SELECT  
	s.StockItems.value('(@Name)[1]', 'varchar(100)') as [StockItemName],
	s.StockItems.value('(SupplierID)[1]', 'int') as [SupplierID],
	s.StockItems.value('(Package/UnitPackageID)[1]','int') AS [UnitPackageID],
	s.StockItems.value('(Package/OuterPackageID)[1]','int') AS [OuterPackageID],
	s.StockItems.value('(Package/QuantityPerOuter)[1]','int') AS [QuantityPerOuter],
	s.StockItems.value('(Package/TypicalWeightPerUnit)[1]','decimal(18,3)') AS [TypicalWeightPerUnit],
	s.StockItems.value('(LeadTimeDays)[1]','int') AS [LeadTimeDays],
	s.StockItems.value('(IsChillerStock)[1]','bit') AS [IsChillerStock],
	s.StockItems.value('(TaxRate)[1]','decimal(18,3)') AS [TaxRate],
	s.StockItems.value('(UnitPrice)[1]','decimal(18,2)') AS [UnitPrice']
FROM @x.nodes('/StockItems/Item') as s(StockItems)

EXEC sp_xml_removedocument @docHandle

GO

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

USE WideWorldImporters

SELECT 
    StockItemID,
	StockItemName,
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture,
	JSON_VALUE(CustomFields, '$.Tags[0]') as Tags
FROM Warehouse.StockItems
GO

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле
*/

SELECT 
    StockItemID,
	StockItemName,
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture,
	JSON_QUERY (CustomFields, '$.Tags') as Tags
FROM Warehouse.StockItems
where JSON_VALUE(CustomFields, '$.Tags[0]')  = 'Vintage'
GO
