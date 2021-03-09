-- CREATE SCHEMA if doesn't exist
-- create schema dw;


DROP TABLE IF EXISTS dw.sales_fact;


-- PRODUCT

DROP TABLE IF EXISTS dw.product_dim;

CREATE TABLE dw.product_dim
(
 prod_id   serial NOT NULL,
 product_id	  varchar(50) NOT NULL,
 product_name varchar(127) NOT NULL,
 subcategory  varchar(50) NOT NULL,
 category     varchar(50) NOT NULL,
 CONSTRAINT PK_product_dim PRIMARY KEY ( prod_id )
);

insert into dw.product_dim
select 
		100+row_number() over ()
		,product_id
		,product_name
		,subcategory
		,category 
from (select distinct product_id, product_name, subcategory, category from stg.orders) pn;

select * from dw.product_dim pd ;


-- SHIPPING

DROP TABLE IF EXISTS dw.ship_dim;

CREATE TABLE dw.ship_dim
(
 ship_id   serial NOT NULL,
 ship_mode varchar(50) NOT NULL,
 CONSTRAINT PK_ship_dim PRIMARY KEY ( ship_id )
);

insert into dw.ship_dim
select 
		100+row_number() over ()
		,ship_mode 
from (select distinct ship_mode from stg.orders) a;

select * from dw.ship_dim;

-- GEOGRAPHY

DROP TABLE IF EXISTS dw.geo_dim;

CREATE TABLE dw.geo_dim
(
 geo_id      serial NOT NULL,
 country     varchar(30) NOT NULL,
 city        varchar(50) NOT NULL,
 state       varchar(50) NOT NULL,
 postal_code varchar(20) NULL,
 CONSTRAINT PK_geo_dim PRIMARY KEY ( geo_id )
);

truncate table dw.geo_dim;

insert into dw.geo_dim
select 
		100+row_number() over ()
		,country
		,city
		,state
		,postal_code 
from (select distinct country, city, state, postal_code from stg.orders) a;

--data quality check
select distinct country, city, state, postal_code from dw.geo_dim
where country is null or city is null or postal_code is null;

-- City Burlington, Vermont doesn't have postal code
update dw.geo_dim
set postal_code = '05401'
where city = 'Burlington'  and postal_code is null;

--also update source file
update stg.orders
set postal_code = '05401'
where city = 'Burlington'  and postal_code is null;

select * from dw.geo_dim;


-- CUSTOMER

DROP TABLE IF EXISTS dw.customer_dim;

CREATE TABLE dw.customer_dim
(
 cust_id   serial NOT NULL,
 customer_id	   varchar(50) NOT NULL,
 customer_name varchar(50) NOT NULL,
 segment       varchar(50) NOT NULL,
 CONSTRAINT PK_customer_dim PRIMARY KEY ( cust_id )
);

insert into dw.customer_dim
select 
		100+row_number() over()
		,customer_id
		,customer_name
		,segment 
from (select distinct customer_id, customer_name, segment from stg.orders) b;

select * from dw.customer_dim;


-- CALENDAR

DROP TABLE IF EXISTS dw.calendar_dim;

CREATE TABLE dw.calendar_dim
(
date_id serial  NOT NULL,
year        int NOT NULL,
quarter     int NOT NULL,
month       int NOT NULL,
week        int NOT NULL,
date        date NOT NULL,
week_day    varchar(20) NOT NULL,
leap  varchar(20) NOT NULL,
CONSTRAINT PK_calendar_dim PRIMARY KEY ( date_id )
);

insert into dw.calendar_dim 
select 
to_char(date,'yyyymmdd')::int as date_id,  
       extract('year' from date)::int as year,
       extract('quarter' from date)::int as quarter,
       extract('month' from date)::int as month,
       extract('week' from date)::int as week,
       date::date,
       to_char(date, 'dy') as week_day,
       extract('day' from
               (date + interval '2 month - 1 day')
              ) = 29
       as leap
  from generate_series(date '2000-01-01',
                       date '2030-01-01',
                       interval '1 day')
       as t(date);

select * from dw.calendar_dim;
      

-- SALES
      
DROP TABLE IF EXISTS dw.sales_fact;

CREATE TABLE dw.sales_fact
(
 sales_id      serial NOT NULL,
 order_id      varchar(50) NOT NULL,
 order_date_id int NOT NULL,
 ship_date_id  int NOT NULL,
 ship_id       integer NOT NULL,
 prod_id       integer NOT NULL,
 cust_id   	   integer NOT NULL,
 geo_id        integer NOT NULL,
 sales        numeric(9,4) NOT NULL,
 quantity      int NOT NULL,
 discount      numeric(8,2) NOT NULL,
 profit        numeric(22,16) NOT NULL,
 CONSTRAINT PK_sales_fact PRIMARY KEY ( sales_id ),
 CONSTRAINT FK_120 FOREIGN KEY ( ship_id ) REFERENCES dw.ship_dim ( ship_id ),
 CONSTRAINT FK_123 FOREIGN KEY ( prod_id ) REFERENCES dw.product_dim ( prod_id ),
 CONSTRAINT FK_126 FOREIGN KEY ( cust_id ) REFERENCES dw.customer_dim ( cust_id ),
 CONSTRAINT FK_129 FOREIGN KEY ( geo_id ) REFERENCES dw.geo_dim ( geo_id )
);

insert into dw.sales_fact 
select 
		100+row_number() over() as sales_id
		,order_id
	 	,to_char(order_date,'yyyymmdd')::int as  order_date_id
	 	,to_char(ship_date,'yyyymmdd')::int as  ship_date_id
		,s.ship_id
		,p.prod_id
		,cust_id
		,geo_id
		,sales
		,quantity
		,discount
		,profit
from stg.orders o 
inner join dw.ship_dim s on o.ship_mode = s.ship_mode
inner join dw.geo_dim g on g.postal_code = o.postal_code and g.country = o.country and g.city = o.city and g.state = o.state
inner join dw.product_dim p on o.product_name = p.product_name and o.subcategory=p.subcategory and o.category=p.category and o.product_id=p.product_id 
inner join dw.customer_dim cd on cd.customer_id=o.customer_id and cd.customer_name=o.customer_name and o.segment=cd.segment;

-- you have got 9994 rows, right?
select count(*) from dw.sales_fact sf
inner join dw.ship_dim s on sf.ship_id=s.ship_id
inner join dw.geo_dim g on sf.geo_id=g.geo_id
inner join dw.product_dim p on sf.prod_id=p.prod_id
inner join dw.customer_dim cd on sf.cust_id=cd.cust_id;
