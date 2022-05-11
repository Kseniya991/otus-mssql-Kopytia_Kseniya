----Создание индексов 

--Таблица Заказчик (customers)
CREATE UNIQUE INDEX customer_name ON dbo.customers ( customer_name DESC);
CREATE UNIQUE INDEX customer_address ON dbo.customers  ( customer_id desc);

--Таблица Заказы (orders)
CREATE UNIQUE INDEX delivery_address ON dbo.orders (order_id desc, order_dttm desc);

--Таблица Изделия (products)
CREATE UNIQUE INDEX product_name ON dbo.products ( product_name DESC);

--ДЗ по инденсам

--Создание индексов для таблиц 
--таблица Заказы (orders) полнотекствый поиск по адресу доставки
use base_grant_sales;
GO

sp_configure 'show advanced options', 1;
reconfigure
sp_configure 'default full-text language';


create fulltext catalog wwi_grant_catalog
with accent_sensitivity = on
as default
authorization [dbo]

go

create fulltext index on dbo.orders ( delivery_address language Russian)
key index PK_orders
on (wwi_grant_catalog)
with (
	change_tracking auto,
	stoplist = system
);


--Составной индекс для таблицы Заказчики (customers)
CREATE UNIQUE INDEX name_adress ON dbo.customers (customer_name asc, customer_address asc)
;

--Индексы для таблицы Строки заказа (order_lines)
--Колоночный индекс
create columnstore index ix_sum_order
on dbo.order_lines (total_sum,currency_cd)
go
;

--Индексы для таблицы Изделия (products)
--полнотекстовы поиск по наимеованию изделия 
sp_configure 'show advanced options', 1;
reconfigure
sp_configure 'default full-text language';


create fulltext catalog wwi_grant_product_catalog
with accent_sensitivity = on
as default
authorization [dbo]

go

create fulltext index on dbo.products (product_name language Russian)
key index PK_products
on (wwi_grant_product_catalog)
with (
	change_tracking auto,
	stoplist = system
);

--Составной индекс 
CREATE UNIQUE INDEX category_name ON dbo.products (category_product_id asc,product_name asc)
;
