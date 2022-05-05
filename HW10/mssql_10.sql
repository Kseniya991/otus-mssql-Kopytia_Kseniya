
---Создание базы данных 
CREATE DATABASE [base_grant_sales]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = base_grant_sales, FILENAME = N'C:\base\base_grant_sales.mdf' , 
	SIZE = 8MB , 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 65536KB )
 LOG ON 
( NAME = base_grant_sales_log, FILENAME = N'C:\base\base_grant_sales_log.ldf' , 
	SIZE = 8MB , 
	MAXSIZE = 10GB , 
	FILEGROWTH = 65536KB )
GO

---- Создание таблиц
use base_grant_sales;
GO

--таблица Заказчики
CREATE TABLE customers(
	customer_id int not null identity(1, 1)  primary key,
	customer_name varchar(255) not null,
	customer_address varchar(255) null,
	contract_cd int not null,
);

--Таблица изделия 
CREATE TABLE products(
	product_id int not null identity(1, 1)  primary key,
	product_name varchar(255) not null,
	weight_per_unit decimal(18,3) null,
	category_product_id int not null,
	product_tipe_id int not null
);

--Таблца Заказы
CREATE TABLE orders(
	order_id 	int not null identity(1, 1)  primary key,
	order_dttm	datetime2 not null,
	customer_id int not null,
	delivery_cd int not null,
	delivery_dt date not null,
	delivery_address varchar(max) not null,
	comments varchar(max) null,
	CONSTRAINT FK_customer_id FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);

--Строка заказа
CREATE TABLE order_lines(
	order_line_id 	int not null identity(1, 1)  primary key,
	order_id int not null ,
	product_id int not null,
	quantity decimal(18,2) not null,
	unit_price decimal(18,2) not null,
	total_sum decimal(18,2) not null,
	currency_cd int not  null,
	CONSTRAINT FK_order_id FOREIGN KEY (order_id)
    REFERENCES orders(order_id),
	CONSTRAINT FK_product_id FOREIGN KEY (product_id)
    REFERENCES products(product_id)
);

--Создание ограничений

ALTER TABLE customers
ADD CONSTRAINT check_customer
  CHECK (customer_name not in ('Грант','ЗАО ИЦ ГРАНТ','ГРАНТ-ПЛЮС'));

ALTER TABLE orders
ADD CONSTRAINT check_delivery_dt
  CHECK (datediff(mm, delivery_dt, getdate()) <=3);

ALTER TABLE order_lines
ADD CONSTRAINT check_total_sum
  CHECK (total_sum>0);


----Создание индексов 

--Таблица Заказчик (customers)
CREATE UNIQUE INDEX customer_name ON dbo.customers ( customer_name DESC);
CREATE UNIQUE INDEX customer_address ON dbo.customers  ( customer_id desc);

--Таблица Заказы (orders)
CREATE UNIQUE INDEX delivery_address ON dbo.orders (order_id desc, order_dttm desc);

--Таблица Изделия (products)
CREATE UNIQUE INDEX product_name ON dbo.products ( product_name DESC);
